# ZCU106 deployment: Milestone A0

Isolated raw-clock/reset/LED smoke test for `xczu7ev-ffvc1156-2-e`.
No PicoRV32, BRAM initialization, firmware, UART, or accelerator integration.
Existing evaluation files remain unchanged.

## Verified official sources

AMD/Xilinx ZCU106 board files **2.6**, shipped with Vivado **2024.1**:

```text
C:\Xilinx\Vivado\2024.1\data\xhub\boards\XilinxBoardStore\boards\Xilinx\zcu106\2.6\
```

| Port | Official component/pin | PACKAGE_PIN | IOSTANDARD | Evidence |
|---|---|---|---|---|
| clk_p | user_si570_sysclk_p | AH12 | DIFF_SSTL12 | part0_pins.xml index 122 |
| clk_n | user_si570_sysclk_n | AJ12 | DIFF_SSTL12 | part0_pins.xml index 123 |
| led | GPIO_LED_0_LS | AL11 | LVCMOS12 | part0_pins.xml index 132 |
| reset | CPU_RESET | G13 | LVCMOS18 | part0_pins.xml index 121 |

`board.xml` interface `user_si570_sysclk` specifies **300000000 Hz**.
Component `led_8bits` explicitly describes **Active High** LEDs; component
`reset` describes **CPU Reset Push Button, Active High**, and its interface
specifies `rst_polarity=1`. Logic 1 illuminates LED 0; holding reset clears it.

Source SHA256:

```text
board.xml      e4dfd8a3713be2610334ed6fcd83f3a626bc6b21d5e8fb848ecf34190d2fefd4
part0_pins.xml cf3366fea8992018d165b83e57dc44910a1e37ea17309a3cd3015047403a01c9
```

The official board-file distribution is [XilinxBoardStore](https://github.com/Xilinx/XilinxBoardStore).
Board background: [AMD UG1244](https://docs.amd.com/v/u/en-US/ug1244-zcu106-eval-bd).
The installed XML is the exact pin/electrical/polarity evidence used here;
no Ultra96 or third-party constraints were used.

## Behavior and constraints

IBUFDS -> BUFG -> 28-bit counter. Counter bit 27 drives LED 0, giving
approximately **1.1176 Hz**, with **0.4474 seconds** on/off at 300 MHz.
Register INIT values provide a defined configuration state. The active-high
CPU reset asynchronously asserts a two-flop release synchronizer; the counter
resets synchronously. No debounce is needed for a smoke-test reset.
Only the asynchronous button input and human-visible LED output are false
pathed; counter and internal reset-release timing must pass at 300 MHz.

The SI570 is programmable: verify its actual setting is 300 MHz before using
these timing/heartbeat expectations. No PS firmware is required by this design.
This test does not verify any MyTinyMobileNetSoC functionality.

## Build and program from WSL

From this deployment directory in WSL Ubuntu:

```sh
make help
make check
make smoke
make program
make clean
```

Vivado still runs on Windows; GNU Make only orchestrates it from WSL.
Windows interop (`cmd.exe`) and `wslpath` must be available. No manual Vivado
Tcl Shell or `settings64.bat` step is needed. The default executable is
`C:\Xilinx\Vivado\2024.1\bin\vivado.bat`. Override it when needed:

```sh
make smoke VIVADO_VERSION=2024.2
make smoke 'VIVADO_ROOT=C:\Program Files\Xilinx\Vivado\2024.1'
```

`VIVADO_BAT` can also override the full executable path. `make help` prints the
configured executable and dynamically converted Windows deployment path.
The wrapper uses `wslpath -w` and `cmd.exe /D /C call` with quoted `pushd` and
`call` arguments in a generated `build/*_wsl.cmd` launcher (CRLF).
`pushd` supports the `\\wsl.localhost\Ubuntu\...` UNC path
by assigning a temporary drive for that command process. Vivado starts inside
`build/` and runs the existing `run_smoke.tcl` or `program.tcl` in batch mode.

All reports, checkpoints, logs, journals, `.Xil` data, and
`zcu106_smoke.bit` stay in the ignored `deployment/build/` directory.
Build logs are `vivado.log`/`vivado.jou`; programming logs are
`program.log`/`program.jou`. Check the build exit status and `build/status.txt`;
bitstream generation is not board proof. `make clean` removes only `build/`.

`make program` requires an existing bitstream and a powered ZCU106 with its
USB/JTAG connection visible to Windows. It never invokes `make smoke`.
Without hardware, target discovery can fail: this is a programming failure,
not a build failure, and the existing bitstream is retained. Inspect
`build/program.log` for the precise Vivado error. The wrapper also checks this
log for `ERROR:` lines because Vivado can return zero after a Tcl programming
error.

The programming script requires exactly one XCZU7EV device; disconnect unrelated
hardware targets if discovery is ambiguous. Programming is explicit and separate
from building. Observe LED 0 blinking; hold CPU_RESET to extinguish it, then
release and confirm heartbeat restarts. Record board revision, oscillator setting,
bitstream hash, DONE status, and observed blink/reset behavior.

## Local verification

Before Vivado launch: selected XDC entries were checked against the official
XML, including frequency and polarity; Tcl static delimiter checks passed;
Icarus compiled the top using AMD's installed IBUFDS/BUFG/glbl simulation models.
A short smoke simulation also checked counter-driven LED transition, button
reset, and synchronized release. Its testbench remained in `/tmp`.
These checks do not replace the physical LED/reset observation.

Vivado 2024.1 completed synthesis, implementation, and bitstream generation
successfully. Post-route WNS is **+2.356 ns**, WHS **+0.055 ns**, TNS/THS zero,
with no failing setup/hold endpoints. All **41** routable nets are fully routed;
the default DRC report has **zero violations**. `check_timing` has no unclocked
registers or unconstrained internal endpoints. It identifies the two documented
external false paths (`reset`, `led`). Vivado rounds the requested 3.333333 ns
period to **3.333 ns** (300.030 MHz), slightly stricter than nominal 300 MHz.

The bitstream has **not been programmed** and physical blink/reset behavior
has **not been observed**. Board-side completion remains pending.
