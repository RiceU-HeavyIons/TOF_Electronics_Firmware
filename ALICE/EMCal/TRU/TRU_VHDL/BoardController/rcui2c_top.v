`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:32:41 08/21/2008 
// Design Name: 
// Module Name:    rcui2c_top 
// Project Name: 
// Target Devices: 
// Tool versions:
//
// Author : Fan.Zhang(CCNU)
// 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// $Id: rcui2c_top.v,v 1.1 2008-11-26 16:34:53 jschamba Exp $
//
//////////////////////////////////////////////////////////////////////////////////
module rcui2c_top
  (reset,
   clk_40m,
   rcu_scl_i,
   rcu_sda_in_i,
   tx_data_in,
   card_addr,
   tx_data_req,
   rx_data_out,
   rx_data_ready,
   rcu_sda_out,
   reg_addr_reg,
   rcui2c_busy_flag);
   
   input reset;
   input clk_40m; 
   input rcu_scl_i;
   input rcu_sda_in_i;
   input [15:0] tx_data_in;
   input [4:0] 	card_addr;
   output 	tx_data_req;
   output [15:0] rx_data_out;
   output 	 rx_data_ready;
   output 	 rcu_sda_out;
   output [7:0]  reg_addr_reg;
   output 	 rcui2c_busy_flag;
   
   //input or output ports
   wire 	 reset;
   wire 	 clk_40m;
   wire 	 rcu_scl_i;
   wire 	 rcu_sda_in_i;
   wire [15:0] 	 tx_data_in;
   wire [4:0] 	 card_addr;
   wire 	 tx_data_req;
   wire [15:0] 	 rx_data_out;
   wire 	 rx_data_ready;
   wire 	 rcu_sda_out;
   wire [7:0] 	 reg_addr_reg;
   wire 	 rcui2c_busy_flag;
   
   //internal wires
   wire 	 rcu_scl;
   wire 	 rcu_sda_in;
   wire 	 start_flag;
   wire [5:0] 	 slave_ack_flag;
   wire [6:0] 	 card_addr_reg;
   wire [8:0] 	 state;
   
   start_flag_gen  U1
     (.rcu_scl(rcu_scl),
      .rcu_sda_in(rcu_sda_in),
      .start_flag(start_flag)
      );
   
   rcui2c_fsm	U2
     (.reset(reset), 
      .clk_40m(clk_40m), 
      .start_flag(start_flag), 
      .slave_ack_flag(slave_ack_flag), 
      .card_addr(card_addr), 
      .card_addr_reg(card_addr_reg), 
      .state(state), 
      .tx_data_req(tx_data_req), 
      .rx_data_ready(rx_data_ready), 
      .rcui2c_busy_flag(rcui2c_busy_flag));
   
   rcui2c_rx	U3
     (.reset(reset), 
      .rcu_scl(rcu_scl), 
      .rcu_sda_in(rcu_sda_in), 
      .state(state), 
      .slave_ack_flag(slave_ack_flag), 
      .card_addr_reg(card_addr_reg), 
      .reg_addr_reg(reg_addr_reg), 
      .rx_data_out(rx_data_out));

   rcui2c_tx	U4
     (.reset(reset), 
      .rcu_scl(rcu_scl), 
      .state(state), 
      .tx_data_in(tx_data_in), 
      .rcu_sda_out(rcu_sda_out) 
      );
   
   rcu_signal_filter U5
     (.clk_40m(clk_40m), 
      .rcu_scl_i(rcu_scl_i), 
      .rcu_sda_in_i(rcu_sda_in_i), 
      .rcu_scl(rcu_scl), 
      .rcu_sda_in(rcu_sda_in));						
   
endmodule
