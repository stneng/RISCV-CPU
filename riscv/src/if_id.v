`include "defines.v"
module if_id (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire[`StallBus] stall_in,
    //ex
    input wire jump_enable,
    //if
    input wire[`AddressBus] pc_in,
    input wire[`InstBus] inst_in,
    //id
    output reg[`AddressBus] pc_out,
    output reg[`InstBus] inst_out
);
    always @(posedge clk_in) begin
        if (rst_in==1) begin
            pc_out<=0;
            inst_out<=0;
        end else if (rdy_in==1) begin
            if (jump_enable==1) begin
                pc_out<=0;
                inst_out<=0;
            end else if (stall_in[2]==1) begin
                ;
            end else if (stall_in[1]==0) begin
                pc_out<=pc_in;
                inst_out<=inst_in;
            end else begin
                pc_out<=0;
                inst_out<=0;
            end
        end
    end
endmodule