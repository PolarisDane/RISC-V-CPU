module decoder(
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire [  `ADDR_TYPE]       if_to_dc_PC,
    input wire [  `INST_TYPE]       if_to_dc_inst,
    input wire [`OPENUM_TYPE]       if_to_dc_op,
    input wire [  `OP_TYPE]         if_to_dc_opType,
    input wire                      if_to_dc_ready,

    output reg [  `REG_INDEX_TYPE]  dc_to_reg_rs1_pos,
    output reg [  `REG_INDEX_TYPE]  dc_to_reg_rs2_pos,
    input wire [  `DATA_TYPE]       reg_to_dc_rs1,
    input wire [  `DATA_TYPE]       reg_to_dc_rs2,
    input wire                      reg_to_dc_rs1_ready,
    input wire                      reg_to_dc_rs2_ready,

    output reg                      issue_ready,
    output reg [  `OP_TYPE]         issue_opType,
    output reg [  `DATA_TYPE]       issue_rs1,
    output reg [  `DATA_TYPE]       issue_rs2,
    output reg [  `REG_INDEX_TYPE]  issue_rd,
    output reg [  `DATA_TYPE]       issue_imm,
    output reg [  `ADDR_TYPE]       issue_PC
);

always @(*) begin
    issue_ready = `FALSE;
    issue_opType = if_to_dc_opType;
    issue_rs1 = 0;
    issue_rs2 = 0;
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
        if (reg_to_dc_rs1_ready) begin
            issue_rs1 = reg_to_dc_rs1;
        end
        if (reg_to_dc_rs2_ready) begin
            issue_rs2 = reg_to_dc_rs2;
        end
        //forward here if needed
        case (if_to_dc_opType)
            `OP_RI begin
                issue_imm = {
                    {21{if_to_dc_inst[31]}},//SEXT
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