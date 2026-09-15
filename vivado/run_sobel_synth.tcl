##################################################################################
# run_sobel_synth.tcl
# Runs synthesis for the Sobel edge detection top module
# Usage: vivado -mode batch -source run_sobel_synth.tcl
##################################################################################

set project_dir "[file normalize [file dirname [info script]]]"
set project_file "${project_dir}/streaming_conv_project/streaming_conv_project.xpr"
set reports_dir  "${project_dir}/reports"

file mkdir $reports_dir

open_project $project_file

# Add Sobel RTL files if not already added
set sobel_rtl [glob -nocomplain "[file normalize $project_dir/../rtl]/*sobel*"]
if {[llength $sobel_rtl] > 0} {
    add_files -norecurse $sobel_rtl
    set_property file_type SystemVerilog [get_files $sobel_rtl]
}

set_property top streaming_sobel_top [current_fileset]

puts "Running synthesis for Sobel edge detection..."
synth_design -top streaming_sobel_top -part xc7a35tcpg236-1

report_utilization -file ${reports_dir}/utilization_sobel.rpt
report_timing_summary -file ${reports_dir}/timing_summary_sobel.rpt
report_timing -file ${reports_dir}/timing_detail_sobel.rpt -max_paths 10

puts "=================================================="
puts " Sobel synthesis complete."
puts "=================================================="
