// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

// Note: clks are dummy

module kasumi_fi (
	input wire clk,

	input  wire [15:0] x,
	input  wire [15:0] ki,
	output wire [15:0] y
);

function [8:0] ze(input [6:0] x);
	begin
		ze = {2'b0, x};
	end
endfunction

function [6:0] tr(input [8:0] x);
	begin
		tr = x[6:0];
	end
endfunction

/******************************************************************************/

wire [6:0] ki1;
wire [8:0] ki2;

assign {ki1, ki2} = ki;

wire [8:0] l0, l2, l4;
wire [6:0] r0, r2, r4;
wire [6:0] l1, l3;
wire [8:0] r1, r3;

assign {l0, r0} = x;

wire [8:0] s9_l0, s9_l2;
wire [6:0] s7_l1, s7_l3;

kasumi_s9 kasumi_s9_inst_l0 (
	.clk (clk),
	.x   (l0),
	.y   (s9_l0)
);

kasumi_s7 kasumi_s7_inst_l1 (
	.clk (clk),
	.x   (l1),
	.y   (s7_l1)
);

kasumi_s9 kasumi_s9_inst_l2 (
	.clk (clk),
	.x   (l2),
	.y   (s9_l2)
);

kasumi_s7 kasumi_s7_inst_l3 (
	.clk (clk),
	.x   (l3),
	.y   (s7_l3)
);

assign l1 = r0;
assign r1 = s9_l0 ^ ze(r0);

assign l2 = r1 ^ ki2;
assign r2 = s7_l1 ^ tr(r1) ^ ki1;

assign l3 = r2;
assign r3 = s9_l2 ^ ze(r2);

assign l4 = r3;
assign r4 = s7_l3 ^ tr(r3);

assign y = {r4, l4};

endmodule
