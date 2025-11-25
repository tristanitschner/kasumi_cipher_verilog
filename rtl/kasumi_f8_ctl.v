// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

module kasumi_f8_ctl (
	input wire clk,

	input  wire         s_ctl_valid,
	output wire         s_ctl_ready,
	input  wire [31:0]  s_ctl_count,
	input  wire [4:0]   s_ctl_bearer,
	input  wire         s_ctl_direction,
	input  wire [127:0] s_ctl_ck,

	input  wire        s_valid,
	output wire        s_ready,
	input  wire        s_last,

	output wire        m_valid,
	input  wire        m_ready,
	output wire        m_last,
	output wire [63:0] m_data
);

wire [63:0] s_a = {s_ctl_count, s_ctl_bearer, s_ctl_direction, 26'b0};

wire [127:0] km = 128'h55555555555555555555555555555555;

wire [127:0] key_init = s_ctl_ck ^ km;

wire         kz_s_valid;
wire         kz_s_ready;
wire [63:0]  kz_s_data;
wire [127:0] kz_s_key;
wire         kz_m_valid;
wire         kz_m_ready;
wire [63:0]  kz_m_data;

kasumi_iter kasumi_iter_inst (
	.clk (clk),
	.s_valid (kz_s_valid),
	.s_ready (kz_s_ready),
	.s_data  (kz_s_data),
	.s_key   (kz_s_key),
	.m_valid (kz_m_valid),
	.m_ready (kz_m_ready),
	.m_data  (kz_m_data)
);

reg r_init = 0;
always @(posedge clk) begin
	if (m_valid && m_ready && m_last) begin
		r_init <= 0;
	end
	if (s_ctl_valid && s_ctl_ready) begin
		r_init <= 1;
	end
end

reg r_running = 0;
always @(posedge clk) begin
	if (m_valid && m_ready && m_last) begin
		r_running <= 0;
	end
	if (r_init && !r_running && kz_m_valid) begin
		r_running <= 1;
	end
end

reg r_last = 0;
always @(posedge clk) begin
	if (m_valid && m_ready && r_last) begin
		r_last <= 0;
	end
	if (s_valid && s_ready && s_last) begin
		r_last <= 1;
	end
end

reg [9:0] blkcnt = 0;
always @(posedge clk) begin
	if (s_valid && s_ready) begin
		if (s_last) begin
			blkcnt <= 0;
		end else begin
			blkcnt <= blkcnt + 1;
		end
	end
end

reg [63:0] r_m_data = 0;
always @(posedge clk) begin
	if (m_valid && m_ready) begin
		if (m_last) begin
			r_m_data <= 0;
		end else begin
			r_m_data <= m_data;
		end
	end
end

reg [63:0] r_a;
always @(posedge clk) begin
	if (r_init && !r_running && kz_m_valid && kz_m_ready) begin
		r_a <= m_data;
	end
end

reg [127:0] r_ck;
always @(posedge clk) begin
	if (s_ctl_valid && s_ctl_ready) begin
		r_ck <= s_ctl_ck;
	end
end

wire [63:0] c_m_data = m_valid ? kz_m_data : r_m_data;

assign kz_s_data = s_ctl_ready ? s_a : r_a ^ {55'b0, blkcnt} ^ c_m_data;
assign kz_s_key = s_ctl_ready ? key_init : r_ck;

// TODO: cleanup

assign m_last = r_last;
assign kz_s_valid = (s_ctl_valid && s_ctl_ready) || (s_valid && s_ready);
assign s_ctl_ready = !r_init || (m_valid && m_ready && m_last);
assign s_ready = r_running && kz_s_ready && !r_last;
assign kz_m_ready = (r_init && !r_running) || (r_running && m_ready);
assign m_valid = r_running && kz_m_valid;
assign m_data = kz_m_data;

`ifdef FORMAL

	reg [31:0] s_ctl_counter = 0;

	always @(posedge clk) begin
		if (s_ctl_valid && s_ctl_ready) begin
			s_ctl_counter <= s_ctl_counter + 1;
		end
	end

	reg [31:0] s_counter = 0;

	always @(posedge clk) begin
		if (s_valid && s_ready && s_last) begin
			s_counter <= s_counter + 1;
		end
	end

	always @(posedge clk) begin
		assert(
			s_ctl_counter == s_counter ||
			s_ctl_counter == s_counter + 1
		);
	end

	reg [31:0] m_counter = 0;

	always @(posedge clk) begin
		if (m_valid && m_ready && m_last) begin
			m_counter <= m_counter + 1;
		end
	end

	always @(posedge clk) begin
		cover(m_counter == 2 && m_counter == s_ctl_counter);
	end

`endif /* FORMAL */

endmodule
