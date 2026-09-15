# run_sim.tcl - Stage 1 Simulation

puts "=== Stage 1: Window Generator Simulation ==="

set_property top tb_window_gen [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

launch_simulation -mode behavioral
run -all

puts "=== Stage 1 Simulation Complete ==="
