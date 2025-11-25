// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

module kasumi_keyschedule (
	input wire clk,

	input wire [2:0] n,

	input  wire [127:0] key,
	output wire [31:0]  kl,
	output wire [47:0]  ko,
	output wire [47:0]  ki
);

function [15:0] rol(input [15:0] x, input [3:0] shamt);
	begin
		rol = x << shamt | x >> (16-shamt);
	end
endfunction

genvar gi;

wire [15:0] k [0:7];

generate for (gi = 0; gi < 8; gi = gi + 1) begin
	assign k[gi] = key[16*(8-gi)-1-:16]; // big endian
end endgenerate

wire [15:0] c [0:7];

assign c[0] = 16'h0123;
assign c[1] = 16'h4567;
assign c[2] = 16'h89ab;
assign c[3] = 16'hcdef;
assign c[4] = 16'hfedc;
assign c[5] = 16'hba98;
assign c[6] = 16'h7654;
assign c[7] = 16'h3210;

wire [15:0] k_prime [0:7];

generate for (gi = 0; gi < 8; gi = gi + 1) begin
	assign k_prime[gi] = k[gi] ^ c[gi];
end endgenerate

assign kl = {rol(k[n],1), k_prime[(n+2)%8]};
assign ko = {rol(k[(n+1)%8],5), rol(k[(n+5)%8],8), rol(k[(n+6)%8],13)};
assign ki = {k_prime[(n+4)%8], k_prime[(n+3)%8], k_prime[(n+7)%8]};

endmodule
