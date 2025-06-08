`timescale 1ns / 1ps

module i2s_tx(
  input clk,
  input [23:0] data_in,
  input invert,
  output i2c_out,
  output ws,
  output bck
);

// Required clock: 24bit x 2(LR) x 48KHz = 2.304MHz
// this clock can't be synthesized with the PLL 
// primitive, hence we will use a strobe
// and use sysclk = 60MHz with divide by 26
// the frequency error will be around 0.16%
reg [5:0]  strobe;
reg [23:0] temp;
reg [4:0] counter;
reg        dx_or_sx;

initial begin
  strobe   = 6'b0;
  temp     = 24'b0;
  dx_or_sx = 1'b0;
  counter = 5'b0;
end

always @(posedge clk) begin
  if(strobe==6'b011001) begin
    temp     <= (counter == 5'b1) ? data_in : {temp[22:0], 1'b0};
    strobe   <= 6'b0;
    counter  <= (counter == 5'b10111) ? 5'b0 : counter + 5'b1;
    dx_or_sx <= (counter == 5'b0) ? ~dx_or_sx : dx_or_sx;
  end
  else begin
    strobe   <= strobe + 6'b1;
  end
end

assign ws      = invert ? ~dx_or_sx : dx_or_sx;
assign i2c_out = temp[23];
assign bck     = strobe > 6'b001100 ? 1'b1 : 1'b0;

endmodule
