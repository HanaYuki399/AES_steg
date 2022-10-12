
module sipomod(clk, si, pout, flag);
input clk, si;
reg  [127:0] po;
reg [7:0] counter= 8'b00000000; 
output reg flag=1'b0;
output reg [127:0] pout;
reg [127:0] tmp;

always @(posedge clk)
begin
//if (clear)
//tmp <= 128'd0;
//else
if (counter>8'd128)
begin
flag<=1'b1;
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


module aes128_cbc(clk, s_inp, s_key, out, s_init_v, flag_sinp);

input clk;
input s_inp;
input  s_key, s_init_v;
wire [127:0] state;
wire [127:0] key;
wire [127:0] init_v;
output reg [127:0] out;
output flag_sinp;

reg [127:0] state_in;
wire [127:0] out_tmp;
reg count=1'b0;
reg incheck=1'b0;
reg flag=1'b0;
//reg [7:0] counter_sinp= 8'b00000000; 

sipomod u1(.clk(clk), .si(s_inp), .pout(state), .flag(flag_sinp)); 
sipomod u2(.clk(clk), .si(s_key), .pout(key), .flag(flag_sinp));
sipomod u3(.clk(clk), .si(s_init_v), .pout(init_v), .flag(flag_sinp));


aes1281 dut1 (.clk(clk), .state(state_in), .key(key), .out(out_tmp));

 
/*always @(posedge clk)
begin
//if (clear)
//tmp <= 128'd0;
//else

if (counter_sinp>8'd128)
begin
flag<=1'b1;
end
else
counter_sinp= counter_sinp + 1;
end*/

always @ (posedge clk)
begin
case (count)
0:state_in <= state ^ init_v;
1:state_in <= state ^ out;
endcase
end

always @ (out_tmp)
begin
count=1'b1;
incheck=~incheck;
end

always @ (state)
begin
incheck=1'b1;
end

always @ (posedge clk)
begin
case (!count&&!incheck)
1:out <= out;
0:out <= out_tmp;
endcase
end


endmodule
