# Run in deployment/build so startup logs and .Xil stay isolated too.
set flow_dir [file dirname [file normalize [info script]]]
set build_dir [file join $flow_dir build]
file mkdir $build_dir
cd $build_dir
set stage preparation
proc status {message} {
    global build_dir
    set f [open [file join $build_dir status.txt] w]
    puts $f $message
    close $f
}
if {[catch {
    status "RUNNING: $stage"
    set_param general.maxThreads 4
    set_part xczu7ev-ffvc1156-2-e
    read_verilog [file join $flow_dir zcu106_smoke_top.v]
    read_xdc [file join $flow_dir zcu106_deployment.xdc]
    set stage synthesis
    synth_design -top zcu106_smoke_top -part xczu7ev-ffvc1156-2-e
    write_checkpoint -force post_synth.dcp
    set stage implementation
    opt_design
    place_design
    phys_opt_design
    route_design
    write_checkpoint -force post_route.dcp
    report_timing_summary -report_unconstrained -file timing_summary.rpt
    report_timing -delay_type max -max_paths 5 -file setup_paths.rpt
    report_timing -delay_type min -max_paths 5 -file hold_paths.rpt
    report_drc -file drc.rpt
    report_utilization -file utilization.rpt
    report_route_status -file route_status.rpt
    check_timing -verbose -file check_timing.rpt
    set stage validation
    foreach delay_type {max min} {
        set paths [get_timing_paths -delay_type $delay_type -max_paths 1]
        if {[llength $paths] != 1} {error "No $delay_type timing path"}
        if {[get_property SLACK [lindex $paths 0]] < 0} {
            error "$delay_type timing failed; review reports"
        }
    }
    set incomplete [get_nets -hierarchical -filter {
        ROUTE_STATUS == UNROUTED || ROUTE_STATUS == PARTIAL || ROUTE_STATUS == ERROR
    }]
    if {[llength $incomplete]} {error "Routing incomplete"}
    set stage bitstream
    # Keep all physical-I/O DRCs enabled; write_bitstream fails on errors.
    write_bitstream -force zcu106_smoke.bit
    status "PASS: timing checked; bitstream generated (not programmed or board-tested)"
} failure options]} {
    status "FAIL: stage=$stage\n$failure\n[dict get $options -errorinfo]"
    puts stderr $failure
    exit 1
}
exit 0
