`timescale 1ns / 1ps

module uart_tx(
    input clk,
    input [7:0] data,
    input i_wr,
    output reg tx_busy,
    output reg txd
    );
  
  parameter SYSCLK = 100_000_000; // MHz
  parameter BAUDRATE = 57600;
  parameter DIVISOR = SYSCLK/BAUDRATE;
  
  enum reg [3:0] {IDLE, INIT, BIT8, BIT7, BIT6, BIT5, BIT4, BIT3, BIT2, BIT1, BIT0} state=IDLE, next_state=IDLE;
        
  reg [8:0]  temp_buf       = 9'b111111111;
  reg [13:0] strobe         = 14'b1;
  
  initial {txd, tx_busy} = {1'b1, 1'b0};
  
  always @(posedge clk) begin
    {state, txd} <= (strobe == 14'b0) ? {next_state, temp_buf[0]} : {state, txd};
    if (strobe == 14'b0) strobe <= (next_state == IDLE) ? 14'b0 : DIVISOR - 1;
    else                 strobe <= strobe - 14'b1;
  end
  
  always @(posedge clk) begin
    case(state)
      IDLE:  {next_state, temp_buf} <= (i_wr && !tx_busy)  ? {INIT, {data, 1'b0}}          : {next_state, temp_buf}; 
      INIT:  {next_state, temp_buf} <= (strobe==DIVISOR/2) ? {BIT8, {1'b1, temp_buf[8:1]}} : {next_state, temp_buf};
      BIT8:  {next_state, temp_buf} <= (strobe==DIVISOR/2) ? {BIT7, {1'b1, temp_buf[8:1]}} : {next_state, temp_buf};
      BIT7:  {next_state, temp_buf} <= (strobe==DIVISOR/2) ? {BIT6, {1'b1, temp_buf[8:1]}} : {next_state, temp_buf};
      BIT6:  {next_state, temp_buf} <= (strobe==DIVISOR/2) ? {BIT5, {1'b1, temp_buf[8:1]}} : {next_state, temp_buf};
      BIT5:  {next_state, temp_buf} <= (strobe==DIVISOR/2) ? {BIT4, {1'b1, temp_buf[8:1]}} : {next_state, temp_buf};
      BIT4:  {next_state, temp_buf} <= (strobe==DIVISOR/2) ? {BIT3, {1'b1, temp_buf[8:1]}} : {next_state, temp_buf};
      BIT3:  {next_state, temp_buf} <= (strobe==DIVISOR/2) ? {BIT2, {1'b1, temp_buf[8:1]}} : {next_state, temp_buf};
      BIT2:  {next_state, temp_buf} <= (strobe==DIVISOR/2) ? {BIT1, {1'b1, temp_buf[8:1]}} : {next_state, temp_buf};
      BIT1:  {next_state, temp_buf} <= (strobe==DIVISOR/2) ? {IDLE, {1'b1, temp_buf[8:1]}} : {next_state, temp_buf};
    endcase
  end
  
  assign tx_busy = state!=IDLE;
  
endmodule
