`include "defines.v"
module register (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    
    input wire write_enable,
    input wire[`RegAddressBus] write_address,
    input wire[`RegBus] write_data,

    input wire read1_enable,
    input wire[`RegAddressBus] read1_address,
    output reg[`RegBus] read1_data,

    input wire read2_enable,
    input wire[`RegAddressBus] read2_address,
    output reg[`RegBus] read2_data
);
    reg[`RegBus] regs[1:31];
    integer i;
    always @(posedge clk_in) begin
        if (rst_in==1) begin
            for (i=1;i<32;i=i+1) begin
                regs[i]<=0;
            end
        end else if (rdy_in==1 && write_enable==1 && write_address!=0) begin
            regs[write_address]<=write_data;
        end
    end
    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            read1_data=0;
        end else if (read1_address==0) begin
            read1_data=0;
        end else if (read1_enable==1) begin
            if (write_enable==1 && write_address==read1_address) begin
                read1_data=write_data;
            end else begin
                read1_data=regs[read1_address];
            end
        end else begin
            read1_data=0;
        end
    end
    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            read2_data=0;
        end else if (read2_address==0) begin
            read2_data=0;
        end else if (read2_enable==1) begin
            if (write_enable==1 && write_address==read2_address) begin
                read2_data=write_data;
            end else begin
                read2_data=regs[read2_address];
            end
        end else begin
            read2_data=0;
        end
    end
endmodule