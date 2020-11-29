`include "defines.v"
module id (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //if_id
    input wire[`AddressBus] pc_in,
    input wire[`InstBus] inst_in,

    //data from ex and mem
    input wire ex_ld,
    input wire ex_rd_done,
    input wire[`RegAddressBus] ex_rd_address,
    input wire[`RegBus] ex_rd_data,
    input wire mem_rd_done,
    input wire[`RegAddressBus] mem_rd_address,
    input wire[`RegBus] mem_rd_data,
    input wire ex_csr_done,
    input wire[`CSRAddressBus] ex_csr_address,
    input wire[`RegBus] ex_csr_data,
    input wire mem_csr_done,
    input wire[`CSRAddressBus] mem_csr_address,
    input wire[`RegBus] mem_csr_data,

    //register and csr
    output reg read1_enable,
    output reg[`RegAddressBus] read1_address,
    input wire[`RegBus] read1_data,
    output reg read2_enable,
    output reg[`RegAddressBus] read2_address,
    input wire[`RegBus] read2_data,
    output reg csr_read1_enable,
    output reg[`CSRAddressBus] csr_read1_address,
    input wire[`RegBus] csr_read1_data,

    //id_ex
    output reg[`AddressBus] pc_out,
    output reg[`RegBus] rs1_out,
    output reg[`RegBus] rs2_out,
    output reg[`RegAddressBus] rd_out,
    output reg[`RegBus] imm_out,
    output reg[`InstShort] inst_out, //inst short code
    output reg[`CSRAddressBus] csr_out,
    output reg[`RegBus] csr_data_out,

    output wire stall_out
);

    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            pc_out=0;
        end else begin
            pc_out=pc_in;
        end
    end
    wire[6:0] opcode=inst_in[6:0];
    
    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            rd_out=0;
            inst_out=`instNOP;
            read1_enable=0;
            read1_address=0;
            read2_enable=0;
            read2_address=0;
            imm_out=0;
            csr_read1_enable=0;
            csr_read1_address=0;
            csr_out=0;
        end else begin
            csr_read1_enable=0;
            csr_read1_address=0;
            csr_out=0;
            case (opcode)
                'h33: begin
                    case (inst_in[14:12])
                        'h0: begin
                            case (inst_in[31:25])
                                'h0: inst_out=`instADD;
                                'h20: inst_out=`instSUB;
                                default: inst_out=`instNOP;
                            endcase
                        end
                        'h1: inst_out=`instSLL;
                        'h2: inst_out=`instSLT;
                        'h3: inst_out=`instSLTU;
                        'h4: inst_out=`instXOR;
                        'h5: begin
                            case (inst_in[31:25])
                                'h0: inst_out=`instSRL;
                                'h20: inst_out=`instSRA;
                                default: inst_out=`instNOP;
                            endcase
                        end
                        'h6: inst_out=`instOR;
                        'h7: inst_out=`instAND;
                        default: inst_out=`instNOP;
                    endcase
                    rd_out=inst_in[11:7];
                    read1_enable=1;
                    read1_address=inst_in[19:15];
                    read2_enable=1;
                    read2_address=inst_in[24:20];
                    imm_out=0;
                end
                'h67: begin
                    case (inst_in[14:12])
                        'h0: inst_out=`instJALR;
                        default: inst_out=`instNOP;
                    endcase
                    rd_out=inst_in[11:7];
                    read1_enable=1;
                    read1_address=inst_in[19:15];
                    read2_enable=0;
                    read2_address=0;
                    imm_out={{20{inst_in[31]}},inst_in[31:20]};
                end
                'h3: begin
                    case (inst_in[14:12])
                        'h0: inst_out=`instLB;
                        'h1: inst_out=`instLH;
                        'h2: inst_out=`instLW;
                        'h4: inst_out=`instLBU;
                        'h5: inst_out=`instLHU;
                        default: inst_out=`instNOP;
                    endcase
                    rd_out=inst_in[11:7];
                    read1_enable=1;
                    read1_address=inst_in[19:15];
                    read2_enable=0;
                    read2_address=0;
                    imm_out={{20{inst_in[31]}},inst_in[31:20]};
                end
                'h13: begin
                    case (inst_in[14:12])
                        'h0: inst_out=`instADDI;
                        'h2: inst_out=`instSLTI;
                        'h3: inst_out=`instSLTIU;
                        'h4: inst_out=`instXORI;
                        'h6: inst_out=`instORI;
                        'h7: inst_out=`instANDI;
                        'h1: inst_out=`instSLLI;
                        'h5: begin
                            case (inst_in[31:25])
                                'h0: inst_out=`instSRLI;
                                'h20: inst_out=`instSRAI;
                                default: inst_out=`instNOP;
                            endcase
                        end
                        default: inst_out=`instNOP;
                    endcase
                    rd_out=inst_in[11:7];
                    read1_enable=1;
                    read1_address=inst_in[19:15];
                    read2_enable=0;
                    read2_address=0;
                    imm_out={{20{inst_in[31]}},inst_in[31:20]};
                end
                'h23: begin
                    case (inst_in[14:12])
                        'h0: inst_out=`instSB;
                        'h1: inst_out=`instSH;
                        'h2: inst_out=`instSW;
                        default: inst_out=`instNOP;
                    endcase
                    rd_out=0;
                    read1_enable=1;
                    read1_address=inst_in[19:15];
                    read2_enable=1;
                    read2_address=inst_in[24:20];
                    imm_out={{20{inst_in[31]}},inst_in[31:25],inst_in[11:7]};
                end
                'h63: begin
                    case (inst_in[14:12])
                        'h0: inst_out=`instBEQ;
                        'h1: inst_out=`instBNE;
                        'h4: inst_out=`instBLT;
                        'h5: inst_out=`instBGE;
                        'h6: inst_out=`instBLTU;
                        'h7: inst_out=`instBGEU;
                        default: inst_out=`instNOP;
                    endcase
                    rd_out=0;
                    read1_enable=1;
                    read1_address=inst_in[19:15];
                    read2_enable=1;
                    read2_address=inst_in[24:20];
                    imm_out={{20{inst_in[31]}},inst_in[7],inst_in[30:25],inst_in[11:8],1'b0};
                end
                'h37: begin
                    inst_out=`instLUI;
                    rd_out=inst_in[11:7];
                    read1_enable=0;
                    read1_address=0;
                    read2_enable=0;
                    read2_address=0;
                    imm_out={inst_in[31:12],{12{1'b0}}};
                end
                'h17: begin
                    inst_out=`instAUIPC;
                    rd_out=inst_in[11:7];
                    read1_enable=0;
                    read1_address=0;
                    read2_enable=0;
                    read2_address=0;
                    imm_out={inst_in[31:12],{12{1'b0}}};
                end
                'h6F: begin
                    inst_out=`instJAL;
                    rd_out=inst_in[11:7];
                    read1_enable=0;
                    read1_address=0;
                    read2_enable=0;
                    read2_address=0;
                    imm_out={{12{inst_in[31]}},inst_in[19:12],inst_in[20],inst_in[30:25],inst_in[24:21],1'b0};
                end
                'h73: begin
                    case (inst_in[14:12])
                        'h1: inst_out=`instCSRRW;
                        'h2: inst_out=`instCSRRS;
                        'h3: inst_out=`instCSRRC;
                        'h5: inst_out=`instCSRRWI;
                        'h6: inst_out=`instCSRRSI;
                        'h7: inst_out=`instCSRRCI;
                        default: inst_out=`instNOP;
                    endcase
                    case (inst_in[14:12])
                        'h1,'h2,'h3: begin
                            read1_enable=1;
                            imm_out=0;
                        end
                        'h5,'h6,'h7: begin
                            read1_enable=0;
                            imm_out=inst_in[19:15];
                        end
                        default: begin
                            read1_enable=0;
                            imm_out=0;
                        end
                    endcase
                    rd_out=inst_in[11:7];
                    read1_address=inst_in[19:15];
                    read2_enable=0;
                    read2_address=0;
                    csr_out=inst_in[31:20];
                    csr_read1_enable=1;
                    csr_read1_address=inst_in[31:20];
                end
                default: begin
                    inst_out=`instNOP;
                    rd_out=0;
                    read1_enable=0;
                    read1_address=0;
                    read2_enable=0;
                    read2_address=0;
                    imm_out=0;
                end
            endcase
        end
    end

    reg reg1_stall;
    always @(*) begin
        reg1_stall=0;
        if (rst_in==1 || rdy_in==0 || read1_address==0) begin
            rs1_out=0;
        end else if (read1_enable==1 && ex_ld==1 && ex_rd_address==read1_address) begin
            rs1_out=0;
            reg1_stall=1;
        end else if (read1_enable==1 && ex_rd_done==1 && ex_rd_address==read1_address) begin
            rs1_out=ex_rd_data;
        end else if (read1_enable==1 && mem_rd_done==1 && mem_rd_address==read1_address) begin
            rs1_out=mem_rd_data;
        end else if (read1_enable==1) begin
            rs1_out=read1_data;
        end else begin
            rs1_out=0;
        end
    end
    reg reg2_stall;
    always @(*) begin
        reg2_stall=0;
        if (rst_in==1 || rdy_in==0 || read2_address==0) begin
            rs2_out=0;
        end else if (read2_enable==1 && ex_ld==1 && ex_rd_address==read2_address) begin
            rs2_out=0;
            reg2_stall=1;
        end else if (read2_enable==1 && ex_rd_done==1 && ex_rd_address==read2_address) begin
            rs2_out=ex_rd_data;
        end else if (read2_enable==1 && mem_rd_done==1 && mem_rd_address==read2_address) begin
            rs2_out=mem_rd_data;
        end else if (read2_enable==1) begin
            rs2_out=read2_data;
        end else begin
            rs2_out=0;
        end
    end
    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            csr_data_out=0;
        end else if (csr_read1_enable==1 && ex_csr_done==1 && ex_csr_address==csr_read1_address) begin
            csr_data_out=ex_csr_data;
        end else if (csr_read1_enable==1 && mem_csr_done==1 && mem_csr_address==csr_read1_address) begin
            csr_data_out=mem_csr_data;
        end else if (csr_read1_enable==1) begin
            csr_data_out=csr_read1_data;
        end else begin
            csr_data_out=0;
        end
    end
    assign stall_out=reg1_stall|reg2_stall;
endmodule