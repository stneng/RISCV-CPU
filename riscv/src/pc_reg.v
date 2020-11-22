`include "defines.v"
module pc_reg (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire[`StallBus] stall_in,
    //ex
    input wire jump_enable,
    input wire[`AddressBus] jump_target,
    //if
    output reg[`AddressBus] pc
);
    always @(posedge clk_in) begin
        if (rst_in==1) begin
            pc<=0;
        end else if (rdy_in==1) begin
            if (jump_enable==1) begin
                pc<=jump_target;
            end else if (stall_in[0]==0) begin
                pc<=pc+4;
            end
        end
    end
endmodule