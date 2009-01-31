`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:07:28 09/08/2008 
// Design Name: 
// Module Name:    write_control 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
//
// $Id: write_control.v,v 1.2 2009-01-31 20:43:39 jschamba Exp $
//
//////////////////////////////////////////////////////////////////////////////////
module write_control
  (
   input wire L1,
   input wire L2,
   input wire reset,
   input wire clk,
   input wire trig_L0,
   input wire readout_end,
   
   output wire [7:0] address,
   output wire write_en,
   output wire [7:0] address_L0
   );

   reg [3:0] state, next_state;
   reg [7:0] counter;
   
   //state machine define
   parameter [3:0] idle = 4'b0000;
   parameter [3:0] start = 4'b0001;
   parameter [3:0] wait_L2 = 4'b0010;
   parameter [3:0] lock = 4'b0100;
   parameter [3:0] wait_readout = 4'b1000;
   
   reg [7:0] address_copy;

   always @(negedge reset or posedge clk)
     begin
	if(~reset) begin 
	   state <= idle;
	   address_copy <= 8'h0;
	end
	else begin
	   state <= next_state;
	   if(write_en&trig_L0) address_copy <= counter;
	end
     end

   reg [14:0] con;
   
   always @ (posedge clk) if(state == wait_readout) con = con + 1; else con = 15'h0;

   always @(L1 or L2 or state or trig_L0 or con)
     begin
	case (state)
	  idle :  if(~L1) next_state <= start; else next_state <= idle;
	  start : next_state <= wait_L2;
	  wait_L2 :  	if(~L2) next_state <= lock; else  next_state <= wait_L2;
	  lock : begin next_state <= wait_readout; end
	  wait_readout : if(con[14]) next_state <= idle; else next_state <= wait_readout;
	  default : next_state <= idle;
	endcase
     end
   
   always @ (negedge reset or posedge clk) 
     begin
	if(~reset) counter <= 8'h0;
	else if(write_en) 	counter <= counter + 1;	
	else 	counter <= counter;
     end

   assign write_en = (state == idle) ? 1'b1 : 1'b0;

   assign address = counter;
// JS: temporarily only write to first 128 points, since we are only reading out 128
//   assign address = {1'b0, counter[6:0]};

   assign address_L0 = address_copy;

endmodule
