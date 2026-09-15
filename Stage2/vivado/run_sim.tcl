##################################################################################
# run_sim.tcl
# Runs behavioral simulation for the streaming convolution project
# Usage: vivado -mode batch -source run_sim.tcl
##################################################################################

set project_dir "[file normalize [file dirname [info script]]]"
set project_file "${project_dir}/streaming_conv_project/streaming_conv_project.xpr"

# Create or open project
if {[file exists $project_file]} {
    open_project $project_file
} else {
    puts "Project not found, creating..."
    source "[file normalize "${project_dir}/create_project.tcl"]"
}

# Set simulation top module explicitly
set_property top tb_streaming_conv [get_filesets sim_1]

# Launch behavioral simulation
launch_simulation -mode behavioral

# Run simulation for sufficient time
# For 64x64 image: ~2*64 + 4 + 62*62 + 100 = 4218 clocks = 42180 ns
run 1000000 ns

# Check simulation status
puts "=================================================="
puts " Simulation complete."
puts " Check waveform and console output for results."
puts "=================================================="

# Close simulation
close_sim -force
