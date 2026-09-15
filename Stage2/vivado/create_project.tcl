##################################################################################
# create_project.tcl
# Creates a Vivado project for Stage 2: Sobel Edge Detection
# Usage: vivado -mode batch -source create_project.tcl
##################################################################################

set project_name "stage2_sobel_edge"
set script_dir   [file normalize [file dirname [info script]]]
set project_dir  [file normalize ${script_dir}]
set rtl_dir      [file normalize ${script_dir}/../rtl]
set tb_dir       [file normalize ${script_dir}/../tb]

# Remove old project if exists
if {[file exists ${project_dir}/${project_name}]} {
    file delete -force ${project_dir}/${project_name}
}

# Create project
create_project ${project_name} ${project_dir}/${project_name} -part xc7a35tcpg236-1 -force

# Use manual compile order to set top modules
set_property source_mgmt_mode None [current_project]

# Add RTL sources to synthesis
add_files -norecurse [glob ${rtl_dir}/*.sv]
set_property file_type SystemVerilog [get_files *.sv -of_objects [get_filesets sources_1]]

# Add testbench to simulation fileset
add_files -fileset sim_1 -norecurse [list "${tb_dir}/tb_sobel_edge.sv"]
set_property file_type SystemVerilog [get_files *.sv -of_objects [get_filesets sim_1]]
set_property top tb_sobel_edge [get_filesets sim_1]

# Set synthesis top
set_property top streaming_sobel_top [current_fileset]

# Enable SystemVerilog for both filesets
set_property -name {xsim.compile.xvlog.more_options} -value "-sv" -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "=================================================="
puts " Project created: ${project_name}"
puts " Part: xc7a35tcpg236-1"
puts "=================================================="
