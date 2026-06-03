###############################################################################################################
# Routing Script for 8-bit ALU
# This script performs global and detail routing for the 8-bit ALU design in IC Compiler II.
# It assumes that the design has been clock tree synthesized as per the cts.tcl script and that the MMMC setup has been done as per mmmc_script.tcl.
# File: routing.tcl
# open cts_block
############################################################################################################### 

# Load the MMMC setup to ensure corners, modes, and scenarios are defined
source ./scripts/mmmc_script.tcl ;# if continuing from CTS, this is already sourced, but safe to source again
set_host_options -max_cores 4 

# ------------------------------------------------------------
# GLOBAL ROUTING
# ------------------------------------------------------------
set_app_options -name route.global.effort_level                 -value high
set_app_options -name route.global.deterministic                -value on

# Timing driven OFF – 2ns is generous for an 8-bit ALU at 14nm,
# congestion closure is more relevant than timing-driven GR here
set_app_options -name route.global.timing_driven               -value true

set_app_options -name route.global.crosstalk_driven -value true
# ------------------------------------------------------------
# DETAIL ROUTING
# ------------------------------------------------------------

# force_end_on_preferred_grid reduces DRC iterations significantly at 14nm
set_app_options -name route.detail.force_end_on_preferred_grid  -value true

# Medium DRC convergence is enough for this block size
set_app_options -name route.detail.drc_convergence_effort_level -value medium

# eco_route_use_soft_spacing: set false to avoid hold violations
# during ECO – your fast corner hold margin (0.05ns) is tight
set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false

# ------------------------------------------------------------
# ROUTE COMMON
# ------------------------------------------------------------
# Fix existing DRC during ECO route passes
set_app_options -name route.common.eco_route_fix_existing_drc   -value true

# Suppress verbose routing logs for a small clean block
set_app_options -name route.common.verbose_level                -value 0

route_global

route_track

route_detail

#route_auto > routing.log

# ------------------------------------------------------------
# ROUTE OPT (post-route optimization)
# ------------------------------------------------------------
# CCD helps with your fast-corner hold (0.05ns uncertainty is tight)
set_app_options -name route_opt.flow.enable_ccd                 -value true

# Power optimization ON – you have leakage+dynamic enabled on all 3 scenarios
set_app_options -name route_opt.flow.enable_power               -value true

route_opt > routing.log

###############################################################################################################
# After routing, it's important to check the design's timing, power, congestion, and DRC/LVS to ensure that the 
# routed design meets the design requirements before proceeding to signoff.
# The following commands will report the timing, power, congestion, and DRC/LVS results to help you identify any 
# potential issues that need to be addressed before moving on to signoff.
###############################################################################################################

check_routes 
check_lvs
report_timing -delay_type max -type full -verbose > timing_report_setup_after_routing.txt
report_timing -delay_type min -type full -verbose > timing_report_hold_after_routing.txt
report_power > power_report_after_routing.txt
report_congestion -rerun_global_router > congestion_report_after_routing.txt

###############################################################################################################
# Incremental Routing to fix any remaining DRCs after the initial routing pass, followed by metal fill and final DRC check.
###############################################################################################################

route_detail -inceremental true -initial_drc true > incremental_routing.log
route_opt > incremental_routing_opt.log ;# Optional incremental route optimization after fixing DRCs or for hold fixes

###############################################################################################################
# After incremental routing, it's important to check the design's timing, power, congestion, and DRC/LVS again 
# to ensure that the incremental routing fixes have resolved the issues without introducing new ones before proceeding to signoff.

# The following commands will report the timing, power, congestion, and DRC/LVS results after incremental routing 
# to help you confirm that the design is ready for signoff.
###############################################################################################################

check_routes 
check_lvs

###############################################################################################################
###############################################################################################################
# Create standard cell filler instances to fill in any gaps in the design after routing, then perform 
# a final DRC check to ensure that the filled design meets all design rules before proceeding to signoff.

# This step is crucial for ensuring that the design is manufacturable and meets the required design rules, 
# as the filler cells help to maintain the integrity of the power grid and reduce the likelihood of manufacturing defects.
###############################################################################################################

create_stdcell_filler \
    -lib_cell [get_lib_cells {
        */SAEDRVT14_FILL1 */SAEDRVT14_FILL16 */SAEDRVT14_FILL2
        */SAEDRVT14_FILL3  */SAEDRVT14_FILL32  */SAEDRVT14_FILL64
        */SAEDRVT14_FILLP2   */SAEDRVT14_FILLP3 */SAEDRVT14_DCAP_V4_5 
        */SAEDRVT14_DCAP_V4_8 */SAEDRVT14_DCAP_V4_16 */SAEDRVT14_DCAP_V4_32 
    }] \
    -prefix FILL

check_legality

###############################################################################################################
# After creating standard cell fillers, it's important to perform a final DRC check to ensure that the filled design 
# meets all design rules before proceeding to signoff.

# The following command will run the DRC check and report any violations that need to be addressed before moving on 
# to signoff.
###############################################################################################################

# --- DRC before fill ---
set_app_options -name signoff.check_drc.runset \
    -value "/data/pdk/pdk14nm/SAED14nm_EDK_03_2025/SAED14nm_EDK_TECH_DATA/icv_drc/saed14nm_1p9m_drc_rules.rs"
set_app_options -name signoff.check_drc.run_dir \
    -value "./drc_signoff"
signoff_check_drc

# Create metal fill and perform final DRC check after fill – important for manufacturability and ensuring design rules are met with the added fill cells.
# --- Metal fill ---
set_app_options \
    -name signoff.create_metal_fill.runset \
    -value "/data/pdk/pdk14nm/SAED14nm_EDK_03_2025/SAED14nm_EDK_TECH_DATA/icv_drc/saed14nm_1p9m_mfill_rules.rs"
    
signoff_create_metal_fill \
    -timing_preserve_setup_slack_threshold 0.1

update_timing

# --- DRC after fill ---
set_app_options -name signoff.check_drc.run_dir \
    -value "./drc_after_fill"
signoff_check_drc

###############################################################################################################
save_block -as routed_block
save_block -as alu_8bit
###############################################################################################################