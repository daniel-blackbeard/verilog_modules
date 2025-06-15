`timescale 1ns / 1ps

module synth_core(
  input         clk,
  input   [4:0] vol,
  input  [15:0] f_mult,
  output reg [23:0] d_out
);
// It produces samples at ~48KHz, that given the constraints of i2s_tx module
// means we can use a frequency of 60MHz and a divisor of 1248
// the frequency error will be around 0.16%
parameter DIV = 12'b10011011111;

reg  [11:0] strobe;
reg  [17:0] phase_accum;      // each bit increases freq by 0.732Hz, we will use sine symmetries
wire  [7:0] samp;
reg   [8:0] data, data_last;  // this is the actual waveform, on this we will make interpolation
reg   [5:0] addr;

reg [23:0] dtemp, dtemp_interp;

initial begin
  addr = 6'b0;
  strobe = 12'b0;
  phase_accum = 18'b0;
  data = 9'b0;
  data_last = 9'b0;
  d_out = 24'b0;
end

always @(posedge clk) begin
  if(strobe==DIV) begin
    strobe <= 12'b0;
    phase_accum <= phase_accum + f_mult;
    data_last <= ((phase_accum>>10) != (phase_accum + f_mult)>>10) ? data : data_last;
  end
  else begin
    strobe <= strobe + 12'b1;
  end

  // This will attempt to infer DSP slices
  // Linear interpolation here
  dtemp <= {{15{data[8]}}, data} - {{15{data_last[8]}}, data_last};
  dtemp_interp <= dtemp*phase_accum[9:0] + ({{15{data_last[8]}}, data_last}<<10);
  d_out <= dtemp_interp * vol;
end

always @(phase_accum, samp) begin
  case(phase_accum[17:16])
    2'b00: addr <= phase_accum[15:10];
    2'b01: addr <= 6'b111111  - phase_accum[15:10];
    2'b10: addr <= phase_accum[15:10];
    2'b11: addr <= 6'b111111  - phase_accum[15:10];
  endcase
  
  case(phase_accum[17:16])
    2'b00: data <= {1'b0,  samp};
    2'b01: data <= {1'b0,  samp};
    2'b10: data <= {1'b1, ~samp};
    2'b11: data <= {1'b1, ~samp};
  endcase
end

rom_sine SINE(.addr(addr), .data_out(samp));

endmodule
