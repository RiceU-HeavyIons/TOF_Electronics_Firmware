`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:34:22 09/09/2008 
// Design Name: 
// Module Name:    register_control 
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
// $Id: register_control.v,v 1.1 2008-11-26 16:34:21 jschamba Exp $  
//
//////////////////////////////////////////////////////////////////////////////////
module register_control
  (
   input wire data_out_sign,
   input wire [6:0] point_address,
   input wire clk,
   input wire clk_dstb,
   input wire reset,
   input wire [7:0] address_L0,
   
   output wire [11:0] address_out,
   output wire read_en,
   output wire [1:0] mux_control,
   output wire dstb,
   output wire trsf 
   );

   reg [1:0] state, next_state;

   //state machine define
   parameter [1:0] idle = 2'b00;
   parameter [1:0] data_out = 2'b01;
   parameter [1:0] release_dstb = 2'b10;

   always @(negedge reset or posedge clk)
     begin
	if(~reset) state <= idle;
	else	state <= next_state;
     end
   
   reg [5:0] counter;
   reg 	     con_sign;
   reg 	     data_out_sign_d;
   reg [1:0] mux;
   reg 	     dstb_d;
   always @(posedge clk)
     begin
	if(counter < 6'h10) begin mux <= 2'b00; con_sign <= 1'b0; end
	else if(counter < 6'h1c) begin mux <= 2'b01; con_sign <= 1'b0; end
	else if(counter == 6'h1c) begin mux <= 2'b10; con_sign <= 1'b0; end
	else if(counter == 6'h1d) begin mux <= 2'b11; con_sign <= 1'b1; end
	else begin mux <= 2'b00; con_sign <= 1'b0; end
	
	if(state[0]) counter <= counter + 1; else counter <= 6'h00;
	
	data_out_sign_d <= data_out_sign;
	dstb_d <= state[0];
     end

   wire sign;
   assign sign = data_out_sign&(~data_out_sign_d);
   
   always @(sign or state or con_sign)
     begin
	case (state)
	  idle : if(sign) next_state <= data_out; else next_state <= idle;
	  data_out : if(con_sign) next_state <= release_dstb; else next_state <= data_out;
	  release_dstb : next_state <= idle;
	  default : next_state <= idle;
	endcase
     end
   
   wire [7:0] read_point;
   assign     read_point = {1'b0,point_address} + address_L0 + 8'hf0;
   assign     address_out = {read_point,counter[3:0]};
   assign     read_en = data_out_sign;
   assign     mux_control = mux;
   
   assign     dstb = (~(state[0]&dstb_d))|clk;
   assign     trsf = ~(state[0]|dstb_d);
   
endmodule
