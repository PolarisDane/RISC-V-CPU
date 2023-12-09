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

wire br_inst=;

always @(*) begin
    alu_branch <= `FALSE;
    case (op)
        `OPENUM_BEQ: branch <= (rs_to_alu_rs1 == rs_to_alu_rs2) ? `TRUE : `FALSE;
        `OPENUM_BNE: branch <= (rs_to_alu_rs1 != rs_to_alu_rs2) ? `TRUE : `FALSE;
        `OPENUM_BLT: branch <= ($signed(rs_to_alu_rs1) < $signed(rs_to_alu_rs2)) ? `TRUE : `FALSE;
        `OPENUM_BGE: branch <= ($signed(rs_to_alu_rs1) >= $signed(rs_to_alu_rs2)) ? `TRUE : `FALSE;
        `OPENUM_BLTU: branch <= (rs_to_alu_rs1 < rs_to_alu_rs2) ? `TRUE : `FALSE;
        `OPENUM_BGEU: branch <= (rs_to_alu_rs1 >= rs_to_alu_rs2) ? `TRUE : `FALSE;
        `OPENUM_ADDI: alu_result <= rs_to_alu_rs1 + rs_to_alu_imm;
        `OPENUM_SLTI: alu_result <= ($signed(rs_to_alu_rs1) < $signed(rs_to_alu_imm));
        `OPENUM_SLTIU: alu_result <= rs_to_alu_rs1 < rs_to_alu_imm;
        `OPENUM_XORI: alu_result <= rs_to_alu_rs1 ^ rs_to_alu_imm;
        `OPENUM_ORI: alu_result <= rs_to_alu_rs1 | rs_to_alu_imm;
        `OPENUM_ANDI: alu_result <= rs_to_alu_rs1 & rs_to_alu_imm;
        `OPENUM_SLLI: alu_result <= rs_to_alu_rs1 << rs_to_alu_imm;
        `OPENUM_SRLI: alu_result <= rs_to_alu_rs1 >> rs_to_alu_imm;
        `OPENUM_SRAI: alu_result <= rs_to_alu_rs1 >>> rs_to_alu_imm;
        `OPENUM_ADD: alu_result <= rs_to_alu_rs1 + rs_to_alu_rs2;
        `OPENUM_SUB: alu_result <= rs_to_alu_rs1 - rs_to_alu_rs2;
        `OPENUM_SLL: alu_result <= rs_to_alu_rs1 << rs_to_alu_rs2;
        `OPENUM_SLT: alu_result <= ($signed(rs_to_alu_rs1) < $signed(rs_to_alu_rs2)) ? 1 : 0;
        `OPENUM_SLTU: alu_result <= rs_to_alu_rs1 < rs_to_alu_rs2 ? 1 : 0;
        `OPENUM_XOR: alu_result <= rs_to_alu_rs1 ^ rs_to_alu_rs2;
        `OPENUM_SRL: alu_result <= rs_to_alu_rs1 >> rs_to_alu_rs2;
        `OPENUM_SRA: alu_result <= rs_to_alu_rs1 >>> rs_to_alu_rs2;
        `OPENUM_OR: alu_result <= rs_to_alu_rs1 | rs_to_alu_rs2;
        `OPENUM_AND: alu_result <= rs_to_alu_rs1 & rs_to_alu_rs2;
        default;
    endcase
end

always @(posedge clk_in) begin
    if (rst_in || clr_in) begin
        alu_ready <= `FALSE;
        alu_result <= 0;
        alu_rob_index <= 0;
        alu_branch <= 0;
        alu_newPC <= 0;
    end
    else if (!rdy_in || !rs_to_alu_ready) begin
        ;
    end
    else begin
        if (rs_to_alu_op) begin

        end
        if (branch) begin
            newPC <= PC + imm;
        end
        else begin
            newPC <= PC + 4;
        end
    end

end
endmodule