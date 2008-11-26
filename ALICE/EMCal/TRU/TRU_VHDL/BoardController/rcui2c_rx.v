`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:14:17 08/20/2008 
// Design Name: 
// Module Name:    rcui2c_rx 
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
// $Id: rcui2c_rx.v,v 1.1 2008-11-26 16:34:53 jschamba Exp $
//
//////////////////////////////////////////////////////////////////////////////////
module rcui2c_rx
  (reset, 
   rcu_scl, 
   rcu_sda_in, 
   state, 
   slave_ack_flag,
   card_addr_reg,
   reg_addr_reg,
   rx_data_out);

   input reset;
   input rcu_scl;
   input rcu_sda_in;
   input [8:0] state;
   output [5:0] slave_ack_flag;
   output [6:0] card_addr_reg;
   output [7:0] reg_addr_reg;
   output [15:0] rx_data_out;	 
   
   //input and output ports
   wire 	 reset;
   wire 	 rcu_scl;
   wire 	 rcu_sda_in;
   wire [8:0] 	 state;
   wire [5:0] 	 slave_ack_flag;
   reg [6:0] 	 card_addr_reg;
   reg [7:0] 	 reg_addr_reg;
   reg [15:0] 	 rx_data_out; 
   
   //internal variables
   reg [5:0] 	 sda_in_counter;
   
   //parameter
   parameter [8:0] idle = 9'b0_0000_0001;
   parameter [8:0] card_addr_rx_state = 9'b0_0000_0010;
   parameter [8:0] slave_ack_state = 9'b0_0000_0100;
   parameter [8:0] reg_addr_rx_state = 9'b0_0000_1000;
   parameter [8:0] rx_data_state = 9'b0_0001_0000;
   parameter [8:0] tx_data_state = 9'b0_0010_0000;
   parameter [8:0] master_ack_state = 9'b0_0100_0000;
   parameter [8:0] master_no_ack_state = 9'b0_1000_0000;
   parameter [8:0] stop_state = 9'b1_0000_0000;
   
   assign 	   slave_ack_flag = sda_in_counter;
   //RX
   always @(negedge reset or posedge rcu_scl)
     begin : RX_OUTPUT_LOGIC //a
	if(~reset) begin
	   sda_in_counter <= 6'b0;
	   card_addr_reg <= 7'b0;
	   reg_addr_reg <= 8'b0;
	   rx_data_out <= 16'b0;
	end else begin //b
	   case(state)
	     idle : 	begin
		sda_in_counter <= 6'b0;
	     end
	     
	     card_addr_rx_state : begin
		sda_in_counter <= sda_in_counter + 6'b1;
		card_addr_reg <= card_addr_reg << 1;
		card_addr_reg[0] <= rcu_sda_in;										
	     end
	     
	     slave_ack_state : begin
		sda_in_counter <= sda_in_counter + 6'b1;
	     end
	     
	     reg_addr_rx_state : begin
		sda_in_counter <= sda_in_counter + 6'b1;
		reg_addr_reg <= reg_addr_reg << 1;
		reg_addr_reg[0] <= rcu_sda_in;										
	     end
	     
	     rx_data_state : begin
		sda_in_counter <= sda_in_counter + 6'b1;
		rx_data_out <= rx_data_out << 1;
		rx_data_out[0] <= rcu_sda_in;
	     end
	     
	     tx_data_state : begin
		sda_in_counter <= sda_in_counter + 6'b1;
	     end
	     
	     master_ack_state : begin
		sda_in_counter <= rcu_sda_in ? 6'h24 : (sda_in_counter+6'b1);
	     end
	     
	     master_no_ack_state : begin
		sda_in_counter <= (~rcu_sda_in) ? 6'h24 : (sda_in_counter+6'b1);
	     end
	     
	     stop_state : 	begin
		sda_in_counter <= 6'b0;
	     end
	     
	     default: 	begin
		sda_in_counter <= 6'b0;
	     end	
	   endcase
	end//b
     end//a
   
endmodule
