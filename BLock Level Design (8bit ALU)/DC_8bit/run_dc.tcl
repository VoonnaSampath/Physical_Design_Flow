###############################################################################################################
# Synthesis Script for 8-bit ALU using Design Compiler
# This script performs RTL synthesis for the 8-bit ALU design in Design Compiler.
# It assumes that the RTL source files are located in the ../rtl directory and that the design constraints are defined in the ../CONSTRAINTS directory.
# File: run_dc.tcl
# Tool Command: dc_shell
###############################################################################################################

set PDK_PATH /data/pdk/pdk14nm/SAED14nm_EDK_03_2025

source -echo -verbose ./rm_setup/dc_setup.tcl

set RTL_SOURCE_FILES ./../rtl/alu_8bit.v

# To define design lib to store intermediate design files
define_design_lib WORK -path ./WORK

set_app_var hdlin_enable_hier_map true

set_svf ./${RESULTS_DIR}/${DESIGN_NAME}.svf

analyze -format verilog ${RTL_SOURCE_FILES}
elaborate ${DESIGN_NAME}
current_design ${DESIGN_NAME}
set_verification_top

read_sdc -echo ./../CONSTRAINTS/alu_8bit.sdc
remove_input_delay [get_ports clk]

# Limiting the usage of high-Vt cells to 20% of total cell instances to balance power and performance in the design.
set_attribute [get_lib_cells {*/*LVT*}] threshold_voltage_group LVT
set_multi_vth_constraint -lvth_percentage 20 -lvth_groups LVT

compile_ultra

set_svf -off

# These files are found in the results directory defined in dc_setup.tcl

write -format verilog -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}
write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}
write_sdf ./${RESULTS_DIR}/${DCRM_DCT_FINAL_SDF_OUTPUT_FILE}
write_sdc -nosplit ./${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}

###############################################################################################################
# Reports Extracted after synthesis to analyze the design's performance, area, and power characteristics before proceeding to floorplanning and placement.
# These reports will help you identify any potential issues that need to be addressed before moving on to the next steps in the physical design flow.
###############################################################################################################

report_timing -delay_type max -type full -verbose > ${REPORTS_DIR}/timing_report_setup_after_synthesis.txt
report_timing -delay_type min -type full -verbose > ${REPORTS_DIR}/timing_report_hold_after_synthesis.txt
report_area > ${REPORTS_DIR}/area_report_after_synthesis.txt
report_cell -nosplit > ${REPORTS_DIR}/report-cell.txt 
report_reference -nosplit > ${REPORTS_DIR}/report-reference.txt 
report_clock_tree > ${REPORTS_DIR}/report-clock-tree.txt 
report_power -nosplit > ${REPORTS_DIR}/report-power.txt
report_threshold_voltage_group -nosplit > ${REPORTS_DIR}/report-threshold.txt
report_qor > ${REPORTS_DIR}/report-qor.txt
report_wire_load -nosplit > ${REPORTS_DIR}/report-wireload.txt

###############################################################################################################