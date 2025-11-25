// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

// Note: clks are dummy

module kasumi_fo (
	input wire clk,

	input  wire [31:0] x,
	input  wire [47:0] ko,
	input  wire [47:0] ki,
	output wire [31:0] y
);

wire [15:0] l_in, r_in;
wire [15:0] ko1, ko2, ko3;
wire [15:0] ki1, ki2, ki3;
wire [15:0] l1, r1, l2, r2, l3, r3;

assign {l_in, r_in} = x;
assign {ko1, ko2, ko3} = ko;
assign {ki1, ki2, ki3} = ki;

wire [15:0] fi_1, fi_2, fi_3;

kasumi_fi kasumi_fi_inst0(
	.clk (clk),
	.x   (l_in ^ ko1),
	.ki  (ki1),
	.y   (fi_1)
);

kasumi_fi kasumi_fi_inst1(
	.clk (clk),
	.x   (l1 ^ ko2),
	.ki  (ki2),
	.y   (fi_2)
);

kasumi_fi kasumi_fi_inst2(
	.clk (clk),
	.x   (l2 ^ ko3),
	.ki  (ki3),
	.y   (fi_3)
);

assign r1 = fi_1 ^ r_in;
assign l1 = r_in;
assign r2 = fi_2 ^ r1;
assign l2 = r1;
assign r3 = fi_3 ^ r2;
assign l3 = r2;

assign y = {l3, r3};

endmodule
