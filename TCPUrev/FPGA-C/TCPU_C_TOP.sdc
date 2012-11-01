# $Id$
## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 12.0 Build 263 08/02/2012 Service Pack 2 SJ Full Version"

## DATE    "Thu Nov 01 09:34:17 2012"

##
## DEVICE  "EP2C20F484C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************


create_clock -name {pld_clkin1} -period 25.000 -waveform { 0.000 12.500 } [get_ports {pld_clkin1}]
create_clock -name {c1_strobe_out} -period 25.000 -waveform { 0.000 12.500 } [get_ports {c1_strobe_out}]
create_clock -name {c2_strobe_out} -period 25.000 -waveform { 0.000 12.500 } [get_ports {c2_strobe_out}]
# JS: this one is fake, since the PLL requirement is at least 100ns
create_clock -name {trig_clk_in_clk} -period 100.000 -waveform { 0.000 40.000 } [get_ports {trig_clk_in_clk}]
create_clock -name {ser_rec_clk} -period 50.000 -waveform { 0.000 25.000 } [get_ports {ser_rec_clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks

#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous \
	-group [get_clocks {\
			pll_instance|altpll_component|pll|clk[0] \
			pll_instance|altpll_component|pll|clk[1] \
			pld_clkin1  \
			c1_strobe_out \
			c2_strobe_out \
		}] \
	-group [get_clocks {\
			PLL_1x_and_16x_inst|altpll_component|pll|clk[0] \
			PLL_1x_and_16x_inst|altpll_component|pll|clk[1] \
			trig_clk_in_clk  \
		}] \
	-group [get_clocks { ser_rec_clk   }] \



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_re9:dffpipe20|dffe21a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_qe9:dffpipe17|dffe18a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_te9:dffpipe19|dffe20a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_se9:dffpipe16|dffe17a*}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

