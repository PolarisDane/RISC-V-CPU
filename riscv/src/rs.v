`include "def.v"

module ReservationStation (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    input wire                      clr_in,

    input wire                      issue_rs_ready,
    input wire [  `ROB_INDEX_TYPE]  issue_rob_index,
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
reg                                    rs_busy[`RS_SIZE-1:0];

wire [            `RS_INDEX_TYPE]      vac_rs;
wire [            `RS_INDEX_TYPE]      work_rs;   
integer i;                

assign rs_full = (vac_rs == `RS_SIZE);
assign vac_rs = (!rs_busy[0]) ? 0 : (!rs_busy[1]) ? 1 : (!rs_busy[2]) ? 2 : (!rs_busy[3]) ? 3 :
                (!rs_busy[4]) ? 4 : (!rs_busy[5]) ? 5 : (!rs_busy[6]) ? 6 : (!rs_busy[7]) ? 7 :
                (!rs_busy[8]) ? 8 : (!rs_busy[9]) ? 9 : (!rs_busy[10]) ? 10 : (!rs_busy[11]) ? 11 :
                (!rs_busy[12]) ? 12 : (!rs_busy[13]) ? 13 : (!rs_busy[14]) ? 14 : (!rs_busy[15]) ? 15 : `RS_SIZE;
assign work_rs = (rs_busy[0] && !rs_rs1_depend[0] && !rs_rs2_depend[0]) ? 0 : (rs_busy[1] && !rs_rs1_depend[1] && !rs_rs2_depend[1]) ? 1 :
                 (rs_busy[2] && !rs_rs1_depend[2] && !rs_rs2_depend[2]) ? 2 : (rs_busy[3] && !rs_rs1_depend[3] && !rs_rs2_depend[3]) ? 3 :
                 (rs_busy[4] && !rs_rs1_depend[4] && !rs_rs2_depend[4]) ? 4 : (rs_busy[5] && !rs_rs1_depend[5] && !rs_rs2_depend[5]) ? 5 :
                 (rs_busy[6] && !rs_rs1_depend[6] && !rs_rs2_depend[6]) ? 6 : (rs_busy[7] && !rs_rs1_depend[7] && !rs_rs2_depend[7]) ? 7 :
                 (rs_busy[8] && !rs_rs1_depend[8] && !rs_rs2_depend[8]) ? 8 : (rs_busy[9] && !rs_rs1_depend[9] && !rs_rs2_depend[9]) ? 9 :
                 (rs_busy[10] && !rs_rs1_depend[10] && !rs_rs2_depend[10]) ? 10 : (rs_busy[11] && !rs_rs1_depend[11] && !rs_rs2_depend[11]) ? 11 :
                 (rs_busy[12] && !rs_rs1_depend[12] && !rs_rs2_depend[12]) ? 12 : (rs_busy[13] && !rs_rs1_depend[13] && !rs_rs2_depend[13]) ? 13 :
                 (rs_busy[14] && !rs_rs1_depend[14] && !rs_rs2_depend[14]) ? 14 : (rs_busy[15] && !rs_rs1_depend[15] && !rs_rs2_depend[15]) ? 15 : `RS_SIZE;

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
        if (issue_rs_ready && vac_rs != `RS_SIZE) begin
            rs_rob_index[vac_rs] <= issue_rob_index;
            rs_rs1_val[vac_rs] <= issue_rs1_val;
            rs_rs2_val[vac_rs] <= issue_rs2_val;
            rs_rs1_depend[vac_rs] <= issue_rs1_depend;
            rs_rs2_depend[vac_rs] <= issue_rs2_depend;
            rs_imm[vac_rs] <= issue_imm;
            rs_PC[vac_rs] <= issue_PC;
            rs_op[vac_rs] <= issue_op;
            rs_busy[vac_rs] <= `TRUE;
        end
        for (i = 0; i < `RS_SIZE; i = i + 1) begin
            if (alu_ready) begin
                if (rs_busy[i] && rs_rs1_depend[i] == alu_rob_index) begin
                    rs_rs1_val[i] <= alu_result;
                    rs_rs1_depend[i] <= 0;
                end
                if (rs_busy[i] && rs_rs2_depend[i] == alu_rob_index) begin
                    rs_rs2_val[i] <= alu_result;
                    rs_rs2_depend[i] <= 0;
                end
            end
            if (lsb_ready) begin
                if (rs_busy[i] && rs_rs1_depend[i] == lsb_rob_index) begin
                    rs_rs1_val[i] <= lsb_result;
                    rs_rs1_depend[i] <= 0;
                end
                if (rs_busy[i] && rs_rs2_depend[i] == lsb_rob_index) begin
                    rs_rs2_val[i] <= lsb_result;
                    rs_rs2_depend[i] <= 0;
                end
            end
        end
        if (work_rs != `RS_SIZE) begin
            rs_to_alu_ready <= `TRUE;
            rs_to_alu_op <= rs_op[work_rs];
            rs_to_alu_rs1 <= rs_rs1_val[work_rs];
            rs_to_alu_rs2 <= rs_rs2_val[work_rs];
            rs_to_alu_rob_index <= rs_rob_index[work_rs];
            rs_to_alu_PC <= rs_PC[work_rs];
            rs_to_alu_imm <= rs_imm[work_rs];
            rs_busy[work_rs] <= `FALSE;
        end
    end
end

endmodule