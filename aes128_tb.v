
module aes128_tb();

wire [127:0] data_out;
wire flag_sinp;
reg [127:0] key_in,init_v;
reg [127:0] data_in;
reg clk;
integer i;
reg sdata_in;
reg skey_in;
reg sinit_v;


//aes128 dut (.clk(clk), .state(data_in), .key(key_in), .out(data_out));
aes128_cbc dut1 (.clk(clk), .s_inp(sdata_in), .s_key(skey_in),.s_init_v(sinit_v), .out(data_out), .flag_sinp(flag_sinp));

initial
begin
 data_in=128'h00000000000000000000000000000000;
 key_in=128'h00000000000000000000000000000000;
 init_v=128'h00000000000000000000000000000000;
 clk=1'b0;
 
 forever #10 clk= ~clk;
end




initial
begin
 key_in=128'h416264756C4D6F697A536865696B686B;     //AbdulMoizSheikhk
 //data_in=128'h596F75617265746865626573746D616E;   //Youarethebestman
 data_in= 128'b01011001011011110111010101100001011100100110010101110100011010000110010101100010011001010111001101110100011011010110000101101110;
 init_v=128'h74686973697363686169746869736973;     //thisischaithisis
// for (i=127;i>-1;i=i-1)

for (i=127;i>=-1;i=i-1)
 begin
 sdata_in =data_in[i];
 skey_in = key_in[i];
 sinit_v = init_v[i];
 #20;
 end
 
/*
#410
 data_in=128'h496C6F7665746F6561746D656174746F;     //Ilovetoeatmeatto
 for (i=0;i<128;i=i+1)
 begin
 sdata_in=data_in[i];
 end
#410
 data_in=128'h596F75617265746865626573746D616E;     //Youarethebestman
 for (i=0;i<128;i=i+1)
 begin
 sdata_in=data_in[i];
 end
*/
end


endmodule
