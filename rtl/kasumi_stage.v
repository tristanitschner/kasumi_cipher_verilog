// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

// Note: key schedule and round calculation are spread across two stages to
// improve timing

module kasumi_stage (
	input wire clk,

	input wire [2:0] n,

	input  wire         s_valid,
	output wire         s_ready,
	input  wire [63:0]  s_data,
	input  wire [127:0] s_key,

	output wire         m_valid,
	input  wire         m_ready,
	output wire [63:0]  m_data,
	output wire [127:0] m_key
);

wire [31:0] l_in, r_in;

wire [47:0] ko;
wire [47:0] ki;
wire [31:0] kl;

kasumi_keyschedule kasumi_keyschedule_inst (
	.clk (clk),
	.n   (n),
	.key (s_key),
	.kl  (kl),
	.ko  (ko),
	.ki  (ki)
);

reg [47:0] r_ko;
reg [47:0] r_ki;
reg [31:0] r_kl;

wire [31:0] f;

/******************************************************************************/
// the stage

reg r_valid = 0;

wire s_fire = s_valid && s_ready;
wire m_fire = m_valid && m_ready;

always @(posedge clk) begin
	case ({s_fire, m_fire})
		2'b10: r_valid <= 1;
		2'b01: r_valid <= 0;
	endcase
end

assign s_ready = !r_valid || (r_valid && m_fire);
assign m_valid = r_valid;

reg [63:0]  r_data;
reg [127:0] r_key;
reg [2:0]   r_n;

always @(posedge clk) begin
	if (s_fire) begin
		r_data <= s_data;
		r_key  <= s_key;
		r_ko   <= ko;
		r_ki   <= ki;
		r_kl   <= kl;
		r_n    <= n;
	end
end

assign {l_in, r_in} = r_data;

kasumi_f kasumi_f_inst (
	.clk (clk),
	.n   (r_n),
	.x   (l_in),
	.ko  (r_ko),
	.ki  (r_ki),
	.kl  (r_kl),
	.y   (f)
);

wire [31:0] l_out, r_out;

assign r_out = l_in;
assign l_out = r_in ^ f;

wire [63:0] c_data;

assign c_data = {l_out, r_out};

assign m_data = c_data;
assign m_key  = r_key;

endmodule
