`include "defines.v"
module mem_wb (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire[`StallBus] stall_in,
    
    //mem
    input wire[`RegAddressBus] rd_address_in,
    input wire[`RegBus] rd_data_in,
    input wire[`CSRAddressBus] csr_in,
    input wire csr_write_enable_in,
    input wire[`RegBus] csr_write_data_in,

    //wb
    output reg[`RegAddressBus] rd_address,
    output reg[`RegBus] rd_data,
    output reg[`CSRAddressBus] csr_out,
    output reg csr_write_enable_out,
    output reg[`RegBus] csr_write_data_out
);
    always @(posedge clk_in) begin
        if (rst_in==1) begin
            rd_address<=0;
            rd_data<=0;
            csr_out<=0;
            csr_write_enable_out<=0;
            csr_write_data_out<=0;
        end else if (rdy_in==1) begin
            if (stall_in[5]==1) begin
                ;
            end else if (stall_in[4]==0) begin
                rd_address<=rd_address_in;
                rd_data<=rd_data_in;
                csr_out<=csr_in;
                csr_write_enable_out<=csr_write_enable_in;
                csr_write_data_out<=csr_write_data_in;
            end else begin
                rd_address<=0;
                rd_data<=0;
                csr_out<=0;
                csr_write_enable_out<=0;
                csr_write_data_out<=0;
            end
        end
    end
endmodule