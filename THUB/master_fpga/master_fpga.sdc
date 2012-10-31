#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk} -period 25.000 -waveform { 0.000 12.500 } [get_ports {clk}]

create_clock -name {tcd_clk} -period 21.000 -waveform { 0.000 10.500 } [get_ports {tcd_clk}]

create_clock -name {maI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {maI[15]}]
create_clock -name {mbI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mbI[15]}]
create_clock -name {mcI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mcI[15]}]
create_clock -name {mdI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mdI[15]}]
create_clock -name {meI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {meI[15]}]
create_clock -name {mfI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mfI[15]}]
create_clock -name {mgI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mgI[15]}]
create_clock -name {mhI[15]} -period 12.500 -waveform { 0.000 6.250 } [get_ports {mhI[15]}]

#create_clock -name {tcd_strb} -period 105.0 -waveform { 0.000 21.0 } [get_ports {tcd_strb}]


#**************************************************************
# Create Generated Clock
#**************************************************************

derive_pll_clocks


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

derive_clock_uncertainty


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
	-group [get_clocks { tcd_clk }] \
	-group [get_clocks {\
			pll_instance|altpll_component|pll|clk[0] \
			pll_instance|altpll_component|pll|clk[2] \
			clk  \
		}] \
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

#set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_dd9:dffpipe16|dffe17a*}]
#set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_cd9:dffpipe13|dffe14a*}]


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

