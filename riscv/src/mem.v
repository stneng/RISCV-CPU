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
    reg[`RegBus] dcache[0:`DcacheSize-1];
    reg[`DcacheTagBus] dcache_tag[0:`DcacheSize-1];
    reg[2:0] dcache_len[0:`DcacheSize-1];
    reg dcache_valid[0:`DcacheSize-1];reg dcache_dirty[0:`DcacheSize-1];
    reg[`AddressBus] last_mem_address;reg last_mem_wr;
    integer i;

    wire current_mem_wr;
    wire[2:0] current_mem_len;
    assign current_mem_wr=(inst_in==`instSB||inst_in==`instSH||inst_in==`instSW)?1:0;
    assign current_mem_len=(inst_in==`instLB||inst_in==`instLBU||inst_in==`instSB)?1:
                           (inst_in==`instLH||inst_in==`instLHU||inst_in==`instSH)?2:
                           (inst_in==`instLW||inst_in==`instSW)?4:0;

    always @(posedge clk_in) begin
        if (rst_in==1) begin
            last_mem_wr<=0;
            for (i=0;i<`DcacheSize;i=i+1) begin
                dcache_valid[i]<=0;
                dcache_dirty[i]<=0;
            end
        end else if (rdy_in==1 && mem_address_in<='h20000) begin
            last_mem_address<=mem_address;last_mem_wr<=mem_wr;
            if (mem_done==1 && last_mem_wr==0) begin
                dcache[last_mem_address[`DcacheIndex]]<=mem_out;
                dcache_tag[last_mem_address[`DcacheIndex]]<=last_mem_address[`DcacheTag];
                dcache_valid[last_mem_address[`DcacheIndex]]<=1;
                dcache_dirty[last_mem_address[`DcacheIndex]]<=0;
                dcache_len[last_mem_address[`DcacheIndex]]<=current_mem_len;
            end
            if (mem_done==1 && last_mem_wr==1) begin
                dcache_valid[last_mem_address[`DcacheIndex]]<=0;
                dcache_dirty[last_mem_address[`DcacheIndex]]<=0;
            end
            if (current_mem_wr==1 &&
                ((dcache_valid[mem_address_in[`DcacheIndex]]==1 && dcache_tag[mem_address_in[`DcacheIndex]]==mem_address_in[`DcacheTag] && dcache_len[mem_address_in[`DcacheIndex]]==current_mem_len) ||
                (dcache_valid[mem_address_in[`DcacheIndex]]==1 && (dcache_tag[mem_address_in[`DcacheIndex]]!=mem_address_in[`DcacheTag] || dcache_len[mem_address_in[`DcacheIndex]]!=current_mem_len) && dcache_dirty[mem_address_in[`DcacheIndex]]==0))) begin
                dcache[mem_address_in[`DcacheIndex]]<=rd_data_in;
                dcache_tag[mem_address_in[`DcacheIndex]]<=mem_address_in[`DcacheTag];
                dcache_valid[mem_address_in[`DcacheIndex]]<=1;
                dcache_dirty[mem_address_in[`DcacheIndex]]<=1;
                dcache_len[mem_address_in[`DcacheIndex]]<=current_mem_len;
            end

        end
    end

    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            mem_get=0;
            mem_wr=0;
            mem_address=0;
            mem_data=0;
            mem_len=0;
            rd_address=0;
            rd_data=0;
            mem_rd_done=0;
            csr_out=0;
            csr_write_enable_out=0;
            csr_write_data_out=0;
            stall_out=0;
        end else begin
            case (inst_in)
                `instNOP: begin
                    mem_get=0;
                    mem_wr=0;
                    mem_address=0;
                    mem_data=0;
                    mem_len=0;
                    rd_address=rd_address_in;
                    rd_data=rd_data_in;
                    mem_rd_done=0;
                    csr_out=0;
                    csr_write_enable_out=0;
                    csr_write_data_out=0;
                    stall_out=0;
                end
                `instLB,`instLH,`instLW,`instLBU,`instLHU: begin
                    if (mem_address_in<='h20000 && dcache_valid[mem_address_in[`DcacheIndex]]==1 && dcache_tag[mem_address_in[`DcacheIndex]]==mem_address_in[`DcacheTag] && dcache_len[mem_address_in[`DcacheIndex]]==current_mem_len) begin
                        mem_get=0;
                        mem_wr=0;
                        mem_address=0;
                        mem_data=0;
                        mem_len=0;
                        rd_address=rd_address_in;
                        rd_data=dcache[mem_address_in[`DcacheIndex]];
                        mem_rd_done=1;
                        stall_out=0;
                    end else if (mem_address_in<='h20000 && dcache_valid[mem_address_in[`DcacheIndex]]==1 && (dcache_tag[mem_address_in[`DcacheIndex]]!=mem_address_in[`DcacheTag] || dcache_len[mem_address_in[`DcacheIndex]]!=current_mem_len) && dcache_dirty[mem_address_in[`DcacheIndex]]==1) begin
                        mem_get=1;
                        mem_wr=1;
                        mem_address=(dcache_tag[mem_address_in[`DcacheIndex]]<<`DcacheIndexLen)+mem_address_in[`DcacheIndex];
                        mem_data=dcache[mem_address_in[`DcacheIndex]];
                        mem_len=dcache_len[mem_address_in[`DcacheIndex]];
                        rd_address=0;
                        rd_data=0;
                        mem_rd_done=0;
                        stall_out=1;
                    end else begin
                        if (mem_done) begin
                            mem_get=0;
                            mem_wr=0;
                            mem_address=0;
                            mem_data=0;
                            mem_len=0;
                            rd_address=rd_address_in;
                            case (inst_in)
                                `instLB: rd_data={{24{mem_out[7]}},mem_out[7:0]};
                                `instLH: rd_data={{16{mem_out[15]}},mem_out[15:0]};
                                `instLW: rd_data=mem_out;
                                `instLBU: rd_data=mem_out[7:0];
                                `instLHU: rd_data=mem_out[15:0];
                                default: rd_data=0;
                            endcase
                            mem_rd_done=1;
                            stall_out=0;
                        end else begin
                            mem_get=1;
                            mem_wr=0;
                            mem_address=mem_address_in;
                            mem_data=0;
                            case (inst_in)
                                `instLB,`instLBU: mem_len=1;
                                `instLH,`instLHU: mem_len=2;
                                `instLW: mem_len=4;
                                default: mem_len=0;
                            endcase
                            rd_address=rd_address_in;
                            rd_data=0;
                            mem_rd_done=0;
                            stall_out=1;
                        end
                    end
                    csr_out=0;
                    csr_write_enable_out=0;
                    csr_write_data_out=0;
                end
                `instSB,`instSH,`instSW: begin
                    if (mem_address_in<='h20000 &&
                        ((dcache_valid[mem_address_in[`DcacheIndex]]==1 && dcache_tag[mem_address_in[`DcacheIndex]]==mem_address_in[`DcacheTag] && dcache_len[mem_address_in[`DcacheIndex]]==current_mem_len) ||
                        (dcache_valid[mem_address_in[`DcacheIndex]]==1 && (dcache_tag[mem_address_in[`DcacheIndex]]!=mem_address_in[`DcacheTag] || dcache_len[mem_address_in[`DcacheIndex]]!=current_mem_len) && dcache_dirty[mem_address_in[`DcacheIndex]]==0))) begin
                        mem_get=0;
                        mem_wr=0;
                        mem_address=0;
                        mem_data=0;
                        mem_len=0;
                        rd_address=0;
                        rd_data=0;
                        mem_rd_done=0;
                        stall_out=0;
                    end else if (mem_address_in<='h20000 && dcache_valid[mem_address_in[`DcacheIndex]]==1 && (dcache_tag[mem_address_in[`DcacheIndex]]!=mem_address_in[`DcacheTag] || dcache_len[mem_address_in[`DcacheIndex]]!=current_mem_len) && dcache_dirty[mem_address_in[`DcacheIndex]]==1) begin
                        mem_get=1;
                        mem_wr=1;
                        mem_address=(dcache_tag[mem_address_in[`DcacheIndex]]<<`DcacheIndexLen)+mem_address_in[`DcacheIndex];
                        mem_data=dcache[mem_address_in[`DcacheIndex]];
                        mem_len=dcache_len[mem_address_in[`DcacheIndex]];
                        rd_address=0;
                        rd_data=0;
                        mem_rd_done=0;
                        stall_out=1;
                    end else begin
                        if (mem_done) begin
                            mem_get=0;
                            mem_wr=0;
                            mem_address=0;
                            mem_data=0;
                            mem_len=0;
                            rd_address=0;
                            rd_data=0;
                            mem_rd_done=0;
                            stall_out=0;
                        end else begin
                            mem_get=1;
                            mem_wr=1;
                            mem_address=mem_address_in;
                            case (inst_in)
                                `instSB: begin
                                    mem_data=rd_data_in[7:0];
                                    mem_len=1;
                                end
                                `instSH: begin
                                    mem_data=rd_data_in[15:0];
                                    mem_len=2;
                                end
                                `instSW: begin
                                    mem_data=rd_data_in;
                                    mem_len=4;
                                end
                                default: begin
                                    mem_data=0;
                                    mem_len=0;
                                end
                            endcase
                            rd_address=0;
                            rd_data=0;
                            mem_rd_done=0;
                            stall_out=1;
                        end
                    end
                    csr_out=0;
                    csr_write_enable_out=0;
                    csr_write_data_out=0;
                end
                default: begin
                    mem_get=0;
                    mem_wr=0;
                    mem_address=0;
                    mem_data=0;
                    mem_len=0;
                    rd_address=rd_address_in;
                    rd_data=rd_data_in;
                    mem_rd_done=1;
                    csr_out=csr_in;
                    csr_write_enable_out=csr_write_enable_in;
                    csr_write_data_out=csr_write_data_in;
                    stall_out=0;
                end
            endcase
        end
    end
endmodule