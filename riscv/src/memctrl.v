`include "defines.v"
module memctrl (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input wire io_buffer_full,
    //ram
    input  wire[ 7:0]          ram_din,			// data input bus
    output reg [ 7:0]          ram_dout,		// data output bus
    output reg [31:0]          ram_a,			// address bus (only 17:0 is used)
    output reg                 ram_wr,			// write/read signal (1 for write)

    //if
    input wire if_pc_get,
    input wire[`AddressBus] if_pc_address,
    output reg if_done,
    output reg[`InstBus] if_out,

    //mem
    input wire mem_get,
    input wire mem_wr,
    input wire[`AddressBus] mem_address,
    input wire[`RegBus] mem_data,
    input wire[2:0] mem_len,
    output reg mem_done,
    output reg[`InstBus] mem_out
);
    reg[1:0] status; //2'b01 if   2'b10 mem_r 2'b11 mem_w
    reg[`AddressBus] current_address;
    reg[7:0] loaddata[0:3];reg[2:0] cnt;

    always @(posedge clk_in) begin
        if (rst_in==1) begin
            status<=2'b00;
            current_address<=0;
            loaddata[0]<=0;loaddata[1]<=0;loaddata[2]<=0;loaddata[3]<=0;
            cnt<=0;
            ram_dout<=0;ram_a<=0;ram_wr<=0;
            if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
        end else if (rdy_in==1) begin
            case (status)
                2'b00: begin
                    if (mem_get==1) begin
                        if (mem_wr==0) begin
                            status<=2'b10;
                            current_address<=mem_address;
                            ram_dout<=0;ram_a<=mem_address;ram_wr<=0;
                        end else if (io_buffer_full==0)begin
                            status<=2'b11;
                            current_address<=mem_address;
                            ram_dout<=mem_data[7:0];ram_a<=mem_address;ram_wr<=1;
                        end else begin
                            status<=2'b00;
                            current_address<=0;
                            ram_dout<=0;ram_a<=0;ram_wr<=0;
                        end
                    end else if (if_pc_get==1) begin
                        status<=2'b01;
                        current_address<=if_pc_address;
                        ram_dout<=0;ram_a<=if_pc_address;ram_wr<=0;
                    end else begin
                        status<=2'b00;
                        current_address<=0;
                        ram_dout<=0;ram_a<=0;ram_wr<=0;
                    end
                    cnt<=0;
                    if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                end
                2'b01: begin
                    if (current_address==if_pc_address) begin
                        if (cnt==1) begin
                            loaddata[0]<=ram_din;
                        end else if (cnt==2) begin
                            loaddata[1]<=ram_din;
                        end else if (cnt==3) begin
                            loaddata[2]<=ram_din;
                        end
                        if (cnt==3) begin
                            status<=2'b01;cnt<=cnt+1;
                            current_address<=if_pc_address;
                            ram_dout<=0;ram_a<=0;ram_wr<=0;
                            if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                        end else if (cnt==4) begin
                            if_done<=1;if_out<={ram_din,loaddata[2],loaddata[1],loaddata[0]};mem_done<=0;mem_out<=0;
                            // check mem
                            cnt<=0;
                            if (mem_get==1) begin
                                if (mem_wr==0) begin
                                    status<=2'b10;
                                    current_address<=mem_address;
                                    ram_dout<=0;ram_a<=mem_address;ram_wr<=0;
                                end else if (io_buffer_full==0)begin
                                    status<=2'b11;
                                    current_address<=mem_address;
                                    ram_dout<=mem_data[7:0];ram_a<=mem_address;ram_wr<=1;
                                end else begin
                                    status<=2'b00;
                                    current_address<=0;
                                    ram_dout<=0;ram_a<=0;ram_wr<=0;
                                end
                            end else begin
                                status<=2'b00;
                                current_address<=0;
                                ram_dout<=0;ram_a<=0;ram_wr<=0;
                            end
                        end else begin
                            status<=2'b01;cnt<=cnt+1;
                            current_address<=if_pc_address;
                            ram_dout<=0;ram_a<=if_pc_address+cnt+1;ram_wr<=0;
                            if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                        end
                    end else begin
                        // WTF
                        status<=2'b00;
                        current_address<=0;
                        loaddata[0]<=0;loaddata[1]<=0;loaddata[2]<=0;loaddata[3]<=0;
                        cnt<=0;
                        ram_dout<=0;ram_a<=0;ram_wr<=0;
                        if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                    end
                end
                2'b10: begin
                    if (current_address==mem_address) begin
                        if (cnt==1) begin
                            loaddata[0]<=ram_din;
                        end else if (cnt==2) begin
                            loaddata[1]<=ram_din;
                        end else if (cnt==3) begin
                            loaddata[2]<=ram_din;
                        end
                        if (cnt==mem_len-1) begin
                            status<=2'b10;cnt<=cnt+1;
                            current_address<=mem_address;
                            ram_dout<=0;ram_a<=0;ram_wr<=0;
                            if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                        end else if (cnt==mem_len) begin
                            if_done<=0;if_out<=0;mem_done<=1;
                            case (mem_len)
                                1: mem_out<=ram_din;
                                2: mem_out<={ram_din,loaddata[0]};
                                4: mem_out<={ram_din,loaddata[2],loaddata[1],loaddata[0]};
                                default: mem_out<=0;
                            endcase
                            // check if
                            cnt<=0;
                            if (if_pc_get==1) begin
                                status<=2'b01;
                                current_address<=if_pc_address;
                                ram_dout<=0;ram_a<=if_pc_address;ram_wr<=0;
                            end else begin
                                status<=2'b00;
                                current_address<=0;
                                ram_dout<=0;ram_a<=0;ram_wr<=0;
                            end
                        end else begin
                            status<=2'b10;cnt<=cnt+1;
                            current_address<=mem_address;
                            ram_dout<=0;ram_a<=mem_address+cnt+1;ram_wr<=0;
                            if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                        end
                    end else begin
                        // WTF
                        status<=2'b00;
                        current_address<=0;
                        loaddata[0]<=0;loaddata[1]<=0;loaddata[2]<=0;loaddata[3]<=0;
                        cnt<=0;
                        ram_dout<=0;ram_a<=0;ram_wr<=0;
                        if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                    end
                end
                2'b11: begin
                    if (current_address==mem_address) begin
                        if (io_buffer_full==1) begin
                            status<=2'b11;cnt<=cnt;
                            current_address<=mem_address;
                            if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                            ram_dout<=0;ram_a<=0;ram_wr<=0;
                        end else if (cnt==mem_len-1) begin
                            if_done<=0;if_out<=0;mem_done<=1;mem_out<=0;
                            // check if
                            cnt<=0;
                            if (if_pc_get==1) begin
                                status<=2'b01;
                                current_address<=if_pc_address;
                                ram_dout<=0;ram_a<=if_pc_address;ram_wr<=0;
                            end else begin
                                status<=2'b00;
                                current_address<=0;
                                ram_dout<=0;ram_a<=0;ram_wr<=0;
                            end
                        end else begin
                            if (cnt==0) begin
                                ram_dout<=mem_data[15:8];ram_a<=mem_address+1;ram_wr<=1;
                            end else if (cnt==1) begin
                                ram_dout<=mem_data[23:16];ram_a<=mem_address+2;ram_wr<=1;
                            end else if (cnt==2) begin
                                ram_dout<=mem_data[31:24];ram_a<=mem_address+3;ram_wr<=1;
                            end
                            status<=2'b11;cnt<=cnt+1;
                            current_address<=mem_address;
                            if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                        end
                    end else begin
                        // WTF
                        status<=2'b00;
                        current_address<=0;
                        loaddata[0]<=0;loaddata[1]<=0;loaddata[2]<=0;loaddata[3]<=0;
                        cnt<=0;
                        ram_dout<=0;ram_a<=0;ram_wr<=0;
                        if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                    end
                end
                default: begin
                    status<=2'b00;
                    current_address<=0;
                    loaddata[0]<=0;loaddata[1]<=0;loaddata[2]<=0;loaddata[3]<=0;
                    cnt<=0;
                    ram_dout<=0;ram_a<=0;ram_wr<=0;
                    if_done<=0;if_out<=0;mem_done<=0;mem_out<=0;
                end
            endcase
        end
    end
endmodule