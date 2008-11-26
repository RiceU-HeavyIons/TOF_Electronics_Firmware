`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:01:27 08/26/2008 
// Design Name: 
// Module Name:    rcu_signal_filter 
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
// $Id: rcu_signal_filter.v,v 1.1 2008-11-26 16:34:53 jschamba Exp $  
//
//////////////////////////////////////////////////////////////////////////////////
module rcu_signal_filter(clk_40m, rcu_scl_i, rcu_sda_in_i, rcu_scl, rcu_sda_in);
   input clk_40m;
   input rcu_scl_i;
   input rcu_sda_in_i;
   output rcu_scl;
   output rcu_sda_in;
   
   wire   clk_40m;
   wire   rcu_scl_i;
   wire   rcu_sda_in_i;
   reg 	  rcu_scl;
   reg 	  rcu_sda_in;
   
   always @(posedge clk_40m)
     begin
	rcu_scl <= rcu_scl_i;
	rcu_sda_in <= rcu_sda_in_i;
     end
   
endmodule
