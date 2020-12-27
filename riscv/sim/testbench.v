// testbench top module file
// for simulation only

`timescale 1ns/1ps
module testbench;

reg clk;
reg rst;
reg btnL;
reg btnR;

riscv_top #(.SIM(1)) top(
    .EXCLK(clk),
    .btnC(rst),
    .btnL(btnL),
    .btnR(btnR),
    .Tx(),
    .Rx(),
    .led()
);

initial begin
  clk=0;
  rst=1;
  btnL=0;
  btnR=0;
  repeat(50) #1 clk=!clk;
  rst=0;
  /*repeat(1000) #1 clk=!clk;
  btnL=1;
  repeat(50) #1 clk=!clk;
  btnL=0;*/
  forever #1 clk=!clk;

  $finish;
end

endmodule