module sipomod_cover(clk, si, pout, flag_cinp);
input clk, si;
reg  [7:0] po;
reg [7:0] counter= 4'b0000; 
output reg flag_cinp=1'b0;
output reg [7:0] pout;
reg [7:0] tmp;

always @(posedge clk)
begin
//if (clear)
//tmp <= 128'd0;
//else
if (counter>4'd8)
begin
flag_cinp<=1'b1;
pout=po;   //Don't send the pout with every input that comes instead wait for it to collect so you get the right output once. Otherwise, the aes block will have unneeded switching, causing it to lose a lot of power.
end
else
begin
tmp <= tmp << 1;
tmp[0] <= si;
po = tmp;
//pout= po;
counter<=counter+1;
end
end
endmodule






module stegano_core(payload,s_cover, clk, out, SD, en);

input [127:0] payload;   //secret data
input s_cover;
wire [7:0] cover;        //cover data
input clk;                 //clk
input en;                  //enable
output reg [7:0] out;        //output
output reg SD;               //stegano done flag

reg imm;                //intermediate flag
reg [6:0] count=7'b0000000;        //counter
reg [127:0] pay1;       //payload dummy
wire flag_cinp;


sipomod_cover u1(.clk(clk), .si(s_cover), .pout(cover), .flag_cinp(flag_cinp));







//implementing 64 cycle count
always@(posedge clk)
begin
if(en==1)
count=count+1;
else 
count=count;
end

//updating flags on 64 cycles
always@(posedge clk) 
begin
case (count[6]&&count[1])
1: begin
imm=1'b1;
SD=1'b1;
end
0:begin
imm=1'b0;
SD=1'b0;
end
endcase
end


//reseting counter after 64 cycles
always@(posedge clk)
begin
if(count>66)
count=7'b0000000;
else
count=count;
end

//actuall steganography
always@(posedge clk)
begin
if (en==1)
begin
if(imm!=1) 
begin
out[7:0]={cover[7:2],pay1[127:126]};
end
else 
begin
out[7:0]=cover[7:0];
end
end
else
out[7:0]=out[7:0];
end


//bharwat
always@(posedge clk)
begin
if(imm!=1) 
begin
pay1=pay1<<2;
end
else 
begin
pay1=pay1;
end
end

//just messing around
always@(posedge clk)
begin
case (en)
1:begin
if (count<=1)
pay1[127:0]<=payload[127:0];
else
pay1[127:0]<=pay1[127:0];

end
0:begin
pay1[127:0]<=pay1[127:0];
end
endcase

end
endmodule


