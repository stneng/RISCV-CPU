`include "defines.v"
module If (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //pc_reg
    input wire[`AddressBus] pc_in,
    //memctrl
    input wire inst_done,
    input wire[`InstBus] inst_in,
    output reg mem_pc_get,
    output reg[`AddressBus] mem_pc_out,
    //if_id
    output reg[`AddressBus] pc_out,
    output reg[`InstBus] inst_out,

    output reg stall_out
);

    reg[`InstBus] icache[0:`IcacheSize-1];
    reg[`IcacheTagBus] icache_tag[0:`IcacheSize-1];
    reg icache_valid[0:`IcacheSize-1];
    integer i;

    always @(posedge clk_in) begin
        if (rst_in==1) begin
            for (i=0;i<`IcacheSize;i=i+1) begin
                icache_valid[i]<=0;
            end
            mem_pc_out<=0;
        end else if (rdy_in==1) begin
            if (inst_done==1) begin
                icache[pc_in[`IcacheIndex]]<=inst_in;
                icache_tag[pc_in[`IcacheIndex]]<=pc_in[`IcacheTag];
                icache_valid[pc_in[`IcacheIndex]]<=1;
                mem_pc_out<=pc_in+4;
            end else begin
                mem_pc_out<=pc_in;
            end
        end
    end
    always @(*) begin
        if (rst_in==1) begin
            pc_out=0;
            inst_out=0;
            stall_out=0;
            mem_pc_get=0;
        end else if (rdy_in==1) begin
            if (inst_done==1) begin
                pc_out=pc_in;
                inst_out=inst_in;
                stall_out=0;
                mem_pc_get=0;
            end else if (icache_valid[pc_in[`IcacheIndex]]==1 && icache_tag[pc_in[`IcacheIndex]]==pc_in[`IcacheTag]) begin
                pc_out=pc_in;
                inst_out=icache[pc_in[`IcacheIndex]];
                stall_out=0;
                mem_pc_get=0;
            end else begin
                pc_out=0;
                inst_out=0;
                stall_out=1;
                mem_pc_get=1;
            end
        end else begin
            pc_out=0;
            inst_out=0;
            stall_out=0;
            mem_pc_get=0;
        end
    end
endmodule