##################################################################################
# run_synth.tcl
# Runs synthesis and generates utilization/timing reports
# Usage: vivado -mode batch -source run_synth.tcl
##################################################################################

set project_dir "[file normalize [file dirname [info script]]]"
set project_file "${project_dir}/streaming_conv_project/streaming_conv_project.xpr"
set reports_dir  "${project_dir}/reports"

# Create reports directory
file mkdir $reports_dir

# Open project
open_project $project_file

# Set top module
set_property top streaming_conv_top [current_fileset]

# Run synthesis
puts "Running synthesis..."
synth_design -top streaming_conv_top -part xc7a35tcpg236-1

# Apply timing constraints
puts "Applying timing constraints..."
read_xdc ${project_dir}/constraints.xdc

# Run placement and routing for accurate timing
puts "Running placement and routing..."
opt_design
place_design
route_design

# Generate reports
puts "Generating reports..."

# Utilization report
report_utilization -file ${reports_dir}/utilization.rpt

# Timing report
report_timing_summary -file ${reports_dir}/timing_summary.rpt
report_timing -file ${reports_dir}/timing_detail.rpt -max_paths 10

# Post-synthesis DRC
report_drc -file ${reports_dir}/drc_post_synth.rpt

puts "=================================================="
puts " Synthesis complete."
puts " Reports saved to: ${reports_dir}"
puts "=================================================="
