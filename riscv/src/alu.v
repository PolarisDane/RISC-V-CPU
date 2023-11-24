module alu (
    input wire                      clk_in;
    input wire                      rst_in;
    input wire                      rdy_in;

    input wire [ `OPENUM_TYPE]      op;     
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
    case (op)
        `OPENUM_ADD: aluResult = rs1 + rs2;
        `OPENUM_ADDI: aluResult = rs1 + imm;
        `OPENUM_BNE: branch = (rs1 != rs2) ? `TRUE : `FALSE;
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