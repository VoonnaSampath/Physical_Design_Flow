##############################################################################
## File        : alu_8bit.sdc
## Description : Synopsys Design Constraints for alu_8bit macro (SAED 14nm)
##               Used in: DC synthesis AND ICC2 P&R
##               Reference clock: 500 MHz (2.0 ns period)
##############################################################################

###############################################################################
# 1. VIRTUAL CLOCK  (kept for reference; NOT used for I/O delays in standalone)
###############################################################################
# WHY KEPT: when alu_8bit is instantiated as a hard macro inside alu_32bit,
# switch I/O delays to VCLK so the parent's clock drives the budget, not this
# block's own CTS tree.  Match period to parent SDC.
# Virtual clock for external interface timing
create_clock \
    -name vclk \
    -period 2 \
    -waveform {0 1}
# NOTE: No [get_ports] → virtual clock (no physical source)


###############################################################################
# 2. REAL DESIGN CLOCK
###############################################################################
create_clock \
    -name clk \
    -period 2 \
    -waveform {0 1} \
    [get_ports clk]

################################################################################
# CLOCK UNCERTAINTY
################################################################################
# Clock uncertainty: jitter + skew budget
#   Setup : 100 ps (5 % of period) — tighten if jitter spec < 50 ps
#   Hold  :  40 ps

# ~10% setup uncertainty
set_clock_uncertainty \
    -setup 0.10 \
    [get_clocks clk]

# ~4% hold uncertainty
set_clock_uncertainty \
    -hold 0.04 \
    [get_clocks clk]

################################################################################
# CLOCK LATENCY  (pre-CTS estimate; replaced by set_propagated_clock post-CTS)
################################################################################

# Internal clock network latency
set_clock_latency \
    -max 0.20 \
    [get_clocks clk]

set_clock_latency \
    -min 0.10 \
    [get_clocks clk]

# Source latency (PLL / CTS insertion estimate)
set_clock_latency \
    -source -max 0.30 \
    [get_clocks clk]

set_clock_latency \
    -source -min 0.20 \
    [get_clocks clk]

################################################################################
# CLOCK TRANSITION
################################################################################

set_clock_transition \
    -max 0.06 \
    -rise \
    [get_clocks clk]

set_clock_transition \
    -max 0.06 \
    -fall \
    [get_clocks clk]

################################################################################
# INPUT DELAYS
################################################################################
# from launch to capture and reports setup/hold paths correctly.
# External logic driving inputs
set_input_delay \
    -max 0.80 \
    -clock vclk \
    [all_inputs]

set_input_delay \
    -min 0.10 \
    -clock vclk \
    [all_inputs]

remove_input_delay [get_ports clk]

################################################################################
# OUTPUT DELAYS
################################################################################
# Outputs: captured by parent FFs, timed against parent clock (VCLK)
# External logic capturing outputs
set_output_delay \
    -max 0.60 \
    -clock vclk \
    [all_outputs]

set_output_delay \
    -min 0.1 \
    -clock vclk \
    [all_outputs]

################################################################################
# DESIGN RULE CONSTRAINTS
################################################################################

# Tight slew target for 14nm 
set_max_transition \
    0.20 \
    [current_design] ;# 200 ps max slew on any net/pin

# Slightly relaxed for output ports
set_max_transition \
    0.20 \
    [all_outputs]

# Capacitance constraint
set_max_capacitance \
    0.20 \
    [current_design] ;# 200 fF max cap

# Fanout constraint
set_max_fanout \
    32 \
    [current_design]  ;# max 32 loads per driver