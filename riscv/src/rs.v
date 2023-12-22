`include "def.v"

module ReservationStation (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    input wire                      clr_in,

    input wire                      issue_rs_ready,
    input wire [  `ROB_INDEX_TYPE]  issue_rob_index,
    input wire [         `OP_TYPE]  issue_opType,
    input wire [     `OPENUM_TYPE]  issue_op,
    input wire [       `DATA_TYPE]  issue_rs1_val,
    input wire [  `ROB_INDEX_TYPE]  issue_rs1_depend,
    input wire [       `DATA_TYPE]  issue_rs2_val,
    input wire [  `ROB_INDEX_TYPE]  issue_rs2_depend,
    input wire [  `REG_INDEX_TYPE]  issue_rd,
    input wire [       `DATA_TYPE]  issue_imm,
    input wire [       `ADDR_TYPE]  issue_PC,

    input wire                      alu_ready,
    input wire [       `DATA_TYPE]  alu_result,
    input wire [  `ROB_INDEX_TYPE]  alu_rob_index,

    input wire                      lsb_ready,
    input wire [  `ROB_INDEX_TYPE]  lsb_rob_index,
    input wire [       `DATA_TYPE]  lsb_result,

    output reg                      rs_to_alu_ready,
    output reg [    `OPENUM_TYPE]   rs_to_alu_op,
    output reg [        `OP_TYPE]   rs_to_alu_opType,
    output reg [      `DATA_TYPE]   rs_to_alu_rs1,
    output reg [      `DATA_TYPE]   rs_to_alu_rs2,
    output reg [ `ROB_INDEX_TYPE]   rs_to_alu_rob_index,
    output reg [      `ADDR_TYPE]   rs_to_alu_PC,
    output reg [      `DATA_TYPE]   rs_to_alu_imm,

    output wire                     rs_full
);

reg [            `ROB_INDEX_TYPE]      rs_rob_index[`RS_SIZE-1:0];
reg [                 `DATA_TYPE]      rs_rs1_val[`RS_SIZE-1:0];
reg [                 `DATA_TYPE]      rs_rs2_val[`RS_SIZE-1:0];
reg [            `ROB_INDEX_TYPE]      rs_rs1_depend[`RS_SIZE-1:0];
reg [            `ROB_INDEX_TYPE]      rs_rs2_depend[`RS_SIZE-1:0];
reg [                 `DATA_TYPE]      rs_imm[`RS_SIZE-1:0];
reg [                 `ADDR_TYPE]      rs_PC[`RS_SIZE-1:0];
reg [               `OPENUM_TYPE]      rs_op[`RS_SIZE-1:0];
reg [                   `OP_TYPE]      rs_opType[`RS_SIZE-1:0];
reg                                    rs_valid[`RS_SIZE-1:0];
reg                                    rs_busy[`RS_SIZE-1:0];

assign rs_full = (vac_rs == `RS_SIZE);

reg [                       31:0]      vac_rs;
reg [                       31:0]      work_rs;   
integer i;                

always @(*) begin
    work_rs = `RS_SIZE;
    vac_rs = `RS_SIZE;
    for (i = 0; i < `RS_SIZE; i = i + 1) begin
        rs_valid[i] = `FALSE;
        if (alu_ready) begin
            if (rs_busy[i] && rs_rs1_depend[i] == alu_rob_index) begin
                rs_rs1_val[i] = alu_result;
                rs_rs1_depend[i] = 0;
            end
            if (rs_busy[i] && rs_rs2_depend[i] == alu_rob_index) begin
                rs_rs2_val[i] = alu_result;
                rs_rs2_depend[i] = 0;
            end
        end
        if (lsb_ready) begin
            if (rs_busy[i] && rs_rs1_depend[i] == lsb_rob_index) begin
                rs_rs1_val[i] = lsb_result;
                rs_rs1_depend[i] = 0;
            end
            if (rs_busy[i] && rs_rs2_depend[i] == lsb_rob_index) begin
                rs_rs2_val[i] = lsb_result;
                rs_rs2_depend[i] = 0;
            end
        end
        if (rs_busy[i] && !rs_rs1_depend[i] && !rs_rs2_depend[i]) begin
            rs_valid[i] = `TRUE;
        end 
        if (rs_valid[i] && work_rs == `RS_SIZE) begin
            work_rs = i;
        end
        if (!rs_busy[i] && vac_rs == `RS_SIZE) begin
            vac_rs = i;
        end
    end
    // $display("rs_full: %d, vac_rs: %d, work_rs: %d", rs_full, vac_rs, work_rs);
end
//modify to hardware search later

always @(posedge clk_in) begin
    if (rst_in || clr_in) begin
        for (i = 0; i < `RS_SIZE; i = i + 1) begin
            rs_busy[i] <= `FALSE;
        end
        rs_to_alu_ready <= `FALSE;
    end
    else if (!rdy_in) begin
        ;
    end
    else begin
        rs_to_alu_ready <= `FALSE;
        if (work_rs != `RS_SIZE) begin
            rs_to_alu_ready <= `TRUE;
            rs_to_alu_op <= rs_op[work_rs];
            rs_to_alu_opType <= rs_opType[work_rs];
            rs_to_alu_rs1 <= rs_rs1_val[work_rs];
            rs_to_alu_rs2 <= rs_rs2_val[work_rs];
            rs_to_alu_rob_index <= rs_rob_index[work_rs];
            rs_to_alu_PC <= rs_PC[work_rs];
            rs_to_alu_imm <= rs_imm[work_rs];
            rs_busy[work_rs] <= `FALSE;
        end
        if (issue_rs_ready) begin
            rs_rob_index[vac_rs] <= issue_rob_index;
            rs_rs1_val[vac_rs] <= issue_rs1_val;
            rs_rs2_val[vac_rs] <= issue_rs2_val;
            rs_rs1_depend[vac_rs] <= issue_rs1_depend;
            rs_rs2_depend[vac_rs] <= issue_rs2_depend;
            rs_imm[vac_rs] <= issue_imm;
            rs_PC[vac_rs] <= issue_PC;
            rs_op[vac_rs] <= issue_op;
            rs_opType[vac_rs] <= issue_opType;
            rs_valid[vac_rs] <= `FALSE;
            rs_busy[vac_rs] <= `TRUE;
        end
    end
end

endmodule