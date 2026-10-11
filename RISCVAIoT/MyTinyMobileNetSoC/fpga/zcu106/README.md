# TinyMobileNet Level 6: ZCU106 resource/timing evaluation

This is a Vivado **non-project** flow for the current Level 6 design. It targets
`xczu7ev-ffvc1156-2-e`, top `my_soc`, with a **20.000 ns / 50 MHz** evaluation
clock by default; an optional Tcl argument overrides the period. It does not generate a bitstream, program a board, initialize firmware,
or compare historical versions. RTL functionality is unchanged.

## Run on Windows

Use a Vivado command prompt with Zynq UltraScale+ device support installed and
an appropriate license. Git on PATH is optional but recommended for metadata.
Use a fresh batch process; do not source this script into a populated project.

Recommended command-prompt sequence, starting in this directory:

```bat
cd /d C:\path\to\Capstone-Project-1-work\RISCVAIoT\MyTinyMobileNetSoC\fpga\zcu106
if not exist build mkdir build
cd build
vivado -mode batch -source ..\run_vivado.tcl -log vivado.log -journal vivado.jou
```

Clock-sweep commands from the same `build` directory (one fresh process per run):

```bat
rem Default: 20.000 ns / 50 MHz
vivado -mode batch -source ..\run_vivado.tcl -log vivado.log -journal vivado.jou
rem 15 ns
vivado -mode batch -source ..\run_vivado.tcl -log vivado.log -journal vivado.jou -tclargs 15.0
rem 12.5 ns
vivado -mode batch -source ..\run_vivado.tcl -log vivado.log -journal vivado.jou -tclargs 12.5
rem 10 ns
vivado -mode batch -source ..\run_vivado.tcl -log vivado.log -journal vivado.jou -tclargs 10.0
```

The argument must be one finite positive numeric period in ns. Invalid arguments
fail before design commands or output-directory creation. No XDC editing is
needed: its single `create_clock` uses the validated Tcl period. Run IDs include
the period; metadata and status record it. Archive startup logs before the next
invocation if needed; timestamped checkpoints/reports are retained automatically.

This places startup logs/journals and `.Xil` in `build`, away from the RTL.
Check `%ERRORLEVEL%` immediately after Vivado. Nonzero means a tool, preparation,
implementation, or required-report failure. The last status/stack trace is saved
when possible; a synthesis checkpoint may still be available after a later error.

The requested basic invocation also works from `fpga/zcu106`:

```bat
vivado -mode batch -source run_vivado.tcl
```

That basic command places startup `vivado.log`/`vivado.jou` in the flow directory.
To redirect those while staying there, create `build` and use
`-log build/vivado.log -journal build/vivado.jou`. The recommended sequence above
keeps all startup artifacts inside `build` as well.

From a **fresh Vivado Tcl shell**, change directory to this flow's `build`
directory, set `argv` to `{}` for the default or `{15.0}` for an override,
and run `source ../run_vivado.tcl`. The script ends with `exit 0` or
`exit 1`, so it terminates that shell. Startup log locations depend on how the
shell was launched. Source/output paths are resolved relative to the script,
not the caller's working directory; paths containing spaces are supported.

## Sources and implementation choices

`rtl_sources.tcl` explicitly lists the complete synthesis hierarchy:

- `my_soc.v`
- `picorv32.v` (also contains the enabled iterative PCPI multiplier)
- `simpleuart.v`
- `my_accel.v`
- `my_conv_accel.v`
- `my_quant_accel.v`
- `my_dw_conv_accel.v`
- `my_pw_conv_accel.v`

No testbench, standalone prototype, simulation file, firmware hex, or debug/formal
define is included. There are no wildcard source reads. The script uses
`set_part`, `read_verilog`, `read_xdc`, and `synth_design`, followed by
`opt_design`, `place_design`, `phys_opt_design`, and `route_design`.
Synthesis uses `-flatten_hierarchy rebuilt`; implementation directives are
`Default`, with `general.maxThreads=4`. Keep these choices and the Vivado version
fixed for reproducibility. Retain the complete run, not just the summary numbers.

## Evaluation constraints versus deployment

`evaluation.xdc` creates `soc_clk` on top-level `clk` with the requested period (default 20.000 ns).
This is the common **initial comparison constraint**, not an assertion about
ZCU106's physical clock source or achieved Fmax.

Physical board pin constraints are intentionally absent. No PACKAGE_PIN,
IOSTANDARD, input/output delay, clock-source wrapper, reset-pin assignment,
false path, or multicycle path is invented. Deployment constraints will be a
**separate later XDC/preparation step** based on validated ZCU106 connections.

Unconstrained reset/UART/LED I/O and unspecified pin/IOSTANDARD findings are
expected in `check_timing`, DRC and methodology reports. They are not suppressed
or downgraded. Tool-selected I/O placement is not a board pinout. If the installed
Vivado cannot place/route this incomplete physical I/O setup, the script fails
clearly; inspect the failure rather than adding arbitrary pins or exceptions.
These reports evaluate the constrained internal clock domain, not complete
board timing, CDC safety, or deployment readiness. No bitstream is generated.

## RAM and firmware

Synthesis can evaluate the current **65,536 x 32-bit (256 KiB)** RAM without an
initialization image. Its registered read, byte-write enables, size and organization
are preserved. Confirm actual inferred memory mapping in the utilization/logs.
No RAM redesign, boot loader or board logic is introduced.

This does **not** provide a working FPGA inference boot. Firmware initialization
currently exists only in `tb.v`, via hierarchical `$readmemh`/byte packing.
That testbench is excluded. Deployment requires a synthesis-compatible firmware
initialization/loading solution later, with the same interface/latency validated.
No RAM contents or simulated inference are used to constrain synthesis.

## Output and reports

Each invocation gets a timestamp/PID/period run ID, so previous runs are retained:

```text
build/<run_id>/
  post_synth.dcp
  post_route.dcp
reports/<run_id>/
  metadata.txt
  rtl_manifest.txt
  status.txt
  run_vivado.tcl             # exact flow snapshot
  rtl_sources.tcl
  evaluation.xdc
  power_not_evaluated.txt
  post_synth/
  post_route/
```

Both stage report directories contain:

- `utilization.rpt`: LUT logic/memory, FF, BRAM, DSP, clock-resource counts
- `utilization_hierarchical.rpt`: attribution by module
- `timing_summary.rpt`: setup/hold WNS/TNS and unconstrained-path information
- `worst_setup_path.rpt`: worst setup path with expanded clock paths
- `clock_utilization.rpt`
- `high_fanout_nets.rpt`
- `methodology.rpt`
- `drc.rpt`
- `check_timing.rpt`: verbose constraint checks

Post-route also contains `route_status.rpt`. Unrouted/partial/error nets cause a
nonzero exit after reports are saved. Other Tcl/tool/report errors also cause
nonzero exit with the failing stage and full stack trace. Negative setup slack
is recorded without discarding the run: **successful execution is not timing
closure**. Check `status.txt` and all route/timing/DRC reports.

Metadata records Git HEAD, dirty/untracked status, Vivado version, target part,
top, requested clock, thread count and directives. `rtl_manifest.txt` records
Git content hashes of each source (including local edits). If Git is unavailable,
metadata says so; archive sources yourself. Flow and XDC snapshots are retained.
Git subprocesses use command-local `-c safe.directory=<repository-root>` to
handle Windows/WSL UNC ownership checks. Only this checkout is trusted, and no
global or repository Git configuration is changed. The root is found by walking
to `.git`, including linked-worktree `.git` files. If the installed Git still
rejects UNC path spelling or Git is missing, the flow continues and records the
error. `hash-object` source fingerprints are still attempted independently;
confirm they are present and archive sources if unavailable.
Build/report/log directories are ignored by Git.

No `report_power` is generated: there is no annotated switching activity or
validated operating-condition setup. A later activity-based estimate must state
its assumptions and confidence; vectorless power is not measured board power.

## Interpret timing and resources

Start with the post-route setup/hold WNS/TNS, worst path and constraint coverage;
post-synthesis timing is diagnostic. Requested 50 MHz is **not achieved Fmax**.
A later Fmax study should rerun implementation at progressively tighter periods
with fixed source, device, tool version and strategies. Use `-tclargs <period_ns>`; the same period drives the XDC, metadata and
post-synthesis constraint assertion. All other strategies remain fixed.

For comparison, use `inference_time = cycles / operating_frequency`, and only
substitute Fmax after establishing a timing-clean frequency. The verified Level 6
cycle count is 26,523,121, including inter-layer UART output. Wall-clock Icarus
runtime is not architectural speedup.

Inspect particularly:

- Large signed-int32 conv/DW/PW multiplication and addition paths; DSP demand may
  be substantial. Firmware's int8 values do not narrow legacy int32 semantics.
- PW batch bank/cache selection before the shared MAC tree. Four-cycle batch
  latency does not permit a four-cycle timing exception.
- PW1's 32 x 128-bit asynchronous cache read: LUTRAM/FF mapping is more plausible
  than synchronous BRAM; confirm mapping rather than assume it.
- Main RAM block-memory inference, reset fanout and MMIO read muxes.
- Quantizer multiplier/variable-shift path, UART CDC and external reset handling.

The clock-override revision has not been run in Vivado. Earlier 20 ns reports
remain historical results; each new period requires its own implementation. Command choices follow AMD's non-project flow documentation:
[UG895](https://docs.amd.com/r/en-US/ug895-vivado-system-level-design-entry/Working-with-Sources-in-Non-Project-Mode)
and [UG835](https://docs.amd.com/r/2024.1-English/ug835-vivado-tcl-commands/check_timing).
