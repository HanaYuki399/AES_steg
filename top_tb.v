module top_tb;

reg key,payload,IV,cover;
reg [127:0] key_f,payload_f,IV_f;
reg [7:0] cover_f;
reg clk;

wire [7:0] out;
wire flag1,flag2;
wire [6:0] count;
wire flag_sinp;
integer i, m;

top uut (.key(key),.payload(payload),.IV(IV),.cover(cover),.clk(clk),.out(out),.flag1(flag1),.flag2(flag2),.count(count), .flag_sinp(flag_sinp));

initial 
begin
clk=1'b0;
cover=8'b00000000;
key_f=128'h416264756C4D6F697A536865696B686B;     
payload_f=128'h596F75617265746865626573746D616E;   
IV_f=128'h74686973697363686169746869736973; 

for (i=127;i>=-1;i=i-1)
 begin
 payload =payload_f[i];
 key= key_f[i];
 IV = IV_f[i];
 #20;
 end
 
 end
 
 
 initial
 begin
 
 for (m=7;m>=-1;m=m-1)
 begin
cover=cover_f[i];

 #20;
 end
 end
 





initial 
begin
forever #10 clk=~clk;
end

endmodule
