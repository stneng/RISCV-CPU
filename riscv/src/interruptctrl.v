`include "defines.v"
module interruptctrl (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire interrupt_enable,
    input wire[2:0] interrupt_cause,
    //pc_reg
    input wire[`AddressBus] pc_in,

    //csr
    output reg csr_read2_enable,
    output reg[`CSRAddressBus] csr_read2_address,
    input wire[`RegBus] csr_read2_data,
    output reg csr_write2_enable,
    output reg[`CSRAddressBus] csr_write2_address,
    output reg[`RegBus] csr_write2_data,

    //jump
    output reg jump_enable,
    output reg[`AddressBus] jump_target,

    output reg stall_out
);
    reg[4:0] cnt;
    reg[2:0] cause;
    always @(posedge clk_in) begin
        if (rst_in) begin
            csr_read2_enable<=0;
            csr_read2_address<=0;
            csr_write2_enable<=0;
            csr_write2_address<=0;
            csr_write2_data<=0;
            jump_enable<=0;
            jump_target<=0;
            stall_out<=0;
            cnt<=0;
            cause<=0;
        end else if (rdy_in==1) begin
            if (interrupt_enable==1) begin
                cnt<=1;
                cause<=interrupt_cause;
                stall_out<=1;
                csr_read2_enable<=1;
                csr_read2_address<=`csrmtvec;
            end else if (cnt>0) begin
                if (cnt<10) begin
                    cnt<=cnt+1;
                end else if (cnt==10) begin
                    cnt<=cnt+1;
                    jump_enable<=1;
                    jump_target<=csr_read2_data[31:2]+4*interrupt_cause;
                    csr_write2_enable<=1;
                    csr_write2_address<=`csrmepc;
                    csr_write2_data<=pc_in;
                end else begin
                    csr_read2_enable<=0;
                    csr_read2_address<=0;
                    csr_write2_enable<=0;
                    csr_write2_address<=0;
                    csr_write2_data<=0;
                    jump_enable<=0;
                    jump_target<=0;
                    stall_out<=0;
                    cnt<=0;
                    cause<=0;
                end
            end
        end
    end
endmodule