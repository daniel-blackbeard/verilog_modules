`timescale 1ns / 1ps

module uart_rx(
    input clk,
    input rxd,
    output reg [7:0] data,
    output reg rx_done
    );
    
  parameter SYSCLK = 100_000_000; // MHz
  parameter BAUDRATE = 57600;
  parameter DIVISOR = SYSCLK/BAUDRATE;

  enum reg [3:0] {IDLE, BIT8, BIT7, BIT6, BIT5, BIT4, BIT3, BIT2, BIT1, BIT0} state=IDLE, next_state=IDLE;
            
  reg [13:0] strobe              = 14'b0;
  reg [7:0]  temp_buf            = 8'b11111111;
    
  initial data = 8'b0;
    
  always @(posedge clk) begin
    state <= (strobe == 14'b0) ? next_state : state;
    if (strobe == 14'b0) strobe <= ((state == IDLE) & rxd) ? 14'b0 : DIVISOR - 1;
    else                 strobe <= strobe - 14'b1;
  end
  
  always @(posedge clk) begin
    data <= (next_state==IDLE) ? temp_buf : data;
  end  
  
  always @(posedge clk) begin
    case(state)
      IDLE:  {next_state, temp_buf} <= ((strobe==DIVISOR/2) & !rxd) ? {BIT8, {8'b00000000}}        : {next_state, temp_buf}; 
      BIT8:  {next_state, temp_buf} <= (strobe==DIVISOR/2)          ? {BIT7, {rxd, temp_buf[7:1]}} : {next_state, temp_buf};
      BIT7:  {next_state, temp_buf} <= (strobe==DIVISOR/2)          ? {BIT6, {rxd, temp_buf[7:1]}} : {next_state, temp_buf};
      BIT6:  {next_state, temp_buf} <= (strobe==DIVISOR/2)          ? {BIT5, {rxd, temp_buf[7:1]}} : {next_state, temp_buf};
      BIT5:  {next_state, temp_buf} <= (strobe==DIVISOR/2)          ? {BIT4, {rxd, temp_buf[7:1]}} : {next_state, temp_buf};
      BIT4:  {next_state, temp_buf} <= (strobe==DIVISOR/2)          ? {BIT3, {rxd, temp_buf[7:1]}} : {next_state, temp_buf};
      BIT3:  {next_state, temp_buf} <= (strobe==DIVISOR/2)          ? {BIT2, {rxd, temp_buf[7:1]}} : {next_state, temp_buf};
      BIT2:  {next_state, temp_buf} <= (strobe==DIVISOR/2)          ? {BIT1, {rxd, temp_buf[7:1]}} : {next_state, temp_buf};
      BIT1:  {next_state, temp_buf} <= (strobe==DIVISOR/2)          ? {IDLE, {rxd, temp_buf[7:1]}} : {next_state, temp_buf};
    endcase
  end
  
  assign rx_done = (state==IDLE) & (next_state==IDLE);
  
endmodule