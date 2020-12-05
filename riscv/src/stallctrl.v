`include "defines.v"
module stallctrl (
    input wire if_stall_in,
    input wire id_stall_in,
    input wire mem_stall_in,
    input wire interrupt_stall_in,

    output reg[`StallBus] stall_out
);
    always @(*) begin
        if (mem_stall_in==1) begin
            stall_out<=6'b011111;
        end else if (id_stall_in==1) begin
            stall_out<=6'b000111;
        end else if (if_stall_in==1 || interrupt_stall_in==1) begin
            stall_out<=6'b000011;
        end else begin
            stall_out<=6'b000000;
        end
    end
endmodule