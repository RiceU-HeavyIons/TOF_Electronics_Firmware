`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:13:41 08/20/2008 
// Design Name: 
// Module Name:    start_flag_gen 
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
// $Id: start_flag_gen.v,v 1.1 2008-11-26 16:34:53 jschamba Exp $

// Detect START condition at rcu_sda_in line. 
// A high-to-low transition on rcu_sda_in line while the serial clock line remains high
// means a START condition.
//////////////////////////////////////////////////////////////////////////////////
module start_flag_gen
  (rcu_scl,
   rcu_sda_in,
   start_flag);
	
   input rcu_scl; //The serial clock line : RCU --> FEE/TRU, ca.150KHz
   input rcu_sda_in; //The serial data line : RCU --> FEE/TRU 
   output start_flag; //"start" flag : module(start_flag_gen) --> module(rcui2c_fsm)
   
   //input or output ports
   wire   rcu_scl;
   wire   rcu_sda_in;	 
   
   reg 	  start_flag;
   
   always @(negedge rcu_scl or negedge rcu_sda_in) begin 
      if(~rcu_scl)begin
	 start_flag <= 1'b0;
      end else begin
	 start_flag <= 1'b1;
      end
   end
		
endmodule
