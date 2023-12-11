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
reg [                   `OP_TYPE]      lsb_opType[`LSB_SIZE-1:0]
reg                                    lsb_ready[`LSB_SIZE-1:0];
reg                                    lsb_busy[`LSB_SIZE-1:0];

reg [                       31:0]       lsb_head;
reg [                       31:0]       lsb_tail;

reg [                       31:0]      vac_lsb;
reg [                       31:0]      work_lsb;             
integer i;
integer lsb_head, lsb_tail;

always @(*) begin

end

always @(posedge clk_in) begin
    if (rst_in || clr_in) begin
        for (i = 0; i < `LSB_SIZE; i = i + 1) begin
            lsb_busy[i] <= `FALSE;
        end
        lsb_to_mc_ready <= `FALSE;
    end
    else if (!rdy_in) begin
        ;
    end 
    else begin
        
    end
end

endmodule