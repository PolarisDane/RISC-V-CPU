`define STATUS_BUSY 2'b11;
`define STATUS_IDLE 2'b00;

`include "Icache.v"

module instructionfetcher (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire                      stall,

    input wire [  `INST_TYPE]       mc_to_if_inst,
    input wire                      mc_to_if_ready,
    output reg [  `ADDR_TYPE]       if_to_mc_PC,
    output reg                      if_to_mc_ready,

    output reg                      if_to_dc_ready,
    output reg [    `OP_TYPE]       if_to_dc_opType,
    output reg [`OPENUM_TYPE]       if_to_dc_op,
    output reg [  `ADDR_TYPE]       if_to_dc_PC,
    output reg [  `INST_TYPE]       if_to_dc_inst,

    input wire                      ic_to_if_hit,
    input wire [  `INST_TYPE]       ic_to_if_hit_inst,
    output reg [  `ADDR_TYPE]       if_to_ic_inst_addr,
    output reg [  `INST_TYPE]       if_to_ic_inst,
    output reg                      if_to_ic_inst_valid,
    output reg                      if_to_ic_ready,

    input wire                      rob_to_if_alter_pc_ready,
    input wire [  `ADDR_TYPE]       rob_to_if_alter_pc,
    input wire                      rob_to_pr_br_commit,
    input wire                      rob_to_pr_br_taken,
    input wire [  `ADDR_TYPE]       pr_to_if_predict,
    output reg [  `ADDR_TYPE]       if_to_pr_PC
);

reg [           `STATUS_TYPE]       status;
reg [             `ADDR_TYPE]       PC;
reg [             `ADDR_TYPE]       nxtPC;

always @(*) begin
    case (if_to_dc_opType)
        `OP_BR begin
            nxtPC = PC + {{12{if_to_dc_inst[31]}}, if_to_dc_inst[7], if_to_dc_inst[30:25], if_to_dc_inst[11:8], 1'b0};
        end
        default;
    endcase
end

Icache icache(
        .clk_in                 (clk_in),
        .rst_in                 (rst_in),
        .rdy_in                 (rdy_in),
        .if_to_ic_inst_addr     (if_to_ic_inst_addr),
        .if_to_ic_inst          (if_to_ic_inst),
        .if_to_ic_ready         (if_to_ic_ready),
        .ic_to_if_hit           (ic_to_if_hit),
        .ic_to_if_hit_inst      (ic_to_if_hit_inst)
);

always @(*) begin
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
        if (status == `STATUS_IDLE) begin
            if_to_ic_inst_valid = `FALSE;
            if_to_ic_ready = `TRUE;
            if_to_dc_ready = `FALSE;
            if (ic_to_if_hit) begin
                if_to_dc_inst = ic_to_if_hit_inst;
                if_to_dc_ready = `TRUE;
                if_to_dc_PC = PC;
                if_to_dc_opType = if_to_dc_inst[`OPTYPE_RANGE];
                //...
            end
            else begin
                if_to_mc_ready = `TRUE;
                if_to_mc_PC <= PC;
                status <= `STATUS_BUSY;
            end
        end
        else begin
            if mc_to_if_ready begin
                if_to_ic_inst_addr = PC;
                if_to_ic_inst = mc_to_if_inst;
                if_to_ic_ready = `TRUE;
                if_to_ic_inst_valid = `TRUE;
                if_to_dc_inst = mc_to_if_inst;
                if_to_dc_ready = `TRUE;
                if_to_dc_PC = PC;
                if_to_dc_opType = mc_to_if_inst[`OPTYPE_RANGE];
                //...
                status <= `STATUS_IDLE;
            end
        end
    end
end

endmodule