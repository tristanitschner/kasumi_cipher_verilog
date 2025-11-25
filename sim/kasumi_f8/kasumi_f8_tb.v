// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

module kasumi_f8_tb;

parameter debug_trace      = 1;
parameter testcase         = 5;
parameter toggle_ctl       = 0;
parameter toggle_sending   = 0;
parameter toggle_reception = 0;

initial begin
    if (debug_trace) begin
        $dumpfile("kasumi_f8_tb.vcd");
        $dumpvars(0, kasumi_f8_tb);
    end
end

reg clk = 1;
initial forever #1 clk = !clk;

reg [31:0] m_packets = 0;

initial begin
	#10000;
	$display("Received %d packets", m_packets);
	$finish;
end

parameter bw = 8; // DO NOT CHANGE

localparam kw = 64/bw;
localparam l2_kw = $clog2(kw);

wire         s_ctl_valid;
wire         s_ctl_ready;
wire [31:0]  s_ctl_count;
wire [4:0]   s_ctl_bearer;
wire         s_ctl_direction;
wire [127:0] s_ctl_ck;

wire             s_valid;
wire             s_ready;
wire             s_last;
wire [63:0]      s_data;
wire [64/bw-1:0] s_keep;

wire             m_valid;
wire             m_ready;
wire             m_last;
wire [63:0]      m_data;
wire [64/bw-1:0] m_keep;

kasumi_f8 #(
	.bw (bw)
) kasumi_f8_inst (
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
	.s_data          (s_data),
	.s_keep          (s_keep),
	.m_valid         (m_valid),
	.m_ready         (m_ready),
	.m_last          (m_last),
	.m_data          (m_data),
	.m_keep          (m_keep)
);

always @(posedge clk) begin
	if (m_valid && m_ready && m_last) begin
		m_packets <= m_packets + 1;
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
		if (m_last) begin
			m_count <= 0;
		end else begin
			m_count <= m_count + 1;
		end
	end
end

function [kw-1:0] count2keep(input [l2_kw-1:0] count);
	integer i;
	begin
		if (count == 0) count2keep = {kw{1'b1}};
		else begin
			count2keep = 0;
			for (i = 0; i < count; i = i + 1) begin
				if (i < count) begin
					count2keep[kw-1-i] = 1'b1;
				end
			end
		end
	end
endfunction

//
// So this is not written anywhere, so I might put it here:
// How byte and keep handling works with the kasumi cipher:
// * any lengths are always padded to a multiple of 8 bits
// * the most significant bits are always the first bits
// * padding takes only place in multiples of eight bits in the output stream
// What this means in practice:
// * Smallest bw = 8
// * Byte is always a multiple of eight bits
// * If your application needs smaller bytes, have fun adjusting the core
//   yourself :)

generate if (testcase == 1) begin : gen_testcase_1

	// Key = 2BD6459F82C5B300952C49104881FF48
	// Count = 72A4F20F
	// Bearer = 0C
	// Direction = 1
	// Length = 798 bits
	// Plaintext:
	// 7EC61272743BF161 4726446A6C38CED1 66F6CA76EB543004 4286346CEF130F92
	// 922B03450D3A9975 E5BD2EA0EB55AD8E 1B199E3EC4316020 E9A1B285E7627953
	// 59B7BDFD39BEF4B2 484583D5AFE082AE E638BF5FD5A60619 3901A08F4AB41AAB
	// 9B134880

	assign s_ctl_ck = s_ctl_valid ? 128'h2bd6459f82c5b300952c49104881ff48 : 128'bx;
	assign s_ctl_count = s_ctl_valid ? 32'h72a4f20f : 32'bx;
	assign s_ctl_bearer = s_ctl_valid ? 5'h0C : 5'bx;
	assign s_ctl_direction = 1;

	localparam length_bits = 798;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = (bits_last / 8) + ((bits_last % 8) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;
	assign s_keep = s_last ? count2keep(bytes_last) : {kw{1'b1}};

	wire [63:0] plaintext [0:length_beats-1];

	assign plaintext[0]  = 64'h7ec61272743bf161;
	assign plaintext[1]  = 64'h4726446a6c38ced1;
	assign plaintext[2]  = 64'h66f6ca76eb543004;
	assign plaintext[3]  = 64'h4286346cef130f92;
	assign plaintext[4]  = 64'h922b03450d3a9975;
	assign plaintext[5]  = 64'he5bd2ea0eb55ad8e;
	assign plaintext[6]  = 64'h1b199e3ec4316020;
	assign plaintext[7]  = 64'he9a1b285e7627953;
	assign plaintext[8]  = 64'h59b7bdfd39bef4b2;
	assign plaintext[9]  = 64'h484583d5afe082ae;
	assign plaintext[10] = 64'he638bf5fd5a60619;
	assign plaintext[11] = 64'h3901a08f4ab41aab;
	assign plaintext[12] = 64'h9b134880 << 8*(bytes_last == 0 ? 0 : (8 - bytes_last));

	assign s_data = plaintext[s_count];

	// enc/dec data
	// D1E2DE70EEF86C69
	// 64FB542BC2D460AA
	// BFAA10A4A093262B
	// 7D199E706FC2D489
	// 1553296910F3A973
	// 012682E41C4E2B02
	// BE2017B7253BBF93
	// 09DE5819CB42E819
	// 56F4C99BC9765CAF
	// 53B1D0BB8279826A
	// DBBC5522E915C120
	// A618A5A7F5E89708
	// 9339650F

	wire [63:0] ciphertext[0:length_beats-1];

	assign ciphertext[0]  = 64'hd1e2de70eef86c69;
	assign ciphertext[1]  = 64'h64fb542bc2d460aa;
	assign ciphertext[2]  = 64'hbfaa10a4a093262b;
	assign ciphertext[3]  = 64'h7d199e706fc2d489;
	assign ciphertext[4]  = 64'h1553296910f3a973;
	assign ciphertext[5]  = 64'h012682e41c4e2b02;
	assign ciphertext[6]  = 64'hbe2017b7253bbf93;
	assign ciphertext[7]  = 64'h09de5819cb42e819;
	assign ciphertext[8]  = 64'h56f4c99bc9765caf;
	assign ciphertext[9]  = 64'h53b1d0bb8279826a;
	assign ciphertext[10] = 64'hdbbc5522e915c120;
	assign ciphertext[11] = 64'ha618a5a7f5e89708;
	assign ciphertext[12] = 64'h9339650f << 8*(bytes_last == 0 ? 0 : (8 - bytes_last));;

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_data == ciphertext[m_count]);
		end
	end

end endgenerate

generate if (testcase == 2) begin : gen_testcase_2

	// Key = EFA8B2229E720C2A7C36EA55E9605695
	// Count = E28BCF7B
	// Bearer = 18
	// Direction = 0
	// Length = 510 bits
	// Plaintext:
	// 10111231E060253A 43FD3F57E37607AB 2827B599B6B1BBDA 37A8ABCC5A8C550D
	// 1BFB2F494624FB50 367FA36CE3BC68F1 1CF93B1510376B02 130F812A9FA169D8

	assign s_ctl_ck = s_ctl_valid ? 128'hefa8b2229e720c2a7c36ea55e9605695 : 128'bx;
	assign s_ctl_count = s_ctl_valid ? 32'he28bcf7b : 32'bx;
	assign s_ctl_bearer = s_ctl_valid ? 5'h18 : 5'bx;
	assign s_ctl_direction = 0;

	localparam length_bits = 510;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = (bits_last / 8) + ((bits_last % 8) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;
	assign s_keep = s_last ? count2keep(bytes_last) : {kw{1'b1}};

	wire [63:0] plaintext [0:length_beats-1];

	assign plaintext[0] = 64'h10111231e060253a;
	assign plaintext[1] = 64'h43fd3f57e37607ab;
	assign plaintext[2] = 64'h2827b599b6b1bbda;
	assign plaintext[3] = 64'h37a8abcc5a8c550d;
	assign plaintext[4] = 64'h1bfb2f494624fb50;
	assign plaintext[5] = 64'h367fa36ce3bc68f1;
	assign plaintext[6] = 64'h1cf93b1510376b02;
	assign plaintext[7] = 64'h130f812a9fa169d8;

	assign s_data = plaintext[s_count];

	// enc/dec data
	// 3DEACC7C15821CAA
	// 89EECADE9B5BD361
	// 4BD0C8419D710385
	// DDBE5849EF1BAC5A
	// E8B14A5B0A674152
	// 1EB4E00BB9ECF3E9
	// F7CCB9CAE74152D7
	// F4E2A034B6EA00EC

	wire [63:0] ciphertext[0:length_beats-1];

	assign ciphertext[0] = 64'h3deacc7c15821caa;
	assign ciphertext[1] = 64'h89eecade9b5bd361;
	assign ciphertext[2] = 64'h4bd0c8419d710385;
	assign ciphertext[3] = 64'hddbe5849ef1bac5a;
	assign ciphertext[4] = 64'he8b14a5b0a674152;
	assign ciphertext[5] = 64'h1eb4e00bb9ecf3e9;
	assign ciphertext[6] = 64'hf7ccb9cae74152d7;
	assign ciphertext[7] = 64'hf4e2a034b6ea00ec;

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_data == ciphertext[m_count]);
		end
	end

end endgenerate

generate if (testcase == 3) begin : gen_testcase_3

	// Key = 5ACB1D644C0D51204EA5F1451010D852
	// Count = FA556B26
	// Bearer = 03
	// Direction = 1
	// Length = 120 bits
	// Plaintext: AD9C441F890B38C4 57A49D421407E8

	assign s_ctl_ck = s_ctl_valid ? 128'h5acb1d644c0d51204ea5f1451010d852 : 128'bx;
	assign s_ctl_count = s_ctl_valid ? 32'hfa556b26 : 32'bx;
	assign s_ctl_bearer = s_ctl_valid ? 5'h03 : 5'bx;
	assign s_ctl_direction = 1;

	localparam length_bits = 120;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = (bits_last / 8) + ((bits_last % 8) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;
	assign s_keep = s_last ? count2keep(bytes_last) : {kw{1'b1}};

	wire [63:0] plaintext [0:length_beats-1];

	assign plaintext[0] = 64'had9c441f890b38c4;
	assign plaintext[1] = 64'h57a49d421407e8 << 8*(bytes_last == 0 ? 0 : (8 - bytes_last));

	assign s_data = plaintext[s_count];

	// enc/dec data
	// 9BC92CA803C67B28
	// A11A4BEE5A0C25

	wire [63:0] ciphertext[0:length_beats-1];

	assign ciphertext[0] = 64'h9bc92ca803c67b28;
	assign ciphertext[1] = 64'ha11a4bee5a0c25 << 8*(bytes_last == 0 ? 0 : (8 - bytes_last));

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_data == ciphertext[m_count]);
		end
	end

end endgenerate

generate if (testcase == 4) begin : gen_testcase_4

	// Key = D3C5D592327FB11C4035C6680AF8C6D1
	// Count = 398A59B4
	// Bearer = 05
	// Direction = 1
	// Length = 253 bits
	// Plaintext: 981BA6824C1BFB1A B485472029B71D80 8CE33E2CC3C0B5FC 1F3DE8A6DC66B1F0

	assign s_ctl_ck = s_ctl_valid ? 128'hd3c5d592327fb11c4035c6680af8c6d1 : 128'bx;
	assign s_ctl_count = s_ctl_valid ? 32'h398a59b4 : 32'bx;
	assign s_ctl_bearer = s_ctl_valid ? 5'h05 : 5'bx;
	assign s_ctl_direction = 1;

	localparam length_bits = 253;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = (bits_last / 8) + ((bits_last % 8) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;
	assign s_keep = s_last ? count2keep(bytes_last) : {kw{1'b1}};

	wire [63:0] plaintext [0:length_beats-1];

	assign plaintext[0] = 64'h981ba6824c1bfb1a;
	assign plaintext[1] = 64'hb485472029b71d80;
	assign plaintext[2] = 64'h8ce33e2cc3c0b5fc;
	assign plaintext[3] = 64'h1f3de8a6dc66b1f0;

	assign s_data = plaintext[s_count];

	// enc/dec data
	// 5BB9431BB1E98BD1
	// 1B93DB7C3D451365
	// 59BB86A295AA204E
	// CBEBF6F7A5101512

	wire [63:0] ciphertext[0:length_beats-1];

	assign ciphertext[0] = 64'h5bb9431bb1e98bd1;
	assign ciphertext[1] = 64'h1b93db7c3d451365;
	assign ciphertext[2] = 64'h59bb86a295aa204e;
	assign ciphertext[3] = 64'hcbebf6f7a5101512;

	always @(posedge clk) begin
		// TODO: fix m last case -> keep signal
		if (m_valid && !m_last) begin
			assert(m_data == ciphertext[m_count]);
		end
	end

end endgenerate

generate if (testcase == 5) begin : gen_testcase_5

	// Key = 6090EAE04C83706EECBF652BE8E36566
	// Count = 72A4F20F
	// Bearer = 09
	// Direction = 0
	// Length = 837 bits
	// Plaintext:
	// 40981BA6824C1BFB 4286B299783DAF44 2C099F7AB0F58D5C 8E46B104F08F01B4
	// 1AB485472029B71D 36BD1A3D90DC3A41 B46D51672AC4C966 3A2BE063DA4BC8D2
	// 808CE33E2CCCBFC6 34E1B259060876A0 FBB5A437EBCC8D31 C19E4454318745E3
	// 987645987A986F2C B0

	assign s_ctl_ck = s_ctl_valid ? 128'h6090eae04c83706eecbf652be8e36566 : 128'bx;
	assign s_ctl_count = s_ctl_valid ? 32'h72a4f20f : 32'bx;
	assign s_ctl_bearer = s_ctl_valid ? 5'h09 : 5'bx;
	assign s_ctl_direction = 0;

	localparam length_bits = 837;
	localparam bits_last = length_bits % 64;
	localparam bytes_last = (bits_last / 8) + ((bits_last % 8) ? 1 : 0);
	localparam length_beats = length_bits/64 + (|(bits_last) ? 1 : 0);

	assign s_last = s_count == length_beats-1;
	assign s_keep = s_last ? count2keep(bytes_last) : {kw{1'b1}};

	wire [63:0] plaintext [0:length_beats-1];

	assign plaintext[0]  = 64'h40981ba6824c1bfb;
	assign plaintext[1]  = 64'h4286b299783daf44;
	assign plaintext[2]  = 64'h2c099f7ab0f58d5c;
	assign plaintext[3]  = 64'h8e46b104f08f01b4;
	assign plaintext[4]  = 64'h1ab485472029b71d;
	assign plaintext[5]  = 64'h36bd1a3d90dc3a41;
	assign plaintext[6]  = 64'hb46d51672ac4c966;
	assign plaintext[7]  = 64'h3a2be063da4bc8d2;
	assign plaintext[8]  = 64'h808ce33e2cccbfc6;
	assign plaintext[9]  = 64'h34e1b259060876a0;
	assign plaintext[10] = 64'hfbb5a437ebcc8d31;
	assign plaintext[11] = 64'hc19e4454318745e3;
	assign plaintext[12] = 64'h987645987a986f2c;
	assign plaintext[13] = 64'hb0 << 8*(bytes_last == 0 ? 0 : (8 - bytes_last));

	assign s_data = plaintext[s_count];

	// enc/dec data
	// DDB364DD2AAEC24D
	// FF291957B78BAD06
	// 3AC579CD9041BABE
	// 89FD195C0578CB9F
	// DE4217566178D202
	// 40206D07CFA619EC
	// 059F63514459FC10
	// D42DC9934E56EBC0
	// CBC60D4D2DF17477
	// 4CBDCD5DA4A35031
	// 7A7F12E1949471F8
	// A295F272E68FC071
	// 59B07D8E2D26E459
	// 9E

	wire [63:0] ciphertext[0:length_beats-1];

	assign ciphertext[0]  = 64'hddb364dd2aaec24d;
	assign ciphertext[1]  = 64'hff291957b78bad06;
	assign ciphertext[2]  = 64'h3ac579cd9041babe;
	assign ciphertext[3]  = 64'h89fd195c0578cb9f;
	assign ciphertext[4]  = 64'hde4217566178d202;
	assign ciphertext[5]  = 64'h40206d07cfa619ec;
	assign ciphertext[6]  = 64'h059f63514459fc10;
	assign ciphertext[7]  = 64'hd42dc9934e56ebc0;
	assign ciphertext[8]  = 64'hcbc60d4d2df17477;
	assign ciphertext[9]  = 64'h4cbdcd5da4a35031;
	assign ciphertext[10] = 64'h7a7f12e1949471f8;
	assign ciphertext[11] = 64'ha295f272e68fc071;
	assign ciphertext[12] = 64'h59b07d8e2d26e459;
	assign ciphertext[13] = 64'h9e << 8*(bytes_last == 0 ? 0 : (8 - bytes_last));

	always @(posedge clk) begin
		if (m_valid) begin
			assert(m_data == ciphertext[m_count]);
		end
	end

end endgenerate

endmodule
