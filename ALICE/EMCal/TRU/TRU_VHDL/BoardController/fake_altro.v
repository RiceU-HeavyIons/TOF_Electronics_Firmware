`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:33:13 09/08/2008 
// Design Name: 
// Module Name:    fake_altro 
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
// $Id: fake_altro.v,v 1.1 2008-11-26 16:34:21 jschamba Exp $
//
//////////////////////////////////////////////////////////////////////////////////
module fake_altro
  (
   input wire rcu_clk, 
   input wire clk_dstb,
   input wire g_clk,
   input wire reset,
   
   input wire L0,
   input wire L1,
   input wire L2,
   
   input wire [1343:0] shift_data,
   
   input wire cstb,
   input wire write_r,
   
   output wire ctrl_out,
   output wire oeab_l,
   output wire oeab_h,
   output wire oeba_l,
   output wire oeba_h,
   
   output wire ackn,
   output wire dstb,
   output wire trsf,
   
   inout wire [39:0] bd,
   output wire [41:0] chipview
   );
   
   wire [39:0] bd_in;
   wire [6:0]  point_address;
   wire [39:0] last_40bit;
   wire [11:0] address_out;
   wire [1:0]  mux_control;
   wire [39:0] out_1,out_2,out_3;
   
   //~~~~~~~write control~~~~~~~~~~//
			
   wire [7:0]  address;
   wire        write_en; 
   wire [7:0]  address_L0;
   wire        readout_end;
   
   wire        write;
   assign      write = write_r;
   
   write_control write_control
     (
      .L1(L1),
      .L2(L2),
      .reset(reset),
      .clk(g_clk),
      .trig_L0(L0),
      .readout_end(readout_end),
      
      .address(address),
      .write_en(),
      .address_L0(address_L0[7:0])
      );
   assign      write_en = 1'b1;
   
   //~~~~~~altro decode~~~~~~~~~~~//

   altro_decode altro_decode
     (
      .rclk(rcu_clk),
      .cstb(cstb),
      .write(write),
      .reset(reset),
      .bd(bd_in[39:0]),
      
      .trsf(trsf),
      
      .ctrl_out(ctrl_out),
      .oeab_h(oeab_h),
      .oeab_l(oeab_l),
      .oeba_h(oeba_h),
      .oeba_l(oeba_l),
      
      .data_out_sign(data_out_sign),
      .point_address(point_address[6:0]),
      
      .ackn(ackn),
      .in_out(in_out),
      
      .last_40bit(last_40bit[39:0]),
      .readout_end(readout_end)
      );
   
   //~~~~~~~~~register control~~~~~~~~~~~//

   register_control register_control
     (
      .data_out_sign(data_out_sign),
      .point_address(point_address),
      .clk(rcu_clk),
      .clk_dstb(rcu_clk),
      .reset(reset),
      .address_L0(address_L0),
      
      .address_out(address_out[11:0]),
      .read_en(),
      .mux_control(mux_control[1:0]),
      .dstb(dstb),
      .trsf(trsf) 
      );
   assign      read_en	= 1'b1; 
   //~~~~~~~~register~~~~~~~~~~~~~~~~~~~//

   wire [1535:0] data_in;
   assign 	 data_in[1535:0] = {192'h0,shift_data[1343:0]};	
   
   wire [47:0] 	 data_1,data_2;
   blockselectRAM_fakealtro blockselectRAM_fakealtro_1	/* synthesis syn_noprune=1 */
     (
      .clka(g_clk),
      .dina(data_in[767:0]),
      .addra(address[7:0]),
      .wea(write_en),
      .clkb(rcu_clk),
      .addrb(address_out[11:0]),
      .enb(read_en),
      .doutb(data_1[47:0]));
   
   blockselectRAM_fakealtro blockselectRAM_fakealtro_2  /* synthesis syn_noprune=1 */
     (
      .clka(g_clk),
      .dina(data_in[1535:768]),
      .addra(address[7:0]),
      .wea(write_en),
      .clkb(rcu_clk),
      .addrb(address_out[11:0]),
      .enb(read_en),
      .doutb(data_2[47:0]));
   
   //~~~~~~~~~~~~mux and inout buf~~~~~~~~~~~~~~~~~~//

   assign 	 out_1[39:0] = {data_1[47:38],data_1[35:26],data_1[23:14],data_1[11:2]};
   assign 	 out_2[39:0] = {data_2[47:38],data_2[35:26],data_2[23:14],data_2[11:2]};
   assign 	 out_3[39:0] = 40'haa8721c2aa;
   
   reg [39:0] 	 bd_mux;
   always @ (out_1 or out_2 or out_3 or last_40bit or mux_control)
     begin
	case(mux_control)
	  2'b00 : bd_mux <= out_1;
	  2'b01	: bd_mux <= out_2;
	  2'b10 : bd_mux <= out_3;
	  2'b11 : bd_mux <= last_40bit;
	endcase
     end
   
   genvar n; generate
      for(n=0; n<40; n=n+1) begin: N
	 IOBUF buffer_BD 
	   (
	    .O (bd_in[n]), 
	    .IO (bd[n]), 
	    .I (bd_mux[n]), 
	    .T (~in_out)
	    ); 
      end
   endgenerate 

   assign chipview[39:0] = bd_mux;
   assign chipview[40] = dstb;
   assign chipview[41] = trsf;
   
endmodule
