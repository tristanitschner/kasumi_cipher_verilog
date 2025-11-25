// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

module kasumi_f9_tb;

// TODO:
// * something is broken with handshaking (core getting stuck)

parameter debug_trace      = 1;
parameter testcase         = 4;
parameter toggle_ctl       = 0;
parameter toggle_sending   = 0;
parameter toggle_reception = 0;

initial begin
    if (debug_trace) begin
        $dumpfile("kasumi_f9_tb.vcd");
        $dumpvars(0, kasumi_f9_tb);
    end
end

reg clk = 1;
initial forever #1 clk = !clk;

reg [31:0] macs_received = 0;

initial begin
	#10000;
	$display("Received %d MACs", macs_received);
	$finish;
end

parameter bw = 1;

localparam kw = 64/bw;

wire         s_ctl_valid;
wire         s_ctl_ready;
wire [31:0]  s_ctl_count;
wire [31:0]  s_ctl_fresh;
wire         s_ctl_direction;
wire [127:0] s_ctl_ik;

wire             s_valid;
wire             s_ready;
wire             s_last;
wire [63:0]      s_data;
wire [64/bw-1:0] s_keep;

wire        m_valid;
wire        m_ready;
wire [31:0] m_mac;

kasumi_f9 #(
	.bw (bw)
) kasumi_f9_inst (
	.clk             (clk),
	.s_ctl_valid     (s_ctl_valid),
	.s_ctl_ready     (s_ctl_ready),
	.s_ctl_count     (s_ctl_count),
	.s_ctl_fresh     (s_ctl_fresh),
	.s_ctl_direction (s_ctl_direction),
	.s_ctl_ik        (s_ctl_ik),
	.s_valid         (s_valid),
	.s_ready         (s_ready),
	.s_last          (s_last),
	.s_data          (s_data),
	.s_keep          (s_keep),
	.m_valid         (m_valid),
	.m_ready         (m_ready),
	.m_mac           (m_mac)
);

always @(posedge clk) begin
	if (m_valid && m_ready) begin
		macs_received <= macs_received + 1;
	end
end

reg r_s_ctl_valid = 1;
reg r_s_valid     = 1;
reg r_m_ready     = 1;

always @(posedge clk) begin
	{r_s_ctl_valid, r_s_valid, r_m_ready} <= $random;
end

assign s_ctl_valid = toggle_ctl       ? r_s_ctl_valid : 1;
assign s_valid     = toggle_sending   ? r_s_valid     : 1;
assign m_ready     = toggle_reception ? r_m_ready     : 1;

reg [31:0] s_count = 0;
always @(posedge clk) begin
	if (s_valid && s_ready) begin
		if (s_last) begin
			s_count <= 0;
		end else begin
			s_count <= s_count + 1;
		end
	end
end

reg [31:0] m_count = 0;
always @(posedge clk) begin
	if (m_valid && m_ready) begin
		m_count <= m_count + 1;
	end
end

function [kw-1:0] count2keep(input [kw-1:0] x);
	integer i;
	begin
		if (x == 0) begin
			count2keep = -1;
		end else begin
			count2keep = 0;
			for (i = 0; i < kw; i = i + 1) begin
				if (i < x) begin
					count2keep[kw-1-i] = 1;
				end
			end
		end
	end
endfunction

generate if (testcase == 1) begin : gen_testcase_1

	// Key = 2BD6459F82C5B300952C49104881FF48
	// Count = 38A6F056
	// Fresh = 05D2EC49
	// Direction = 0
	// Length = 189 bits
	// Message: 6B227737296F393C 8079353EDC87E2E8 05D2EC49A4F2D8E0
	
	assign s_ctl_ik = 128'h2bd6459f82c5b300952c49104881ff48;
	assign s_ctl_count = 32'h38a6f056;
	assign s_ctl_fresh = 32'h05d2ec49;
	assign s_ctl_direction = 0;

	localparam length_bits = 189;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = bits_last/bw + ((bits_last % bw) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;

	assign s_keep = s_last ? count2keep(bytes_last) : -1;

	wire [63:0] message [0:length_beats-1];

	assign message[0] = 64'h6b227737296f393c;
	assign message[1] = 64'h8079353edc87e2e8;
	assign message[2] = 64'h05d2ec49a4f2d8e0;

	assign s_data = message[s_count];

	// MAC-I: F63BD72C

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_mac == 32'hf63bd72c);
		end
	end

end endgenerate

generate if (testcase == 2) begin : gen_testcase_2

	// Key = D42F682428201CAFCD9F97945E6DE7B7
	// Count = 3EDC87E2
	// Fresh = A4F2D8E2
	// Direction = 1
	// Length = 254 bits
	// Message:: B5924384328A4AE0 0B737109F8B6C8DD 2B4DB63DD533981C EB19AAD52A5B2BC0

	assign s_ctl_ik = 128'hd42f682428201cafcd9f97945e6de7b7;
	assign s_ctl_count = 32'h3edc87e2;
	assign s_ctl_fresh = 32'ha4f2d8e2;
	assign s_ctl_direction = 1;

	localparam length_bits = 254;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = bits_last/bw + ((bits_last % bw) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;

	assign s_keep = s_last ? count2keep(bytes_last) : -1;

	wire [63:0] message [0:length_beats-1];

	assign message[0] = 64'hb5924384328a4ae0;
	assign message[1] = 64'h0b737109f8b6c8dd;
	assign message[2] = 64'h2b4db63dd533981c;
	assign message[3] = 64'heb19aad52a5b2bc0;

	assign s_data = message[s_count];

	// MAC-I: A9DAF1FF

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_mac == 32'hA9DAF1FF);
		end
	end

end endgenerate

generate if (testcase == 3) begin : gen_testcase_3

	// Key = FDB9CFDF28936CC483A31869D81B8FAB
	// Count = 36AF6144
	// Fresh = 9838F03A
	// Direction = 1
	// Length = 319 bits
	// Message::
	// 5932BC0ACE2B0ABA 33D8AC188AC54F34 6FAD10BF9DEE2920 B43BD0C53A915CB7
	// DF6CAA72053ABFF2

	assign s_ctl_ik = 128'hfdb9cfdf28936cc483a31869d81b8fab;
	assign s_ctl_count = 32'h36af6144;
	assign s_ctl_fresh = 32'h9838f03a;
	assign s_ctl_direction = 1;

	localparam length_bits = 319;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = bits_last/bw + ((bits_last % bw) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;

	assign s_keep = s_last ? count2keep(bytes_last) : -1;

	wire [63:0] message [0:length_beats-1];

	assign message[0] = 64'h5932bc0ace2b0aba;
	assign message[1] = 64'h33d8ac188ac54f34;
	assign message[2] = 64'h6fad10bf9dee2920;
	assign message[3] = 64'hb43bd0c53a915cb7;
	assign message[4] = 64'hdf6caa72053abff2;

	assign s_data = message[s_count];

	// MAC-I: 1537D316

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_mac == 32'h1537d316);
		end
	end

end endgenerate

generate if (testcase == 4) begin : gen_testcase_4

	// Key = C736C6AAB22BFFF91E2698D2E22AD57E
	// Count = 14793E41
	// Fresh = 0397E8FD
	// Direction = 1
	// Length = 384 bits
	// Message::
	// D0A7D463DF9FB2B2 78833FA02E235AA1 72BD970C1473E129 07FB648B6599AAA0
	// B24A038665422B20 A499276A50427009

	assign s_ctl_ik = 128'hc736c6aab22bfff91e2698d2e22ad57e;
	assign s_ctl_count = 32'h14793e41;
	assign s_ctl_fresh = 32'h0397e8fd;
	assign s_ctl_direction = 1;

	localparam length_bits = 384;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = bits_last/bw + ((bits_last % bw) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;

	assign s_keep = s_last ? count2keep(bytes_last) : -1;

	wire [63:0] message [0:length_beats-1];

	assign message[0] = 64'hd0a7d463df9fb2b2;
	assign message[1] = 64'h78833fa02e235aa1;
	assign message[2] = 64'h72bd970c1473e129;
	assign message[3] = 64'h07fb648b6599aaa0;
	assign message[4] = 64'hb24a038665422b20;
	assign message[5] = 64'ha499276a50427009;

	assign s_data = message[s_count];

	// MAC-I: DD7DFADD

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_mac == 32'hdd7dfadd);
		end
	end

end endgenerate

generate if (testcase == 5) begin : gen_testcase_5

	// Key = F4EBEC69E73EAF2EB2CF6AF4B3120FFD
	// Count = 296F393C
	// Fresh = 6B227737
	// Direction = 1
	// Length = 1000 bits
	// Message::
	// 10BFFF839E0C7165 8DBB2D1707E14572 4F41C16F48BF403C 3B18E38FD5D1663B
	// 6F6D900193E3CEA8 BB4F1B4F5BE82203 2232A78D7D75238D 5E6DAECD3B4322CF
	// 59BC7EA84AB18811 B5BFB7BC553F4FE4 4478CE287A148799 90D18D12CA79D2C8
	// 55149021CD5CE8CA 0371CA04FCCE143E 3D7CFEE94585B588 5CAC46068B

	assign s_ctl_ik = 128'hf4ebec69e73eaf2eb2cf6af4b3120ffd;
	assign s_ctl_count = 32'h296f393c;
	assign s_ctl_fresh = 32'h6b227737;
	assign s_ctl_direction = 1;

	localparam length_bits = 1000;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = bits_last/bw + ((bits_last % bw) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;

	assign s_keep = s_last ? count2keep(bytes_last) : -1;

	wire [63:0] message [0:length_beats-1];

	assign message[0]  = 64'h10bfff839e0c7165;
	assign message[1]  = 64'h8dbb2d1707e14572;
	assign message[2]  = 64'h4f41c16f48bf403c;
	assign message[3]  = 64'h3b18e38fd5d1663b;
	assign message[4]  = 64'h6f6d900193e3cea8;
	assign message[5]  = 64'hbb4f1b4f5be82203;
	assign message[6]  = 64'h2232a78d7d75238d;
	assign message[7]  = 64'h5e6daecd3b4322cf;
	assign message[8]  = 64'h59bc7ea84ab18811;
	assign message[9]  = 64'hb5bfb7bc553f4fe4;
	assign message[10] = 64'h4478ce287a148799;
	assign message[11] = 64'h90d18d12ca79d2c8;
	assign message[12] = 64'h55149021cd5ce8ca;
	assign message[13] = 64'h0371ca04fcce143e;
	assign message[14] = 64'h3d7cfee94585b588;
	assign message[15] = 64'h5cac46068b << bw*(kw - bytes_last);

	assign s_data = message[s_count];

	// MAC-I: C383839D

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_mac == 32'hc383839d);
		end
	end

end endgenerate

endmodule
