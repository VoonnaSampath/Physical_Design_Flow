###############################################################################################################
# 8-bit ALU Design - Placement Script
# This script performs placement for the 8-bit ALU design in IC Compiler II.
# It assumes that the design has been floorplanned and power planned as per the design_planning.tcl script.
# File: placement.tcl
# open powerplan_block
###############################################################################################################

source ./scripts/mmmc_script.tcl
set_host_options -max_cores 4

check_design -checks pre_placement_stage

# Small block – 0.75 util is safe, auto density handles local hotspots
set_app_options -name place.coarse.congestion_driven_max_util   -value 0.75
set_app_options -name place.coarse.congestion_layer_aware       -value true
set_app_options -name place.coarse.auto_density_control         -value enhanced


# No scandef in this flow
set_app_options -name place.coarse.continue_on_missing_scandef  -value true

# Pin access quality at 14nm matters – keep incremental on
set_app_options -name place.legalize.optimize_pin_access            -value true
set_app_options -name place.legalize.optimize_pin_access_incremental -value true

foreach scenario [list $scenario_slow $scenario_fast $scenario_typical] {
    current_scenario $scenario
    source $CONSTRAINTS -echo -verbose
    }

set_ignored_layers -min_routing_layer M2 -max_routing_layer M8

place_opt > placement.log

###############################################################################################################
# Create tie cells for any floating power pins after placement, then check legality before proceeding to CTS.

# This step ensures that any power pins that are not connected to the power grid after placement are tied to 
# the appropriate power or ground reference, which is crucial for ensuring the functionality and reliability of the 
# design before moving on to clock tree synthesis.
###############################################################################################################

add_tie_cells \
    -tie_high_lib_cells [get_lib_cells {
        saed14rvt_base_frame_timing/SAEDRVT14_TIE1_4
        saed14lvt_base_frame_timing/SAEDLVT14_TIE1_4
        saed14hvt_base_frame_timing/SAEDHVT14_TIE1_4
    }] \
    -tie_low_lib_cells [get_lib_cells {
        saed14rvt_base_frame_timing/SAEDRVT14_TIE0_4 
        saed14lvt_base_frame_timing/SAEDLVT14_TIE0_4 
        saed14hvt_base_frame_timing/SAEDHVT14_TIE0_4 
    }]

check_legality -verbose

###############################################################################################################
# After placement, report congestion and timing to identify any potential issues before CTS and routing.
# These reports will help you understand if there are any local congestion hotspots or timing violations that need to be addressed before proceeding to the next steps.
###############################################################################################################

report_congestion -rerun_global_router > congestion_report_after_placement.txt
report_timing -delay_type max -type full -verbose > timing_report_setup_after_placement.txt
report_timing -delay_type min -type full -verbose > timing_report_hold_after_placement.txt
report_utilization > utilization_report_after_placement.txt
report_placement > placement_report.txt
report_power > power_report_after_placement.txt

###############################################################################################################
save_block -as placement_block
###############################################################################################################
