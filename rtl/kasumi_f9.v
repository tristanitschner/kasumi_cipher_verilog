// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

// Note:
// * minimum bw = 8 (please don't use anything smaller or anything that is not
// divisible by 8)

module kasumi_f9 #(
	parameter bw = 8
) (
	input wire clk,

	input  wire         s_ctl_valid,
	output wire         s_ctl_ready,
	input  wire [31:0]  s_ctl_count,
	input  wire [31:0]  s_ctl_fresh,
	input  wire [127:0] s_ctl_ik,
	input  wire         s_ctl_direction,

	input  wire             s_valid,
	output wire             s_ready,
	input  wire             s_last,
	input  wire [63:0]      s_data,
	input  wire [64/bw-1:0] s_keep,

	output wire        m_valid,
	input  wire        m_ready,
	output wire [31:0] m_mac
);

localparam kw = 64/bw;

wire         kz_s_valid;
wire         kz_s_ready;
wire [63:0]  kz_s_data;
wire [127:0] kz_s_key;
wire         kz_m_valid;
wire         kz_m_ready;
wire [63:0]  kz_m_data;

kasumi_iter kasumi_iter_inst (
	.clk     (clk),
	.s_valid (kz_s_valid),
	.s_ready (kz_s_ready),
	.s_data  (kz_s_data),
	.s_key   (kz_s_key),
	.m_valid (kz_m_valid),
	.m_ready (kz_m_ready),
	.m_data  (kz_m_data)
);

/******************************************************************************/

wire [127:0] km = 128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;

function [5:0] countones(input [64/bw-1:0] x);
	integer i;
	reg [5:0] result;
	begin
		result = 0;
		for (i = 0; i < 64/bw; i = i + 1) begin
			if (x[i]) result = result + 1;
		end
		countones = result;
	end
endfunction

wire [5:0] s_count = countones(s_keep);

wire [63:0] first_beat = {s_ctl_count, s_ctl_fresh}; // on ctl handshake

reg r_last = 0;
always @(posedge clk) begin
	if (s_valid && s_ready) begin
		r_last <= s_last;
	end
	if (m_valid && m_ready) begin
		r_last <= 0;
	end
end

reg [kw-1:0] r_keep = 0;
always @(posedge clk) begin
	if (s_valid && s_ready) begin
		r_keep <= s_keep;
	end
end

reg [127:0] r_ik;
always @(posedge clk) begin
	if (s_ctl_valid && s_ctl_ready) begin
		r_ik <= s_ctl_ik;
	end
end

reg r_direction;
always @(posedge clk) begin
	if (s_ctl_valid && s_ctl_ready) begin
		r_direction <= s_ctl_direction;
	end
end

reg [63:0] r_b = 0;

always @(posedge clk) begin
	if (kz_m_valid && kz_m_ready && r_state != st_idle) begin
		r_b <= kz_m_data ^ r_b;
	end
	if (m_valid && m_ready) begin
		r_b <= 0;
	end
end

/******************************************************************************/

wire s_needs_extra_beat = s_last && (s_keep[0] || (bw == 1 ? s_keep[1] : 0));
wire s_needs_extra_beat_special = s_last && (!s_keep[0] && (bw == 1 ? s_keep[1] : 0));

reg r_needs_extra_beat = 0; // little helper
always @(posedge clk) begin
	if (kz_m_valid && kz_m_ready) begin
		r_needs_extra_beat <= 0;
	end
	if (s_valid && s_ready && s_needs_extra_beat) begin
		r_needs_extra_beat <= 1;
	end
end

reg r_needs_extra_beat_special = 0; // little helper
generate if (bw == 1) begin : gen_special_case

	always @(posedge clk) begin
		if (kz_m_valid && kz_m_ready) begin
			r_needs_extra_beat_special <= 0;
		end
		if (s_valid && s_ready && s_needs_extra_beat_special) begin
			r_needs_extra_beat_special <= 1;
		end
	end

end endgenerate

localparam st_idle       = 2'd0;
localparam st_data       = 2'd1;
localparam st_extra_beat = 2'd2;
localparam st_mac        = 2'd3;

reg [1:0] r_state = st_idle;
always @(posedge clk) begin
	case (r_state) 
		st_idle: begin
			if (s_ctl_valid && s_ctl_ready) begin
				r_state <= st_data;
			end
		end
		st_data: begin
			if (kz_m_valid && kz_m_ready && r_last) begin
				if (r_needs_extra_beat) begin
					r_state <= st_extra_beat;
				end else begin
					r_state <= st_mac;
				end
			end
		end
		st_extra_beat: begin
			if (kz_m_valid && kz_m_ready) begin
				r_state <= st_mac;
			end
		end
		st_mac: begin
			if (m_valid && m_ready) begin
				r_state <= st_idle;
			end
		end
	endcase
end

// TODO: clean up the mess below...

assign s_ctl_ready = kz_s_ready && r_state == st_idle;

assign s_ready = kz_s_ready && r_state == st_data && !r_last;

assign m_valid = r_state == st_mac && kz_m_valid;

assign kz_s_valid = (s_ctl_valid && r_state == st_idle) ||
	(s_valid && r_state == st_data && !r_last) ||
	(r_state == st_data && r_last) ||
	(r_state == st_extra_beat);

wire [63:0] s_data_extra = {r_direction, 1'b1, 62'b0};

wire [63:0] s_data_padded = 
	r_needs_extra_beat_special ? {1'b1,       63'b0} :
	r_needs_extra_beat         ? s_data_extra :
	s_data | ({r_direction, 1'b1, 64'b0} >> (2+bw*s_count));

assign kz_s_data =
	r_needs_extra_beat ? s_data_padded ^ kz_m_data : 
	(r_state == st_data && !r_needs_extra_beat && r_last) ? kz_m_data ^ r_b :
	r_state == st_data ? ((s_last && (!s_needs_extra_beat || s_needs_extra_beat_special)) ? s_data_padded : s_data) ^ kz_m_data :
	r_last ? kz_m_data ^ r_b : 
	r_state == st_idle ? first_beat :
	kz_m_data;

assign m_mac = kz_m_data[63:32];

assign kz_s_key = 
	r_needs_extra_beat ? r_ik :
	r_last ? r_ik ^ km : r_state == st_idle ? s_ctl_ik : r_ik;

assign kz_m_ready = 
	r_state == st_idle ? 0 : 
	r_state == st_data ? 1 : 
	r_state == st_extra_beat ? 1 : 
	r_state == st_mac ? m_ready : 0;

endmodule
