// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

module kasumi_fl (
	input wire clk,

	input  wire [31:0] x,
	input  wire [31:0] key,
	output wire [31:0] y
);

function [15:0] rol16(input [15:0] x);
	begin
		rol16 = {x[14:0], x[15]};
	end
endfunction

wire [15:0] kl1,   kl2;
wire [15:0] l_in,  r_in;
wire [15:0] l_out, r_out;

assign {kl1, kl2} = key;
assign {l_in, r_in} = x;
assign r_out = r_in ^ rol16(l_in  & kl1);
assign l_out = l_in ^ rol16(r_out | kl2);
assign y = {l_out, r_out};

endmodule
