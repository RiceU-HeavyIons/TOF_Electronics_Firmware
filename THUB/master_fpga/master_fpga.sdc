## Generated SDC file "master_fpga.out.sdc"

## Copyright (C) 1991-2010 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 10.0 Build 218 06/27/2010 SJ Full Version"

## DATE    "Tue Jul 20 13:30:50 2010"

##
## DEVICE  "EP2C35F672C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk} -period 25.000 -waveform { 0.000 12.500 } [get_ports {clk}]
create_clock -name {tcd_clk} -period 21.000 -waveform { 0.000 10.500 } [get_ports {tcd_clk}]
create_clock -name {mcI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mcI[15]}]
create_clock -name {mgI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mgI[15]}]
create_clock -name {mfI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mfI[15]}]
create_clock -name {mhI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mhI[15]}]
create_clock -name {meI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {meI[15]}]
create_clock -name {maI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {maI[15]}]
create_clock -name {mdI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mdI[15]}]
create_clock -name {mbI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mbI[15]}]

#create_clock -name {tcd_strb} -period 105.0 -waveform { 0.000 21.0 } [get_ports {tcd_strb}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {pll:pll_instance|altpll:altpll_component|_clk0} \
	-source [get_pins {pll_instance|altpll_component|pll|inclk[0]}] \
	-duty_cycle 50.000 \
	-multiply_by 2 \
	-master_clock {clk} \
	[get_pins {pll_instance|altpll_component|pll|clk[0]}] 
create_generated_clock -name {pll:pll_instance|altpll:altpll_component|_clk2} \
	-source [get_pins {pll_instance|altpll_component|pll|inclk[0]}] \
	-duty_cycle 50.000 \
	-multiply_by 1 -divide_by 4 \
	-master_clock {clk} \
	[get_pins {pll_instance|altpll_component|pll|clk[2]}] 

#create_generated_clock -name {tcd_strb} -source [get_ports {tcd_clk}] -divide_by 5 -master_clock {tcd_clk} [get_ports {tcd_strb}] 


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

set_clock_groups -asynchronous \
	-group [get_clocks {  tcd_clk }] \
	-group [get_clocks {  pll:pll_instance|altpll:altpll_component|_clk0  pll:pll_instance|altpll:altpll_component|_clk2  clk  }] \
	-group [get_clocks {  maI[15]  }] \
	-group [get_clocks {  mbI[15]  }] \
	-group [get_clocks {  mcI[15]  }] \
	-group [get_clocks {  mdI[15]  }] \
	-group [get_clocks {  meI[15]  }] \
	-group [get_clocks {  mfI[15]  }] \
	-group [get_clocks {  mgI[15]  }] \
	-group [get_clocks {  mhI[15]  }] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_keepers {lpm_counter:counter23b|cntr_u8k:auto_generated|safe_q[*]}] -to [get_keepers {s_stage1}]

set_false_path -from [get_keepers {ddl:ddl_inst|ddl_receiver:RX|event_read}] -to [get_keepers {synchronizer:syncA|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {ddl:ddl_inst|ddl_receiver:RX|event_read}] -to [get_keepers {synchronizer:syncB|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {ddl:ddl_inst|ddl_receiver:RX|event_read}] -to [get_keepers {synchronizer:syncC|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {ddl:ddl_inst|ddl_receiver:RX|event_read}] -to [get_keepers {synchronizer:syncD|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {ddl:ddl_inst|ddl_receiver:RX|event_read}] -to [get_keepers {synchronizer:syncE|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {ddl:ddl_inst|ddl_receiver:RX|event_read}] -to [get_keepers {synchronizer:syncF|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {ddl:ddl_inst|ddl_receiver:RX|event_read}] -to [get_keepers {synchronizer:syncG|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {ddl:ddl_inst|ddl_receiver:RX|event_read}] -to [get_keepers {synchronizer:syncH|dcfifo:sync_fifo*}]

set_false_path -from [get_keepers {control_registers:control_reg_inst|reg0_out[0]}] -to [get_keepers {synchronizer:syncA|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {control_registers:control_reg_inst|reg0_out[0]}] -to [get_keepers {synchronizer:syncB|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {control_registers:control_reg_inst|reg0_out[0]}] -to [get_keepers {synchronizer:syncC|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {control_registers:control_reg_inst|reg0_out[0]}] -to [get_keepers {synchronizer:syncD|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {control_registers:control_reg_inst|reg0_out[0]}] -to [get_keepers {synchronizer:syncE|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {control_registers:control_reg_inst|reg0_out[0]}] -to [get_keepers {synchronizer:syncF|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {control_registers:control_reg_inst|reg0_out[0]}] -to [get_keepers {synchronizer:syncG|dcfifo:sync_fifo*}]
set_false_path -from [get_keepers {control_registers:control_reg_inst|reg0_out[0]}] -to [get_keepers {synchronizer:syncH|dcfifo:sync_fifo*}]

set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_dd9:dffpipe16|dffe17a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_cd9:dffpipe13|dffe14a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_7f9:dffpipe8|dffe9a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_6f9:dffpipe5|dffe6a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_3v8:dffpipe11|dffe12a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_2v8:dffpipe8|dffe9a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_gd9:dffpipe9|dffe10a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_fd9:dffpipe6|dffe7a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_9f9:dffpipe8|dffe9a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_8f9:dffpipe5|dffe6a*}]
set_false_path -from [get_keepers {*dcfifo_id02*|delayed_wrptr_g[*]}] -to [get_keepers {*dcfifo_id02*|*rs_dgwp|*dffpipe13|dffe14a[*]}]
set_false_path -from [get_keepers {*dcfifo_id02*|rdptr_g[*]}] -to [get_keepers {*dcfifo_id02*|*ws_dgrp|*dffpipe16|dffe17a[*]}]
set_false_path -from [get_keepers {*dcfifo_lh12*|delayed_wrptr_g[*]}] -to [get_keepers {*dcfifo_lh12*|*rs_dgwp|*dffpipe5|dffe6a[*]}]
set_false_path -from [get_keepers {*dcfifo_lh12*|rdptr_g[*]}] -to [get_keepers {*dcfifo_lh12*|*ws_dgrp|*dffpipe8|dffe9a[*]}]
set_false_path -from [get_keepers {*dcfifo_n202*|delayed_wrptr_g[*]}] -to [get_keepers {*dcfifo_n202*|*rs_dgwp|*dffpipe8|dffe9a[*]}]
set_false_path -from [get_keepers {*dcfifo_n202*|rdptr_g[*]}] -to [get_keepers {*dcfifo_n202*|*ws_dgrp|*dffpipe11|dffe12a[*]}]
set_false_path -from [get_keepers {*dcfifo_re02*|delayed_wrptr_g[*]}] -to [get_keepers {*dcfifo_re02*|*rs_dgwp|*dffpipe6|dffe7a[*]}]
set_false_path -from [get_keepers {*dcfifo_re02*|rdptr_g[*]}] -to [get_keepers {*dcfifo_re02*|*ws_dgrp|*dffpipe9|dffe10a[*]}]
set_false_path -from [get_keepers {*dcfifo_vh12*|delayed_wrptr_g[*]}] -to [get_keepers {*dcfifo_vh12*|*rs_dgwp|*dffpipe5|dffe6a[*]}]
set_false_path -from [get_keepers {*dcfifo_vh12*|rdptr_g[*]}] -to [get_keepers {*dcfifo_vh12*|*ws_dgrp|*dffpipe8|dffe9a[*]}]


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

