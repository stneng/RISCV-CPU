`include "defines.v"
module mem (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //ex_mem
    input wire[`RegAddressBus] rd_address_in,
    input wire[`RegBus] rd_data_in, //rd_data or rs2(mem write)
    input wire[`InstShort] inst_in, //inst short code
    input wire[`AddressBus] mem_address_in,
    input wire[`CSRAddressBus] csr_in,
    input wire csr_write_enable_in,
    input wire[`RegBus] csr_write_data_in,

    //memctrl
    input wire mem_done,
    input wire[`InstBus] mem_out,
    output reg mem_get,
    output reg mem_wr,
    output reg[`AddressBus] mem_address,
    output reg[`RegBus] mem_data,
    output reg[2:0] mem_len,

    //to mem_wb and id
    output reg[`RegAddressBus] rd_address,
    output reg[`RegBus] rd_data,
    output reg mem_rd_done, // to id
    output reg[`CSRAddressBus] csr_out,
    output reg csr_write_enable_out,
    output reg[`RegBus] csr_write_data_out,

    output reg stall_out
);
    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            mem_get<=0;
            mem_wr<=0;
            mem_address<=0;
            mem_data<=0;
            mem_len<=0;
            rd_address<=0;
            rd_data<=0;
            mem_rd_done<=0;
            csr_out<=0;
            csr_write_enable_out<=0;
            csr_write_data_out<=0;
            stall_out<=0;
        end else begin
            case (inst_in)
                `instNOP: begin
                    mem_get<=0;
                    mem_wr<=0;
                    mem_address<=0;
                    mem_data<=0;
                    mem_len<=0;
                    rd_address<=rd_address_in;
                    rd_data<=rd_data_in;
                    mem_rd_done<=0;
                    csr_out<=0;
                    csr_write_enable_out<=0;
                    csr_write_data_out<=0;
                    stall_out<=0;
                end
                `instLB,`instLH,`instLW,`instLBU,`instLHU: begin
                    if (mem_done) begin
                        mem_get<=0;
                        mem_wr<=0;
                        mem_address<=0;
                        mem_data<=0;
                        mem_len<=0;
                        rd_address<=rd_address_in;
                        case (inst_in)
                            `instLB: rd_data<={{24{mem_out[7]}},mem_out[7:0]};
                            `instLH: rd_data<={{16{mem_out[15]}},mem_out[15:0]};
                            `instLW: rd_data<=mem_out;
                            `instLBU: rd_data<=mem_out[7:0];
                            `instLHU: rd_data<=mem_out[15:0];
                            default: rd_data<=0;
                        endcase
                        mem_rd_done<=1;
                        stall_out<=0;
                    end else begin
                        mem_get<=1;
                        mem_wr<=0;
                        mem_address<=mem_address_in;
                        mem_data<=0;
                        case (inst_in)
                            `instLB,`instLBU: mem_len<=1;
                            `instLH,`instLHU: mem_len<=2;
                            `instLW: mem_len<=4;
                            default: mem_len<=0;
                        endcase
                        rd_address<=rd_address_in;
                        rd_data<=0;
                        mem_rd_done<=0;
                        stall_out<=1;
                    end
                    csr_out<=0;
                    csr_write_enable_out<=0;
                    csr_write_data_out<=0;
                end
                `instSB,`instSH,`instSW: begin
                    if (mem_done) begin
                        mem_get<=0;
                        mem_wr<=0;
                        mem_address<=0;
                        mem_data<=0;
                        mem_len<=0;
                        rd_address<=0;
                        rd_data<=0;
                        mem_rd_done<=0;
                        stall_out<=0;
                    end else begin
                        mem_get<=1;
                        mem_wr<=1;
                        mem_address<=mem_address_in;
                        case (inst_in)
                            `instSB: begin
                                mem_data<=rd_data_in[7:0];
                                mem_len<=1;
                            end
                            `instSH: begin
                                mem_data<=rd_data_in[15:0];
                                mem_len<=2;
                            end
                            `instSW: begin
                                mem_data<=rd_data_in;
                                mem_len<=4;
                            end
                            default: begin
                                mem_data<=0;
                                mem_len<=0;
                            end
                        endcase
                        rd_address<=0;
                        rd_data<=0;
                        mem_rd_done<=0;
                        stall_out<=1;
                    end
                    csr_out<=0;
                    csr_write_enable_out<=0;
                    csr_write_data_out<=0;
                end
                default: begin
                    mem_get<=0;
                    mem_wr<=0;
                    mem_address<=0;
                    mem_data<=0;
                    mem_len<=0;
                    rd_address<=rd_address_in;
                    rd_data<=rd_data_in;
                    mem_rd_done<=1;
                    csr_out<=csr_in;
                    csr_write_enable_out<=csr_write_enable_in;
                    csr_write_data_out<=csr_write_data_in;
                    stall_out<=0;
                end
            endcase
        end
    end
endmodule