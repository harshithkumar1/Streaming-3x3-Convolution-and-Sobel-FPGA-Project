# run_sim.tcl - Stage 2: Sobel Edge Detection Simulation

puts "=== Stage 2: Sobel Edge Detection Simulation ==="

set_property top tb_sobel_edge [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

launch_simulation -mode behavioral
run -all

puts "=== Stage 2 Simulation Complete ==="
