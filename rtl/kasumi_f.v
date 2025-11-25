// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

module kasumi_f (
	input wire clk,

	input wire [2:0] n,

	input  wire [31:0] x,
	input  wire [47:0] ko,
	input  wire [47:0] ki,
	input  wire [31:0] kl,
	output wire [31:0] y
);

// wire [31:0] result_odd;
// wire [31:0] result_even;
// 
// /******************************************************************************/
// // odd case
// 
// wire [31:0] fl;
// 
// kasumi_fl kasumi_fl_inst_odd (
// 	.clk (clk),
// 	.x   (x),
// 	.key (kl),
// 	.y   (fl)
// );
// 
// kasumi_fo kasumi_fo_inst_odd (
// 	.clk (clk),
// 	.x   (fl),
// 	.ko  (ko),
// 	.ki  (ki),
// 	.y   (result_odd)
// );
// 
// /******************************************************************************/
// // even case
// 
// wire [31:0] fo;
// 
// kasumi_fo kasumi_fo_inst_even (
// 	.clk (clk),
// 	.x   (x),
// 	.ko  (ko),
// 	.ki  (ki),
// 	.y   (fo)
// );
// 
// kasumi_fl kasumi_fl_inst_even (
// 	.clk (clk),
// 	.x   (fo),
// 	.key (kl),
// 	.y   (result_even)
// );
// 
// /******************************************************************************/
// 
// wire is_odd = !n[0]; // we start counting at zero, so add one
// 
// assign y = is_odd ? result_odd : result_even;

// NEW TRY!
// -> resource usage is significantly less, timing only a little worse

wire [31:0] fo_x;
wire [47:0] fo_ko;
wire [47:0] fo_ki;
wire [31:0] fo_y;

kasumi_fo kasumi_fo_inst (
	.clk (clk),
	.x   (fo_x),
	.ko  (fo_ko),
	.ki  (fo_ki),
	.y   (fo_y)
);

wire [31:0] fl_y_odd;

kasumi_fl kasumi_fl_inst_odd (
	.clk (clk),
	.x   (x),
	.key (kl),
	.y   (fl_y_odd)
);

wire [31:0] fl_y_even;

kasumi_fl kasumi_fl_inst_even (
	.clk (clk),
	.x   (fo_y),
	.key (kl),
	.y   (fl_y_even)
);

wire is_odd = !n[0];

assign fo_x = is_odd ? fl_y_odd : x;
assign fo_ko = ko;
assign fo_ki = ki;

assign y = is_odd ? fo_y : fl_y_even;

endmodule
