// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

module kasumi_iter_tb;

parameter debug_trace      = 1;
parameter testcase         = 4;
parameter toggle_sending   = 1;
parameter toggle_reception = 1;

initial begin
    if (debug_trace) begin
        $dumpfile("kasumi_iter_tb.vcd");
        $dumpvars(0, kasumi_iter_tb);
    end
end

reg clk = 1;
initial forever #1 clk = !clk;

initial begin
	#10000;
	$finish;
end

wire         s_valid;
wire         s_ready;
wire [63:0]  s_data;
wire [127:0] s_key;

wire         m_valid;
wire         m_ready;
wire [63:0]  m_data;

kasumi_iter kasumi_inst (
	.clk (clk),

	.s_valid (s_valid),
	.s_ready (s_ready),
	.s_data  (s_data),
	.s_key   (s_key),

	.m_valid (m_valid),
	.m_ready (m_ready),
	.m_data  (m_data)
);

reg r_s_valid = 0;
always @(posedge clk) begin
	r_s_valid <= $random;
end

wire i_valid = toggle_sending ? r_s_valid : 1;

reg r_m_ready = 0;
always @(posedge clk) begin
	r_m_ready <= $random;
end

assign m_ready = toggle_reception ? r_m_ready : 1;

wire s_fire = s_valid && s_ready;
wire m_fire = m_valid && m_ready;

generate if (testcase == 1) begin : gen_testcase_1

	// Key: 2B D6 45 9F 82 C5 B3 00 95 2C 49 10 48 81 FF 48
	// input: EA 02 47 14 AD 5C 4D 84
	// output: DF 1F 9B 25 1C 0B F4 5F

	assign s_data = 64'hea024714ad5c4d84;
	assign s_key  = 128'h2bd6459f82c5b300952c49104881ff48;

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_data == 64'hdf1f9b251c0bf45f);
		end
	end

	assign s_valid = i_valid;

end endgenerate

generate if (testcase == 2) begin : gen_testcase_2

	// Key: 8C E3 3E 2C C3 C0 B5 FC 1F 3D E8 A6 DC 66 B1 F3
	// input: D3 C5 D5 92 32 7F B1 1C
	// output: DE 55 19 88 CE B2 F9 B7

	assign s_data = 64'hd3c5d592327fb11c;
	assign s_key  = 128'h8ce33e2cc3c0b5fc1f3de8a6dc66b1f3;

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_data == 64'hde551988ceb2f9b7);
		end
	end

	assign s_valid = i_valid;

end endgenerate

generate if (testcase == 3) begin : gen_testcase_3

	// Key: 40 35 C6 68 0A F8 C6 D1 A8 FF 86 67 B1 71 40 13
	// input: 62 A5 40 98 1B A6 F9 B7
	// output: 45 92 B0 E7 86 90 F7 1B

	assign s_data = 64'h62a540981ba6f9b7;
	assign s_key  = 128'h4035c6680af8c6d1a8ff8667b1714013;

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_data == 64'h4592b0e78690f71b);
		end
	end

	assign s_valid = i_valid;

end endgenerate

generate if (testcase == 4) begin : gen_testcase_4

	// Iterated test for full S-box coverage
	// Key = 3A 3B 39 B5 C3 F2 37 6D 69 F7 D5 46 E5 F8 5D 43
	// Input = CA 49 C1 C7 57 71 AB 0B
	// After 50 repeated encryptions
	// Output = 73 8B AD 4C 4A 69 08 02

	wire [63:0] s_start = 64'hca49c1c75771ab0b;
	wire [63:0] m_end = 64'h738bad4c4a690802;

	assign s_key = 128'h3a3b39b5c3f2376d69f7d546e5f85d43;

	reg [31:0] s_count = 0;

	always @(posedge clk) begin
		if (s_valid && s_ready) begin
			s_count <= s_count + 1;
		end
	end

	reg [63:0] r_temp = 0;
	reg r_valid = 0;
	always @(posedge clk) begin
		if (m_valid && m_ready) begin
			r_temp <= m_data;
		end
	end

	always @(posedge clk) begin
		if (m_valid && m_ready) begin
			r_valid <= 1;
		end
		if (s_valid && s_ready) begin
			r_valid <= 0;
		end
	end


	reg r_init = 1;
	always @(posedge clk) begin
		if (s_valid && s_ready) begin
			r_init <= 0;
		end
	end

	assign s_data = r_init ? s_start : r_valid ? r_temp : m_data;
	assign s_valid = r_init || r_valid;

	always @(posedge clk) begin
		if (m_valid && s_count == 50) begin
			assert(m_data == m_end);
		end
	end

end endgenerate

endmodule
