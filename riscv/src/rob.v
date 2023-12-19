module ReorderBuffer (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    
    input wire                      lsb_ready,
    input wire [       `DATA_TYPE]  lsb_result,
    input wire [  `ROB_INDEX_TYPE]  lsb_rob_index,
    output wire                     rob_to_lsb_ready,
    output wire [ `ROB_INDEX_TYPE]  rob_to_lsb_commit_index,

    input wire                      alu_ready,
    input wire [       `DATA_TYPE]  alu_result,
    input wire [  `ROB_INDEX_TYPE]  alu_rob_index,
    input wire                      alu_branch,
    input wire [       `ADDR_TYPE]  alu_newPC,

    input wire                      issue_ready,
    input wire [         `OP_TYPE]  issue_opType,
    input wire [  `REG_INDEX_TYPE]  issue_rd,
    input wire [       `DATA_TYPE]  issue_imm,
    input wire [       `ADDR_TYPE]  issue_PC,
    input wire                      issue_pred_br,

    input wire [  `ROB_INDEX_TYPE]  dc_to_rob_rs1_check,
    input wire [  `ROB_INDEX_TYPE]  dc_to_rob_rs2_check,
    output wire                     rob_to_dc_rs1_ready,
    output wire [      `DATA_TYPE]  rob_to_dc_rs1_val,
    output wire                     rob_to_dc_rs2_ready,
    output wire [      `DATA_TYPE]  rob_to_dc_rs2_val,

    output wire                     rob_to_reg_commit,
    output wire [ `ROB_INDEX_TYPE]  rob_to_reg_rob_index,
    output wire [ `REG_INDEX_TYPE]  rob_to_reg_index,
    output wire [      `DATA_TYPE]  rob_to_reg_val,  

    output reg                      clr_in,//wrong prediction, need to revert
    output reg  [      `ADDR_TYPE]  rob_to_if_alter_pc,
    output reg                      rob_to_pr_ready,  
    output reg  [      `ADDR_TYPE]  rob_to_pr_PC,
    output reg                      rob_to_pr_br_taken,

    output wire                     rob_full
)

reg [             `ROB_INDEX_TYPE]  head;
reg [             `ROB_INDEX_TYPE]  tail;
reg                                 rob_ready[`ROB_SIZE-1:0];
reg [             `REG_INDEX_TYPE]  rob_rd[`ROB_SIZE-1:0];
reg [                    `OP_TYPE]  rob_opType[`ROB_SIZE-1:0];
reg [                  `ADDR_TYPE]  rob_PC[`ROB_SIZE-1:0];
reg [                  `ADDR_TYPE]  rob_brPC[`ROB_SIZE-1:0];
reg [                  `DATA_TYPE]  rob_result[`ROB_SIZE-1:0];
reg                                 rob_pred_br[`ROB_SIZE-1:0];
reg                                 rob_true_br[`ROB_SIZE-1:0];
wire [            `ROB_INDEX_TYPE]  nxt_head;
wire [            `ROB_INDEX_TYPE]  nxt_tail;
wire                                rob_empty;

assign rob_empty = (head == tail);
assign rob_full = (nxt_tail == head);
assign nxt_head = (head + 1) % `ROB_SIZE;
assign nxt_tail = (tail + 1) % `ROB_SIZE;
assign rob_to_dc_rs1_ready = rob_ready[dc_to_rob_rs1_check];
assign rob_to_dc_rs1_val = rob_result[dc_to_rob_rs1_check];
assign rob_to_dc_rs2_ready = rob_ready[dc_to_rob_rs2_check];
assign rob_to_dc_rs2_val = rob_result[dc_to_rob_rs2_check];

integer i;

always @(posedge clk_in) begin
    if (rst_in || clr_in) begin
        head <= 0;
        tail <= 0;
        rob_to_pr_ready <= `FALSE;
        rob_to_reg_commit <= `FALSE;
        clr_in <= 0;
    end
    else if (!rdy_in) begin
        ;
    end
    else begin
        rob_to_reg_commit <= `FALSE;
        rob_to_pr_ready <= `FALSE;
        if (lsb_ready) begin
            rob_ready[lsb_rob_index] <= 1;//must be head of rob
            rob_result[lsb_rob_index] <= lsb_result;
        end
        if (alu_ready) begin
            rob_ready[alu_rob_index] <= 1;
            rob_result[alu_rob_index] <= alu_result;
            rob_brPC[alu_rob_index] <= alu_newPC;
            rob_true_br[alu_rob_index] <= alu_branch;
        end
        if (issue_rob_ready && !rob_full) begin
            rob_ready[nxt_tail] <= `FALSE;
            rob_rd[nxt_tail] <= issue_rd;
            rob_opType[nxt_tail] <= issue_opType;
            rob_PC[nxt_tail] <= issue_PC;
            rob_brPC[nxt_tail] <= 0;
            rob_result[nxt_tail] <= 0;
            rob_pred_br[nxt_tail] <= issue_pred_br;
            rob_true_br[nxt_tail] <= 0;
            tail <= nxt_tail;
        end
        if (rob_ready[nxt_head] && !rob_empty) begin
            head <= nxt_head;
            if (rob_pred_br[nxt_head] != rob_true_br[nxt_head]) begin
                    clr_in <= 1;
                    rob_to_if_alter_pc <= rob_pred_br[nxt_head] ? rob_PC[nxt_head] + 4 : rob_brPC[nxt_head];
            end//maybe JALR
            if (rob_opType[nxt_head] == `OP_BR) begin
                rob_to_pr_ready <= `TRUE;
                rob_to_pr_PC <= rob_PC[nxt_head];
                rob_to_pr_br_taken <= rob_true_br[nxt_head];
            end
            rob_to_reg_commit <= `TRUE;
            rob_to_reg_index <= rob_rd[nxt_head];
            rob_to_reg_rob_index <= nxt_head;
            rob_to_reg_val <= rob_result[nxt_head];
        end
    end
end

endmodule