
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


set_attribute [get_lib_cells {*/*LVT*}] threshold_voltage_group LVT
set_multi_vth_constraint -lvth_percentage 20 -lvth_groups LVT

compile_ultra

write -format verilog -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}
write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}
write_sdf ./${RESULTS_DIR}/${DCRM_DCT_FINAL_SDF_OUTPUT_FILE}

write_sdc -nosplit ./${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}

set_svf -off