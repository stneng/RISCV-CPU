`include "defines.v"
module ex (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //id_ex
    input wire[`AddressBus] pc_in,
    input wire[`RegBus] rs1_in,
    input wire[`RegBus] rs2_in,
    input wire[`RegAddressBus] rd_in,
    input wire[`RegBus] imm_in,
    input wire[`InstShort] inst_in, //inst short code
    input wire[`CSRAddressBus] csr_in,
    input wire[`RegBus] csr_data_in,

    //to ex_mem and id
    output reg[`RegAddressBus] rd_address,
    output reg[`RegBus] rd_data, //rd_data or rs2(mem write)
    output reg[`InstShort] inst_out, //inst short code
    output reg[`AddressBus] mem_address,
    output reg ex_ld, // to id
    output reg ex_rd_done, // to id
    output reg[`CSRAddressBus] csr_out,
    output reg csr_write_enable_out,
    output reg[`RegBus] csr_write_data_out,

    //jump
    output reg jump_enable,
    output reg[`AddressBus] jump_target
);

    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            rd_address=0;
            rd_data=0;
            inst_out=`instNOP;
            mem_address=0;
            ex_ld=0;
            ex_rd_done=0;
            jump_enable=0;
            jump_target=0;
            csr_out=0;
            csr_write_data_out=0;
            csr_write_enable_out=0;
        end else begin
            rd_address=rd_in;
            inst_out=inst_in;
            rd_data=0;
            mem_address=0;
            ex_ld=0;
            ex_rd_done=0;
            jump_enable=0;
            jump_target=0;
            csr_out=csr_in;
            csr_write_data_out=0;
            csr_write_enable_out=0;
            case (inst_in)
                `instNOP: begin
                    rd_address=0;
                end
                `instLUI: begin
                    rd_data=imm_in;
                    ex_rd_done=1;
                end
                `instAUIPC: begin
                    rd_data=pc_in+imm_in;
                    ex_rd_done=1;
                end
                `instJAL: begin
                    rd_data=pc_in+4;
                    ex_rd_done=1;
                    jump_enable=1;
                    jump_target=pc_in+imm_in;
                end
                `instJALR: begin
                    rd_data=pc_in+4;
                    ex_rd_done=1;
                    jump_enable=1;
                    jump_target=(rs1_in+imm_in)&32'hFFFFFFFE;
                end
                `instBEQ: begin
                    if (rs1_in==rs2_in) begin
                        jump_enable=1;
                        jump_target=pc_in+imm_in;
                    end
                end
                `instBNE: begin
                    if (rs1_in!=rs2_in) begin
                        jump_enable=1;
                        jump_target=pc_in+imm_in;
                    end
                end
                `instBLT: begin
                    if ($signed(rs1_in)<$signed(rs2_in)) begin
                        jump_enable=1;
                        jump_target=pc_in+imm_in;
                    end
                end
                `instBGE: begin
                    if ($signed(rs1_in)>=$signed(rs2_in)) begin
                        jump_enable=1;
                        jump_target=pc_in+imm_in;
                    end
                end
                `instBLTU: begin
                    if (rs1_in<rs2_in) begin
                        jump_enable=1;
                        jump_target=pc_in+imm_in;
                    end
                end
                `instBGEU: begin
                    if (rs1_in>=rs2_in) begin
                        jump_enable=1;
                        jump_target=pc_in+imm_in;
                    end
                end
                `instLB,`instLH,`instLW,`instLBU,`instLHU: begin
                    mem_address=rs1_in+imm_in;
                    ex_ld=1;
                end
                `instSB,`instSH,`instSW: begin
                    mem_address=rs1_in+imm_in;
                    rd_data=rs2_in;
                end
                `instADDI: begin
                    rd_data=rs1_in+imm_in;
                    ex_rd_done=1;
                end
                `instSLTI: begin
                    rd_data=$signed(rs1_in)<$signed(imm_in);
                    ex_rd_done=1;
                end
                `instSLTIU: begin
                    rd_data=rs1_in<imm_in;
                    ex_rd_done=1;
                end
                `instXORI: begin
                    rd_data=rs1_in^imm_in;
                    ex_rd_done=1;
                end
                `instORI: begin
                    rd_data=rs1_in|imm_in;
                    ex_rd_done=1;
                end
                `instANDI: begin
                    rd_data=rs1_in&imm_in;
                    ex_rd_done=1;
                end
                `instSLLI: begin
                    rd_data=rs1_in<<imm_in[4:0];
                    ex_rd_done=1;
                end
                `instSRLI: begin
                    rd_data=rs1_in>>imm_in[4:0];
                    ex_rd_done=1;
                end
                `instSRAI: begin
                    rd_data=$signed(rs1_in)>>imm_in[4:0];
                    ex_rd_done=1;
                end
                `instADD: begin
                    rd_data=rs1_in+rs2_in;
                    ex_rd_done=1;
                end
                `instSUB: begin
                    rd_data=rs1_in-rs2_in;
                    ex_rd_done=1;
                end
                `instSLL: begin
                    rd_data=rs1_in<<rs2_in[4:0];
                    ex_rd_done=1;
                end
                `instSLT: begin
                    rd_data=$signed(rs1_in)<$signed(rs2_in);
                    ex_rd_done=1;
                end
                `instSLTU: begin
                    rd_data=rs1_in<rs2_in;
                    ex_rd_done=1;
                end
                `instXOR: begin
                    rd_data=rs1_in^rs2_in;
                    ex_rd_done=1;
                end
                `instSRL: begin
                    rd_data=rs1_in>>rs2_in[4:0];
                    ex_rd_done=1;
                end
                `instSRA: begin
                    rd_data=$signed(rs1_in)>>rs2_in[4:0];
                    ex_rd_done=1;
                end
                `instOR: begin
                    rd_data=rs1_in|rs2_in;
                    ex_rd_done=1;
                end
                `instAND: begin
                    rd_data=rs1_in&rs2_in;
                    ex_rd_done=1;
                end
                `instCSRRW: begin
                    csr_write_data_out=rs1_in;
                    rd_data=csr_data_in;
                    csr_write_enable_out=1;
                end
                `instCSRRS: begin
                    csr_write_data_out=csr_data_in|rs1_in;
                    rd_data=csr_data_in;
                    csr_write_enable_out=1;
                end
                `instCSRRC: begin
                    csr_write_data_out=csr_data_in&(~rs1_in);
                    rd_data=csr_data_in;
                    csr_write_enable_out=1;
                end
                `instCSRRWI: begin
                    csr_write_data_out=imm_in;
                    rd_data=csr_data_in;
                    csr_write_enable_out=1;
                end
                `instCSRRSI: begin
                    csr_write_data_out=csr_data_in|imm_in;
                    rd_data=csr_data_in;
                    csr_write_enable_out=1;
                end
                `instCSRRCI: begin
                    csr_write_data_out=csr_data_in&(~imm_in);
                    rd_data=csr_data_in;
                    csr_write_enable_out=1;
                end
                `instMRET: begin
                    jump_enable=1;
                    jump_target=csr_data_in;
                end
                default: begin
                    rd_address=0;
                end
            endcase
        end
    end
endmodule