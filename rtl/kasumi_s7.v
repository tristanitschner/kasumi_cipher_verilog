// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2025 Tristan Itschner
`default_nettype none
`timescale 1 ns / 1 ps

module kasumi_s7 (
	input wire clk,

	input  wire [6:0] x,
	output wire [6:0] y
);

wire [6:0] lookup_table [0:127];

assign y = lookup_table[x];

// generated code below

assign lookup_table[0] = 7'd54;
assign lookup_table[1] = 7'd50;
assign lookup_table[2] = 7'd62;
assign lookup_table[3] = 7'd56;
assign lookup_table[4] = 7'd22;
assign lookup_table[5] = 7'd34;
assign lookup_table[6] = 7'd94;
assign lookup_table[7] = 7'd96;
assign lookup_table[8] = 7'd38;
assign lookup_table[9] = 7'd6;
assign lookup_table[10] = 7'd63;
assign lookup_table[11] = 7'd93;
assign lookup_table[12] = 7'd2;
assign lookup_table[13] = 7'd18;
assign lookup_table[14] = 7'd123;
assign lookup_table[15] = 7'd33;
assign lookup_table[16] = 7'd55;
assign lookup_table[17] = 7'd113;
assign lookup_table[18] = 7'd39;
assign lookup_table[19] = 7'd114;
assign lookup_table[20] = 7'd21;
assign lookup_table[21] = 7'd67;
assign lookup_table[22] = 7'd65;
assign lookup_table[23] = 7'd12;
assign lookup_table[24] = 7'd47;
assign lookup_table[25] = 7'd73;
assign lookup_table[26] = 7'd46;
assign lookup_table[27] = 7'd27;
assign lookup_table[28] = 7'd25;
assign lookup_table[29] = 7'd111;
assign lookup_table[30] = 7'd124;
assign lookup_table[31] = 7'd81;
assign lookup_table[32] = 7'd53;
assign lookup_table[33] = 7'd9;
assign lookup_table[34] = 7'd121;
assign lookup_table[35] = 7'd79;
assign lookup_table[36] = 7'd52;
assign lookup_table[37] = 7'd60;
assign lookup_table[38] = 7'd58;
assign lookup_table[39] = 7'd48;
assign lookup_table[40] = 7'd101;
assign lookup_table[41] = 7'd127;
assign lookup_table[42] = 7'd40;
assign lookup_table[43] = 7'd120;
assign lookup_table[44] = 7'd104;
assign lookup_table[45] = 7'd70;
assign lookup_table[46] = 7'd71;
assign lookup_table[47] = 7'd43;
assign lookup_table[48] = 7'd20;
assign lookup_table[49] = 7'd122;
assign lookup_table[50] = 7'd72;
assign lookup_table[51] = 7'd61;
assign lookup_table[52] = 7'd23;
assign lookup_table[53] = 7'd109;
assign lookup_table[54] = 7'd13;
assign lookup_table[55] = 7'd100;
assign lookup_table[56] = 7'd77;
assign lookup_table[57] = 7'd1;
assign lookup_table[58] = 7'd16;
assign lookup_table[59] = 7'd7;
assign lookup_table[60] = 7'd82;
assign lookup_table[61] = 7'd10;
assign lookup_table[62] = 7'd105;
assign lookup_table[63] = 7'd98;
assign lookup_table[64] = 7'd117;
assign lookup_table[65] = 7'd116;
assign lookup_table[66] = 7'd76;
assign lookup_table[67] = 7'd11;
assign lookup_table[68] = 7'd89;
assign lookup_table[69] = 7'd106;
assign lookup_table[70] = 7'd0;
assign lookup_table[71] = 7'd125;
assign lookup_table[72] = 7'd118;
assign lookup_table[73] = 7'd99;
assign lookup_table[74] = 7'd86;
assign lookup_table[75] = 7'd69;
assign lookup_table[76] = 7'd30;
assign lookup_table[77] = 7'd57;
assign lookup_table[78] = 7'd126;
assign lookup_table[79] = 7'd87;
assign lookup_table[80] = 7'd112;
assign lookup_table[81] = 7'd51;
assign lookup_table[82] = 7'd17;
assign lookup_table[83] = 7'd5;
assign lookup_table[84] = 7'd95;
assign lookup_table[85] = 7'd14;
assign lookup_table[86] = 7'd90;
assign lookup_table[87] = 7'd84;
assign lookup_table[88] = 7'd91;
assign lookup_table[89] = 7'd8;
assign lookup_table[90] = 7'd35;
assign lookup_table[91] = 7'd103;
assign lookup_table[92] = 7'd32;
assign lookup_table[93] = 7'd97;
assign lookup_table[94] = 7'd28;
assign lookup_table[95] = 7'd66;
assign lookup_table[96] = 7'd102;
assign lookup_table[97] = 7'd31;
assign lookup_table[98] = 7'd26;
assign lookup_table[99] = 7'd45;
assign lookup_table[100] = 7'd75;
assign lookup_table[101] = 7'd4;
assign lookup_table[102] = 7'd85;
assign lookup_table[103] = 7'd92;
assign lookup_table[104] = 7'd37;
assign lookup_table[105] = 7'd74;
assign lookup_table[106] = 7'd80;
assign lookup_table[107] = 7'd49;
assign lookup_table[108] = 7'd68;
assign lookup_table[109] = 7'd29;
assign lookup_table[110] = 7'd115;
assign lookup_table[111] = 7'd44;
assign lookup_table[112] = 7'd64;
assign lookup_table[113] = 7'd107;
assign lookup_table[114] = 7'd108;
assign lookup_table[115] = 7'd24;
assign lookup_table[116] = 7'd110;
assign lookup_table[117] = 7'd83;
assign lookup_table[118] = 7'd36;
assign lookup_table[119] = 7'd78;
assign lookup_table[120] = 7'd42;
assign lookup_table[121] = 7'd19;
assign lookup_table[122] = 7'd15;
assign lookup_table[123] = 7'd41;
assign lookup_table[124] = 7'd88;
assign lookup_table[125] = 7'd119;
assign lookup_table[126] = 7'd59;
assign lookup_table[127] = 7'd3;

endmodule
