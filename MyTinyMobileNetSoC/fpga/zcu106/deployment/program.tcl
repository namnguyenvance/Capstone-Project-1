# Explicitly invoked programming step; does not run during the build.
set flow_dir [file dirname [file normalize [info script]]]
set bitfile [file join $flow_dir build zcu106_smoke.bit]
if {![file isfile $bitfile]} {error "Missing smoke bitstream: $bitfile"}
open_hw_manager
connect_hw_server
open_hw_target
set devices [get_hw_devices -filter {PART =~ xczu7ev*}]
if {[llength $devices] != 1} {error "Expected exactly one XCZU7EV; found $devices"}
set device [lindex $devices 0]
current_hw_device $device
refresh_hw_device -update_hw_probes false $device
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device -update_hw_probes false $device
close_hw_manager
exit 0
