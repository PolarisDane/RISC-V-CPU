module Predictor (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire                      rob_to_pr_ready,
    input wire [  `ADDR_TYPE]       rob_to_pr_PC,
    input wire                      rob_to_pr_br_taken,
    input wire [  `ADDR_TYPE]       if_to_pr_PC,
    output wire                     pr_to_if_prediction
)

reg [                    1:0]       pr_state[`PREDICTOR_SIZE-1:0];
wire [`PREDICTOR_INDEX_RANGE]       rob_index;

assign prediction = pr_state[if_to_pr_PC[8:2]][1];
assign rob_index = rob_to_pr_PC[8:2];

integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        for (i = 0; i < `PREDICTOR_SIZE; i = i + 1) begin
            pr_state[i] <= 2'b10;
        end
    end
    else if (!rdy_in) begin
        ;
    end
    else begin
        if (rob_to_pr_ready) begin
            case (pr_state[rob_index])
                2'b00: begin
                    pr_state[rob_index] <= rob_to_pr_br_taken ? 2'b01 : 2'b00;
                end
                2'b01: begin
                    pr_state[rob_index] <= rob_to_pr_br_taken ? 2'b11 : 2'b00;
                end
                2'b10: begin
                    pr_state[rob_index] <= rob_to_pr_br_taken ? 2'b11 : 2'b00;
                end
                2'b11: begin
                    pr_state[rob_index] <= rob_to_pr_br_taken ? 2'b11 : 2'b10;
                end
            endcase
        end
    end
end

endmodule