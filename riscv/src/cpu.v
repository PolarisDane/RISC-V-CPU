// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "def.v"

module cpu(
    input wire                      clk_in,			// system clock signal
    input wire                      rst_in,			// reset signal
    input wire                      rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]              mem_din,		// data input bus
    output wire [ 7:0]              mem_dout,		// data output bus
    output wire [31:0]              mem_a,			// address bus (only 17:0 is used)
    output wire                     mem_wr,			// write/read signal (1 for write)
	
	input  wire                     io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			    dbgreg_dout		// cpu register output (debugging demo)
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

//revert signal
wire                                clr_in;
wire [                 `ADDR_TYPE]  rob_to_if_alter_PC;

//full signal
wire                                rob_full;
wire                                lsb_full;
wire                                rs_full;

//mc signal
wire                                mc_valid;

//alu broadcast
wire                                alu_ready;
wire [                 `DATA_TYPE]  alu_result;
wire [            `ROB_INDEX_TYPE]  alu_rob_index;
wire                                alu_branch;
wire [                 `ADDR_TYPE]  alu_newPC;

//lsb broadcast
wire                                lsb_ready;
wire [                 `DATA_TYPE]  lsb_result;
wire [            `ROB_INDEX_TYPE]  lsb_result_rob_index;

//rob with pr
wire                                rob_to_pr_ready;
wire [                 `ADDR_TYPE]  rob_to_pr_PC;
wire                                rob_to_pr_br_taken;

//rob with reg
wire [            `ROB_INDEX_TYPE]  rob_to_reg_rob_index;
wire [            `REG_INDEX_TYPE]  rob_to_reg_index;
wire [                 `DATA_TYPE]  rob_to_reg_val;
wire                                rob_to_reg_commit;

//rob with dc
wire [            `ROB_INDEX_TYPE]  rob_to_dc_rename_index;
wire                                rob_to_dc_rs1_ready;
wire [                 `DATA_TYPE]  rob_to_dc_rs1_val;
wire                                rob_to_dc_rs2_ready;
wire [                 `DATA_TYPE]  rob_to_dc_rs2_val;
wire [            `ROB_INDEX_TYPE]  dc_to_rob_rs1_check;
wire [            `ROB_INDEX_TYPE]  dc_to_rob_rs2_check;

//rob with lsb
wire                                rob_to_lsb_ready;
wire [            `ROB_INDEX_TYPE]  rob_to_lsb_commit_index;

//issue signal
wire                                issue_ready;
wire [            `ROB_INDEX_TYPE]  issue_rob_index;
wire [                   `OP_TYPE]  issue_opType;
wire [               `OPENUM_TYPE]  issue_op;
wire [                 `DATA_TYPE]  issue_rs1_val;
wire [            `ROB_INDEX_TYPE]  issue_rs1_depend;
wire [                 `DATA_TYPE]  issue_rs2_val;
wire [            `ROB_INDEX_TYPE]  issue_rs2_depend;
wire [            `REG_INDEX_TYPE]  issue_rd;
wire [                 `DATA_TYPE]  issue_imm;
wire [                 `ADDR_TYPE]  issue_PC;
wire                                issue_lsb_ready;
wire                                issue_rs_ready;
wire                                issue_pred_br;

//dc with reg
wire [            `REG_INDEX_TYPE]  dc_to_reg_rs1_pos;
wire [            `REG_INDEX_TYPE]  dc_to_reg_rs2_pos;
wire [                 `DATA_TYPE]  reg_to_dc_rs1_val;
wire [                 `DATA_TYPE]  reg_to_dc_rs2_val;
wire [            `ROB_INDEX_TYPE]  reg_to_dc_rs1_depend;
wire [            `ROB_INDEX_TYPE]  reg_to_dc_rs2_depend;

//if with dc
wire [                 `ADDR_TYPE]  if_to_dc_PC;
wire [                 `INST_TYPE]  if_to_dc_inst;
wire [                   `OP_TYPE]  if_to_dc_opType;
wire                                if_to_dc_ready;
wire                                if_to_dc_pred_br;
wire                                stall;

//if with mc
wire [                 `INST_TYPE]  mc_to_if_inst;
wire                                mc_to_if_ready;
wire [                 `ADDR_TYPE]  if_to_mc_PC;
wire                                if_to_mc_ready;

//if with ic
wire                                ic_to_if_hit;
wire [                 `INST_TYPE]  ic_to_if_hit_inst;
wire [                 `ADDR_TYPE]  if_to_ic_inst_addr;
wire [                 `INST_TYPE]  if_to_ic_inst;
wire                                if_to_ic_inst_valid;

//if with pr
wire                                pr_to_if_prediction;
wire [                 `ADDR_TYPE]  if_to_pr_PC;

//lsb with mc
wire                                lsb_to_mc_ready;
wire [                  `LEN_TYPE]  lsb_to_mc_len;
wire [                   `OP_TYPE]  lsb_to_mc_opType;
wire [                 `DATA_TYPE]  lsb_to_mc_data;
wire [                 `ADDR_TYPE]  lsb_to_mc_addr;
wire                                mc_to_lsb_ld_done;  
wire                                mc_to_lsb_st_done;
wire [                 `DATA_TYPE]  mc_to_lsb_result;

//alu with rs
wire                                rs_to_alu_ready;
wire [               `OPENUM_TYPE]  rs_to_alu_op;
wire [                   `OP_TYPE]  rs_to_alu_opType;
wire [                 `DATA_TYPE]  rs_to_alu_rs1;
wire [                 `DATA_TYPE]  rs_to_alu_rs2;
wire [            `ROB_INDEX_TYPE]  rs_to_alu_rob_index;
wire [                 `ADDR_TYPE]  rs_to_alu_PC;
wire [                 `DATA_TYPE]  rs_to_alu_imm;

ALU alu(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .clr_in(clr_in),
    .rs_to_alu_ready(rs_to_alu_ready),
    .rs_to_alu_op(rs_to_alu_op),
    .rs_to_alu_opType(rs_to_alu_opType),
    .rs_to_alu_rs1(rs_to_alu_rs1),
    .rs_to_alu_rs2(rs_to_alu_rs2),
    .rs_to_alu_rob_index(rs_to_alu_rob_index),
    .rs_to_alu_PC(rs_to_alu_PC),
    .rs_to_alu_imm(rs_to_alu_imm),
    .alu_ready(alu_ready),
    .alu_result(alu_result),
    .alu_rob_index(alu_rob_index),
    .alu_branch(alu_branch),
    .alu_newPC(alu_newPC)
);

InstructionFetcher instructionfetcher(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .clr_in(clr_in),
    .mc_valid(mc_valid),
    .mc_to_if_inst(mc_to_if_inst),
    .mc_to_if_ready(mc_to_if_ready),
    .if_to_mc_PC(if_to_mc_PC),
    .if_to_mc_ready(if_to_mc_ready),
    .stall(stall),
    .if_to_dc_ready(if_to_dc_ready),
    .if_to_dc_opType(if_to_dc_opType),
    .if_to_dc_PC(if_to_dc_PC),
    .if_to_dc_inst(if_to_dc_inst),
    .if_to_dc_pred_br(if_to_dc_pred_br),
    .ic_to_if_hit(ic_to_if_hit),
    .ic_to_if_hit_inst(ic_to_if_hit_inst),
    .if_to_ic_inst_addr(if_to_ic_inst_addr),
    .if_to_ic_inst(if_to_ic_inst),
    .if_to_ic_inst_valid(if_to_ic_inst_valid),
    .rob_to_if_alter_PC(rob_to_if_alter_PC),
    .if_to_pr_PC(if_to_pr_PC),
    .pr_to_if_prediction(pr_to_if_prediction)
);

Icache icache(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .if_to_ic_inst_addr(if_to_ic_inst_addr),
    .if_to_ic_inst(if_to_ic_inst),
    .if_to_ic_inst_valid(if_to_ic_inst_valid),
    .ic_to_if_hit(ic_to_if_hit),
    .ic_to_if_hit_inst(ic_to_if_hit_inst)
);

MemController memcontroller(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .clr_in(clr_in),
    .io_buffer_full(io_buffer_full),
    .mem_to_mc_din(mem_din),
    .mc_to_mem_dout(mem_dout),
    .mc_to_mem_addr(mem_a),
    .mc_to_mem_wr(mem_wr),
    .if_to_mc_PC(if_to_mc_PC),
    .if_to_mc_ready(if_to_mc_ready),
    .mc_to_if_inst(mc_to_if_inst),
    .mc_to_if_ready(mc_to_if_ready),
    .lsb_to_mc_ready(lsb_to_mc_ready),
    .lsb_to_mc_len(lsb_to_mc_len),
    .lsb_to_mc_opType(lsb_to_mc_opType),
    .lsb_to_mc_data(lsb_to_mc_data),
    .lsb_to_mc_addr(lsb_to_mc_addr),
    .mc_to_lsb_ld_done(mc_to_lsb_ld_done),
    .mc_to_lsb_st_done(mc_to_lsb_st_done),
    .mc_to_lsb_result(mc_to_lsb_result),
    .mc_valid(mc_valid)
);

LoadStoreBuffer lsb(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .clr_in(clr_in),
    .issue_lsb_ready(issue_lsb_ready),
    .issue_rob_index(issue_rob_index),
    .issue_opType(issue_opType),
    .issue_op(issue_op),
    .issue_rs1_val(issue_rs1_val),
    .issue_rs1_depend(issue_rs1_depend),
    .issue_rs2_val(issue_rs2_val),
    .issue_rs2_depend(issue_rs2_depend),
    .issue_rd(issue_rd),
    .issue_imm(issue_imm),
    .issue_PC(issue_PC),
    .rob_to_lsb_ready(rob_to_lsb_ready),
    .rob_to_lsb_commit_index(rob_to_lsb_commit_index),
    .alu_to_lsb_ready(alu_to_lsb_ready),
    .alu_to_lsb_result(alu_to_lsb_result),
    .alu_to_lsb_rob_index(alu_to_lsb_rob_index),
    .mc_to_lsb_ld_done(mc_to_lsb_ld_done),
    .mc_to_lsb_st_done(mc_to_lsb_st_done),
    .mc_to_lsb_result(mc_to_lsb_result),
    .mc_valid(mc_valid),
    .lsb_to_mc_ready(lsb_to_mc_ready),
    .lsb_to_mc_len(lsb_to_mc_len),
    .lsb_to_mc_opType(lsb_to_mc_opType),
    .lsb_to_mc_data(lsb_to_mc_data),
    .lsb_to_mc_addr(lsb_to_mc_addr),
    .lsb_full(lsb_full),
    .lsb_ready(lsb_ready),
    .lsb_result(lsb_result),
    .lsb_result_rob_index(lsb_result_rob_index)
);

RegisterFile regfile(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .issue_ready(issue_ready),
    .issue_rd(issue_rd),
    .issue_rob_index(issue_rob_index),
    .dc_to_reg_rs1_pos(dc_to_reg_rs1_pos),
    .dc_to_reg_rs2_pos(dc_to_reg_rs2_pos),
    .reg_to_dc_rs1_val(reg_to_dc_rs1_val),
    .reg_to_dc_rs2_val(reg_to_dc_rs2_val),
    .reg_to_dc_rs1_depend(reg_to_dc_rs1_depend),
    .reg_to_dc_rs2_depend(reg_to_dc_rs2_depend),
    .rob_to_reg_commit(rob_to_reg_commit),
    .rob_to_reg_rob_index(rob_to_reg_rob_index),
    .rob_to_reg_index(rob_to_reg_index),
    .rob_to_reg_val(rob_to_reg_val)
);

Decoder decoder(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .clr_in(clr_in),
    .rob_full(rob_full),
    .rs_full(rs_full),
    .lsb_full(lsb_full),
    .if_to_dc_PC(if_to_dc_PC),
    .if_to_dc_inst(if_to_dc_inst),
    .if_to_dc_opType(if_to_dc_opType),
    .if_to_dc_ready(if_to_dc_ready),
    .if_to_dc_pred_br(if_to_dc_pred_br),
    .stall(stall),
    .dc_to_reg_rs1_pos(dc_to_reg_rs1_pos),
    .dc_to_reg_rs2_pos(dc_to_reg_rs2_pos),
    .reg_to_dc_rs1_val(reg_to_dc_rs1_val),
    .reg_to_dc_rs2_val(reg_to_dc_rs2_val),
    .reg_to_dc_rs1_depend(reg_to_dc_rs1_depend),
    .reg_to_dc_rs2_depend(reg_to_dc_rs2_depend),
    .alu_ready(alu_ready),
    .alu_result(alu_result),
    .alu_rob_index(alu_rob_index),
    .lsb_ready(lsb_ready),
    .lsb_result(lsb_result),
    .lsb_rob_index(lsb_result_rob_index),
    .rob_to_dc_rename_index(rob_to_dc_rename_index),
    .rob_to_dc_rs1_ready(rob_to_dc_rs1_ready),
    .rob_to_dc_rs1_val(rob_to_dc_rs1_val),
    .rob_to_dc_rs2_ready(rob_to_dc_rs2_ready),
    .rob_to_dc_rs2_val(rob_to_dc_rs2_val),
    .dc_to_rob_rs1_check(dc_to_rob_rs1_check),
    .dc_to_rob_rs2_check(dc_to_rob_rs2_check),
    .issue_ready(issue_ready),
    .issue_rob_index(issue_rob_index),
    .issue_opType(issue_opType),
    .issue_op(issue_op),
    .issue_rs1_val(issue_rs1_val),
    .issue_rs1_depend(issue_rs1_depend),
    .issue_rs2_val(issue_rs2_val),
    .issue_rs2_depend(issue_rs2_depend),
    .issue_rd(issue_rd),
    .issue_imm(issue_imm),
    .issue_PC(issue_PC),
    .issue_lsb_ready(issue_lsb_ready),
    .issue_rs_ready(issue_rs_ready),
    .issue_pred_br(issue_pred_br)
);

ReservationStation reservationstation(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .clr_in(clr_in),
    .issue_rs_ready(issue_rs_ready),
    .issue_rob_index(issue_rob_index),
    .issue_opType(issue_opType),
    .issue_op(issue_op),
    .issue_rs1_val(issue_rs1_val),
    .issue_rs1_depend(issue_rs1_depend),
    .issue_rs2_val(issue_rs2_val),
    .issue_rs2_depend(issue_rs2_depend),
    .issue_rd(issue_rd),
    .issue_imm(issue_imm),
    .issue_PC(issue_PC),
    .alu_ready(alu_ready),
    .alu_result(alu_result),
    .alu_rob_index(alu_rob_index),
    .lsb_ready(lsb_ready),
    .lsb_result(lsb_result),
    .lsb_rob_index(lsb_result_rob_index),
    .rs_to_alu_ready(rs_to_alu_ready),
    .rs_to_alu_op(rs_to_alu_op),
    .rs_to_alu_opType(rs_to_alu_opType),
    .rs_to_alu_rs1(rs_to_alu_rs1),
    .rs_to_alu_rs2(rs_to_alu_rs2),
    .rs_to_alu_rob_index(rs_to_alu_rob_index),
    .rs_to_alu_PC(rs_to_alu_PC),
    .rs_to_alu_imm(rs_to_alu_imm),
    .rs_full(rs_full)
);

ReorderBuffer reorderbuffer(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    .lsb_ready(lsb_ready),
    .lsb_result(lsb_result),
    .lsb_rob_index(lsb_result_rob_index),
    .rob_to_lsb_ready(rob_to_lsb_ready),
    .rob_to_lsb_commit_index(rob_to_lsb_commit_index),
    .alu_ready(alu_ready),
    .alu_result(alu_result),
    .alu_rob_index(alu_rob_index),
    .alu_branch(alu_branch),
    .alu_newPC(alu_newPC),
    .issue_ready(issue_ready),
    .issue_opType(issue_opType),
    .issue_rd(issue_rd),
    .issue_imm(issue_imm),
    .issue_PC(issue_PC),
    .issue_pred_br(issue_pred_br),
    .dc_to_rob_rs1_check(dc_to_rob_rs1_check),
    .dc_to_rob_rs2_check(dc_to_rob_rs2_check),
    .rob_to_dc_rename_index(rob_to_dc_rename_index),
    .rob_to_dc_rs1_ready(rob_to_dc_rs1_ready),
    .rob_to_dc_rs1_val(rob_to_dc_rs1_val),
    .rob_to_dc_rs2_ready(rob_to_dc_rs2_ready),
    .rob_to_dc_rs2_val(rob_to_dc_rs2_val),
    .rob_to_reg_commit(rob_to_reg_commit),
    .rob_to_reg_rob_index(rob_to_reg_rob_index),
    .rob_to_reg_index(rob_to_reg_index),
    .rob_to_reg_val(rob_to_reg_val),
    .clr_in(clr_in),
    .rob_to_if_alter_PC(rob_to_if_alter_PC),
    .rob_to_pr_ready(rob_to_pr_ready),
    .rob_to_pr_PC(rob_to_pr_PC),
    .rob_to_pr_br_taken(rob_to_pr_br_taken),
    .rob_full(rob_full)
);

endmodule