# Non-project Level 6 resource/timing evaluation. No bitstream or boot image.
# Invoke in a fresh Vivado batch process; see README.md for Windows commands.
set flow_dir [file dirname [file normalize [info script]]]
set rtl_dir [file normalize [file join $flow_dir ../..]]
set fpga_part xczu7ev-ffvc1156-2-e
set top_module my_soc
set clock_period_ns 20.000
# Validate before creating output directories or invoking any design commands.
if {[llength $argv] > 1} {
    puts stderr "Usage: vivado -mode batch -source run_vivado.tcl -tclargs <positive_period_ns>"
    exit 1
}
if {[llength $argv] == 1} {
    set requested_period [lindex $argv 0]
    if {![string is double -strict $requested_period] ||
        [catch {expr {double($requested_period) > 0.0 && double($requested_period) < Inf}} valid] || !$valid} {
        puts stderr "Invalid clock period '$requested_period': expected a finite positive numeric value in ns"
        exit 1
    }
    set clock_period_ns [expr {double($requested_period)}]
}
set max_threads 4
set period_tag [string map {. p + _ - m} $clock_period_ns]
set run_id "[clock format [clock seconds] -format %Y%m%d_%H%M%S]_[pid]_${period_tag}ns"

# Trust only this repository for each Git subprocess, never global Git config.
# Walking to .git works for both normal checkouts and linked worktrees.
set git_repo_dir $rtl_dir
while {![file exists [file join $git_repo_dir .git]] &&
       [file dirname $git_repo_dir] ne $git_repo_dir} {
    set git_repo_dir [file dirname $git_repo_dir]
}
set build_dir [file join $flow_dir build $run_id]
set reports_dir [file join $flow_dir reports $run_id]
set stage preparation

proc write_text {path text} {
    set channel [open $path w]
    puts $channel $text
    close $channel
}

# A missing Git executable/repository does not prevent evaluation. Record it.
proc git_info {args} {
    global rtl_dir git_repo_dir
    if {[catch {exec git -c "safe.directory=$git_repo_dir" -C $rtl_dir {*}$args} result]} {
        return "UNAVAILABLE: $result"
    }
    return [string trim $result]
}

proc stage_reports {name} {
    global reports_dir
    set dir [file join $reports_dir $name]
    file mkdir $dir
    report_utilization -file [file join $dir utilization.rpt]
    report_utilization -hierarchical -file [file join $dir utilization_hierarchical.rpt]
    report_timing_summary -report_unconstrained -file [file join $dir timing_summary.rpt]
    report_timing -delay_type max -max_paths 1 -nworst 1 \
        -path_type full_clock_expanded -file [file join $dir worst_setup_path.rpt]
    report_clock_utilization -file [file join $dir clock_utilization.rpt]
    report_high_fanout_nets -file [file join $dir high_fanout_nets.rpt]
    report_methodology -file [file join $dir methodology.rpt]
    report_drc -file [file join $dir drc.rpt]
    check_timing -verbose -file [file join $dir check_timing.rpt]
}

# Catch every preparation/design/report error, identify the stage, retain the
# full Tcl stack trace, and return nonzero to the Windows calling process.
if {[catch {
    file mkdir $build_dir $reports_dir
    cd $build_dir
    write_text [file join $reports_dir status.txt] "RUNNING: $stage\nrequested_clock_period_ns=$clock_period_ns"
    set commit [git_info rev-parse HEAD]
    set git_status [git_info status --short --untracked-files=all]
    set metadata [join [list \
        "run_id=$run_id" \
        "git_commit=$commit" \
        "vivado_version=[version -short]" \
        "fpga_part=$fpga_part" \
        "top_module=$top_module" \
        "requested_clock_period_ns=$clock_period_ns" \
        "requested_clock_frequency_mhz=[expr {1000.0 / $clock_period_ns}]" \
        "max_threads=$max_threads" \
        "synthesis_flatten_hierarchy=rebuilt" \
        "implementation_directives=Default" \
        "physical_pin_constraints=absent; evaluation only" \
        "ram_initialization=absent; hardware boot not supported" \
        "power_evaluation=not performed" \
        "git_status_begin" $git_status "git_status_end"] "\n"]
    write_text [file join $reports_dir metadata.txt] $metadata
    foreach file {run_vivado.tcl rtl_sources.tcl evaluation.xdc} {
        file copy [file join $flow_dir $file] [file join $reports_dir $file]
    }
    source [file join $flow_dir rtl_sources.tcl]
    set sources [list]
    set source_metadata [list]
    foreach relative $rtl_sources {
        set path [file normalize [file join $rtl_dir $relative]]
        if {![file isfile $path]} { error "Missing synthesis RTL source: $path" }
        lappend sources $path
        lappend source_metadata "$relative | git_blob=[git_info hash-object -- $path]"
    }
    write_text [file join $reports_dir rtl_manifest.txt] [join $source_metadata "\n"]
    write_text [file join $reports_dir power_not_evaluated.txt] \
        "No report_power: no annotated switching activity or validated operating conditions. Vectorless estimates are not measured board power."

    set stage read_sources
    set_param general.maxThreads $max_threads
    set_part $fpga_part
    read_verilog $sources
    read_xdc [file join $flow_dir evaluation.xdc]

    set stage synthesis
    synth_design -top $top_module -part $fpga_part -flatten_hierarchy rebuilt
    set clocks [get_clocks -quiet soc_clk]
    if {[llength $clocks] != 1} { error "Expected exactly one soc_clk constraint" }
    if {abs([get_property PERIOD $clocks] - $clock_period_ns) > 0.000001} {
        error "evaluation.xdc clock period disagrees with metadata"
    }
    write_checkpoint -force [file join $build_dir post_synth.dcp]
    set stage post_synth_reports
    stage_reports post_synth

    set stage optimization
    opt_design -directive Default
    set stage placement
    place_design -directive Default
    set stage physical_optimization
    phys_opt_design -directive Default
    set stage routing
    route_design -directive Default
    write_checkpoint -force [file join $build_dir post_route.dcp]
    set stage post_route_reports
    stage_reports post_route
    report_route_status -file [file join $reports_dir post_route route_status.rpt]

    set incomplete_nets [get_nets -hierarchical -filter {
        ROUTE_STATUS == UNROUTED || ROUTE_STATUS == PARTIAL || ROUTE_STATUS == ERROR
    }]
    if {[llength $incomplete_nets] != 0} {
        error "Routing incomplete: [llength $incomplete_nets] unrouted/partial/error nets; see route_status.rpt"
    }

    # Completion is not a claim of timing closure or board readiness. Preserve
    # negative slack and all DRC/unconstrained-I/O findings for evaluation.
    set paths [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
    if {[llength $paths] == 0} { error "No constrained setup path found after routing" }
    set worst_slack [get_property SLACK [lindex $paths 0]]
    write_text [file join $reports_dir status.txt] \
        "COMPLETED evaluation; worst_setup_slack_ns=$worst_slack\nrequested_clock_period_ns=$clock_period_ns\nReview timing_summary.rpt, check_timing.rpt, drc.rpt and route_status.rpt. No bitstream generated."
    puts "Evaluation complete. Reports: $reports_dir"
    puts "Checkpoints: $build_dir"
    puts "Worst constrained setup slack: $worst_slack ns (requested period $clock_period_ns ns)"
} failure options]} {
    set detail "FAILED at stage=$stage\nrequested_clock_period_ns=$clock_period_ns\n$failure\n[dict get $options -errorinfo]"
    puts stderr $detail
    if {[file isdirectory $reports_dir]} {
        catch {write_text [file join $reports_dir status.txt] $detail}
    }
    exit 1
}
exit 0
