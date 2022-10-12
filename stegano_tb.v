module stegano_tb;

reg [127:0] payload;
reg [7:0] cover;
reg clk;
reg en;
wire [7:0] out;
wire SD;
wire [127:0]pay1;
stegano_core uut(.payload(payload), .cover(cover), .clk(clk), .out(out), .SD(SD), .en(en));


initial 
begin
payload= 128'h416264756C4D6F697A536865696B686B;
cover= 8'b00000000;
clk=1'b0;
en=1'b0;
#20
cover= 8'b10000000;
#20
cover= 8'b11000000;
en=1'b1;
#20
cover= 8'b11000000;
end




initial 
begin
forever #10 clk=~clk;
end


endmodule
