`include "def.v"

module ALU (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    input wire                      clr_in,

    input wire                      rs_to_alu_ready,
    input wire [    `OPENUM_TYPE]   rs_to_alu_op,
    input wire [      `DATA_TYPE]   rs_to_alu_rs1,
    input wire [      `DATA_TYPE]   rs_to_alu_rs2,
    input wire [ `ROB_INDEX_TYPE]   rs_to_alu_rob_index,
    input wire [      `ADDR_TYPE]   rs_to_alu_PC,
    input wire [      `DATA_TYPE]   rs_to_alu_imm,

    output reg                      alu_ready,
    output reg [      `DATA_TYPE]   alu_result,
    output reg [ `ROB_INDEX_TYPE]   alu_rob_index,
    output reg                      alu_branch,
    output reg [      `ADDR_TYPE]   alu_newPC
);

always @(*) begin
    alu_ready = rs_to_alu_ready;
    alu_result = 0;
    alu_rob_index = rs_to_alu_rob_index;
    alu_branch = `FALSE;
    alu_newPC = 0;
    case (rs_to_alu_op)
        `OPENUM_BEQ: begin
            alu_branch = (rs_to_alu_rs1 == rs_to_alu_rs2) ? `TRUE : `FALSE;
            alu_newPC = rs_to_alu_PC + rs_to_alu_imm;
        end
        `OPENUM_BNE: begin
            alu_branch = (rs_to_alu_rs1 != rs_to_alu_rs2) ? `TRUE : `FALSE;
            alu_newPC = rs_to_alu_PC + rs_to_alu_imm;
        end
        `OPENUM_BLT: begin
            alu_branch = ($signed(rs_to_alu_rs1) < $signed(rs_to_alu_rs2)) ? `TRUE : `FALSE;
            alu_newPC = rs_to_alu_PC + rs_to_alu_imm;
        end
        `OPENUM_BGE: begin
            alu_branch = ($signed(rs_to_alu_rs1) >= $signed(rs_to_alu_rs2)) ? `TRUE : `FALSE;
            alu_newPC = rs_to_alu_PC + rs_to_alu_imm;
        end
        `OPENUM_BLTU: begin
            alu_branch = (rs_to_alu_rs1 < rs_to_alu_rs2) ? `TRUE : `FALSE;
            alu_newPC = rs_to_alu_PC + rs_to_alu_imm;
        end
        `OPENUM_BGEU: begin
            alu_branch = (rs_to_alu_rs1 >= rs_to_alu_rs2) ? `TRUE : `FALSE;
            alu_newPC = rs_to_alu_PC + rs_to_alu_imm;
        end
        `OPENUM_ADDI: alu_result = rs_to_alu_rs1 + rs_to_alu_imm;
        `OPENUM_SLTI: alu_result = ($signed(rs_to_alu_rs1) < $signed(rs_to_alu_imm));
        `OPENUM_SLTIU: alu_result = rs_to_alu_rs1 < rs_to_alu_imm;
        `OPENUM_XORI: alu_result = rs_to_alu_rs1 ^ rs_to_alu_imm;
        `OPENUM_ORI: alu_result = rs_to_alu_rs1 | rs_to_alu_imm;
        `OPENUM_ANDI: alu_result = rs_to_alu_rs1 & rs_to_alu_imm;
        `OPENUM_SLLI: alu_result = rs_to_alu_rs1 << rs_to_alu_imm[5:0];
        `OPENUM_SRLI: alu_result = rs_to_alu_rs1 >> rs_to_alu_imm[5:0];
        `OPENUM_SRAI: alu_result = rs_to_alu_rs1 >>> rs_to_alu_imm[5:0];
        `OPENUM_ADD: alu_result = rs_to_alu_rs1 + rs_to_alu_rs2;
        `OPENUM_SUB: alu_result = rs_to_alu_rs1 - rs_to_alu_rs2;
        `OPENUM_SLL: alu_result = rs_to_alu_rs1 << rs_to_alu_rs2;
        `OPENUM_SLT: alu_result = ($signed(rs_to_alu_rs1) < $signed(rs_to_alu_rs2)) ? 1 : 0;
        `OPENUM_SLTU: alu_result = rs_to_alu_rs1 < rs_to_alu_rs2 ? 1 : 0;
        `OPENUM_XOR: alu_result = rs_to_alu_rs1 ^ rs_to_alu_rs2;
        `OPENUM_SRL: alu_result = rs_to_alu_rs1 >> rs_to_alu_rs2;
        `OPENUM_SRA: alu_result = rs_to_alu_rs1 >>> rs_to_alu_rs2;
        `OPENUM_OR: alu_result = rs_to_alu_rs1 | rs_to_alu_rs2;
        `OPENUM_AND: alu_result = rs_to_alu_rs1 & rs_to_alu_rs2;
        `OPENUM_LUI: alu_result = rs_to_alu_imm;
        `OPENUM_AUIPC: alu_result = rs_to_alu_imm + rs_to_alu_PC;
        `OPENUM_JAL: begin
            alu_branch = `TRUE;
            alu_result = rs_to_alu_PC + 4;
            alu_newPC = rs_to_alu_PC + rs_to_alu_imm;
        end
        `OPENUM_JALR: begin
            alu_branch = `TRUE;
            alu_result = rs_to_alu_PC + 4;
            alu_newPC = (rs_to_alu_imm + rs_to_alu_rs1) & 32'hfffffffe;
        end
        default;
    endcase
end
endmodule