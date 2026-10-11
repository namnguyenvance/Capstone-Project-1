# Resource/timing evaluation ONLY; not a ZCU106 deployment constraint set.
# Common initial comparison frequency: 50 MHz. Physical clock source,
# PACKAGE_PIN, IOSTANDARD and external I/O timing are intentionally undefined.
# Board deployment requires a separate, validated deployment XDC and reset/CDC
# handling. No false paths or multicycle paths are introduced here.
# run_vivado.tcl supplies the validated period; this is the only create_clock.
create_clock -name soc_clk -period $::clock_period_ns [get_ports clk]
