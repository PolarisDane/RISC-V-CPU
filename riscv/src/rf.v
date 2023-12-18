module RegisterFile (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    input wire                      clr_in,

    input wire                      issue_ready,
    input wire  [  `REG_INDEX_TYPE] issue_rd,
    input wire  [  `ROB_INDEX_TYPE] issue_rob_index,

    input wire  [  `REG_INDEX_TYPE] dc_to_reg_rs1_pos,
    input wire  [  `REG_INDEX_TYPE] dc_to_reg_rs2_pos,
    output reg  [       `DATA_TYPE] reg_to_dc_rs1_val,
    output reg  [       `DATA_TYPE] reg_to_dc_rs2_val,
    output reg  [  `ROB_INDEX_TYPE] reg_to_dc_rs1_depend,
    output reg  [  `ROB_INDEX_TYPE] reg_to_dc_rs2_depend,

    input wire                      rob_to_reg_commit,
    input wire  [  `ROB_INDEX_TYPE] rob_to_reg_rob_index,
    input wire  [  `REG_INDEX_TYPE] rob_to_reg_index,
    input wire  [       `DATA_TYPE] rob_to_reg_val
)

reg [                   `DATA_TYPE] reg_val[`REG_SIZE];
reg [              `ROB_INDEX_TYPE] reg_depend[`REG_SIZE];
integer i;

assign reg_to_dc_rs1_val = reg_val[dc_to_reg_rs1_pos];
assign reg_to_dc_rs1_depend = reg_depend[dc_to_reg_rs1_pos];
assign reg_to_dc_rs2_val = reg_val[dc_to_reg_rs2_pos];
assign reg_to_dc_rs2_depend = reg_depend[dc_to_reg_rs2_pos];

always @(*) begin
    if (rob_to_reg_commit && rob_to_reg_rob_index == reg_depend[dc_to_reg_rs1_pos]) begin
        reg_to_dc_rs1_val <= rob_to_reg_val;
        reg_to_dc_rs1_depend <= 0;
    end
    else begin
        reg_to_dc_rs1_val <= reg_val[dc_to_reg_rs1_pos];
        reg_to_dc_rs1_depend <= reg_depend[dc_to_reg_rs1_pos];
    end
    if (rob_to_reg_commit && rob_to_reg_rob_index == reg_depend[dc_to_reg_rs2_pos]) begin
        reg_to_dc_rs2_val <= rob_to_reg_val;
        reg_to_dc_rs2_depend <= 0;
    end
    else begin
        reg_to_dc_rs2_val <= reg_val[dc_to_reg_rs2_pos];
        reg_to_dc_rs2_depend <= reg_depend[dc_to_reg_rs2_pos];
    end
end

always @(posedge clk_in) begin
    if (rst_in) begin
        for (i = 0; i < `REG_SIZE; i = i + 1) begin
            reg_val[i] <= 0;
            reg_depend[i] <= 0;
        end
    end
    else if (rdy_in) begin
        ;
    end
    else begin
        if (rob_to_reg_commit) begin
            if (rob_to_reg_index != 0) begin
                reg_val[rob_to_reg_index] <= rob_to_reg_val;
                if (reg_depend[rob_to_reg_rob_index] == rob_to_reg_rob_index) begin
                   reg_depend[rob_to_reg_index] <= 0;
                end
            end//x0 can't be modified
        end
        if (issue_ready && issue_rd != 0) begin
            reg_depend[issue_rd] <= issue_rob_index;
        end//x0 has no dependency
    end
end

endmodule