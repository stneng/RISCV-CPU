// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
    input  wire                 rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

    input  wire                 io_buffer_full, // 1 if uart buffer is full

    output wire [31:0]          dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
`include "defines.v"

wire if_stall_in;
wire id_stall_in;
wire mem_stall_in;
wire[`StallBus] stall_in;
stallctrl stallctrl0(
    .if_stall_in(if_stall_in),
    .id_stall_in(id_stall_in),
    .mem_stall_in(mem_stall_in),
    .stall_out(stall_in)
);
wire reg_write_enable;
assign reg_write_enable=1;
wire[`RegAddressBus] reg_write_address;
wire[`RegBus] reg_write_data;
wire reg_read1_enable;
wire[`RegAddressBus] reg_read1_address;
wire[`RegBus] reg_read1_data;
wire reg_read2_enable;
wire[`RegAddressBus] reg_read2_address;
wire[`RegBus] reg_read2_data;
register register0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .write_enable(reg_write_enable),
    .write_address(reg_write_address),
    .write_data(reg_write_data),
    .read1_enable(reg_read1_enable),
    .read1_address(reg_read1_address),
    .read1_data(reg_read1_data),
    .read2_enable(reg_read2_enable),
    .read2_address(reg_read2_address),
    .read2_data(reg_read2_data)
);

wire jump_enable;
wire[`AddressBus] jump_target;

wire[`AddressBus] pc_to_if;
pc_reg pc_reg0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .stall_in(stall_in),
    .jump_enable(jump_enable),
    .jump_target(jump_target),
    .pc(pc_to_if)
);

wire if_mem_inst_done;
wire[`InstBus] if_mem_inst_in;
wire if_mem_pc_get;
wire[`AddressBus] if_mem_pc_out;
wire[`AddressBus] pc_out_to_ifid;
wire[`InstBus] inst_out_to_ifid;
If if0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .pc_in(pc_to_if),
    .inst_done(if_mem_inst_done),
    .inst_in(if_mem_inst_in),
    .mem_pc_get(if_mem_pc_get),
    .mem_pc_out(if_mem_pc_out),
    .pc_out(pc_out_to_ifid),
    .inst_out(inst_out_to_ifid),
    .stall_out(if_stall_in)
);

wire[`AddressBus] pc_out_to_id;
wire[`InstBus] inst_out_to_id;
if_id if_id0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .stall_in(stall_in),
    .jump_enable(jump_enable),
    .pc_in(pc_out_to_ifid),
    .inst_in(inst_out_to_ifid),
    .pc_out(pc_out_to_id),
    .inst_out(inst_out_to_id)
);

wire ex_ld,ex_rd_done;
wire[`RegAddressBus] ex_rd_address;
wire[`RegBus] ex_rd_data;
wire mem_rd_done;
wire[`RegAddressBus] mem_rd_address;
wire[`RegBus] mem_rd_data;
wire[`AddressBus] pc_out_to_idex;
wire[`RegBus] rs1_out_to_idex;
wire[`RegBus] rs2_out_to_idex;
wire[`RegAddressBus] rd_out_to_idex;
wire[`RegBus] imm_out_to_idex;
wire[`InstShort] inst_out_to_idex;
id id0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .pc_in(pc_out_to_id),
    .inst_in(inst_out_to_id),
    .ex_ld(ex_ld),
    .ex_rd_done(ex_rd_done),
    .ex_rd_address(ex_rd_address),
    .ex_rd_data(ex_rd_data),
    .mem_rd_done(mem_rd_done),
    .mem_rd_address(mem_rd_address),
    .mem_rd_data(mem_rd_data),
    .read1_enable(reg_read1_enable),
    .read1_address(reg_read1_address),
    .read1_data(reg_read1_data),
    .read2_enable(reg_read2_enable),
    .read2_address(reg_read2_address),
    .read2_data(reg_read2_data),
    .pc_out(pc_out_to_idex),
    .rs1_out(rs1_out_to_idex),
    .rs2_out(rs2_out_to_idex),
    .rd_out(rd_out_to_idex),
    .imm_out(imm_out_to_idex),
    .inst_out(inst_out_to_idex),
    .stall_out(id_stall_in)
);

wire[`AddressBus] pc_out_to_ex;
wire[`RegBus] rs1_out_to_ex;
wire[`RegBus] rs2_out_to_ex;
wire[`RegAddressBus] rd_out_to_ex;
wire[`RegBus] imm_out_to_ex;
wire[`InstShort] inst_out_to_ex;
id_ex id_ex0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .stall_in(stall_in),
    .jump_enable(jump_enable),
    .pc_in(pc_out_to_idex),
    .rs1_in(rs1_out_to_idex),
    .rs2_in(rs2_out_to_idex),
    .rd_in(rd_out_to_idex),
    .imm_in(imm_out_to_idex),
    .inst_in(inst_out_to_idex),
    .pc_out(pc_out_to_ex),
    .rs1_out(rs1_out_to_ex),
    .rs2_out(rs2_out_to_ex),
    .rd_out(rd_out_to_ex),
    .imm_out(imm_out_to_ex),
    .inst_out(inst_out_to_ex)
);

wire[`InstShort] ex_inst_out;
wire[`AddressBus] ex_mem_address;
ex ex0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .pc_in(pc_out_to_ex),
    .rs1_in(rs1_out_to_ex),
    .rs2_in(rs2_out_to_ex),
    .rd_in(rd_out_to_ex),
    .imm_in(imm_out_to_ex),
    .inst_in(inst_out_to_ex),
    .rd_address(ex_rd_address),
    .rd_data(ex_rd_data),
    .inst_out(ex_inst_out),
    .mem_address(ex_mem_address),
    .ex_ld(ex_ld),
    .ex_rd_done(ex_rd_done),
    .jump_enable(jump_enable),
    .jump_target(jump_target)
);

wire[`RegAddressBus] rd_address_to_mem;
wire[`RegBus] rd_data_to_mem;
wire[`InstShort] inst_out_to_mem;
wire[`AddressBus] mem_address_to_mem;
ex_mem ex_mem0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .stall_in(stall_in),
    .rd_address_in(ex_rd_address),
    .rd_data_in(ex_rd_data),
    .inst_in(ex_inst_out),
    .mem_address_in(ex_mem_address),
    .rd_address(rd_address_to_mem),
    .rd_data(rd_data_to_mem),
    .inst_out(inst_out_to_mem),
    .mem_address(mem_address_to_mem)
);

wire mem_mem_done;
wire[`InstBus] mem_mem_out;
wire mem_mem_get;
wire mem_mem_wr;
wire[`AddressBus] mem_mem_address;
wire[`RegBus] mem_mem_data;
wire[2:0] mem_mem_len;
mem mem0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .rd_address_in(rd_address_to_mem),
    .rd_data_in(rd_data_to_mem),
    .inst_in(inst_out_to_mem),
    .mem_address_in(mem_address_to_mem),
    .mem_done(mem_mem_done),
    .mem_out(mem_mem_out),
    .mem_get(mem_mem_get),
    .mem_wr(mem_mem_wr),
    .mem_address(mem_mem_address),
    .mem_data(mem_mem_data),
    .mem_len(mem_mem_len),
    .rd_address(mem_rd_address),
    .rd_data(mem_rd_data),
    .mem_rd_done(mem_rd_done),
    .stall_out(mem_stall_in)
);

mem_wb mem_wb0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .stall_in(stall_in),
    .rd_address_in(mem_rd_address),
    .rd_data_in(mem_rd_data),
    .rd_address(reg_write_address),
    .rd_data(reg_write_data)
);

memctrl memctrl0(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .io_buffer_full(io_buffer_full),
    .ram_din(mem_din),
    .ram_dout(mem_dout),
    .ram_a(mem_a),
    .ram_wr(mem_wr),
    .if_pc_get(if_mem_pc_get),
    .if_pc_address(if_mem_pc_out),
    .if_done(if_mem_inst_done),
    .if_out(if_mem_inst_in),
    .mem_get(mem_mem_get),
    .mem_wr(mem_mem_wr),
    .mem_address(mem_mem_address),
    .mem_data(mem_mem_data),
    .mem_len(mem_mem_len),
    .mem_done(mem_mem_done),
    .mem_out(mem_mem_out)
);

endmodule