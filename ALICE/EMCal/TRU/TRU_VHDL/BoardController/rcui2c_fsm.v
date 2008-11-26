`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:38:05 08/20/2008 
// Design Name: 
// Module Name:    rcui2c_fsm 
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
// $Id: rcui2c_fsm.v,v 1.1 2008-11-26 16:34:53 jschamba Exp $
//
//////////////////////////////////////////////////////////////////////////////////
module rcui2c_fsm
  (
   reset, 
   clk_40m, 
   start_flag, 
   slave_ack_flag, 
   card_addr, 
   card_addr_reg, 
   state, 
   tx_data_req, 
   rx_data_ready, 
   rcui2c_busy_flag
   );
   
   input reset;
   input clk_40m;
   input start_flag;
   input [5:0] slave_ack_flag;
   input [4:0] card_addr;
   input [6:0] card_addr_reg;
   output [8:0] state;
   output 	tx_data_req;
   output 	rx_data_ready;
   output 	rcui2c_busy_flag;
   
   //input or output ports
   wire 	reset;
   wire 	clk_40m;
   wire 	start_flag;
   wire [5:0] 	slave_ack_flag;
   wire [4:0] 	card_addr;
   wire [6:0] 	card_addr_reg;
   reg [8:0] 	state;
   reg 		tx_data_req;
   reg 		rx_data_ready;
   reg 		rcui2c_busy_flag;
   
   //internal variables
   reg [8:0] 	next_state;
   wire 	addr_match_flag;
   
   assign 	addr_match_flag = (card_addr_reg[5:1] == card_addr)||(card_addr_reg[6]&&(~card_addr_reg[0]));
   
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
   
   
   
   always @(negedge reset or negedge clk_40m)
     begin
	if(~reset)begin
	   rcui2c_busy_flag = 1'b0;
	   tx_data_req = 1'b0;
	   rx_data_ready = 1'b0;
	   next_state = idle;
	end else begin
	   case(state)
	     idle : 	begin
		tx_data_req = 1'b0;
		rx_data_ready = 1'b0;
		rcui2c_busy_flag = 1'b0;						
		next_state = start_flag ? card_addr_rx_state : idle;						
	     end
	     card_addr_rx_state :
	       begin						
		  tx_data_req = 1'b0;
		  rx_data_ready = 1'b0;
		  rcui2c_busy_flag = 1'b0;
		  case(slave_ack_flag)
		    6'h00,6'h01,6'h02,6'h03,6'h04,6'h05,6'h06,6'h07 : 
		      next_state = card_addr_rx_state;
		    6'h08 : next_state = addr_match_flag ? slave_ack_state : idle; 
		    default: next_state = idle;
		  endcase
	       end
	     slave_ack_state :
	       begin
		  tx_data_req = 1'b0;
		  rx_data_ready = 1'b0;
		  rcui2c_busy_flag = 1'b1;
		  case(slave_ack_flag)						
		    6'h09 : next_state = reg_addr_rx_state;//17
		    6'h12 : next_state = card_addr_reg[0]? tx_data_state : rx_data_state;										
		    6'h1b : next_state = rx_data_state;
		    6'h24 : begin 
		       next_state = stop_state;
		    end
		    6'h11 :  begin 
		       tx_data_req = card_addr_reg[0];
		       next_state = slave_ack_state;
		    end
		    6'h08,6'h1a : next_state = slave_ack_state;
		    6'h23 : begin
		       rx_data_ready = 1'b1;
		       next_state = slave_ack_state;
		    end
		    default : next_state = idle; 
		  endcase
	       end										
	     reg_addr_rx_state :
	       begin
		  tx_data_req = 1'b0;
		  rx_data_ready = 1'b0;
		  rcui2c_busy_flag = 1'b1;
		  case(slave_ack_flag)
		    6'h9,6'h0a,6'h0b,6'h0c,6'h0d,6'h0e,6'h0f,6'h10 : 
		      next_state = reg_addr_rx_state;
		    6'h11 :  begin
		       next_state = slave_ack_state;
		       tx_data_req = card_addr_reg[0];//RCU read FEE/TRU : 1
		    end						
		    default : next_state = idle;
		  endcase
	       end
	     rx_data_state :
	       begin
		  tx_data_req = 1'b0;
		  rx_data_ready = 1'b0;
		  rcui2c_busy_flag = 1'b1;
		  case(slave_ack_flag)
		    6'h12,6'h13,6'h14,6'h15,6'h16,6'h17,6'h18,6'h19 : 
		      next_state = rx_data_state;						
		    6'h1a : next_state = slave_ack_state;
		    6'h1b,6'h1c,6'h1d,6'h1e,6'h1f,6'h20,6'h21,6'h22 : 
		      next_state = rx_data_state;
		    6'h23 :	next_state = slave_ack_state;	
		    default :next_state = idle;
		  endcase
	       end
	     
	     tx_data_state :
	       begin
		  tx_data_req = 1'b0;
		  rx_data_ready = 1'b0;
		  rcui2c_busy_flag = 1'b1;
		  case(slave_ack_flag)
		    6'h12,6'h13,6'h14,6'h15,6'h16,6'h17,6'h18,6'h19 : 
		      next_state = tx_data_state;						
		    6'h1a : next_state = master_ack_state;
		    6'h1b,6'h1c,6'h1d,6'h1e,6'h1f,6'h20,6'h21,6'h22 : 
		      next_state = tx_data_state;
		    6'h23 :	next_state = master_no_ack_state;
		    default :next_state = idle;
		  endcase
	       end			
	     master_ack_state	:
	       begin
		  tx_data_req = 1'b0;
		  rx_data_ready = 1'b0;
		  rcui2c_busy_flag = 1'b1;
		  case(slave_ack_flag)
		    6'h1a : next_state = master_ack_state;
		    6'h1b : next_state = tx_data_state;
		    default : next_state = idle;
		  endcase
	       end						
	     master_no_ack_state :
	       begin
		  tx_data_req = 1'b0;
		  rx_data_ready = 1'b0;
		  rcui2c_busy_flag = 1'b1;
		  case(slave_ack_flag)
		    6'h23 : next_state = master_no_ack_state;
		    6'h24 : next_state = stop_state;
		    default : next_state = idle;
		  endcase
	       end
	     stop_state : 
	       begin
		  tx_data_req = 1'b0;
		  rx_data_ready = 1'b0;
		  rcui2c_busy_flag = 1'b1;
		  case(slave_ack_flag)
		    6'h24 : begin 
		       next_state = stop_state;
		    end
		    default : next_state = idle;
		  endcase
	       end
	     default :begin 
		next_state = idle;
	     end
	   endcase
	end
     end
   
   //state transition
   always @(negedge reset or posedge clk_40m)
     begin
	if(~reset) begin
	   state <= idle;
	end else begin
	   state <= next_state;
	end
     end
   
endmodule
