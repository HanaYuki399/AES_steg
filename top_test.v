module top(key,payload,IV,cover,clk,out,flag1,flag2,count,flag_sinp);

input key;
input  payload;
input IV;
input cover;
input clk;
output [7:0] out;
output reg flag1=1'b0;  //for encryption
output wire flag2;    //for stegano wire for tb bharwat

output reg [6:0] count=7'b0000000;
output flag_sinp;
wire [127:0] res_aes; 
reg [127:0] in_stegano;
reg baari=1'b1;
reg [7:0] save_inp= 8'b00000000;


aes128_cbc dut1 (.clk(clk), .s_inp(payload), .s_key(key),.s_init_v(IV), .out(res_aes), .flag_sinp(flag_sinp));
//aes128_cbc uut1 (.clk(clk), .state(payload), .key(key), .out(res_aes), .init_v(IV));
stegano_core uut2 (.payload(in_stegano), .s_cover(cover), .clk(clk), .out(out), .SD(flag2), .en(!baari));

always @ (posedge clk)
begin
if (save_inp>128)
begin
count=count+1;
end
save_inp= save_inp + 1;
end

always @ (posedge clk)
begin 
if(count>=23 && count<=26)
flag1=1;
end
//else
//flag1=0; 
//end

always@(posedge clk)
begin
if(count==24)
baari=0;
end
//else
//baari=baari;
//end


always @ (posedge clk)
begin
if (count==90)
begin
count=7'b0000000;
save_inp=8'b00000000;
end
//else
//count<=count; 
end


always @ (posedge clk)
begin
case (baari)
0: begin
if(flag1==1) begin
in_stegano<=res_aes;
end
//else
//in_stegano<=in_stegano;
end
1: begin
if(flag1==1&&flag2==1)
in_stegano<=res_aes;
else
in_stegano<=in_stegano;
end

endcase
end
 
endmodule
