`define STATUS_BUSY 2'b11;
`define STATUS_IDLE 2'b00;

`include "Icache.v"

module InstructionFetcher (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    input wire                      clr_in,

    input wire                      stall,

    input wire [  `INST_TYPE]       mc_to_if_inst,
    input wire                      mc_to_if_ready,
    output reg [  `ADDR_TYPE]       if_to_mc_PC,
    output reg                      if_to_mc_ready,

    output reg                      if_to_dc_ready,
    output reg [    `OP_TYPE]       if_to_dc_opType,
    output reg [  `ADDR_TYPE]       if_to_dc_PC,
    output reg [  `INST_TYPE]       if_to_dc_inst,

    input wire                      ic_to_if_hit,
    input wire [  `INST_TYPE]       ic_to_if_hit_inst,
    output reg [  `ADDR_TYPE]       if_to_ic_inst_addr,
    output reg [  `INST_TYPE]       if_to_ic_inst,
    output reg                      if_to_ic_inst_valid,

    input wire                      rob_to_if_alter_pc_ready,
    input wire [  `ADDR_TYPE]       rob_to_if_alter_pc,

    input wire                      pr_to_if_jump
);

reg [           `STATUS_TYPE]       status;
reg [             `ADDR_TYPE]       PC;
reg [             `ADDR_TYPE]       nxtPC;

always @(*) begin
    if (if_to_dc_inst[`OPTYPE_RANGE] == `OP_JAL) begin
        nxtPC <= PC + {{12{if_to_dc_inst[31]}},if_to_dc_inst[19:12],if_to_dc_inst[20],if_to_dc_inst[30:21],1'b0};
    end
    else if (if_to_dc_inst[`OPTYPE_RANGE] == `OP_BR && pr_to_if_prediction) begin
        nxtPC <= PC + {{20{if_to_dc_inst[31]}},if_to_dc_inst[7],if_to_dc_inst[30:25],if_to_dc_inst[11:8],1'b0};
    end
    else begin
        nxtPC <= PC + 4;
    end
end

always @(posedge clk_in) begin
    if (rst_in) begin
        status <= `STATUS_IDLE;
        if_to_mc_ready <= `FALSE;
        if_to_dc_ready <= `FALSE;
        if_to_ic_ready <= `FALSE;
        if_to_ic_inst_valid <= `FALSE;
        PC <= `BLANK_ADDR;
        nxtPC <= `BLANK_ADDR;
    end
    else if (!rdy) begin
        ;
    end
    else if (stall) begin
        ;
    end
    else begin
        if_to_ic_inst_valid = `FALSE;
        if (rob_to_if_alter_pc_ready) begin
            PC = rob_to_if_alter_pc;
        end
        else begin
            if (ic_to_if_hit) begin
                if_to_dc_inst <= ic_to_if_hit_inst;
                if_to_dc_ready <= `TRUE;
                if_to_dc_PC <= PC;
                if_to_dc_opType <= if_to_dc_inst[`OPTYPE_RANGE];
                PC <= nxtPC;
                if_to_ic_inst_addr <= nxtPC;
            end
            else begin
                if (status == `STATUS_IDLE) begin
                    if_to_mc_ready <= `TRUE;
                    if_to_mc_PC <= PC;
                    status <= `STATUS_BUSY;
                end
                else begin
                    if (mc_to_if_ready) begin
                        if_to_ic_inst_addr <= PC;
                        if_to_ic_inst <= mc_to_if_inst;
                        if_to_ic_inst_valid <= `TRUE;
                        if_to_dc_inst <= mc_to_if_inst;
                        if_to_dc_ready <= `TRUE;
                        if_to_dc_PC <= PC;
                        if_to_dc_opType <= mc_to_if_inst[`OPTYPE_RANGE];
                        PC <= nxtPC;
                        if_to_ic_inst_addr <= nxtPC;
                        status <= `STATUS_IDLE;
                    end
                end
            end
        end
    end
end

endmodule