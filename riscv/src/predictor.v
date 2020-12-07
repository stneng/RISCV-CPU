`include "defines.v"
module predictor (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire[`AddressBus] pc_in,
    output reg[`AddressBus] next_pc_out,
    output reg branch_taken_out,

    input wire write_enable,
    input wire[`AddressBus] write_pc,
    input wire[`AddressBus] write_target,
    input wire write_taken
);
    reg[`AddressBus] target[0:`predictorSize-1];
    reg[`predictorTagBus] tag[0:`predictorSize-1];
    reg[1:0] cnt[0:`predictorSize-1];
    integer i;
    always @(posedge clk_in) begin
        if (rst_in==1) begin
            for (i=0;i<`predictorSize;i=i+1) begin
                cnt[i]<=0;
            end
        end else if (rdy_in==1) begin
            if (write_enable==1) begin
                target[write_pc[`predictorIndex]]<=write_target;
                tag[write_pc[`predictorIndex]]<=write_pc[`predictorTag];
                if (write_taken==1 && cnt[write_pc[`predictorIndex]]<3) cnt[write_pc[`predictorIndex]]<=cnt[write_pc[`predictorIndex]]+1;
                if (write_taken==0 && cnt[write_pc[`predictorIndex]]>0) cnt[write_pc[`predictorIndex]]<=cnt[write_pc[`predictorIndex]]-1;
            end
        end
    end

    always @(*) begin
        if (rst_in==1) begin
            next_pc_out=0;
            branch_taken_out=0;
        end else if (rdy_in==1) begin
            if (tag[pc_in[`predictorIndex]]==pc_in[`predictorTag] && cnt[pc_in[`predictorIndex]][1]==1) begin
                next_pc_out=target[pc_in[`predictorIndex]];
                branch_taken_out=1;
            end else begin
                next_pc_out=pc_in+4;
                branch_taken_out=0;
            end
        end else begin
            next_pc_out=0;
            branch_taken_out=0;
        end
    end
endmodule