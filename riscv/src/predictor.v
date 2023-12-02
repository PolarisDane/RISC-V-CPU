module predictor (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire                      rob_to_pr_br_commit,
    input wire                      rob_to_pr_br_taken,
    input wire [  `ADDR_TYPE]       if_to_pr_PC,
    output reg                      pr_to_if_predict
)

reg [];

endmodule