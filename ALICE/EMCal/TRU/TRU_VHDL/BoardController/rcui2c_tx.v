`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:31:23 08/20/2008 
// Design Name: 
// Module Name:    rcui2c_tx 
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
// $Id: rcui2c_tx.v,v 1.1 2008-11-26 16:34:53 jschamba Exp $
//
//////////////////////////////////////////////////////////////////////////////////
module rcui2c_tx
  (reset,
   rcu_scl,
   state,
   tx_data_in,
   rcu_sda_out);
   
   input reset;
   input rcu_scl;
   input [8:0] state;
   input [15:0] tx_data_in;
   output 	rcu_sda_out;
   
   //input/output ports
   wire 	reset;
   wire 	rcu_scl;
   wire [8:0] 	state;
   wire [15:0] 	tx_data_in;
   reg 		rcu_sda_out;
   
   //internal variables
   reg [16:0] 	tx_data_buf;
   
   parameter [8:0] idle = 9'b0_0000_0001;
   parameter [8:0] card_addr_rx_state = 9'b0_0000_0010;
   parameter [8:0] slave_ack_state = 9'b0_0000_0100;
   parameter [8:0] reg_addr_rx_state = 9'b0_0000_1000;
   parameter [8:0] rx_data_state = 9'b0_0001_0000;
   parameter [8:0] tx_data_state = 9'b0_0010_0000;
   parameter [8:0] master_ack_state = 9'b0_0100_0000;
   parameter [8:0] master_no_ack_state = 9'b0_1000_0000;
   parameter [8:0] stop_state = 9'b1_0000_0000;
   
   
   always @(negedge reset or negedge rcu_scl)
     begin//a
	if(~reset)begin
	   rcu_sda_out <= 1'b1;
	end else begin//b
	   case(state)
	     idle :  begin
		rcu_sda_out <= 1'b1;
	     end
	     
	     tx_data_state : begin
		rcu_sda_out <= tx_data_buf[16];
	     end								 
	     
	     slave_ack_state : begin
	        rcu_sda_out <= 1'b0;
	     end
	     
	     master_ack_state : begin
		rcu_sda_out <= 1'b1;
	     end
	     
	     default : begin
		rcu_sda_out <= 1'b1;
	     end
	   endcase
	end//b	 
     end//a	
   
   always @(posedge rcu_scl)
     if(~reset) begin
	tx_data_buf <= 17'b0;
     end else if(state == slave_ack_state) begin 
	tx_data_buf <= {tx_data_in[15:8],1'b1,tx_data_in[7:0]};
     end else begin
	tx_data_buf <= tx_data_buf <<1;
     end
   
endmodule
