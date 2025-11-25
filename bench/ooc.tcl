read_verilog -sv [glob ../rtl/*.v]

set module [lindex $argv 0]

set part xc7a100tfgg484-3

read_xdc ooc.xdc

synth_design -mode out_of_context -part $part -top $module
opt_design
report_utilization -hierarchical
report_timing
report_design_analysis -logic_level_distribution
write_checkpoint -force $module.dcp
