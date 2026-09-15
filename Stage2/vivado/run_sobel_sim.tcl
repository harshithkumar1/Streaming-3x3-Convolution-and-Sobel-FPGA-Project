# run_sobel_sim.tcl - Sobel Edge Detection Simulation
# Run in Vivado Tcl Console after create_project.tcl

puts "=== Stage 2: Sobel Edge Detection Simulation ==="

# Set project properties
set_property top tb_sobel_edge [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Launch simulation
launch_simulation -mode behavioral

# Run simulation
run -all

# Close simulation
close_sim

puts "=== Sobel Simulation Complete ==="
