// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

// Keep the block chain wrapper separate, just for the good style :)

module kasumi_f8 #( 
	parameter bw = 8
) (
	input wire clk,

	input  wire         s_ctl_valid,
	output wire         s_ctl_ready,
	input  wire [31:0]  s_ctl_count,
	input  wire [4:0]   s_ctl_bearer,
	input  wire         s_ctl_direction,
	input  wire [127:0] s_ctl_ck,

	input  wire             s_valid,
	output wire             s_ready,
	input  wire             s_last,
	input  wire [63:0]      s_data,
	input  wire [64/bw-1:0] s_keep,

	output wire             m_valid,
	input  wire             m_ready,
	output wire             m_last,
	output wire [63:0]      m_data,
	output wire [64/bw-1:0] m_keep
);

localparam kw = 64/bw;

wire [63:0] i_m_data;

kasumi_f8_ctl kasumi_f8_ctl_inst (
	.clk             (clk),
	.s_ctl_valid     (s_ctl_valid),
	.s_ctl_ready     (s_ctl_ready),
	.s_ctl_count     (s_ctl_count),
	.s_ctl_bearer    (s_ctl_bearer),
	.s_ctl_direction (s_ctl_direction),
	.s_ctl_ck        (s_ctl_ck),
	.s_valid         (s_valid),
	.s_ready         (s_ready),
	.s_last          (s_last),
	.m_valid         (m_valid),
	.m_ready         (m_ready),
	.m_last          (m_last),
	.m_data          (i_m_data)
);

reg [63:0] r_data;
always @(posedge clk) begin
	if (s_valid && s_ready) begin
		r_data <= s_data;
	end
end

reg [kw-1:0] r_keep;
always @(posedge clk) begin
	if (s_valid && s_ready) begin
		r_keep <= s_keep;
	end
end
assign m_keep = r_keep;

function [63:0] mask_by_keep(input [63:0] data, input [kw-1:0] keep);
	integer i;
	begin
		mask_by_keep = 0;
		for (i = 0; i < kw; i = i + 1) begin
			if (keep[i]) begin
				mask_by_keep[bw*(i+1)-1-:bw] = data[bw*(i+1)-1-:bw];
			end
		end
	end
endfunction

wire [63:0] c_data = r_data ^ i_m_data;

assign m_data = mask_by_keep(c_data, r_keep);

endmodule
