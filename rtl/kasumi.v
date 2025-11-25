// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

// Note:
// * this is the unrolled kasumi cipher, it does not make much sense using
// this in f8 or f9 due to the recursive dependencies, however feel free to
// use it in a proper suitable cbc mode

module kasumi (
	input wire clk,

	input  wire         s_valid,
	output wire         s_ready,
	input  wire [63:0]  s_data,
	input  wire [127:0] s_key,

	output wire         m_valid,
	input  wire         m_ready,
	output wire [63:0]  m_data
);

genvar gi;

wire [8:0]   i_valid;
wire [8:0]   i_ready;
wire [63:0]  i_data [0:8];
wire [127:0] i_key  [0:8];

assign i_valid[0] = s_valid;
assign s_ready = i_ready[0];
assign i_data[0] = s_data;
assign i_key[0] = s_key;

generate for (gi = 0; gi < 8; gi = gi + 1) begin

	kasumi_stage kasumi_stage_inst (
		.clk (clk),

		.n (gi),

		.s_valid (i_valid [gi]),
		.s_ready (i_ready [gi]),
		.s_data  (i_data  [gi]),
		.s_key   (i_key   [gi]),

		.m_valid (i_valid [gi+1]),
		.m_ready (i_ready [gi+1]),
		.m_data  (i_data  [gi+1]),
		.m_key   (i_key   [gi+1])
	);

end endgenerate

assign m_valid = i_valid[8];
assign i_ready[8] = m_ready;
assign m_data = i_data[8];

endmodule
