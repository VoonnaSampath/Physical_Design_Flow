###############################################################################################################
# Design Planning Script for 8-bit ALU
# Script: design_planning.tcl
###############################################################################################################

set PDK_PATH /data/pdk/pdk14nm/SAED14nm_EDK_03_2025

create_lib -ref_lib "$PDK_PATH/SAED14nm_EDK_STD_RVT/ndm/saed14rvt_base_frame_timing.ndm 
    $PDK_PATH/SAED14nm_EDK_STD_LVT/ndm/saed14lvt_base_frame_timing.ndm 
    $PDK_PATH/SAED14nm_EDK_STD_HVT/ndm/saed14hvt_base_frame_timing.ndm" ALU_8bit_14_LIB

set_ref_libs -add ${PDK_PATH}/SAED14nm_EDK_STD_RVT/ndm/saed14rvt_cg_frame_timing.ndm
set_ref_libs -add ${PDK_PATH}/SAED14nm_EDK_STD_LVT/ndm/saed14lvt_cg_frame_timing.ndm
set_ref_libs -add ${PDK_PATH}/SAED14nm_EDK_STD_HVT/ndm/saed14hvt_cg_frame_timing.ndm

read_verilog {./../DC_8bit/results/alu_8bit.mapped.v } -library ALU_8bit_14_LIB -top alu_8bit

save_lib
save_block

###############################################################################################################
save_block -as pre_floorplan_block
###############################################################################################################

###############################################################################################################
# Floor Planning Script for 8-bit ALU
# open pre_floorplan_block
###############################################################################################################

initialize_floorplan -control_type core -core_offset 4.8 -core_utilization 0.6

#set_individual_pin_constraints -ports [all_inputs] -sides {1 3} -pin_spacing_distance 2
#set_individual_pin_constraints -ports [all_outputs] -sides {2 4} -pin_spacing_distance 1
#set_individual_pin_constraints -ports clk -sides 3
#create_placement -floorplan

place_pins -self

###############################################################################################################
# After floorplanning, it's important to check the design's pin placement and overall floorplan quality to ensure 
# that it meets the design requirements before proceeding to power planning and placement.
# The following commands will report the pin placement, utilization, and design metrics to help you identify 
# any potential issues that need to be addressed before moving on to power planning and placement.
###############################################################################################################

report_utilization > utilization_report_after_floorplanning.txt
#report_cell_density > cell_density_report_after_floorplanning.txt
#report_pin_utilization > pin_utilization_report_after_floorplanning.txt
report_design > design_report_after_floorplanning.txt

###############################################################################################################
save_block -as floorplan_block
###############################################################################################################

###############################################################################################################
# Power Planning Script for 8-bit ALU
# open floorplan_block
###############################################################################################################

#to create pg ports
create_port -direction in VDD
create_port -direction in VSS

#to create power nets
create_net -power {VDD}
create_net -ground {VSS}

# to create power shapes for VDD and VSS to connect to the power/ground Ring    
create_shape -shape_type rect -layer M7 -boundary {{0 11.36} {4 12.34}} -port VDD 
create_shape -shape_type rect -layer M7 -boundary {{0.0 15.82} {2.2 16.81}} -port VSS 

# to connect power/ground_nets
connect_pg_net -all_blocks -automatic

###############################################################################################################
### to create pg ring pattern
###############################################################################################################

create_pg_ring_pattern core_ring_pattern -vertical_layer M9 -vertical_width 1 -vertical_spacing 0.8 -horizontal_layer M8 -horizontal_width 1 -horizontal_spacing 0.8

set_pg_strategy core_power_ring -core -pattern { {name : core_ring_pattern} {nets : {VDD VSS}} {offset : {1 1}} }

compile_pg -strategies core_power_ring

check_pg_drc

###############################################################################################################
###  to create pg mesh pattern
###############################################################################################################

create_pg_mesh_pattern core_mesh_pattern -layers { {{vertical_layer: M7}{width: 0.35} {spacing: interleaving} {pitch: 1.48} {offset: .80}} {{horizontal_layer: M8}{width: 0.4} {spacing: interleaving} {pitch: 1.16} {offset: .96}}}

set_pg_strategy core_mesh -pattern { {pattern:core_mesh_pattern} {nets: VDD VSS}} -core -extension { {stop: innermost_ring} }

compile_pg -strategies core_mesh

check_pg_drc

check_pg_connectivity

###############################################################################################################
### to create std cell power rail pattern
###############################################################################################################

create_pg_std_cell_conn_pattern std_cell_rail -layers {M1} -rail_width 0.1
  
set_pg_strategy rail_strat -core -pattern { {name: std_cell_rail} {nets: VDD VSS} }

compile_pg -strategies rail_strat

###############################################################################################################
# After power planning, it's important to check the design's power grid connectivity and DRC to ensure that the 
# power distribution network is correctly implemented and meets the design requirements before proceeding to placement.
# The following commands will report the power grid connectivity and DRC results to help you identify any potential 
# issues that need to be addressed before moving on to placement.
###############################################################################################################

check_pg_drc

check_pg_missing_vias

check_pg_connectivity

###############################################################################################################
# Create boundary cells and tap cells (PRE-PLACEMENT PHYSICAL ONLY CELLS), then check legality before proceeding to placement.
###############################################################################################################

create_boundary_cells -left_boundary_cell SAEDRVT14_CAPT3 -right_boundary_cell SAEDRVT14_CAPT3 -top_boundary_cells SAEDRVT14_CAPT2 -bottom_boundary_cells SAEDRVT14_CAPB3

create_tap_cells -lib_cell SAEDRVT14_TAPPN -distance 13 -skip_fixed_cells

check_legality -verbose 

###############################################################################################################
save_block -as powerplan_block
###############################################################################################################

###############################################################################################################
# After floorplanning, it's important to check the design's pin placement and overall floorplan quality to ensure 
# that it meets the design requirements before proceeding to power planning and placement.
# The following commands will report the pin placement, utilization, and design metrics to help you identify 
# any potential issues that need to be addressed before moving on to power planning and placement.
###############################################################################################################

report_utilization > utilization_report_after_powerplanning.txt
#report_cell_density > cell_density_report_after_powerplanning.txt
#report_pin_utilization > pin_utilization_report_after_powerplanning.txt
report_design > design_report_after_powerplanning.txt

###############################################################################################################