module Decoder(
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire                      rob_full,
    input wire                      rs_full,
    input wire                      lsb_full,

    input wire [       `ADDR_TYPE]  if_to_dc_PC,
    input wire [       `INST_TYPE]  if_to_dc_inst,
    input wire [         `OP_TYPE]  if_to_dc_opType,
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

    input wire                      lsb_result_ready,
    input wire [  `ROB_INDEX_TYPE]  lsb_result_rob_index,
    input wire [       `DATA_TYPE]  lsb_result_val,

    input wire [  `ROB_INDEX_TYPE]  rob_to_dc_rs1_ready,
    input wire [       `DATA_TYPE]  rob_to_dc_rs1_val,
    input wire [  `ROB_INDEX_TYPE]  rob_to_dc_rs2_ready,
    input wire [       `DATA_TYPE]  rob_to_dc_rs2_val,

    output reg                      issue_ready,
    output reg [         `OP_TYPE]  issue_opType,
    output reg [     `OPENUM_TYPE]  issue_op,
    output reg [       `DATA_TYPE]  issue_rs1_val,
    output reg [  `ROB_INDEX_TYPE]  issue_rs1_depend,
    output reg [       `DATA_TYPE]  issue_rs2_val,
    output reg [  `ROB_INDEX_TYPE]  issue_rs2_depend,
    output reg [  `REG_INDEX_TYPE]  issue_rd,
    output reg [       `DATA_TYPE]  issue_imm,
    output reg [       `ADDR_TYPE]  issue_PC,
    output reg                      issue_lsb_ready,
    output reg                      issue_rs_ready
);

always @(*) begin
    issue_ready = `FALSE;
    issue_op = if_to_dc_op;
    issue_opType = if_to_dc_opType;
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
        end//change to combinational logic circuit maybe?
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
                issue_op <= `OPENUM_LUI;
                issue_rs1_val <= 0;
                issue_rs2_val <= 0;
                issue_rs1_depend <= 0;
                issue_rs2_depend <= 0;
                issue_imm <= {
                    if_to_dc_inst[31:12],
                    12'b0
                };
            end
            `OP_AUIPC begin
                issue_op <= `OPENUM_AUIPC;
                issue_rs1_val <= 0;
                issue_rs2_val <= 0;
                issue_rs1_depend <= 0;
                issue_rs2_depend <= 0;
                issue_imm <= {
                    if_to_dc_inst[31:12],
                    12'b0
                };
            end
            `OP_JAL begin
                issue_op <= `OPENUM_JAL;
                issue_rs1_val <= 0;
                issue_rs2_val <= 0;
                issue_rs1_depend <= 0;
                issue_rs2_depend <= 0;
                issue_imm <= {
                    {12{if_to_dc_inst[31]}},
                    if_to_dc_inst[19:12],
                    if_to_dc_inst[20],
                    if_to_dc_inst[30:21],
                    1'b0
                };
            end
            `OP_JALR begin
                issue_op <= `OPENUM_JALR;
                issue_rs2_val <= 0;
                issue_rs2_depend <= 0;
                issue_imm = {
                    {21{if_to_dc_inst[31]}},
                    if_to_dc_inst[30:20]
                };
            end
            `OP_RC begin
                case (if_to_dc_inst[`FUNC3_RANGE])
                    `FUNC3_ADD_SUB: begin
                        case (if_to_dc_inst[`FUNC7_RANGE])
                            `FUNC7_ADD: begin
                                issue_op <= `OPENUM_ADD;
                            end
                            `FUNC7_SUB: begin
                                issue_op <= `OPENUM_SUB;
                            end 
                        endcase
                    end
                    `FUNC3_SLL: begin
                        issue_op <= `OPENUM_SLL;
                    end
                    `FUNC3_SLT: begin
                        issue_op <= `OPENUM_SLT;
                    end
                    `FUNC3_SLTU: begin
                        issue_op <= `OPENUM_SLTU;
                    end
                    `FUNC3_XOR: begin
                        issue_op <= `OPENUM_XOR;
                    end
                    `FUNC3_SRL_SRA: begin
                        case (if_to_dc_inst[`FUNC7_RANGE])
                            `FUNC7_SRL: begin
                                issue_op <= `OPENUM_SRL;
                            end
                            `FUNC7_SRA: begin
                                issue_op <= `OPENUM_SRA;
                            end 
                        endcase
                    end
                    `FUNC3_OR: begin
                        issue_op <= `OPENUM_OR;
                    end
                    `FUNC3_AND: begin
                        issue_op <= `OPENUM_AND;
                    end
                endcase
            end
            `OP_RI begin
                case (if_to_dc_inst[`FUNC3_RANGE])
                    `FUNC3_ADDI: begin
                        issue_op <= `OPENUM_ADDI;
                    end
                    `FUNC3_SLLI: begin
                        issue_op <= `OPENUM_SLLI;
                    end
                    `FUNC3_SLTI: begin
                        issue_op <= `OPENUM_SLTI;
                    end
                    `FUNC3_SLTIU: begin
                        issue_op <= `OPENUM_SLTIU;
                    end
                    `FUNC3_XORI: begin
                        issue_op <= `OPENUM_XORI;
                    end
                    `FUNC3_SRLI_SRAI: begin
                        case (if_to_dc_inst[`FUNC7_RANGE])
                            `FUNC7_SRLI: begin
                                issue_op <= `OPENUM_SRLI;
                            end
                            `FUNC7_SRAI: begin
                                issue_op <= `OPENUM_SRAI;
                            end 
                        endcase
                    end
                    `FUNC3_ORI: begin
                        issue_op <= `OPENUM_ORI;
                    end
                    `FUNC3_ANDI: begin
                        issue_op <= `OPENUM_ANDI;
                    end
                endcase
                issue_imm <= {
                    {21{if_to_dc_inst[31]}},
                    if_to_dc_inst[30:20]
                };
            end
            `OP_BR begin
                case (if_to_dc_inst[`FUNC3_RANGE])
                    `FUNC3_BEQ: begin
                        issue_op <= `OPENUM_BEQ;
                    end
                    `FUNC3_BNE: begin
                        issue_op <= `OPENUM_BNE;
                    end
                    `FUNC3_BLT: begin
                        issue_op <= `OPENUM_BLT;
                    end
                    `FUNC3_BGE: begin
                        issue_op <= `OPENUM_BGE;
                    end
                    `FUNC3_BLTU: begin
                        issue_op <= `OPENUM_BLTU;
                    end
                    `FUNC3_BGEU: begin
                        issue_op <= `OPENUM_BGEU;
                    end
                endcase
                issue_rd <= 0;
                issue_imm <= {
                    {20{if_to_dc_inst[31]}},
                    if_to_dc_inst[7],
                    if_to_dc_inst[30:25],
                    if_to_dc_inst[11:8],
                    1'b0
                };
            end
            `OP_LD begin
                case (if_to_dc_inst[`FUNC3_RANGE])
                    `FUNC3_LB: begin
                        issue_op <= `OPENUM_LB;
                    end
                    `FUNC3_LH: begin
                        issue_op <= `OPENUM_LH;
                    end
                    `FUNC3_LW: begin
                        issue_op <= `OPENUM_LW;
                    end
                    `FUNC3_LBU: begin
                        issue_op <= `OPENUM_LBU;
                    end
                    `FUNC3_LHU: begin
                        issue_op <= `OPENUM_LHU;
                    end
                endcase
                issue_imm <= {
                    {21{if_to_dc_inst[31]}},
                    if_to_dc_inst[30:20]
                };
            end
            `OP_ST begin
                case (if_to_dc_inst[`FUNC3_RANGE])
                    `FUNC3_SB: begin
                        issue_op <= `OPENUM_SB;
                    end
                    `FUNC3_SH: begin
                        issue_op <= `OPENUM_SH;
                    end
                    `FUNC3_SW: begin
                        issue_op <= `OPENUM_SW;
                    end
                endcase
                issue_rd <= 0;
                issue_imm <= {
                    {21{if_to_dc_inst[31]}},
                    if_to_dc_inst[30:25],
                    if_to_dc_inst[11:7]
                };
            end
        endcase
    end
end
endmodule