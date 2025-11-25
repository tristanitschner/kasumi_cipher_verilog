// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

module kasumi_iter (
	input wire clk,

	input  wire         s_valid,
	output wire         s_ready,
	input  wire [63:0]  s_data,
	input  wire [127:0] s_key,

	output wire         m_valid,
	input  wire         m_ready,
	output wire [63:0]  m_data
);

wire s_fire = s_valid && s_ready;
wire m_fire = m_valid && m_ready;

reg r_running = 0;
always @(posedge clk) begin
	if (m_fire) begin
		r_running <= 0;
	end
	if (s_fire) begin
		r_running <= 1;
	end
end

reg [2:0] counter = 0;
wire counter_last = counter == 0;

wire do_something = s_fire || (r_running && !counter_last);

always @(posedge clk) begin
	if (do_something) begin
		counter <= counter + 1;
	end
end

wire         kz_s_valid;
wire         kz_s_ready;
wire [63:0]  kz_s_data;
wire [127:0] kz_s_key;

wire         kz_m_valid;
wire         kz_m_ready;
wire [63:0]  kz_m_data;
wire [127:0] kz_m_key;

kasumi_stage kasumi_stage_inst (
	.clk (clk),

	.n (counter),

	.s_valid (kz_s_valid),
	.s_ready (kz_s_ready),
	.s_data  (kz_s_data),
	.s_key   (kz_s_key),

	.m_valid (kz_m_valid),
	.m_ready (kz_m_ready),
	.m_data  (kz_m_data),
	.m_key   (kz_m_key)
);

assign kz_s_valid = do_something;
assign s_ready = !r_running || (r_running && m_fire);

assign kz_s_data = s_fire ? s_data : kz_m_data;
assign kz_s_key  = s_fire ? s_key  : kz_m_key;

assign m_valid = r_running && counter_last; 
assign kz_m_ready = m_valid ? m_ready : 1;

assign m_data = kz_m_data;

endmodule
