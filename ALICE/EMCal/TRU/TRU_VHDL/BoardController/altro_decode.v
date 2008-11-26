`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:51:00 09/08/2008 
// Design Name: 
// Module Name:    altro_decode 
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
// $Id: altro_decode.v,v 1.1 2008-11-26 16:34:21 jschamba Exp $
//
//////////////////////////////////////////////////////////////////////////////////
module altro_decode
  (
   input wire rclk,
   input wire cstb,
   input wire write,
   input wire reset,
   input wire [39:0] bd,
   
   input wire trsf,
   
   output wire ctrl_out,
   output wire oeab_h,
   output wire oeab_l,
   output wire oeba_h,
   output wire oeba_l,
   
   output wire data_out_sign,
   output wire [6:0] point_address,
   
   output wire ackn,
   output wire in_out,
   
   output wire [39:0] last_40bit,
   output reg readout_end
   
   );

   reg [7:0] state, next_state;
   
   //state machine define
   parameter [7:0] idle = 8'b0000_0000;
   parameter [7:0] start = 8'b0000_0001;
   parameter [7:0] decode = 8'b0000_0010;
   parameter [7:0] decode_en = 8'b0000_0100;
   parameter [7:0] set_ackn = 8'b0000_1000;
   parameter [7:0] release_ackn = 8'b0001_0000;
   parameter [7:0] wait_out = 8'b0010_0000;
   parameter [7:0] data_out = 8'b0100_0000;
   parameter [7:0] stop = 8'b1000_0000;

   always @(negedge reset or posedge rclk)
     begin
	if(~reset) state <= idle;
	else	state <= next_state;
     end

   reg trsf_d;
   wire stop_out_sign;
   always @(posedge rclk) trsf_d = trsf ;
   assign stop_out_sign = trsf&(~trsf_d);
   
   reg [3:0] point_adr; 
   reg 	     branch;
   reg [2:0] chip_address;
   always @(cstb or state or stop_out_sign or bd or write or point_address)
     begin
	case (state)
	  idle : 
	    begin
	       if(~cstb) next_state <= start; else next_state <= idle;
	       readout_end <= 1'h0;
	    end
	  start : next_state <= decode;
	  decode : 
	    if({bd[38:37],bd[35:32],write,bd[24:20]} == 12'h01a) next_state <= decode_en; 
	    else  next_state <= idle;
	  decode_en : begin 
	     next_state <= set_ackn;
	     point_adr <= bd[28:25];
	     branch <= bd[36];
	     chip_address <= bd[31:29];
	  end
	  set_ackn : if(cstb) next_state <= release_ackn; else next_state <= set_ackn;
	  release_ackn : next_state <= wait_out;
	  wait_out : next_state <= data_out;
	  data_out : if(stop_out_sign) next_state <= stop; else next_state <= data_out;
	  stop : begin 
	     next_state <= idle; 
	     if(7'b1111111 == point_address) readout_end <= 1'h1; else readout_end <= 1'h0;
	  end
	  default : next_state <= idle;
	endcase
     end
   
   assign ctrl_out = ~(state[6]|state[3]);
   assign oeab_h = ~state[6];
   assign oeab_l = ~state[6];
   assign oeba_h = ~oeab_h;
   assign oeba_l = ~oeab_l;
   assign data_out_sign = state[6];
   assign point_address = {chip_address,point_adr};
   assign ackn = ~state[3];
   assign in_out = state[6];
   assign last_40bit = {28'haaa872a,branch,4'h0,chip_address,point_adr};
   
endmodule


