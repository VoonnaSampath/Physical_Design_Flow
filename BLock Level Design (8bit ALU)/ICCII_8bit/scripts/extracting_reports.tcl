###############################################################################################################
# Extracting Reports Script for 8-bit ALU
# This script performs extraction for the 8-bit ALU design in IC Compiler II.
# File: extracting_reports.tcl
# This script assumes that the design has been fully routed as per the routing.tcl script

# open alu_8bit block and then run this script to extract parasitics, generate SDF, and create final GDS/DEF/LEF 
# outputs for your 8-bit ALU design.
#############################################################################################################

file mkdir outputs
file mkdir reports

###################################################################################################################

# Slow corner SPEF (Cmax — setup sign-off)
write_parasitics \
    -format spef \
    -corner $corner_slow \
    -output outputs/alu_8bit_slow.spef

# Fast corner SPEF (Cmin — hold sign-off)
write_parasitics \
    -format spef \
    -corner $corner_fast \
    -output outputs/alu_8bit_fast.spef

# Typical corner SPEF (Cnom — power analysis)
write_parasitics \
    -format spef \
    -corner $corner_typical \
    -output outputs/alu_8bit_typical.spef
    
###################################################################################################################

write_verilog \
    -hierarchy all \
    -top_module_first \
    outputs/alu_8bit_netlist.v

###################################################################################################################

# Slow corner SDF — setup sign-off (use -MAXIMUM in simulator for worst delay)
write_sdf \
    -corner $corner_slow \
    -mode $mode1 outputs/alu_8bit_slow.sdf

# Fast corner SDF — hold sign-off (use -MINIMUM in simulator for best delay)
write_sdf \
    -corner $corner_fast \
    -mode $mode1 outputs/alu_8bit_fast.sdf

###################################################################################################################

write_def outputs/alu_8bit.def

###################################################################################################################

write_lef outputs/alu_8bit_abstract.lef

###################################################################################################################

set PDK_PATH /data/pdk/pdk14nm/SAED14nm_EDK_03_2025

# Standard cell GDS for each Vt type
set rvt_gds "$PDK_PATH/SAED14nm_EDK_STD_RVT/gds/saed14rvt.gds"
set lvt_gds "$PDK_PATH/SAED14nm_EDK_STD_LVT/gds/saed14lvt.gds"
set hvt_gds "$PDK_PATH/SAED14nm_EDK_STD_HVT/gds/saed14hvt.gds"

# Merge all Vt GDS files into a single self-contained output GDS.
# The design GDS (block-level shapes) is always included automatically.
write_gds \
    -merge_files [list $rvt_gds $lvt_gds $hvt_gds] \
	outputs/alu_8bit_final.gds

###################################################################################################################
# If going to call this alu_8bit as a hard macro in a larger design, you would typically use the generated LEF file 
# (alu_8bit_abstract.lef) for the macro definition, and the DEF file (alu_8bit.def) for the detailed placement and 
# routing information when integrating into the larger design. The GDS file (alu_8bit_final.gds) contains the full layout 
# geometry and is used for final tape-out and manufacturing.

# If you are using this block as a hard macro, you would typically provide the LEF file to the integrator for placement 
# and the GDS file for final layout verification and tape-out. The DEF file can be used for detailed placement and routing 
# information during the integration phase, but the LEF is more commonly used for macro definition and placement in the larger design.
###################################################################################################################
# For calling this as a hard macro in 32 bit alu
# After extraction, 

open_block alu_8bit

create_frame \
-block_all true \
-merge_metal_blockage true \
-block_lower_layers_of_pins metal_blockage \
-hierarchical true

create_abstract

save_block
save_lib
###################################################################################################################
# then use this library ALU_8bit_14_LIB as the reference library when integrating into the larger 32-bit ALU design, 
# and use the generated LEF and GDS files for macro definition and final layout verification respectively.

# While creating the block ICCII will automatically generates an design.ndm for the block, which can be used in the larger design.
# By using create_frame, it will generate a frame.ndm file
###################################################################################################################