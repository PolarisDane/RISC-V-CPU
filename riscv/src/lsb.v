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
    output reg                      lsb_to_mc_ready,
    output reg [   `LEN_TYPE]       lsb_to_mc_len,
    output reg [    `OP_TYPE]       lsb_to_mc_opType,
    output reg [  `DATA_TYPE]       lsb_to_mc_data,
    output reg [  `ADDR_TYPE]       lsb_to_mc_addr,

    output wire                     lsb_full,
    output reg                      lsb_ready,
    output reg [      `DATA_TYPE]   lsb_result,
    output reg [ `ROB_INDEX_TYPE]   lsb_rob_index
)

reg [            `ROB_INDEX_TYPE]      lsb_rob_index[`LSB_SIZE-1:0];
reg [                 `DATA_TYPE]      lsb_rs1_val[`LSB_SIZE-1:0];
reg [                 `DATA_TYPE]      lsb_rs2_val[`LSB_SIZE-1:0];
reg [            `ROB_INDEX_TYPE]      lsb_rs1_depend[`LSB_SIZE-1:0];
reg [            `ROB_INDEX_TYPE]      lsb_rs2_depend[`LSB_SIZE-1:0];
reg [                 `DATA_TYPE]      lsb_imm[`LSB_SIZE-1:0];
reg [                 `ADDR_TYPE]      lsb_PC[`LSB_SIZE-1:0];
reg [               `OPENUM_TYPE]      lsb_op[`LSB_SIZE-1:0];
reg [                   `OP_TYPE]      lsb_opType[`LSB_SIZE-1:0];
reg                                    lsb_valid[`LSB_SIZE-1:0];

reg [                        1:0]      status;
reg [                 `LSB_RANGE]      head;
reg [                 `LSB_RANGE]      tail;
wire [                `LSB_RANGE]      nxt_head;
wire [                `LSB_RANGE]      nxt_tail;              
wire                                   lsb_empty;                
      
assign lsb_empty = (head == tail);
assign lsb_full = (nxt_tail == head);
assign nxt_head = (nxt_head + 1) % `LSB_SIZE;
assign nxt_tail = (nxt_tail + 1) % `LSB_SIZE;

integer i;

always @(*) begin
    for (i = 0; i < `LSB_SIZE; i = i + 1) begin
        lsb_valid[i] <= `FALSE;
        if (alu_to_lsb_ready) begin
            if (lsb_rs1_depend[i] == alu_to_lsb_rob_index) begin
                lsb_rs1_val[i] <= alu_to_lsb_result;
                lsb_rs1_depend[i] <= 0;
            end
            if (lsb_rs2_depend[i] == alu_to_lsb_rob_index) begin
                lsb_rs2_val[i] <= alu_to_lsb_result;
                lsb_rs2_depend[i] <= 0;
            end
        end
        if (lsb_ready) begin
            if (lsb_rs1_depend[i] == lsb_rob_index) begin
                lsb_rs1_val[i] <= lsb_result;
                lsb_rs1_depend[i] <= 0;
            end
            if (lsb_rs2_depend[i] == lsb_rob_index) begin
                lsb_rs2_val[i] <= lsb_result;
                lsb_rs2_depend[i] <= 0;
            end
        end
        if (!lsb_rs1_depend[i] && !lsb_rs2_depend[i]) begin
            lsb_valid[i] <= `TRUE;
        end
    end
end

always @(posedge clk_in) begin
    if (rst_in || clr_in) begin
        head <= 0;
        tail <= 0;
        lsb_to_mc_ready <= `FALSE;
        lsb_ready <= `FALSE;
    end
    else if (!rdy_in) begin
        ;
    end 
    else begin
        if (issue_lsb_ready && !lsb_full) begin
            lsb_rob_index[nxt_tail] <= issue_rob_index;
            lsb_rs1_val[nxt_tail] <= issue_rs1_val;
            lsb_rs2_val[nxt_tail] <= issue_rs2_val;
            lsb_rs1_depend[nxt_tail] <= issue_rs1_depend;
            lsb_rs2_depend[nxt_tail] <= issue_rs2_depend;
            lsb_imm[nxt_tail] <= issue_imm;
            lsb_PC[nxt_tail] <= issue_PC;
            lsb_op[nxt_tail] <= issue_op;
            lsb_opType[nxt_tail] <= issue_opType;
            lsb_valid[nxt_tail] <= `FALSE;
            tail <= nxt_tail;
        end
        case (status)
            `STATUS_IDLE: begin
                lsb_ready <= `FALSE;
                if (!lsb_empty && lsb_valid[nxt_head] && rob_to_lsb_ready && rob_to_lsb_commit_index == lsb_rob_index[nxt_head]) begin
                    head <= nxt_head;
                    lsb_to_mc_ready = `TRUE;
                    lsb_to_mc_addr <= lsb_rs1_val[nxt_head] + lsb_imm[nxt_head];
                    lsb_to_mc_data <= lsb_rs2_val[nxt_head];
                    lsb_to_mc_opType <= lsb_opType[nxt_head];
                    lsb_rob_index <= lsb_rob_index[nxt_head];
                    lsb_to_mc_len <= //TODO
                    status <= `STATUS_BUSY;
                end
            end
            `STATUS_BUSY: begin
                if (mc_to_lsb_ld_done) begin
                    lsb_to_mc_ready = `FALSE;
                    lsb_result <= mc_to_lsb_result;
                    lsb_ready <= `TRUE;
                    status <= `STATUS_IDLE;
                end
                if (mc_to_lsb_st_done) begin
                    lsb_to_mc_ready = `FALSE;
                    lsb_ready <= `TRUE;
                    status <= `STATUS_IDLE;
                end
            end
        endcase
    end
end

endmodule