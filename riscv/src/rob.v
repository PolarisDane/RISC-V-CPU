`include "def.v"

module ReorderBuffer (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    
    input wire                      lsb_full,
    input wire                      lsb_ready,
    input wire [       `DATA_TYPE]  lsb_result,
    input wire [  `ROB_INDEX_TYPE]  lsb_rob_index,
    output wire                     rob_to_lsb_ready,
    output wire [ `ROB_INDEX_TYPE]  rob_to_lsb_commit_index,

    input wire                      rs_full,
    input wire                      alu_ready,
    input wire [       `DATA_TYPE]  alu_result,
    input wire [  `ROB_INDEX_TYPE]  alu_rob_index,
    input wire                      alu_branch,
    input wire [       `ADDR_TYPE]  alu_newPC,

    input wire                      issue_ready,
    input wire [         `OP_TYPE]  issue_opType,
    input wire [  `REG_INDEX_TYPE]  issue_rd,
    input wire [       `ADDR_TYPE]  issue_PC,
    input wire                      issue_pred_br,

    input wire [  `ROB_INDEX_TYPE]  dc_to_rob_rs1_check,
    input wire [  `ROB_INDEX_TYPE]  dc_to_rob_rs2_check,
    output wire [ `ROB_INDEX_TYPE]  rob_to_dc_rename_index,
    output wire                     rob_to_dc_rs1_ready,
    output wire [      `DATA_TYPE]  rob_to_dc_rs1_val,
    output wire                     rob_to_dc_rs2_ready,
    output wire [      `DATA_TYPE]  rob_to_dc_rs2_val,

    output reg                      rob_to_reg_commit,
    output reg [  `ROB_INDEX_TYPE]  rob_to_reg_rob_index,
    output reg [  `REG_INDEX_TYPE]  rob_to_reg_index,
    output reg [       `DATA_TYPE]  rob_to_reg_val,  

    output reg                      clr_in,//wrong prediction, need to revert
    output reg  [      `ADDR_TYPE]  rob_to_if_alter_PC,
    output reg                      rob_to_pr_ready,  
    output reg  [      `ADDR_TYPE]  rob_to_pr_PC,
    output reg                      rob_to_pr_br_taken,

    output wire                     rob_full
);

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
assign rob_full = (nxt_tail == head) || (head == 0 && nxt_tail == `ROB_SIZE - 1);
assign nxt_head = (head + 1 == `ROB_SIZE) ? 1 : head + 1;
assign nxt_tail = (tail + 1 == `ROB_SIZE) ? 1 : tail + 1;
assign rob_to_dc_rename_index = nxt_tail;
assign rob_to_dc_rs1_ready = rob_ready[dc_to_rob_rs1_check];
assign rob_to_dc_rs1_val = rob_result[dc_to_rob_rs1_check];
assign rob_to_dc_rs2_ready = rob_ready[dc_to_rob_rs2_check];
assign rob_to_dc_rs2_val = rob_result[dc_to_rob_rs2_check];
assign rob_to_lsb_ready = !rob_empty;
assign rob_to_lsb_commit_index = nxt_head;

integer i;
integer file_p;
integer clk_cnt;

// initial begin
//     file_p = $fopen("PC.txt");
//     clk_cnt = 0;
// end

always @(posedge clk_in) begin
    // $display("rob head %d tail %d", head, tail);
    // clk_cnt <= clk_cnt + 1;
    // $fdisplay(file_p, "clk_cnt: %d", clk_cnt);
    if (rst_in || clr_in) begin
        // if (clr_in) begin
        //     $display("rob clr, clk_cnt: %d", clk_cnt);
        // end
        head <= 0;
        tail <= 0;
        rob_to_pr_ready <= `FALSE;
        rob_to_reg_commit <= `FALSE;
        clr_in <= 0;

        // clearing everything in the buffer
        for (i = 0; i < `ROB_SIZE; i = i + 1) begin
            rob_ready[i] <= `FALSE;
            rob_rd[i] <= 0;
            rob_opType[i] <= 0;
            rob_PC[i] <= 0;
            rob_brPC[i] <= 0;
            rob_result[i] <= 0;
            rob_pred_br[i] <= 0;
            rob_true_br[i] <= 0;
        end
    end
    else if (!rdy_in) begin
        ;
    end
    else begin
        // $fdisplay(file_p, "Issue PC: %x", issue_PC);
        if (lsb_ready) begin
            rob_ready[lsb_rob_index] <= `TRUE;//must be head of rob
            rob_result[lsb_rob_index] <= lsb_result;
        end
        if (alu_ready) begin
            rob_ready[alu_rob_index] <= `TRUE;
            rob_result[alu_rob_index] <= alu_result;
            rob_brPC[alu_rob_index] <= alu_newPC;
            rob_true_br[alu_rob_index] <= alu_branch;
        end
        if (issue_ready && !rob_full && !lsb_full && !rs_full) begin
            // $display("ROB accept issue pc: %x, clk_cnt: %d", issue_PC, clk_cnt);
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
            // $fdisplay(file_p, "rob committing");
            // $fdisplay(file_p, "PC: %x", rob_PC[nxt_head]);
            // $fdisplay(file_p, "prediction: %d", rob_pred_br[nxt_head]);
            // $fdisplay(file_p, "true branch: %d", rob_true_br[nxt_head]);
            if (rob_pred_br[nxt_head] != rob_true_br[nxt_head]) begin
                clr_in <= 1;
                rob_to_if_alter_PC <= rob_pred_br[nxt_head] ? rob_PC[nxt_head] + 4 : rob_brPC[nxt_head];
                // $fdisplay(file_p, "branch fail");
                // $display("rob_PC[nxt_head] = %d, rob_brPC[nxt_head] = %d", rob_PC[nxt_head], rob_brPC[nxt_head]);
                // $display("PC changed to %x", rob_pred_br[nxt_head] ? rob_PC[nxt_head] + 4 : rob_brPC[nxt_head]);
            end//maybe JALR
            if (rob_opType[nxt_head] == `OP_BR) begin
                rob_to_pr_ready <= `TRUE;
                rob_to_pr_PC <= rob_PC[nxt_head];
                rob_to_pr_br_taken <= rob_true_br[nxt_head];
            end
            else begin
                rob_to_pr_ready <= `FALSE;
            end
            // if (rob_rd[nxt_head] != 0)
            // $fdisplay(file_p, "rob index %d committing PC %x, value: %d, clk_cnt: %d", rob_rd[nxt_head], rob_PC[nxt_head], rob_result[nxt_head], clk_cnt);
            rob_to_reg_commit <= `TRUE;
            rob_to_reg_index <= rob_rd[nxt_head];
            rob_to_reg_rob_index <= nxt_head;
            rob_to_reg_val <= rob_result[nxt_head];
        end
        else begin
            rob_to_pr_ready <= `FALSE;
            rob_to_reg_commit <= `FALSE;
        end
    end
end

endmodule