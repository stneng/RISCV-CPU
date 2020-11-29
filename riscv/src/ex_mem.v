`include "defines.v"
module ex_mem (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire[`StallBus] stall_in,
    
    //ex
    input wire[`RegAddressBus] rd_address_in,
    input wire[`RegBus] rd_data_in, //rd_data or rs2(mem write)
    input wire[`InstShort] inst_in, //inst short code
    input wire[`AddressBus] mem_address_in,
    input wire[`CSRAddressBus] csr_in,
    input wire csr_write_enable_in,
    input wire[`RegBus] csr_write_data_in,

    //mem
    output reg[`RegAddressBus] rd_address,
    output reg[`RegBus] rd_data, //rd_data or rs2(mem write)
    output reg[`InstShort] inst_out, //inst short code
    output reg[`AddressBus] mem_address,
    output reg[`CSRAddressBus] csr_out,
    output reg csr_write_enable_out,
    output reg[`RegBus] csr_write_data_out
);
    always @(posedge clk_in) begin
        if (rst_in==1) begin
            rd_address<=0;
            rd_data<=0;
            inst_out<=`instNOP;
            mem_address<=0;
            csr_out<=0;
            csr_write_enable_out<=0;
            csr_write_data_out<=0;
        end else if (rdy_in==1) begin
            if (stall_in[4]==1) begin
                ;
            end else if (stall_in[3]==0) begin
                rd_address<=rd_address_in;
                rd_data<=rd_data_in;
                inst_out<=inst_in;
                mem_address<=mem_address_in;
                csr_out<=csr_in;
                csr_write_enable_out<=csr_write_enable_in;
                csr_write_data_out<=csr_write_data_in;
            end else begin
                rd_address<=0;
                rd_data<=0;
                inst_out<=`instNOP;
                mem_address<=0;
                csr_out<=0;
                csr_write_enable_out<=0;
                csr_write_data_out<=0;
            end
        end
    end
endmodule