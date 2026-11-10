#!/usr/bin/env python3
"""Run existing NATIVE_RUN kernels on the unchanged PicoRV32 SoC.

All generated firmware, simulation instrumentation and results stay in --output.
No training, production firmware rebuild, or accelerator source changes.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    commands = []

    def run(command, log=None):
        commands.append([str(x) for x in command])
        if log:
            with (out / log).open('w') as stream:
                subprocess.run(command, cwd=out, stdout=stream,
                               stderr=subprocess.STDOUT, check=True)
        else:
            subprocess.run(command, cwd=out, check=True)

    sources = ['start.s', 'main_tinymobilenet.c', 'dl_ops.c', 'quantize.c',
               'tinymobilenet_model_data.c']
    run(['riscv32-unknown-elf-gcc', '-mabi=ilp32', '-march=rv32im',
         '-ffreestanding', '-nostdlib', '-O2', '-DNATIVE_RUN',
         '-DTINYMOBILENET_TEST_COUNT=1', '-T', root / 'sections.lds',
         '-o', out / 'firmware.elf', *[root / s for s in sources]], 'firmware_build.log')
    run(['riscv32-unknown-elf-objcopy', '-O', 'verilog',
         out / 'firmware.elf', out / 'firmware.hex'])
    run(['riscv32-unknown-elf-objdump', '-d', out / 'firmware.elf'], 'firmware.dis')
    if re.search(r'\t(?:divu?|remu?)\s', (out / 'firmware.dis').read_text()):
        raise RuntimeError('Firmware contains unsupported DIV/REM instructions')
    run(['riscv32-unknown-elf-size', out / 'firmware.elf'], 'firmware_size.txt')
    run(['riscv32-unknown-elf-gcc', '--version'], 'compiler_version.txt')
    run(['verilator', '--version'], 'simulator_version.txt')
    # Observe the existing CSR sampling point, without adding firmware instructions.
    # Fail on any peripheral compute transaction, including the multiply peripheral.
    monitor = '''
    always @(posedge clk) begin
        if (resetn && uut.mem_valid &&
            (uut.accel_sel || uut.conv_accel_sel || uut.quant_accel_sel ||
             uut.dw_conv_accel_sel || uut.pw_conv_accel_sel))
            $fatal(1, "CPU BASELINE FAILURE: compute MMIO access");
        if (resetn && uut.cpu.cpu_state == uut.cpu.cpu_state_ld_rs1 &&
            uut.cpu.is_rdcycle_rdcycleh_rdinstr_rdinstrh && uut.cpu.instr_rdcycle)
            $display("BASELINE_COUNTER cycle=%0d instructions=%0d",
                     uut.cpu.count_cycle, uut.cpu.count_instr);
    end
'''
    tb = (root / 'tb.v').read_text()
    (out / 'tb_instrumented.v').write_text(tb.replace('endmodule', monitor + '\nendmodule'))
    rtl = ['my_soc.v', 'picorv32.v', 'simpleuart.v', 'my_accel.v',
           'my_conv_accel.v', 'my_quant_accel.v', 'my_dw_conv_accel.v', 'my_pw_conv_accel.v']
    run(['verilator', '--binary', '--timing', '-Wno-fatal', '--top-module', 'tb',
         '-j', '4', '--Mdir', out / 'obj_dir', out / 'tb_instrumented.v',
         *[root / s for s in rtl]], 'simulator_build.log')
    run([out / 'obj_dir/Vtb'], 'simulation.log')
    log = (out / 'simulation.log').read_text()
    counters = [(int(c), int(i)) for c, i in re.findall(
        r'BASELINE_COUNTER cycle=(\d+) instructions=(\d+)', log)]
    if len(counters) != 20:
        raise RuntimeError(f'Expected 20 timing samples, found {len(counters)}')
    layers = ['Conv0', 'DW1', 'PW1', 'DW2', 'PW2', 'DW3', 'PW3', 'GAP', 'FC']
    results = {
        'definition': 'Existing NATIVE_RUN software kernels on unchanged RV32IM SoC; no compute MMIO',
        'quantization': 'Existing native C rounding, not RTL or TFLite bit-exactness',
        'layers': {name: {'cycles': counters[2*n+2][0] - counters[2*n+1][0],
                          'instructions': counters[2*n+2][1] - counters[2*n+1][1]}
                   for n, name in enumerate(layers)},
        'total_cycles': counters[-1][0] - counters[0][0],
        'total_instructions': counters[-1][1] - counters[0][1],
        'level6_reference_cycles': 26523121,
        'scores': [int(x) for x in re.search(r'Scores: \[([^]]+)\]', log)[1].split(',')],
        'source_sha256': {s: hashlib.sha256((root / s).read_bytes()).hexdigest()
                          for s in sources + rtl + ['tb.v', 'mnist_test_images.h', 'sections.lds']},
        'commands': commands,
    }
    results['level6_speedup'] = results['total_cycles'] / 26523121
    results['prediction'] = max(range(10), key=lambda i: results['scores'][i])
    results['completion_correct'] = 'All predictions correct' in log
    uart_cycles = [int(x) for x in re.findall(r'(\d+) cycles', log)]
    expected_cycles = [results['layers'][name]['cycles'] for name in layers] + [results['total_cycles']]
    if uart_cycles != expected_cycles:
        raise RuntimeError('Passive counter samples do not match firmware UART timings')
    if not results['completion_correct'] or results['prediction'] != 7:
        raise RuntimeError('Expected image 0 / label 7 to complete correctly')
    (out / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
    print(json.dumps({k: v for k, v in results.items() if k not in ('commands', 'source_sha256')}, indent=2))


if __name__ == '__main__':
    main()
