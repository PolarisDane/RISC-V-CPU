`include "def.v"

`define STATUS_BUSY 2'b11
`define STATUS_IDLE 2'b00

module InstructionFetcher (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    input wire                      clr_in,

    input wire                      mc_valid,
    input wire [       `INST_TYPE]  mc_to_if_inst,
    input wire                      mc_to_if_ready,
    output reg [       `ADDR_TYPE]  if_to_mc_PC,
    output reg                      if_to_mc_ready,

    input wire                      stall,
    output reg                      if_to_dc_ready,
    output reg [         `OP_TYPE]  if_to_dc_opType,
    output reg [       `ADDR_TYPE]  if_to_dc_PC,
    output reg [       `INST_TYPE]  if_to_dc_inst,
    output reg                      if_to_dc_pred_br,

    input wire                      ic_to_if_hit,
    input wire [       `INST_TYPE]  ic_to_if_hit_inst,
    output reg [       `ADDR_TYPE]  if_to_ic_fetch_addr,
    output reg [       `ADDR_TYPE]  if_to_ic_update_addr,
    output reg [       `INST_TYPE]  if_to_ic_inst,
    output reg                      if_to_ic_inst_valid,

    input wire [       `ADDR_TYPE]  rob_to_if_alter_PC,

    output wire [      `ADDR_TYPE]  if_to_pr_PC,
    input wire                      pr_to_if_prediction
);

reg [                `STATUS_TYPE]  status;
reg [                  `ADDR_TYPE]  PC;
wire [                 `ADDR_TYPE]  nxtPC;
wire [                 `INST_TYPE]  cur_inst;
wire                                pred;
assign if_to_pr_PC = PC;
assign cur_inst = ic_to_if_hit ? ic_to_if_hit_inst : (mc_to_if_ready ? mc_to_if_inst : 0);
assign pred = cur_inst[`OPTYPE_RANGE] == `OP_BR ? pr_to_if_prediction
    : (cur_inst[`OPTYPE_RANGE] == `OP_JAL ? 1 : 0);
assign nxtPC = cur_inst[`OPTYPE_RANGE] == `OP_JAL ? PC + {{12{cur_inst[31]}},cur_inst[19:12],cur_inst[20],cur_inst[30:21],1'b0}
    : ((cur_inst[`OPTYPE_RANGE] == `OP_BR && pred) ? PC + {{20{cur_inst[31]}},cur_inst[7],cur_inst[30:25],cur_inst[11:8],1'b0} : PC + 4);

integer file_p;
integer clk_cnt;

initial begin
    file_p = $fopen("if.txt");
    clk_cnt = 0;
end

always @(posedge clk_in) begin
    clk_cnt <= clk_cnt + 1;
    if (rst_in) begin
        status <= `STATUS_IDLE;
        if_to_mc_ready <= `FALSE;
        if_to_dc_ready <= `FALSE;
        if_to_ic_inst_valid <= `FALSE;
        if_to_ic_fetch_addr <= 0;
        PC <= 0;
    end
    else if (!rdy_in) begin
        ;
    end
    else if (stall) begin
        if_to_dc_ready <= `FALSE;
    end
    else begin
        if_to_dc_ready <= `FALSE;
        if_to_ic_inst_valid <= `FALSE;
        if (clr_in) begin
            status <= `STATUS_IDLE;
            if_to_mc_ready <= `FALSE;
            PC <= rob_to_if_alter_PC;
            if_to_ic_fetch_addr <= rob_to_if_alter_PC;
        end
        else begin
            if_to_dc_pred_br <= pred;
            if (ic_to_if_hit) begin
                $fdisplay(file_p, "clk_cnt: %d, PC: %x, inst: %x", clk_cnt, PC, ic_to_if_hit_inst);
                if_to_mc_ready <= `FALSE;
                if_to_dc_ready <= `TRUE;
                if_to_dc_PC <= PC;
                if_to_dc_opType <= ic_to_if_hit_inst[`OPTYPE_RANGE];
                if_to_dc_inst <= ic_to_if_hit_inst;
                if_to_ic_fetch_addr <= nxtPC;
                PC <= nxtPC;
            end
            else begin
                if (status == `STATUS_IDLE) begin
                    if_to_mc_ready <= `TRUE;
                    if_to_mc_PC <= PC;
                    status <= `STATUS_BUSY;
                end
                else begin
                    if (mc_valid) begin
                        if_to_mc_ready <= `FALSE; 
                    end
                    if (mc_to_if_ready) begin
                        if_to_mc_ready <= `FALSE;
                        if_to_ic_update_addr <= PC;
                        if_to_ic_inst <= mc_to_if_inst;
                        if_to_ic_inst_valid <= `TRUE;
                        if_to_ic_fetch_addr <= nxtPC;
                        if_to_dc_ready <= `TRUE;
                        if_to_dc_PC <= PC;
                        if_to_dc_opType <= mc_to_if_inst[`OPTYPE_RANGE];
                        if_to_dc_inst <= mc_to_if_inst;
                        PC <= nxtPC;
                        status <= `STATUS_IDLE;
                    end
                end
            end
        end
    end
end

endmodule