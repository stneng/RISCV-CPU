`include "defines.v"
module id_ex (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire[`StallBus] stall_in,
    //ex
    input wire jump_enable,
    //id
    input wire[`AddressBus] pc_in,
    input wire[`RegBus] rs1_in,
    input wire[`RegBus] rs2_in,
    input wire[`RegAddressBus] rd_in,
    input wire[`RegBus] imm_in,
    input wire[`InstShort] inst_in, //inst short code
    //ex
    output reg[`AddressBus] pc_out,
    output reg[`RegBus] rs1_out,
    output reg[`RegBus] rs2_out,
    output reg[`RegAddressBus] rd_out,
    output reg[`RegBus] imm_out,
    output reg[`InstShort] inst_out //inst short code
);
    always @(posedge clk_in) begin
        if (rst_in==1) begin
            pc_out<=0;
            rs1_out<=0;
            rs2_out<=0;
            rd_out<=0;
            imm_out<=0;
            inst_out<=0;
        end else if (rdy_in==1) begin
            if (stall_in[3]==1) begin
                ;
            end else if (jump_enable==1) begin
                pc_out<=0;
                rs1_out<=0;
                rs2_out<=0;
                rd_out<=0;
                imm_out<=0;
                inst_out<=0;
            end else if (stall_in[2]==0) begin
                pc_out<=pc_in;
                rs1_out<=rs1_in;
                rs2_out<=rs2_in;
                rd_out<=rd_in;
                imm_out<=imm_in;
                inst_out<=inst_in;
            end else begin
                pc_out<=0;
                rs1_out<=0;
                rs2_out<=0;
                rd_out<=0;
                imm_out<=0;
                inst_out<=0;
            end
        end
    end
endmodule