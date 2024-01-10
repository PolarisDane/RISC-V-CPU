`include "def.v"

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
    output wire [       `DATA_TYPE] reg_to_dc_rs1_val,
    output wire [       `DATA_TYPE] reg_to_dc_rs2_val,
    output wire [  `ROB_INDEX_TYPE] reg_to_dc_rs1_depend,
    output wire [  `ROB_INDEX_TYPE] reg_to_dc_rs2_depend,

    input wire                      rob_to_reg_commit,
    input wire  [  `ROB_INDEX_TYPE] rob_to_reg_rob_index,
    input wire  [  `REG_INDEX_TYPE] rob_to_reg_index,
    input wire  [       `DATA_TYPE] rob_to_reg_val
);

reg [                   `DATA_TYPE] reg_val[`REG_SIZE-1:0];
reg [              `ROB_INDEX_TYPE] reg_depend[`REG_SIZE-1:0];
integer i;

integer file_p;
integer clk_cnt;

// initial begin
//     clk_cnt = 0;
//     file_p = $fopen("reg.txt");
// end

assign reg_to_dc_rs1_val = (rob_to_reg_commit && (rob_to_reg_rob_index == reg_depend[dc_to_reg_rs1_pos])) ? rob_to_reg_val : reg_val[dc_to_reg_rs1_pos];
assign reg_to_dc_rs1_depend = (rob_to_reg_commit && (rob_to_reg_rob_index == reg_depend[dc_to_reg_rs1_pos])) ? 0 : reg_depend[dc_to_reg_rs1_pos];
assign reg_to_dc_rs2_val = (rob_to_reg_commit && (rob_to_reg_rob_index == reg_depend[dc_to_reg_rs2_pos])) ? rob_to_reg_val : reg_val[dc_to_reg_rs2_pos];
assign reg_to_dc_rs2_depend = (rob_to_reg_commit && (rob_to_reg_rob_index == reg_depend[dc_to_reg_rs2_pos])) ? 0 : reg_depend[dc_to_reg_rs2_pos];

always @(posedge clk_in) begin
    clk_cnt <= clk_cnt + 1;
    // $fdisplay(file_p, "clk: %d", clk_cnt);
    // $fdisplay(file_p, "reg t0: %x", reg_val[5]);
    if (rst_in) begin
        for (i = 0; i < `REG_SIZE; i = i + 1) begin
            reg_val[i] <= 0;
            reg_depend[i] <= 0;
        end
    end
    else if (!rdy_in) begin
        ;
    end
    else begin
        if (clr_in) begin
            for (i = 0; i < `REG_SIZE; i = i + 1) begin
                reg_depend[i] <= 0;
            end
        end
        if (rob_to_reg_commit) begin
            // $display("rob committing to regfile");
            if (rob_to_reg_index != 0) begin
                // $fdisplay(file_p, "RF: %d\t<=\t%d", rob_to_reg_index, rob_to_reg_val);
                // $fdisplay(file_p, "RF: %d\t<=\t%d, clk_cnt: %d", rob_to_reg_index, rob_to_reg_val, clk_cnt);
                reg_val[rob_to_reg_index] <= rob_to_reg_val;
                if (reg_depend[rob_to_reg_index] == rob_to_reg_rob_index) begin
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