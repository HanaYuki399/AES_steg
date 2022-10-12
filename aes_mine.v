




module aes1281(clk, state, key, out);
    input          clk;
    input  [127:0] state, key;
    output [127:0] out;
    reg    [127:0] s0, k0;
    wire   [127:0] s1, s2, s3, s4, s5, s6, s7, s8, s9,
                   k1, k2, k3, k4, k5, k6, k7, k8, k9,
                   k0b, k1b, k2b, k3b, k4b, k5b, k6b, k7b, k8b, k9b;

    always @ (posedge clk)
      begin
        s0 <= state ^ key;
        k0 <= key;
      end

    expand_key_128
        a1 (clk, k0, k1, k0b, 8'h1),
        a2 (clk, k1, k2, k1b, 8'h2),
        a3 (clk, k2, k3, k2b, 8'h4),
        a4 (clk, k3, k4, k3b, 8'h8),
        a5 (clk, k4, k5, k4b, 8'h10),
        a6 (clk, k5, k6, k5b, 8'h20),
        a7 (clk, k6, k7, k6b, 8'h40),
        a8 (clk, k7, k8, k7b, 8'h80),
        a9 (clk, k8, k9, k8b, 8'h1b),
       a10 (clk, k9,   , k9b, 8'h36);

    one_round
        r1 (clk, s0, k0b, s1),
        r2 (clk, s1, k1b, s2),
        r3 (clk, s2, k2b, s3),
        r4 (clk, s3, k3b, s4),
        r5 (clk, s4, k4b, s5),
        r6 (clk, s5, k5b, s6),
        r7 (clk, s6, k6b, s7),
        r8 (clk, s7, k7b, s8),
        r9 (clk, s8, k8b, s9);

    final_round
        rf (clk, s9, k9b, out);
endmodule

module expand_key_128(clk, in, out_1, out_2, rcon);
    input              clk;
    input      [127:0] in;
    input      [7:0]   rcon;
    output reg [127:0] out_1;
    output     [127:0] out_2;
    wire       [31:0]  k0, k1, k2, k3,
                       v0, v1, v2, v3;
    reg        [31:0]  k0a, k1a, k2a, k3a;
    wire       [31:0]  k0b, k1b, k2b, k3b, k4a;

    assign {k0, k1, k2, k3} = in;
    
    assign v0 = {k0[31:24] ^ rcon, k0[23:0]};
    assign v1 = v0 ^ k1;
    assign v2 = v1 ^ k2;
    assign v3 = v2 ^ k3;

    always @ (posedge clk)
        {k0a, k1a, k2a, k3a} <= {v0, v1, v2, v3};

    S4
        S4_0 (clk, {k3[23:0], k3[31:24]}, k4a);

    assign k0b = k0a ^ k4a;
    assign k1b = k1a ^ k4a;
    assign k2b = k2a ^ k4a;
    assign k3b = k3a ^ k4a;

    always @ (posedge clk)
        out_1 <= {k0b, k1b, k2b, k3b};

    assign out_2 = {k0b, k1b, k2b, k3b};
endmodule



/* one AES round for every two clock cycles */
module one_round (clk, state_in, key, state_out);
    input              clk;
    input      [127:0] state_in, key;
    output reg [127:0] state_out;
    wire       [31:0]  s0,  s1,  s2,  s3,
                       z0,  z1,  z2,  z3,
                       p00, p01, p02, p03,
                       p10, p11, p12, p13,
                       p20, p21, p22, p23,
                       p30, p31, p32, p33,
                       k0,  k1,  k2,  k3;

    assign {k0, k1, k2, k3} = key;

    assign {s0, s1, s2, s3} = state_in;

    table_lookup
        t0 (clk, s0, p00, p01, p02, p03),
        t1 (clk, s1, p10, p11, p12, p13),
        t2 (clk, s2, p20, p21, p22, p23),
        t3 (clk, s3, p30, p31, p32, p33);

    assign z0 = p00 ^ p11 ^ p22 ^ p33 ^ k0;
    assign z1 = p03 ^ p10 ^ p21 ^ p32 ^ k1;
    assign z2 = p02 ^ p13 ^ p20 ^ p31 ^ k2;
    assign z3 = p01 ^ p12 ^ p23 ^ p30 ^ k3;

    always @ (posedge clk)
        state_out <= {z0, z1, z2, z3};
endmodule

/* AES final round for every two clock cycles */
module final_round (clk, state_in, key_in, state_out);
    input              clk;
    input      [127:0] state_in;
    input      [127:0] key_in;
    output reg [127:0] state_out;
    wire [31:0] s0,  s1,  s2,  s3,
                z0,  z1,  z2,  z3,
                k0,  k1,  k2,  k3;
    wire [7:0]  p00, p01, p02, p03,
                p10, p11, p12, p13,
                p20, p21, p22, p23,
                p30, p31, p32, p33;
    
    assign {k0, k1, k2, k3} = key_in;
    
    assign {s0, s1, s2, s3} = state_in;

    S4
        S4_1 (clk, s0, {p00, p01, p02, p03}),
        S4_2 (clk, s1, {p10, p11, p12, p13}),
        S4_3 (clk, s2, {p20, p21, p22, p23}),
        S4_4 (clk, s3, {p30, p31, p32, p33});

    assign z0 = {p00, p11, p22, p33} ^ k0;
    assign z1 = {p10, p21, p32, p03} ^ k1;
    assign z2 = {p20, p31, p02, p13} ^ k2;
    assign z3 = {p30, p01, p12, p23} ^ k3;

    always @ (posedge clk)
        state_out <= {z0, z1, z2, z3};
endmodule




/*http://cs-www.cs.yale.edu/homes/peralta/CircuitStuff/CMT.html*/
module S(
    input clk,
    input [7:0] in,
    output reg [7:0] out
    );
	
	wire[0:7] s, x;

	assign x = in;
	
	always @ (posedge clk)
        out <= s;
	
	wire [21:0] y;
	wire [67:0] t;
	wire [17:0] z;
	
	assign y[14] = x[3] ^ x[5];
	assign y[13] = x[0] ^ x[6];
	assign y[9] = x[0] ^ x[3];
	assign y[8] = x[0] ^ x[5];
	assign t[0] = x[1] ^ x[2];
	assign y[1] = t[0] ^ x[7];
	assign y[4] = y[1] ^ x[3];
	assign y[12] = y[13] ^ y[14];
	assign y[2] = y[1] ^ x[0];
	assign y[5] = y[1] ^ x[6];
	assign y[3] = y[5] ^ y[8];
	assign t[1] = x[4] ^ y[12];
	assign y[15] = t[1] ^ x[5];
	assign y[20] = t[1] ^ x[1];
	assign y[6] = y[15] ^ x[7];
	assign y[10] = y[15] ^ t[0];
	assign y[11] = y[20] ^ y[9];
	assign y[7] = x[7] ^ y[11];
	assign y[17] = y[10] ^ y[11];
	assign y[19] = y[10] ^ y[8];
	assign y[16] = t[0] ^ y[11];
	assign y[21] = y[13] ^ y[16];
	assign y[18] = x[0] ^ y[16];
	
	assign t[2] = y[12] & y[15];
	assign t[3] = y[3] & y[6];
	assign t[4] = t[3] ^ t[2];
	assign t[5] = y[4] & x[7];
	assign t[6] = t[5] ^ t[2]; 
	assign t[7] = y[13] & y[16];
	assign t[8] = y[5] & y[1];
	assign t[9] = t[8] ^ t[7];
	assign t[10] = y[2] & y[7];
	assign t[11] = t[10] ^ t[7];
	assign t[12] = y[9] & y[11];
	assign t[13] = y[14] & y[17];
	assign t[14] = t[13] ^ t[12];
	assign t[15] = y[8] & y[10];
	assign t[16] = t[15] ^ t[12];
	assign t[17] = t[4] ^ t[14];
	assign t[18] = t[6] ^ t[16];
	assign t[19] = t[9] ^ t[14];
	assign t[20] = t[11] ^ t[16];
	assign t[21] = t[17] ^ y[20];
	assign t[22] = t[18] ^ y[19];
	assign t[23] = t[19] ^ y[21];
	assign t[24] = t[20] ^ y[18];
	
	assign t[25] = t[21] ^ t[22];
	assign t[26] = t[21] & t[23];
	assign t[27] = t[24] ^ t[26];
	assign t[28] = t[25] & t[27]; 
	assign t[29] = t[28] ^ t[22];
	assign t[30] = t[23] ^ t[24];
	assign t[31] = t[22] ^ t[26];
	assign t[32] = t[31] & t[30];
	assign t[33] = t[32] ^ t[24];
	assign t[34] = t[23] ^ t[33];
	assign t[35] = t[27] ^ t[33];
	assign t[36] = t[24] & t[35]; 
	assign t[37] = t[36] ^ t[34];
	assign t[38] = t[27] ^ t[36];
	assign t[39] = t[29] & t[38];
	assign t[40] = t[25] ^ t[39];
	
	assign t[41] = t[40] ^ t[37];
	assign t[42] = t[29] ^ t[33];
	assign t[43] =  t[29] ^ t[40];
	assign t[44] =  t[33] ^ t[37];
	assign t[45] = t[42] ^ t[41];
	assign z[0] = t[44] & y[15];
	assign z[1] = t[37] & y[6];
	assign z[2] = t[33] & x[7];
	assign z[3] = t[43] & y[16];
	assign z[4] = t[40] & y[1];
	assign z[5] = t[29] & y[7];
	assign z[6] = t[42] & y[11];
	assign z[7] = t[45] & y[17];
	assign z[8] = t[41] & y[10];
	assign z[9] = t[44] & y[12];
	assign z[10] = t[37] & y[3];
	assign z[11] = t[33] & y[4];
	assign z[12] = t[43] & y[13];
	assign z[13] = t[40] & y[5];
	assign z[14] = t[29] & y[2];
	assign z[15] = t[42] & y[9];
	assign z[16] = t[45] & y[14];
	assign z[17] = t[41] & y[8];
	
	assign t[46] = z[15] ^ z[16];
	assign t[47] = z[10] ^ z[11];
	assign t[48] = z[5] ^ z[13];
	assign t[49] = z[9] ^ z[10];
	assign t[50] = z[2] ^ z[12];
	assign t[51] = z[2] ^ z[5];
	assign t[52] = z[7] ^ z[8];
	assign t[53] = z[0] ^ z[3];
	assign t[54] = z[6] ^ z[7];
	assign t[55] = z[16] ^ z[17];
	assign t[56] = z[12] ^ t[48];
	assign t[57] = t[50] ^ t[53];
	assign t[58] = z[4] ^ t[46];
	assign t[59] = z[3] ^ t[54];
	assign t[60] = t[46] ^ t[57];
	assign t[61] = z[14] ^ t[57];
	assign t[62] = t[52] ^ t[58];
	assign t[63] = t[49] ^ t[58];
	assign t[64] = z[4] ^ t[59];
	assign t[65] = t[61] ^ t[62];
	assign t[66] = z[1] ^ t[63];
	assign s[0] = t[59] ^ t[63];
	assign s[6] = ~t[56 ] ^ t[62]; 
	assign s[7] = ~t[48 ] ^ t[60]; 
	assign t[67] = t[64] ^ t[65];
	assign s[3] = t[53] ^ t[66];
	assign s[4] = t[51] ^ t[66];
	assign s[5] = t[47] ^ t[65];
	assign s[1] = ~t[64 ] ^ s[3]; 
	assign s[2] = ~t[55 ] ^ t[67]; 
  
endmodule 


module xS (clk, in, out); //this is sbox times 2 
    input clk;
    input [7:0] in;
    output [7:0] out;
    
    wire [7:0] out_2;
	
	S S_(
		.clk(clk),
		.in(in),
		.out(out_2)
	);
	
	wire dummy;
	
	assign {dummy, out} = out_2[7]? {out_2, 1'b0}^9'h11b : {out_2, 1'b0}; //Finite Field Multiplication: https://www.cs.uaf.edu/2013/spring/cs463/lecture/02_11_groups_fields.html
	
	
endmodule



module table_lookup (clk, state, p0, p1, p2, p3);
    input clk;
    input [31:0] state;
    output [31:0] p0, p1, p2, p3;
    wire [7:0] b0, b1, b2, b3;
    
    assign {b0, b1, b2, b3} = state;
    T
        t0 (clk, b0, {p0[23:0], p0[31:24]}),
        t1 (clk, b1, {p1[15:0], p1[31:16]}),
        t2 (clk, b2, {p2[7:0],  p2[31:8]} ),
        t3 (clk, b3, p3);
endmodule

/* substitue four bytes in a word */
module S4 (clk, in, out);
    input clk;
    input [31:0] in;
    output [31:0] out;
    
    S
        S_0 (clk, in[31:24], out[31:24]),
        S_1 (clk, in[23:16], out[23:16]),
        S_2 (clk, in[15:8],  out[15:8] ),
        S_3 (clk, in[7:0],   out[7:0]  );
endmodule

/* S_box, S_box, S_box*(x+1), S_box*x */
module T (clk, in, out);
    input         clk;
    input  [7:0]  in;
    output [31:0] out;
    
    S
        s0 (clk, in, out[31:24]);
    assign out[23:16] = out[31:24];
    xS
        s4 (clk, in, out[7:0]);
    assign out[15:8] = out[23:16] ^ out[7:0];
endmodule

/* S box */
module S_table (clk, in, out); //fuck BRAM; use combinational logic in simple binry mathematics with AND OR nad NOT gates. 
    input clk;
    input [7:0] in;   //in[7]=a; in[6]=b in[5]=c in[4]=d;
    output reg [7:0] out;
    reg [7:0] M0,M1,M2,M3,M4,M5,M6,M7,M8,M9,MA,MB,MC,MD,ME,MF;   
    

    always @ (posedge clk)
    begin   //column 00
    M0[7]<= (in[7] & in[5]) | (in[7] & !in[4]) | ( !in[7] & !in[6] & !in[5] & in[4]) | (in[5] & !in[4]);
    M0[6]<= (in[7] & !in[6]) | ( !in[7] & in[6] & in[5]) | (in[6] & in[5] & !in[4]) | ( !in[6] & !in[5]) | ( !in[5] & in[4]);
    M0[5]<= (in[7] & in[6] & !in[4]) | (in[7] & !in[6] & in[5]) | (in[7] & !in[5] & in[4]) | ( !in[7] & !in[6] & !in[4]);
    M0[4]<= (in[7] & in[6] & !in[5]) | ( !in[7] & in[6] & in[4]) | ( !in[7] & in[5] & !in[4]);
    M0[3]<= (in[7] & in[6] & in[5] & in[4]) | (in[7] & !in[5] & !in[4]) | ( !in[7] & !in[6] & !in[5] & in[4]) | (in[6] & !in[5] & !in[4]);
    M0[2]<= (in[7] & !in[6] & !in[5] & !in[4]) | (in[7] & in[5] & in[4]) | ( !in[7] & !in[6] & in[5]);
    M0[1]<= (in[7] & in[6] & !in[5] & !in[4]) | (in[7] & !in[6] & in[5] & in[4]) | ( !in[7] & !in[6] & !in[4]) | ( !in[7] & !in[5] & in[4]);
    M0[0]<= (in[7] & in[6] & in[5] & !in[4]) | (in[7] & !in[6] & in[5] & in[4]) | ( !in[7] & in[6] & !in[5]) | ( !in[7] & in[6] & in[4]) | ( !in[7] & !in[6] & !in[4]) | ( !in[6] & !in[5] & !in[4]);
    end

    always @ (posedge clk)
    begin   //column 01
    M1[7]<= ( !in[7] & in[6]) | ( !in[7] & in[5]) | (in[6] & in[5]) | ( !in[6] & in[4]);
    M1[6]<= (in[7] & in[6] & !in[4]) | ( !in[7] & in[6] & !in[5] & in[4]) | ( !in[7] & !in[6] & !in[4]) | ( !in[7] & in[5] & !in[4]) | ( !in[6] & in[5] & in[4]);
    M1[5]<= (in[7] & in[6]) | ( !in[7] & !in[6] & !in[4]) | (in[6] & in[5]) | (in[5] & !in[4]);
    M1[4]<= (in[7] & in[6] & !in[4]) | (in[7] & in[5] & !in[4]) | ( !in[7] & !in[6] & !in[4]) | (in[6] & !in[5] & in[4]);
    M1[3]<= (in[7] & in[6] & !in[5]) | (in[7] & !in[6] & in[5] & in[4]) | ( !in[7] & in[5] & !in[4]) | (in[6] & in[5] & !in[4]) | ( !in[6] & !in[5] & !in[4]);
    M1[2]<= (in[7] & in[6] & !in[5] & in[4]) | ( !in[7] & !in[6] & in[5]) | ( !in[7] & in[5] & !in[4]) | ( !in[6] & !in[5] & !in[4]);
    M1[1]<= (in[7] & in[6] & !in[5] & in[4]) | (in[7] & !in[6] & in[5] & !in[4]) | ( !in[7] & in[6] & in[5]) | ( !in[7] & in[6] & !in[4]) | ( !in[7] & !in[6] & in[4]);
    M1[0]<= (in[7] & !in[6] & !in[5] & in[4]) | ( !in[7] & in[6]) | ( !in[7] & in[5]) | (in[6] & in[5] & in[4]);
    end

    always @ (posedge clk)
    begin   //column 02
    M2[7]<= (in[7] & in[6] & in[4]) | ( !in[7] & !in[6] & !in[5] & in[4]) | ( !in[7] & in[5] & !in[4]) | (in[6] & in[5] & !in[4]);
    M2[6]<= ( !in[7] & in[6] & in[5] & in[4]) | ( !in[7] & !in[6] & !in[5]) | ( !in[6] & !in[5] & in[4]);
    M2[5]<= (in[7] & in[6] & !in[5]) | (in[7] & !in[6] & in[5]) | ( !in[7] & in[6] & !in[4]) | ( !in[7] & !in[5] & !in[4]) | ( !in[6] & in[5] & in[4]);
    M2[4]<= (in[7] & in[6] & !in[5] & in[4]) | (in[7] & !in[6] & in[5]) | (in[7] & in[5] & !in[4]) | ( !in[6] & !in[4]);
    M2[3]<= (in[7] & in[6] & in[5]) | (in[7] & in[5] & !in[4]) | ( !in[7] & in[6] & !in[4]) | ( !in[6] & !in[5] & in[4]);
    M2[2]<= (in[7] & in[6] & !in[5]) | (in[7] & !in[6] & in[4]) | ( !in[7] & !in[5] & !in[4]);
    M2[1]<= (in[7] & !in[6]) | ( !in[7] & in[5] & !in[4]) | ( !in[6] & in[5]) | ( !in[6] & !in[4]);
    M2[0]<= (in[7] & !in[5]) | (in[7] & in[4]) | ( !in[7] & !in[6]);
    end

    always @ (posedge clk)
    begin   //column 03
    M3[7]<= (in[7]&(!in[6])&(!in[5]))|((!in[7])&in[5]&in[4])|((!in[7])&in[6]&in[4])|((!in[7])&in[6]&in[5]);
    M3[6]<= ((!in[7])&in[6]&in[5]&(!in[4]))|((!in[6])&(!in[5]))|((!in[6])&in[4])|((!in[5])&in[4]);
    M3[5]<= (in[7]&(!in[6])&in[5]&in[4])|(in[7]&(!in[5])&(!in[4]))|(!in[7]&!in[6]&!in[5])|(!in[7]&in[5]&!in[4])|(in[6]&!in[5]&in[4]);
    M3[4]<= (!in[6]&!in[5]&in[4])|(in[6]&in[5]&(!in[4]))|(!in[7]&!in[5]&!in[4]);
    M3[3]<= (in[7]&!in[6])|(in[7]&in[5]&in[4])|(!in[7]&in[6])|(!in[7]&!in[5])|(!in[5]&!in[4]);
    M3[2]<= (in[7]&(!in[5]))|(in[7]&in[4])|(!in[7]&!in[6]&in[5]&!in[4])|(in[6]&in[4])|(!in[5]&in[4]);
    M3[1]<= (in[7]&in[6]&!in[5])|(!in[7]&in[5])|(!in[7]&!in[4])|(!in[6]&in[5]&!in[4]);
    M3[0]<= (!in[7]&!in[6]&!in[5])|(!in[7]&in[4])|(in[6]&in[5])|(in[5]&in[4]);
    end

    always @ (posedge clk)
    begin   //column 04
    M4[7]<= (in[7] && in[5] && in[4]) || ( ~in[7] && ~in[6] && ~in[5]) || (in[6] && in[5] && in[4]);
    M4[6]<= (in[7] && in[6] && ~in[5] && in[4]) || (in[7] && ~in[6] && ~in[4]) || ( ~in[7] && ~in[6] && ~in[5]) || (in[6] && in[5] && ~in[4]);
    M4[5]<= (in[7] && in[6] && in[5]) || ( ~in[7] && ~in[6] && ~in[4]) || ( ~in[7] && ~in[5] && in[4]) || ( ~in[6] && ~in[5] && in[4]);
    M4[4]<= ( ~in[7] && ~in[6]) || (in[6] && in[5] && in[4]) || ( ~in[5] && ~in[4]);
    M4[3]<= (in[7] && in[6]) || (in[7] && ~in[4]) || ( ~in[7] && ~in[6] && in[4]) || (in[6] && ~in[5] && ~in[4]) || ( ~in[6] && in[5] && in[4]);
    M4[2]<= (in[7] && in[5] && in[4]) || (in[7] && ~in[5] && ~in[4]) || ( ~in[7] && ~in[6] && in[5] && ~in[4]);
    M4[1]<= ( ~in[7] && ~in[4]) || (in[6] && in[5] && in[4]) || ( ~in[6] && ~in[5]);
    M4[0]<= (in[7] && ~in[6] && ~in[4]) || (in[7] && in[5]) || ( ~in[7] && in[6] && ~in[4]);
    end

    always @ (posedge clk)
    begin   //column 05
    M5[7]<=(in[7] && in[6] && ~in[4]) || (in[7] && ~in[5] && ~in[4]) || ( ~in[7] && in[6] && in[4]) || (in[5] && in[4]) ;
    M5[6]<= (in[7] && in[5] && in[4]) || ( ~in[7] && ~in[5]) || (in[6] && in[5] && ~in[4]);
    M5[5]<= (in[7] && in[6] && in[5] && in[4]) || (in[7] && ~in[6] && ~in[5] && in[4]) || ( ~in[7] && in[6] && ~in[5]) || ( ~in[7] && ~in[6] && ~in[4]) || (in[6] && ~in[5] && ~in[4]);
    M5[4]<= (in[7] && in[6] && in[5] && ~in[4]) || (in[7] && ~in[6] && ~in[5] && ~in[4]) || ( ~in[7] && ~in[6] && in[5]) || ( ~in[7] && in[4]) || ( ~in[6] && in[5] && in[4]);
    M5[3]<= (~in[7] && in[6]) || ( ~in[7] && ~in[4]) || (in[6] && in[5] && ~in[4]) || ( ~in[6] && ~in[5] && in[4]);
    M5[2]<= (in[7] && ~in[5] && ~in[4]) || ( ~in[7] && in[6]) || ( ~in[6] && in[5]) || (in[5] && in[4]);
    M5[1]<= (in[7] && in[6] && in[4]) || (in[7] && ~in[5]) || ( ~in[7] && ~in[6] && in[5]) || ( ~in[6] && ~in[4]) || ( ~in[5] && ~in[4]);
    M5[0]<= (in[7] && in[6] && ~in[5] && in[4]) || (in[7] && ~in[6] && in[5] && in[4]) || ( ~in[7] && in[6] && in[5]) || ( ~in[7] && ~in[6] && ~in[5]) || ( ~in[7] && ~in[6] && ~in[4]) || (in[6] && in[5] && ~in[4]) || ( ~in[6] && ~in[5] && ~in[4]);
    end

    always @ (posedge clk)
    begin   //column 06
    M6[7]<=  (in[7] && in[6] && ~in[4]) || (in[7] && ~in[5] && in[4]) || ( ~in[7] && ~in[6] && in[5] && ~in[4]) || (in[6] && ~in[5] && in[4]);
    M6[6]<=  (in[7] && in[6] && in[4]) || (in[7] && in[5] && in[4]) || ( ~in[7] && ~in[6] && ~in[5]) || ( ~in[7] && ~in[6] && ~in[4]) || ( ~in[7] && ~in[5] && ~in[4]) || ( ~in[6] && ~in[5] && ~in[4]);
    M6[5]<=  (in[7] && in[6] && ~in[5]) || ( ~in[7] && in[6] && in[5]) || ( ~in[7] && in[6] && in[4]) || ( ~in[7] && ~in[6] && ~in[4]) || ( ~in[6] && in[5] && ~in[4]);
    M6[4]<=  (in[7] && ~in[5] && in[4]) || ( ~in[7] && in[6]) || ( ~in[7] && in[5] && ~in[4]) || (in[6] && ~in[5]);
    M6[3]<=  (in[7] && in[6] && in[5] && ~in[4]) || (in[7] && ~in[6] && in[5] && in[4]) || ( ~in[7] && in[6] && in[5] && in[4]) || ( ~in[7] && ~in[5] && ~in[4]);
    M6[2]<=  (in[7] && in[6] && ~in[5]) || (in[7] && ~in[4]) || ( ~in[7] && ~in[6]) || ( ~in[6] && in[5]);
    M6[1]<=  (in[7] && in[6] && in[4]) || (in[7] && in[5] && in[4]) || ( ~in[7] && ~in[6] && ~in[5]) || ( ~in[7] && ~in[4]) || (in[6] && in[5] && ~in[4]);
    M6[0]<=  ( ~in[7] && ~in[6]) || ( ~in[7] && in[5] && ~in[4]) || ( ~in[7] && ~in[5] && in[4]); 
    end

    always @ (posedge clk)
    begin   //column 07
    M7[7]<=( ~in[7] && ~in[6]) || ( ~in[7] && in[5]) || (in[6] && ~in[4]) || ( ~in[6] && in[4]) ;
    M7[6]<= (in[7] && in[6] && ~in[5] && ~in[4]) || ( ~in[7] && ~in[6] && ~in[5]) || ( ~in[7] && ~in[5] && in[4]) || (in[6] && in[5] && in[4]) || ( ~in[6] && in[5] && ~in[4]) ;
    M7[5]<= (in[7] && in[5] && in[4]) || ( ~in[7] && in[6] && ~in[5] && ~in[4]) || ( ~in[7] && ~in[6] && ~in[5] && in[4]) || (in[6] && in[5] && in[4]);
    M7[4]<= (in[7] && ~in[6] && ~in[4]) || (in[7] && in[5] && ~in[4]) || ( ~in[7] && in[4]);
    M7[3]<= (in[7] && in[4]) || (in[6] && ~in[5] && in[4]) || ( ~in[6] && in[5]);
    M7[2]<= (in[7] && in[6] && ~in[5]) || (in[7] && ~in[4]) || ( ~in[7] && in[6] && in[5]) || ( ~in[6] && ~in[4]);
    M7[1]<= (in[7] && ~in[5] && ~in[4]) || ( ~in[7] && ~in[6] && in[5] && in[4]) || (in[6] && ~in[5] && in[4]);
    M7[0]<= (in[7] && ~in[6] && in[5] && in[4]) || ( ~in[7] && in[6] && in[5]) || ( ~in[7] && in[6] && in[4]) || ( ~in[6] && ~in[5] && ~in[4]);
    end

    always @ (posedge clk)
    begin   //column 08
    M8[7]<= ((in[7] & !in[4]) | ( !in[7] & in[6] & in[5] & in[4]) | ( !in[7] & !in[6] & !in[5] & in[4]));
    M8[6]<= ((in[7] & !in[6]) | (in[7] & in[4]) | ( !in[7] & in[6] & !in[4]) | (in[6] & !in[5]));
    M8[5]<= ((in[7] & in[6] & !in[5]) | (in[7] & !in[6] & in[5] & in[4]) | ( !in[7] & in[6] & in[4]) | ( !in[7] & !in[6] & !in[4]) | ( !in[7] & !in[5] & in[4]));
    M8[4]<= ((in[7] & in[6] & in[5] & !in[4]) | ( !in[7] & in[6] & in[5] & in[4]) | ( !in[7] & !in[6] & !in[4]) | ( !in[7] & !in[5] & !in[4]));
    M8[3]<= ((in[7] & in[6] & !in[4]) | (in[7] & !in[6] & in[5] & in[4]) | ( !in[7] & in[6] & in[4]) | ( !in[7] & !in[5] & in[4]));
    M8[2]<= ((in[7] & !in[6] & !in[5]) | ( !in[7] & in[5]) | ( !in[6] & in[4]));
    M8[1]<= ((in[7] & !in[6] & !in[5] & in[4]) | (in[7] & in[5] & !in[4]) | ( !in[7] & in[6] & !in[5]) | ( !in[7] & !in[6] & in[5] & in[4]));
    M8[0]<= ((in[7] & in[6] & in[4]) | ( !in[7] & !in[6] & in[4]) | (in[6] & in[5] & !in[4]));
    end

    always @ (posedge clk)
    begin   //column 09
    M9[7]<= ((in[7] & !in[5] & !in[4]) | ( !in[7] & in[5] & !in[4]) | ( !in[7] & !in[5] & in[4]) | (in[6] & in[5] & in[4]) | ( !in[6] & in[5] & !in[4]) | ( !in[6] & !in[5] & in[4]));
    M9[6]<= ((in[7] & in[6] & !in[5] & !in[4]) | (in[7] & !in[6] & in[5]) | ( !in[7] & in[6] & in[5] & !in[4]) | ( !in[7] & !in[5] & in[4]) | ( !in[6] & !in[5] & in[4]));
    M9[5]<= ((in[7] & !in[6] & !in[5]) | (in[7] & !in[5] & in[4]) | ( !in[7] & in[6] & in[5]) | ( !in[7] & in[6] & !in[4]) | ( !in[7] & in[5] & !in[4]));
    M9[4]<= ((in[7] & in[6]) | (in[7] & in[5]) | ( !in[7] & !in[6] & in[4]) | (in[6] & in[5]) | (in[6] & !in[4]));
    M9[3]<= ((in[7] & in[6] & in[5]) | (in[7] & !in[6] & !in[5] & in[4]) | ( !in[7] & in[6] & !in[5]) | (in[6] & !in[4]));
    M9[2]<= ((in[7] & in[6] & !in[4]) | (in[7] & !in[6] & in[4]) | (in[7] & !in[5]) | ( !in[7] & in[6] & in[5] & in[4]) | ( !in[7] & !in[6] & in[5] & !in[4]) | ( !in[6] & !in[5] & in[4]));
    M9[1]<= ((in[7] & !in[6]) | (in[7] & in[5] & !in[4]) | ( !in[7] & in[6] & !in[5]) | ( !in[7] & in[5] & in[4]));
    M9[0]<= ((in[7] & in[6] & in[4]) | ( !in[7] & !in[4]) | (in[6] & !in[5]) | ( !in[6] & !in[4]));
    end

    always @ (posedge clk)
    begin   //column 0A
    MA[7]<= ((in[7] & in[5] & !in[4]) | ( !in[7] & in[6] & !in[5]) | ( !in[7] & in[4]) | ( !in[6] & in[5]) | ( !in[6] & in[4]));
    MA[6]<= ((in[7] & in[6] & !in[5]) | (in[7] & !in[6] & in[5] & in[4]) | ( !in[7] & in[6] & in[5] & in[4]) | ( !in[7] & !in[6] & !in[4]) | ( !in[5] & !in[4]));
    MA[5]<= ((in[7] & in[5] & in[4]) | (in[7] & !in[5] & !in[4]) | ( !in[7] & !in[5] & in[4]) | ( !in[6] & !in[5]) | ( !in[6] & !in[4]));
    MA[4]<= ((in[7] & !in[6] & in[4]) | (in[7] & !in[5]) | ( !in[7] & in[6] & in[4]) | (in[6] & !in[5]));
    MA[3]<= ((in[7] & !in[6] & !in[5]) | (in[7] & !in[6] & !in[4]) | ( !in[7] & in[6] & in[4]) | (in[6] & in[5] & in[4]));
    MA[2]<= ((in[7] & in[5]) | (in[6] & !in[5]) | ( !in[6] & !in[4]));
    MA[1]<= (( !in[7] & in[6]) | ( !in[7] & !in[5]) | (in[6] & in[5] & !in[4]) | (in[6] & !in[5] & in[4]) | ( !in[6] & !in[5] & !in[4]));
    MA[0]<= ((in[7] & in[6] & in[5]) | (in[7] & in[6] & in[4]) | ( !in[7] & !in[6] & !in[4]));
    end

    always @ (posedge clk)
    begin   //column 0B
    MB[7]<= ((in[7] & in[6] & in[5] & !in[4]) | (in[7] & in[6] & !in[5] & in[4]) | ( !in[7] & in[6] & !in[5] & !in[4]) | ( !in[7] & !in[6] & in[5]) | ( !in[7] & !in[6] & in[4]) | ( !in[6] & in[5] & in[4]));
    MB[6]<= (( !in[6] & in[5]) | (in[5] & !in[4]));
    MB[5]<= (!in[7] | (in[6] & !in[5] & in[4]) | ( !in[6] & in[5]) | ( !in[6] & !in[4]) | (in[5] & !in[4]));
    MB[4]<= ((in[7] & !in[5]) | ( !in[7] & in[5] & !in[4]) | (in[6] & !in[5]));
    MB[3]<= ((in[7] & in[6]) | (in[7] & in[5] & in[4]) | ( !in[7] & !in[5] & in[4]) | (in[6] & in[5] & !in[4]) | ( !in[6] & !in[5] & !in[4]));
    MB[2]<= ((in[7] & in[6] & in[5] & in[4]) | (in[7] & !in[5] & !in[4]) | ( !in[7] & in[6] & in[5] & !in[4]) | ( !in[6] & !in[5] & in[4]));
    MB[1]<= ((in[7] & !in[6] & in[5]) | (in[7] & in[5] & in[4]) | ( !in[7] & in[6] & !in[4]) | ( !in[7] & !in[6] & !in[5]) | ( !in[7] & !in[6] & in[4]) | (in[6] & !in[5] & !in[4]));
    MB[0]<= (( !in[7] & !in[5]) | ( !in[7] & !in[4]) | in[6] | ( !in[5] & !in[4]));
    end

    always @ (posedge clk)
    begin   //column 0C
    MC[7]<= (in[7]&in[6]&in[4])|(in[7] & in[5] & !in[4]) | (in[7] & !in[5] & in[4]) | ( !in[7] & !in[6] & !in[5]) | ( !in[7] & !in[6] & in[4]);
    MC[6]<= (in[7]&!in[6]&in[4])| (in[7] & !in[5] & !in[4]) | ( !in[7] & in[6] & !in[5] & in[4]) | ( !in[7] & !in[6] & in[5]) | (in[6] & in[5] & !in[4]) | ( !in[6] & !in[5] & !in[4]);
    MC[5]<= (in[7]&in[5]&in[4])| ( !in[7] & !in[6] & in[5]) | ( !in[7] & !in[5] & !in[4]) | ( !in[6] & !in[5] & !in[4]);
    MC[4]<= (!in[7]&!in[6]&!in[4])| ( !in[7] & in[5] & !in[4]) | (in[6] & in[5] & in[4]) | ( !in[6] & in[5] & !in[4]) | ( !in[6] & !in[5] & in[4]);
    MC[3]<= (in[7]&in[6]&!in[4])| ( !in[7] & !in[6] & in[4]) | ( !in[7] & !in[5]) | ( !in[6] & !in[5] & in[4]);
    MC[2]<= (in[7]&in[6]&in[5]&!in[4])| (in[7] & !in[6] & in[4]) | (in[7] & !in[5]  & in[4]) | ( !in[6] & !in[5] );
    MC[1]<= (in[7]&in[6]&!in[4])| (in[7] & !in[5] & in[4]) | ( !in[7] & !in[6] & in[5] & in[4]) | ( !in[7] & !in[6] & !in[5] & !in[4]) | (in[6] & !in[5] & in[4]);
    MC[0]<= (in[6]&!in[5]&!in[4])| ( !in[6] & in[5] );
    end

    always @ (posedge clk)
    begin   //column 0d
    MD[7]<= (in[7] & in[6] & !in[5]) | ( !in[7] & in[6]  & in[5] & in[4]) | ( !in[7] & !in[6] & !in[5]) | (in[6] & !in[5] & !in[4]) | ( !in[6] & in[5] & !in[4]);
    MD[6]<= (in[7] & in[6] & in[5]) | (in[7] & in[4]) | ( !in[7] & !in[6] & !in[4]) | ( !in[7] & !in[5] & !in[4]) | (in[6] & in[4]) | ( !in[6] & !in[5] & !in[4]);
    MD[5]<= ( !in[7] & in[6] & in[5]) | ( !in[7] & !in[6] & in[4]) | (in[6] & !in[5] & !in[4]) | ( !in[6] & in[5] & in[4]);
    MD[4]<= (in[7] & !in[6]) | (in[7] & !in[4]) | (in[6] & in[5]) | ( !in[6] & !in[4]);
    MD[3]<= (in[7] & !in[6] & in[4]) | (in[7] & !in[5] & !in[4]) | ( !in[7] & in[6] & in[4]) | ( !in[7] & in[5] & !in[4]);
    MD[2]<= (in[7] & !in[4]) | ( !in[7] & in[4]) | (in[6] & in[5]) | ( !in[6] & !in[5]);
    MD[1]<= (in[7] & !in[6] & in[4]) | ( !in[7] & in[5] & in[4]) | ( !in[7] & !in[5] & !in[4]);
    MD[0]<= (in[7] & in[6] & !in[5]) | (in[7] & !in[4]) | ( !in[7] & in[5] & in[4]) | ( !in[5] & !in[4]);
    end

    

    always @ (posedge clk)
    begin   //column 0e
    ME[7]<= (in[7] & in[6] & !in[5] & !in[4]) | (in[7] & !in[6] & in[5]) | ( !in[7] & in[6] & in[5]) | ( !in[7] & !in[6] & !in[5] & !in[4]) | (in[5] & in[4]); 
    ME[6]<= (in[7] & !in[6] & in[5] & !in[4]) | ( !in[7] & in[6] & in[4]) | ( !in[7] & !in[5] & in[4]); 
    ME[5]<= (in[7] & in[5]) | ( !in[7] & !in[6]) | ( !in[7] & !in[5] & !in[4]) | (in[5] & in[4]);
    ME[4]<= (in[7] & !in[6] & !in[5] & !in[4]) | ( !in[7] & in[5]) | ( !in[7] & in[4]) | (in[6] & in[4]);
    ME[3]<= (in[7] & in[4]) | (in[6] & !in[5]) | (in[6] & !in[4]) | ( !in[5] & !in[4]);
    ME[2]<= (in[7] & in[6] & !in[5] & in[4]) | (in[7] & !in[6] & in[5]) | ( !in[7] & in[6] & !in[4]);
    ME[1]<= (!in[7] & in[6] & !in[4]) | ( !in[7] & !in[5] & !in[4]) | (in[6] & !in[5] & !in[4]) | ( !in[6] & in[4]) | (in[5] & in[4]);
    ME[0]<= (in[7] & !in[5]) | ( !in[7] & !in[4]) | (in[6] & in[5] & in[4]);
    end

    always @ (posedge clk)
    begin   //column 0f
    MF[7]<= ( !in[7] & in[6]) | (in[6] & !in[4]) | ( !in[5] & in[4]);
    MF[6]<= (in[7] & in[5] & !in[4]) | ( !in[7] & in[4]) | ( !in[6] & !in[5]);
    MF[5]<= (in[7] & !in[6] & !in[4]) | ( !in[7] & in[6] & in[5] & !in[4]) | ( !in[7] & !in[6] & in[5] & in[4]) | ( !in[6] & !in[5] & !in[4]);
    MF[4]<= (in[7] & in[6] & in[5]) | (in[7] & !in[5] & in[4]) | ( !in[7] & in[5] & in[4]) | ( !in[6] & !in[4]);
    MF[3]<= (in[7] & in[6] & !in[5]) | (in[7] & !in[6] & in[5]) | (in[7] & !in[6] & in[4]) | (in[6] & in[5] & !in[4]) | (in[6] & !in[5] & in[4]);
    MF[2]<= (in[7] & in[6] & in[5]) | ( !in[7] & !in[6] & in[5]) | ( !in[7] & !in[5] & !in[4]) | (in[6] & !in[5] & in[4]);
    MF[1]<= (in[7] & in[6]) | (in[7] & !in[5]) | (in[6] & in[4]) | ( !in[6] & !in[5] & !in[4]);
    MF[0]<= (in[7] & !in[6] & !in[5]) | (in[7] & in[5] & !in[4]) | ( !in[7] & in[6] & !in[5] & in[4]) | ( !in[7] & !in[6] & in[5]);
    end


    always @ (posedge clk)
    begin   //selection block based on 4 least significant bits 
    case (in[3:0])
    4'b0000: out <= M0;
    4'b0001: out <= M1;
    4'b0010: out <= M2;
    4'b0011: out <= M3;
    4'b0100: out <= M4;
    4'b0101: out <= M5;
    4'b0110: out <= M6;
    4'b0111: out <= M7;
    4'b1000: out <= M8;
    4'b1001: out <= M9;
    4'b1010: out <= MA;
    4'b1011: out <= MB;
    4'b1100: out <= MC;
    4'b1101: out <= MD;
    4'b1110: out <= ME;
    4'b1111: out <= MF;
    endcase
    end
   
endmodule
    

/* S box * x */
module xS_table (clk, in, out); //uses BRAM, implementation based on logic operations included in sbox.v
    input clk;
    input [7:0] in;
    output reg [7:0] out;

    always @ (posedge clk)
    case (in)
    8'h00: out <= 8'hc6;
    8'h01: out <= 8'hf8;
    8'h02: out <= 8'hee;
    8'h03: out <= 8'hf6;
    8'h04: out <= 8'hff;
    8'h05: out <= 8'hd6;
    8'h06: out <= 8'hde;
    8'h07: out <= 8'h91;
    8'h08: out <= 8'h60;
    8'h09: out <= 8'h02;
    8'h0a: out <= 8'hce;
    8'h0b: out <= 8'h56;
    8'h0c: out <= 8'he7;
    8'h0d: out <= 8'hb5;
    8'h0e: out <= 8'h4d;
    8'h0f: out <= 8'hec;
    8'h10: out <= 8'h8f;
    8'h11: out <= 8'h1f;
    8'h12: out <= 8'h89;
    8'h13: out <= 8'hfa;
    8'h14: out <= 8'hef;
    8'h15: out <= 8'hb2;
    8'h16: out <= 8'h8e;
    8'h17: out <= 8'hfb;
    8'h18: out <= 8'h41;
    8'h19: out <= 8'hb3;
    8'h1a: out <= 8'h5f;
    8'h1b: out <= 8'h45;
    8'h1c: out <= 8'h23;
    8'h1d: out <= 8'h53;
    8'h1e: out <= 8'he4;
    8'h1f: out <= 8'h9b;
    8'h20: out <= 8'h75;
    8'h21: out <= 8'he1;
    8'h22: out <= 8'h3d;
    8'h23: out <= 8'h4c;
    8'h24: out <= 8'h6c;
    8'h25: out <= 8'h7e;
    8'h26: out <= 8'hf5;
    8'h27: out <= 8'h83;
    8'h28: out <= 8'h68;
    8'h29: out <= 8'h51;
    8'h2a: out <= 8'hd1;
    8'h2b: out <= 8'hf9;
    8'h2c: out <= 8'he2;
    8'h2d: out <= 8'hab;
    8'h2e: out <= 8'h62;
    8'h2f: out <= 8'h2a;
    8'h30: out <= 8'h08;
    8'h31: out <= 8'h95;
    8'h32: out <= 8'h46;
    8'h33: out <= 8'h9d;
    8'h34: out <= 8'h30;
    8'h35: out <= 8'h37;
    8'h36: out <= 8'h0a;
    8'h37: out <= 8'h2f;
    8'h38: out <= 8'h0e;
    8'h39: out <= 8'h24;
    8'h3a: out <= 8'h1b;
    8'h3b: out <= 8'hdf;
    8'h3c: out <= 8'hcd;
    8'h3d: out <= 8'h4e;
    8'h3e: out <= 8'h7f;
    8'h3f: out <= 8'hea;
    8'h40: out <= 8'h12;
    8'h41: out <= 8'h1d;
    8'h42: out <= 8'h58;
    8'h43: out <= 8'h34;
    8'h44: out <= 8'h36;
    8'h45: out <= 8'hdc;
    8'h46: out <= 8'hb4;
    8'h47: out <= 8'h5b;
    8'h48: out <= 8'ha4;
    8'h49: out <= 8'h76;
    8'h4a: out <= 8'hb7;
    8'h4b: out <= 8'h7d;
    8'h4c: out <= 8'h52;
    8'h4d: out <= 8'hdd;
    8'h4e: out <= 8'h5e;
    8'h4f: out <= 8'h13;
    8'h50: out <= 8'ha6;
    8'h51: out <= 8'hb9;
    8'h52: out <= 8'h00;
    8'h53: out <= 8'hc1;
    8'h54: out <= 8'h40;
    8'h55: out <= 8'he3;
    8'h56: out <= 8'h79;
    8'h57: out <= 8'hb6;
    8'h58: out <= 8'hd4;
    8'h59: out <= 8'h8d;
    8'h5a: out <= 8'h67;
    8'h5b: out <= 8'h72;
    8'h5c: out <= 8'h94;
    8'h5d: out <= 8'h98;
    8'h5e: out <= 8'hb0;
    8'h5f: out <= 8'h85;
    8'h60: out <= 8'hbb;
    8'h61: out <= 8'hc5;
    8'h62: out <= 8'h4f;
    8'h63: out <= 8'hed;
    8'h64: out <= 8'h86;
    8'h65: out <= 8'h9a;
    8'h66: out <= 8'h66;
    8'h67: out <= 8'h11;
    8'h68: out <= 8'h8a;
    8'h69: out <= 8'he9;
    8'h6a: out <= 8'h04;
    8'h6b: out <= 8'hfe;
    8'h6c: out <= 8'ha0;
    8'h6d: out <= 8'h78;
    8'h6e: out <= 8'h25;
    8'h6f: out <= 8'h4b;
    8'h70: out <= 8'ha2;
    8'h71: out <= 8'h5d;
    8'h72: out <= 8'h80;
    8'h73: out <= 8'h05;
    8'h74: out <= 8'h3f;
    8'h75: out <= 8'h21;
    8'h76: out <= 8'h70;
    8'h77: out <= 8'hf1;
    8'h78: out <= 8'h63;
    8'h79: out <= 8'h77;
    8'h7a: out <= 8'haf;
    8'h7b: out <= 8'h42;
    8'h7c: out <= 8'h20;
    8'h7d: out <= 8'he5;
    8'h7e: out <= 8'hfd;
    8'h7f: out <= 8'hbf;
    8'h80: out <= 8'h81;
    8'h81: out <= 8'h18;
    8'h82: out <= 8'h26;
    8'h83: out <= 8'hc3;
    8'h84: out <= 8'hbe;
    8'h85: out <= 8'h35;
    8'h86: out <= 8'h88;
    8'h87: out <= 8'h2e;
    8'h88: out <= 8'h93;
    8'h89: out <= 8'h55;
    8'h8a: out <= 8'hfc;
    8'h8b: out <= 8'h7a;
    8'h8c: out <= 8'hc8;
    8'h8d: out <= 8'hba;
    8'h8e: out <= 8'h32;
    8'h8f: out <= 8'he6;
    8'h90: out <= 8'hc0;
    8'h91: out <= 8'h19;
    8'h92: out <= 8'h9e;
    8'h93: out <= 8'ha3;
    8'h94: out <= 8'h44;
    8'h95: out <= 8'h54;
    8'h96: out <= 8'h3b;
    8'h97: out <= 8'h0b;
    8'h98: out <= 8'h8c;
    8'h99: out <= 8'hc7;
    8'h9a: out <= 8'h6b;
    8'h9b: out <= 8'h28;
    8'h9c: out <= 8'ha7;
    8'h9d: out <= 8'hbc;
    8'h9e: out <= 8'h16;
    8'h9f: out <= 8'had;
    8'ha0: out <= 8'hdb;
    8'ha1: out <= 8'h64;
    8'ha2: out <= 8'h74;
    8'ha3: out <= 8'h14;
    8'ha4: out <= 8'h92;
    8'ha5: out <= 8'h0c;
    8'ha6: out <= 8'h48;
    8'ha7: out <= 8'hb8;
    8'ha8: out <= 8'h9f;
    8'ha9: out <= 8'hbd;
    8'haa: out <= 8'h43;
    8'hab: out <= 8'hc4;
    8'hac: out <= 8'h39;
    8'had: out <= 8'h31;
    8'hae: out <= 8'hd3;
    8'haf: out <= 8'hf2;
    8'hb0: out <= 8'hd5;
    8'hb1: out <= 8'h8b;
    8'hb2: out <= 8'h6e;
    8'hb3: out <= 8'hda;
    8'hb4: out <= 8'h01;
    8'hb5: out <= 8'hb1;
    8'hb6: out <= 8'h9c;
    8'hb7: out <= 8'h49;
    8'hb8: out <= 8'hd8;
    8'hb9: out <= 8'hac;
    8'hba: out <= 8'hf3;
    8'hbb: out <= 8'hcf;
    8'hbc: out <= 8'hca;
    8'hbd: out <= 8'hf4;
    8'hbe: out <= 8'h47;
    8'hbf: out <= 8'h10;
    8'hc0: out <= 8'h6f;
    8'hc1: out <= 8'hf0;
    8'hc2: out <= 8'h4a;
    8'hc3: out <= 8'h5c;
    8'hc4: out <= 8'h38;
    8'hc5: out <= 8'h57;
    8'hc6: out <= 8'h73;
    8'hc7: out <= 8'h97;
    8'hc8: out <= 8'hcb;
    8'hc9: out <= 8'ha1;
    8'hca: out <= 8'he8;
    8'hcb: out <= 8'h3e;
    8'hcc: out <= 8'h96;
    8'hcd: out <= 8'h61;
    8'hce: out <= 8'h0d;
    8'hcf: out <= 8'h0f;
    8'hd0: out <= 8'he0;
    8'hd1: out <= 8'h7c;
    8'hd2: out <= 8'h71;
    8'hd3: out <= 8'hcc;
    8'hd4: out <= 8'h90;
    8'hd5: out <= 8'h06;
    8'hd6: out <= 8'hf7;
    8'hd7: out <= 8'h1c;
    8'hd8: out <= 8'hc2;
    8'hd9: out <= 8'h6a;
    8'hda: out <= 8'hae;
    8'hdb: out <= 8'h69;
    8'hdc: out <= 8'h17;
    8'hdd: out <= 8'h99;
    8'hde: out <= 8'h3a;
    8'hdf: out <= 8'h27;
    8'he0: out <= 8'hd9;
    8'he1: out <= 8'heb;
    8'he2: out <= 8'h2b;
    8'he3: out <= 8'h22;
    8'he4: out <= 8'hd2;
    8'he5: out <= 8'ha9;
    8'he6: out <= 8'h07;
    8'he7: out <= 8'h33;
    8'he8: out <= 8'h2d;
    8'he9: out <= 8'h3c;
    8'hea: out <= 8'h15;
    8'heb: out <= 8'hc9;
    8'hec: out <= 8'h87;
    8'hed: out <= 8'haa;
    8'hee: out <= 8'h50;
    8'hef: out <= 8'ha5;
    8'hf0: out <= 8'h03;
    8'hf1: out <= 8'h59;
    8'hf2: out <= 8'h09;
    8'hf3: out <= 8'h1a;
    8'hf4: out <= 8'h65;
    8'hf5: out <= 8'hd7;
    8'hf6: out <= 8'h84;
    8'hf7: out <= 8'hd0;
    8'hf8: out <= 8'h82;
    8'hf9: out <= 8'h29;
    8'hfa: out <= 8'h5a;
    8'hfb: out <= 8'h1e;
    8'hfc: out <= 8'h7b;
    8'hfd: out <= 8'ha8;
    8'hfe: out <= 8'h6d;
    8'hff: out <= 8'h2c;
    endcase
endmodule