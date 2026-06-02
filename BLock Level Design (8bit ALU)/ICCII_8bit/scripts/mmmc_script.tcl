###############################################################################################################
# 8-bit ALU - Multi-Mode Multi-Corner (MMMC) Setup Script
# This script sets up the design for multi-mode multi-corner analysis in IC Compiler II.
# File: mmmc_script.tcl
###############################################################################################################

set PDK_PATH /data/pdk/pdk14nm/SAED14nm_EDK_03_2025
set CONSTRAINTS ./../CONSTRAINTS/alu_8bit.sdc

###############################################################################################################

remove_modes   -all
remove_corners -all
remove_scenarios -all

###############################################################################################################

set corner_slow "slow"
set corner_fast "fast"
set corner_typical "typical"

create_corner $corner_slow
create_corner $corner_fast
create_corner $corner_typical

set mode1 "func"
create_mode $mode1

################################################################################################################ Slow corner → setup analysis (worst-case delay)
# Fast corner → hold analysis (best-case delay, hold is harder)
# Typical     → power analysis (representative switching activity)
###############################################################################################################

set scenario_slow "${mode1}_${corner_slow}"
set scenario_fast "${mode1}_${corner_fast}"
set scenario_typical "${mode1}_${corner_typical}"

create_scenario -name $scenario_slow -mode $mode1 -corner $corner_slow
create_scenario -name $scenario_fast -mode $mode1 -corner $corner_fast
create_scenario -name $scenario_typical -mode $mode1 -corner $corner_typical

###############################################################################################################
# Cmax = worst-case capacitance (worst setup, used for slow corner)
# Cmin = best-case capacitance  (best hold,  used for fast corner)
# Nominal = typical (used for power estimation in typical corner)
###############################################################################################################

set tluplus_cmax    "$PDK_PATH/SAED14nm_EDK_TECH_DATA/tlup/saed14nm_1p9m_Cmax.tlup"
set tluplus_cmin    "$PDK_PATH/SAED14nm_EDK_TECH_DATA/tlup/saed14nm_1p9m_Cmin.tlup"
set tluplus_nominal "$PDK_PATH/SAED14nm_EDK_TECH_DATA/tlup/saed14nm_1p9m_Cnom.tlup"
set layer_map_file  "$PDK_PATH/SAED14nm_EDK_TECH_DATA/map/saed14nm_tf_itf_tluplus.map"

read_parasitic_tech -tlup $tluplus_cmax    -layermap $layer_map_file -name p1
read_parasitic_tech -tlup $tluplus_cmin    -layermap $layer_map_file -name p2
read_parasitic_tech -tlup $tluplus_nominal -layermap $layer_map_file -name p3

# Assign parasitics to corners
# Slow corner: late=Cmax (pessimistic delay), early=Cmin (optimistic, for hold check)
set_parasitic_parameters -late_spec p1 -early_spec p2 \
                         -corners $corner_slow
# Fast corner: same pairing — fast cells with Cmax late / Cmin early
# WHY: Hold is checked on fast corner because cells switch fastest →
#      data arrives so quickly it can violate hold of the capturing FF
set_parasitic_parameters -late_spec p1 -early_spec p2 \
                         -corners $corner_fast
# Typical: late=nominal, early=nominal — balanced for power estimation
set_parasitic_parameters -late_spec p3 -early_spec p3 \
                         -corners $corner_typical

###############################################################################################################

current_corner $corner_slow
set_operating_conditions \
    -max_library "$PDK_PATH/SAED14nm_EDK_STD_RVT/liberty/nldm/base/saed14rvt_base_ss0p585v125c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_LVT/liberty/nldm/base/saed14lvt_base_ss0p585v125c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_HVT/liberty/nldm/base/saed14hvt_base_ss0p585v125c.db" \
    -min_library "$PDK_PATH/SAED14nm_EDK_STD_RVT/liberty/nldm/base/saed14rvt_base_ss0p585v125c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_LVT/liberty/nldm/base/saed14lvt_base_ss0p585v125c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_HVT/liberty/nldm/base/saed14hvt_base_ss0p585v125c.db"

current_corner $corner_fast
set_operating_conditions \
    -max_library "$PDK_PATH/SAED14nm_EDK_STD_RVT/liberty/nldm/base/saed14rvt_base_ff0p88vm40c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_LVT/liberty/nldm/base/saed14lvt_base_ff0p88vm40c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_HVT/liberty/nldm/base/saed14hvt_base_ff0p88vm40c.db" \
    -min_library "$PDK_PATH/SAED14nm_EDK_STD_RVT/liberty/nldm/base/saed14rvt_base_ff0p88vm40c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_LVT/liberty/nldm/base/saed14lvt_base_ff0p88vm40c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_HVT/liberty/nldm/base/saed14hvt_base_ff0p88vm40c.db"
                  
current_corner $corner_typical
set_operating_conditions \
    -max_library "$PDK_PATH/SAED14nm_EDK_STD_RVT/liberty/nldm/base/saed14rvt_base_tt0p8v25c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_LVT/liberty/nldm/base/saed14lvt_base_tt0p8v25c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_HVT/liberty/nldm/base/saed14hvt_base_tt0p8v25c.db" \
    -min_library "$PDK_PATH/SAED14nm_EDK_STD_RVT/liberty/nldm/base/saed14rvt_base_tt0p8v25c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_LVT/liberty/nldm/base/saed14lvt_base_tt0p8v25c.db \
                  $PDK_PATH/SAED14nm_EDK_STD_HVT/liberty/nldm/base/saed14hvt_base_tt0p8v25c.db" 

###############################################################################################################

current_mode $mode1
source $CONSTRAINTS -echo -verbose

###############################################################################################################
set_scenario_status $scenario_slow \
    -setup true -hold false \
    -leakage_power true -dynamic_power true \
    -max_transition true -max_capacitance true \
    -min_capacitance false -active true

set_scenario_status $scenario_fast \
    -setup false -hold true \
    -leakage_power true -dynamic_power true \
    -max_transition true -max_capacitance true \
    -min_capacitance false -active true

set_scenario_status $scenario_typical \
    -setup false -hold false \
    -leakage_power true -dynamic_power true \
    -max_transition true -max_capacitance true \
    -min_capacitance false -active true

###############################################################################################################
###############################################################################################################