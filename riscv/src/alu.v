module alu (
    input wire                      clk_in;
    input wire                      rst_in;
    input wire                      rdy_in;

    input wire [     `OP_TYPE]      opType;     
    input wire [   `DATA_TYPE]      rs1;
    input wire [   `DATA_TYPE]      rs2;
    input wire [   `ADDR_TYPE]      PC;
    input wire [   `DATA_TYPE]      imm;

    output reg                      aluResult;
    output reg                      branch;
    output reg                      newPC;
);

always @(*) begin
    branch = `FALSE;
    case (OP_TYPE)
        `OP_ADD: aluResult = rs1 + rs2;
        `OP_SUB: aluResult = rs1 - rs2;
        `OP_BNE: branch = (rs1 != rs2) ? `TRUE : `FALSE;
        default;
    endcase
end

always @(posedge clk_in) begin
    if (branch) begin
        newPC <= PC + imm;
    end
    else begin
        newPC <= PC + 4;
    end
end
endmodule