###############################################################################################################
# CTS Script for 8-bit ALU
# This script performs clock tree synthesis for the 8-bit ALU design in IC Compiler II
# It assumes that the design has been placed as per the placement.tcl script and that the MMMC setup has been done as per mmmc_script.tcl.
# File: cts.tcl
# open placement_block
###############################################################################################################

# Load the MMMC setup to ensure corners, modes, and scenarios are defined
source ./scripts/mmmc_script.tcl ;# if continuing from placement, this is already sourced, but safe to source again
set_host_options -max_cores 4

report_scenarios    

# Single clock, simple tree – global route guided buffering is enough
set_app_options -name cts.compile.enable_global_route           -value true
set_app_options -name cts.compile.enable_local_skew             -value true
set_app_options -name cts.optimize.enable_local_skew            -value true

# Match your SDC clock transition of 50ps = 0.05ns
set_app_options -name cts.common.default_max_transition         -value 0.05

# CTS cell prefix – keep your naming convention
set_app_options -name cts.common.user_instance_name_prefix      -value CTS_

# 3. Buffer / Inverter Specification
# Restrict the tool to only use symmetrical clock buffers/inverters from the SAED14 lib
# (Prevents the tool from using standard logic cells for the clock tree)
set_lib_cell_purpose -exclude cts [get_lib_cells */*] ;# Exclude everything first
set_lib_cell_purpose -include cts [get_lib_cells {
    */SAEDRVT14_BUF_S_2   */SAEDRVT14_BUF_S_4   */SAEDRVT14_BUF_S_8   */SAEDRVT14_BUF_S_16
    */SAEDRVT14_INV_S_2     */SAEDRVT14_INV_S_4     */SAEDRVT14_INV_S_8     */SAEDRVT14_INV_S_16
    */SAEDLVT14_BUF_S_2   */SAEDLVT14_BUF_S_4   */SAEDLVT14_BUF_S_8   */SAEDLVT14_BUF_S_16
    */SAEDLVT14_INV_S_2     */SAEDLVT14_INV_S_4     */SAEDLVT14_INV_S_8     */SAEDLVT14_INV_S_16
}] ;# Include only the specified buffer/inverter cells for CTS

# Low power pruning for a simple 8-bit tree
set_app_options -name cts.common.enable_low_power               -value true

# Auto exceptions handle your single-clock topology cleanly
set_app_options -name cts.common.enable_auto_exceptions         -value true
set_app_options -name cts.common.enable_auto_skew_target_for_local_skew -value true

# ------------------------------------------------------------
# TIMING (critical for your 3-scenario MMMC setup)
# ------------------------------------------------------------
# CPPR: removes clock reconvergence pessimism – essential with
# source latency max=0.30 / min=0.20 in SDC
set_app_options -name time.remove_clock_reconvergence_pessimism -value true

foreach scenario [list $scenario_slow $scenario_fast $scenario_typical] {
    current_scenario $scenario
    source $CONSTRAINTS -echo -verbose
    }

set_clock_tree_options -target_skew 0.040
set_clock_tree_options -target_latency 0.300

set_max_transition 0.08 [get_clocks *]
set_max_capacitance 0.05 [get_clocks *]

clock_opt

set_propagated_clock clk

###############################################################################################################
# After CTS, it's important to check the clock tree quality and timing to ensure that the synthesized clock tree meets the design requirements before proceeding to routing.
# The following commands will report the clock tree structure, quality of results (QoR), 
# and timing for each scenario to help you identify any potential issues that need to be addressed before moving on to routing.
###############################################################################################################

check_timing -type full -verbose
report_clock_tree > cts_report.txt
report_clock_tree_qor > cts_qor_report.txt
report_timing -delay_type max -type full -verbose > timing_report_setup_after_cts.txt
report_timing -delay_type min -type full -verbose > timing_report_hold_after_cts.txt

###############################################################################################################
save_block -as cts_block
###############################################################################################################