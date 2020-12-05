`include "defines.v"
module csr (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    
    input wire write1_enable,
    input wire[`CSRAddressBus] write1_address,
    input wire[`RegBus] write1_data,

    input wire write2_enable,
    input wire[`CSRAddressBus] write2_address,
    input wire[`RegBus] write2_data,

    input wire read1_enable,
    input wire[`CSRAddressBus] read1_address,
    output reg[`RegBus] read1_data,

    input wire read2_enable,
    input wire[`CSRAddressBus] read2_address,
    output reg[`RegBus] read2_data
);
    reg[`RegBus] regs[0:11];
    integer i;
    wire[3:0] short_write1_address;assign short_write1_address=((write1_address[6]==1)?7:0)+write1_address[3:0];
    wire[3:0] short_write2_address;assign short_write2_address=((write2_address[6]==1)?7:0)+write2_address[3:0];
    wire[3:0] short_read1_address;assign short_read1_address=((read1_address[6]==1)?7:0)+read1_address[3:0];
    wire[3:0] short_read2_address;assign short_read2_address=((read2_address[6]==1)?7:0)+read2_address[3:0];

    always @(posedge clk_in) begin
        if (rst_in==1) begin
            for (i=0;i<12;i=i+1) begin
                regs[i]<=0;
            end
        end else if (rdy_in==1) begin
            if (write1_enable==1) begin
                regs[short_write1_address]<=write1_data;
            end
            if (write2_enable==1) begin
                regs[short_write2_address]<=write2_data;
            end
        end
    end
    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            read1_data=0;
        end else if (read1_enable==1) begin
            if (write1_enable==1 && short_write1_address==short_read1_address) begin
                read1_data=write1_data;
            end else if (write2_enable==1 && short_write2_address==short_read2_address) begin
                read1_data=write2_data;
            end else begin
                read1_data=regs[short_read1_address];
            end
        end else begin
            read1_data=0;
        end
    end
    always @(*) begin
        if (rst_in==1 || rdy_in==0) begin
            read2_data=0;
        end else if (read2_enable==1) begin
            if (write1_enable==1 && short_write1_address==short_read2_address) begin
                read2_data=write1_data;
            end else if (write2_enable==1 && short_write2_address==short_read2_address) begin
                read2_data=write2_data;
            end else begin
                read2_data=regs[short_read2_address];
            end
        end else begin
            read2_data=0;
        end
    end
endmodule