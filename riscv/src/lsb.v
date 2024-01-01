`include "def.v"

`define STATUS_BUSY 2'b11
`define STATUS_IDLE 2'b00

module LoadStoreBuffer (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    input wire                      clr_in,

    input wire                      issue_lsb_ready,
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

    input wire                      rob_to_lsb_ready,
    input wire [  `ROB_INDEX_TYPE]  rob_to_lsb_commit_index,    

    input wire                      alu_to_lsb_ready,
    input wire [       `DATA_TYPE]  alu_to_lsb_result,
    input wire [  `ROB_INDEX_TYPE]  alu_to_lsb_rob_index,

    input wire                      mc_to_lsb_ld_done,
    input wire                      mc_to_lsb_st_done,
    input wire [  `DATA_TYPE]       mc_to_lsb_result,
    input wire                      mc_to_lsb_valid,
    output reg                      lsb_to_mc_ready,
    output reg [   `LEN_TYPE]       lsb_to_mc_len,
    output reg [    `OP_TYPE]       lsb_to_mc_opType,
    output reg [  `DATA_TYPE]       lsb_to_mc_data,
    output reg [  `ADDR_TYPE]       lsb_to_mc_addr,

    output wire                     lsb_full,
    output reg                      lsb_ready,
    output reg [      `DATA_TYPE]   lsb_result,
    output reg [ `ROB_INDEX_TYPE]   lsb_result_rob_index
);

reg [            `ROB_INDEX_TYPE]      lsb_rob_index[`LSB_SIZE-1:0];
reg [                 `DATA_TYPE]      lsb_rs1_val[`LSB_SIZE-1:0];
reg [                 `DATA_TYPE]      lsb_rs2_val[`LSB_SIZE-1:0];
reg [            `ROB_INDEX_TYPE]      lsb_rs1_depend[`LSB_SIZE-1:0];
reg [            `ROB_INDEX_TYPE]      lsb_rs2_depend[`LSB_SIZE-1:0];
reg [                 `DATA_TYPE]      lsb_imm[`LSB_SIZE-1:0];
reg [                 `ADDR_TYPE]      lsb_PC[`LSB_SIZE-1:0];
reg [               `OPENUM_TYPE]      lsb_op[`LSB_SIZE-1:0];
reg [                   `OP_TYPE]      lsb_opType[`LSB_SIZE-1:0];

reg [               `STATUS_TYPE]      status;
reg [            `LSB_INDEX_TYPE]      head;
reg [            `LSB_INDEX_TYPE]      tail;
wire [           `LSB_INDEX_TYPE]      nxt_head;
wire [           `LSB_INDEX_TYPE]      nxt_tail;              
wire                                   lsb_empty;
reg [               `OPENUM_TYPE]      head_op;          
      
assign lsb_empty = (head == tail);
assign lsb_full = (nxt_tail == head) || (head == 0 && nxt_tail == `LSB_SIZE - 1);
assign nxt_head = (head + 1 == `LSB_SIZE) ? 1 : head + 1;
assign nxt_tail = (tail + 1 == `LSB_SIZE) ? 1 : tail + 1;

integer i;

always @(*) begin
    for (i = 0; i < `LSB_SIZE; i = i + 1) begin
        if (alu_to_lsb_ready) begin
            if (lsb_rs1_depend[i] == alu_to_lsb_rob_index) begin
                lsb_rs1_val[i] = alu_to_lsb_result;
                lsb_rs1_depend[i] = 0;
            end
            if (lsb_rs2_depend[i] == alu_to_lsb_rob_index) begin
                lsb_rs2_val[i] = alu_to_lsb_result;
                lsb_rs2_depend[i] = 0;
            end
        end
        if (lsb_ready) begin
            if (lsb_rs1_depend[i] == lsb_result_rob_index) begin
                lsb_rs1_val[i] = lsb_result;
                lsb_rs1_depend[i] = 0;
            end
            if (lsb_rs2_depend[i] == lsb_result_rob_index) begin
                lsb_rs2_val[i] = lsb_result;
                lsb_rs2_depend[i] = 0;
            end
        end
    end
end

integer file_p;
integer clk_cnt;

initial begin
    file_p = $fopen("lsb.txt");
    clk_cnt = 0;
end

always @(posedge clk_in) begin
    clk_cnt <= clk_cnt + 1;
    if (rst_in || clr_in) begin
        status <= `STATUS_IDLE;
        head <= 0;
        tail <= 0;
        lsb_to_mc_ready <= `FALSE;
        lsb_ready <= `FALSE;
    end
    else if (!rdy_in) begin
        ;
    end 
    else begin
        lsb_ready <= `FALSE;
        if (issue_lsb_ready && !lsb_full) begin
            $fdisplay(file_p, "issue to lsb rob index: %d", issue_rob_index);
            lsb_rob_index[nxt_tail] <= issue_rob_index;
            lsb_rs1_val[nxt_tail] <= issue_rs1_val;
            lsb_rs2_val[nxt_tail] <= issue_rs2_val;
            lsb_rs1_depend[nxt_tail] <= issue_rs1_depend;
            lsb_rs2_depend[nxt_tail] <= issue_rs2_depend;
            lsb_imm[nxt_tail] <= issue_imm;
            lsb_PC[nxt_tail] <= issue_PC;
            lsb_op[nxt_tail] <= issue_op;
            lsb_opType[nxt_tail] <= issue_opType;
            tail <= nxt_tail;
        end
        $fdisplay(file_p, "clk_cnt: %d, lsb_rs1_depend: %d, lsb_rs2_depend: %d, rob_to_lsb_commit_index: %d, lsb_rob_index: %d", clk_cnt, lsb_rs1_depend[nxt_head], lsb_rs2_depend[nxt_head], rob_to_lsb_commit_index, lsb_rob_index[nxt_head]);
        case (status)
            `STATUS_IDLE: begin
                if (!lsb_empty && !lsb_rs1_depend[nxt_head] && !lsb_rs2_depend[nxt_head] && rob_to_lsb_ready && rob_to_lsb_commit_index == lsb_rob_index[nxt_head]) begin
                    head <= nxt_head;
                    lsb_to_mc_ready <= `TRUE;
                    lsb_to_mc_addr <= lsb_rs1_val[nxt_head] + lsb_imm[nxt_head];
                    lsb_to_mc_data <= lsb_rs2_val[nxt_head];
                    lsb_to_mc_opType <= lsb_opType[nxt_head];
                    lsb_result_rob_index <= lsb_rob_index[nxt_head];
                    head_op <= lsb_op[nxt_head];
                    case (lsb_op[nxt_head])
                        `OPENUM_LB: begin
                            lsb_to_mc_len <= 2'b01;
                        end
                        `OPENUM_LH: begin
                            lsb_to_mc_len <= 2'b10;
                        end
                        `OPENUM_LW: begin
                            lsb_to_mc_len <= 2'b11;
                        end
                        `OPENUM_LBU: begin
                            lsb_to_mc_len <= 2'b01;
                        end
                        `OPENUM_LHU: begin
                            lsb_to_mc_len <= 2'b10;
                        end
                        `OPENUM_SB: begin
                            lsb_to_mc_len <= 2'b01;
                        end
                        `OPENUM_SH: begin
                            lsb_to_mc_len <= 2'b10;
                        end
                        `OPENUM_SW: begin
                            lsb_to_mc_len <= 2'b11;
                        end
                    endcase
                    status <= `STATUS_BUSY;
                end
            end
            `STATUS_BUSY: begin
                if (mc_to_lsb_valid) begin
                    lsb_to_mc_ready <= `FALSE;
                end
                if (mc_to_lsb_ld_done) begin
                    case (head_op)
                        `OPENUM_LB: begin
                            lsb_result <= {24'b0, mc_to_lsb_result[7:0]};
                        end
                        `OPENUM_LH: begin
                            lsb_result <= {16'b0, mc_to_lsb_result[15:0]};
                        end
                        `OPENUM_LW: begin
                            lsb_result <= mc_to_lsb_result;
                        end
                        `OPENUM_LBU: begin
                            lsb_result <= {{24{mc_to_lsb_result[7]}}, mc_to_lsb_result[7:0]};
                        end
                        `OPENUM_LHU: begin
                            lsb_result <= {{16{mc_to_lsb_result[15]}}, mc_to_lsb_result[15:0]};
                        end
                    endcase
                    lsb_ready <= `TRUE;
                    status <= `STATUS_IDLE;
                end
                if (mc_to_lsb_st_done) begin
                    lsb_ready <= `TRUE;
                    status <= `STATUS_IDLE;
                end
            end
        endcase
    end
end

endmodule