# create_project.tcl - Stage 1: Window Generator

set project_name "stage1_window_generator"
set project_dir "[file normalize [file dirname [info script]]]"
set rtl_dir "${project_dir}/../rtl"
set tb_dir "${project_dir}/../tb"

create_project $project_name $project_dir -part xc7a35tcpg236-1 -force

add_files [glob ${rtl_dir}/*.sv]
add_files -fileset sim_1 [glob ${tb_dir}/*.sv]

set_property top streaming_window_top [current_fileset]
set_property top tb_window_gen [get_filesets sim_1]
set_property top_lib xil_defaultlib [current_fileset]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Stage 1 project created successfully!"
