module Decoder(
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire                      rob_full,

    input wire [       `ADDR_TYPE]  if_to_dc_PC,
    input wire [       `INST_TYPE]  if_to_dc_inst,
    input wire [         `OP_TYPE]  if_to_dc_opType,
    input wire [     `OPENUM_TYPE]  if_to_dc_op,
    input wire                      if_to_dc_ready,

    output wire [ `REG_INDEX_TYPE]  dc_to_reg_rs1_pos,
    output wire [ `REG_INDEX_TYPE]  dc_to_reg_rs2_pos,
    input wire [       `DATA_TYPE]  reg_to_dc_rs1_val,
    input wire [       `DATA_TYPE]  reg_to_dc_rs2_val,
    input wire [  `ROB_INDEX_TYPE]  reg_to_dc_rs1_depend,
    input wire [  `ROB_INDEX_TYPE]  reg_to_dc_rs2_depend,

    input wire                      alu_result_ready,
    input wire [  `ROB_INDEX_TYPE]  alu_result_rob_index,
    input wire [       `DATA_TYPE]  alu_result_val,

    input wire [  `ROB_INDEX_TYPE]  rob_to_dc_rs1_ready,
    input wire [       `DATA_TYPE]  rob_to_dc_rs1_val,
    input wire [  `ROB_INDEX_TYPE]  rob_to_dc_rs2_ready,
    input wire [       `DATA_TYPE]  rob_to_dc_rs2_val,

    output reg                      issue_ready,
    output reg [         `OP_TYPE]  issue_op,
    output reg [       `DATA_TYPE]  issue_rs1_val,
    output reg [  `ROB_INDEX_TYPE]  issue_rs1_depend,
    output reg [       `DATA_TYPE]  issue_rs2_val,
    output reg [  `ROB_INDEX_TYPE]  issue_rs2_depend,
    output reg [  `REG_INDEX_TYPE]  issue_rd,
    output reg [       `DATA_TYPE]  issue_imm,
    output reg [       `ADDR_TYPE]  issue_PC
);

always @(*) begin
    issue_ready = `FALSE;
    issue_op = if_to_dc_op;
    issue_rs1_val = 0;
    issue_rs1_depend = 0;
    issue_rs2_val = 0;
    issue_rs2_depend = 0;
    issue_rd = if_to_dc_inst[7:0];
    issue_imm = 0;
    issue_PC = if_to_dc_PC;
    if (rst_in || !if_to_dc_ready) begin
        issue_ready = `FALSE;
    end
    else if (!rdy) begin
        ;
    end
    else begin
        issue_ready = `TRUE;
        if (!reg_to_dc_rs1_depend) begin
            issue_rs1_val = reg_to_dc_rs1_val;
        end
        else if (rob_to_dc_rs1_ready) begin
            issue_rs1_val = rob_to_dc_rs1_val;
        end
        else if (alu_result_ready && alu_result_rob_index == reg_to_dc_rs1_depend) begin
            issue_rs1_val = alu_result_val;
        end
        else begin
            issue_rs1_depend = reg_to_dc_rs1_depend;
        end
        if (!reg_to_dc_rs2_depend) begin
            issue_rs2_val = reg_to_dc_rs2_val;
        end
        else if (rob_to_dc_rs2_ready) begin
            issue_rs2_val = rob_to_dc_rs2_val;
        end
        else if (alu_result_ready && alu_result_rob_index == reg_to_dc_rs2_depend) begin
            issue_rs2_val = alu_result_val;
        end
        else begin
            issue_rs2_depend = reg_to_dc_rs2_depend;
        end
        //forward here if needed
        case (if_to_dc_opType)
            `OP_LUI begin
                issue_rs1_val = 0;
                issue_rs2_val = 0;
                issue_rs1_depend = 0;
                issue_rs2_depend = 0;
                issue_imm = {
                    if_to_dc_inst[31:12],
                    12'b0
                };
            end
            `OP_AUIPC begin
                issue_rs1_val = 0;
                issue_rs2_val = 0;
                issue_rs1_depend = 0;
                issue_rs2_depend = 0;
                issue_imm = {
                    if_to_dc_inst[31:12],
                    12'b0
                };
            end
            `OP_JAL begin
                issue_rs1_val = 0;
                issue_rs2_val = 0;
                issue_rs1_depend = 0;
                issue_rs2_depend = 0;
                issue_imm = {
                    {12{if_to_dc_inst[31]}},
                    if_to_dc_inst[19:12],
                    if_to_dc_inst[20],
                    if_to_dc_inst[30:21],
                    1'b0
                };
            end
            `OP_JALR begin
                issue_rs2_val = 0;
                issue_rs2_depend = 0;
                issue_imm = {
                    {21{if_to_dc_inst[31]}},
                    if_to_dc_inst[30:20]
                };
            end
            `OP_RC begin
            end
            `OP_RI begin
                issue_imm = {
                    {21{if_to_dc_inst[31]}},
                    if_to_dc_inst[30:20]
                };
            end
            `OP_BR begin
                issue_rd = 0;
                issue_imm = {
                    {20{if_to_dc_inst[31]}},
                    if_to_dc_inst[7],
                    if_to_dc_inst[30:25],
                    if_to_dc_inst[11:8],
                    1'b0
                };
            end
            `OP_LD begin
                issue_imm = {
                    {21{if_to_dc_inst[31]}},
                    if_to_dc_inst[30:20]
                };
            end
            `OP_ST begin
                issue_rd = 0;
                issue_imm = {
                    {21{if_to_dc_inst[31]}},
                    if_to_dc_inst[30:25],
                    if_to_dc_inst[11:7]
                };
            end
        endcase
    end
end
endmodule