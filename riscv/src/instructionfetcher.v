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
    output reg [       `ADDR_TYPE]  if_to_ic_inst_addr,
    output reg [       `INST_TYPE]  if_to_ic_inst,
    output reg                      if_to_ic_inst_valid,

    input wire [       `ADDR_TYPE]  rob_to_if_alter_PC,

    output wire [      `ADDR_TYPE]  if_to_pr_PC,
    input wire                      pr_to_if_prediction
);

reg [                `STATUS_TYPE]  status;
reg [                  `ADDR_TYPE]  PC;
reg [                  `ADDR_TYPE]  nxtPC;
assign if_to_pr_PC = PC;

always @(*) begin
    if_to_dc_pred_br = pr_to_if_prediction;
    if (mc_to_if_inst[`OPTYPE_RANGE] == `OP_JALR) begin
        nxtPC = PC + 4;
        if_to_dc_pred_br = `FALSE;
    end
    else if (mc_to_if_inst[`OPTYPE_RANGE] == `OP_JAL) begin
        nxtPC = PC + {{12{mc_to_if_inst[31]}},mc_to_if_inst[19:12],mc_to_if_inst[20],mc_to_if_inst[30:21],1'b0};
        if_to_dc_pred_br = `TRUE;
    end
    else if (mc_to_if_inst[`OPTYPE_RANGE] == `OP_BR && pr_to_if_prediction) begin
        nxtPC = PC + {{20{mc_to_if_inst[31]}},mc_to_if_inst[7],mc_to_if_inst[30:25],mc_to_if_inst[11:8],1'b0};
    end
    else begin
        nxtPC = PC + 4;
    end
end

integer file_p;

initial begin
    file_p = $fopen("if.txt");
end

always @(posedge clk_in) begin
    // $display("IF PC: %x", PC);
    if (rst_in) begin
        status <= `STATUS_IDLE;
        if_to_mc_ready <= `FALSE;
        if_to_dc_ready <= `FALSE;
        if_to_ic_inst_valid <= `FALSE;
        PC <= 0;
        nxtPC <= 0;
    end
    else if (!rdy_in) begin
        ;
    end
    else if (stall) begin
        ;
    end
    else begin
        if_to_dc_ready = `FALSE;
        if_to_ic_inst_valid = `FALSE;
        if (clr_in) begin
            // $display("if PC altered!!!");
            status <= `STATUS_IDLE;
            if_to_mc_ready <= `FALSE;
            PC <= rob_to_if_alter_PC;
        end
        else begin
            if (ic_to_if_hit) begin
                if_to_mc_ready <= `FALSE;
                if_to_dc_inst <= ic_to_if_hit_inst;
                if_to_dc_ready <= `TRUE;
                if_to_dc_PC <= PC;
                if_to_dc_opType <= if_to_dc_inst[`OPTYPE_RANGE];
                PC <= nxtPC;
                if_to_ic_inst_addr <= nxtPC;
            end
            else begin
                $fdisplay(file_p, "if check");
                if (status == `STATUS_IDLE) begin
                    $fdisplay(file_p, "if idle");
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
                        if_to_ic_inst_addr <= PC;
                        if_to_ic_inst <= mc_to_if_inst;
                        if_to_ic_inst_valid <= `TRUE;
                        if_to_dc_inst <= mc_to_if_inst;
                        if_to_dc_ready <= `TRUE;
                        if_to_dc_PC <= PC;
                        if_to_dc_opType <= mc_to_if_inst[`OPTYPE_RANGE];
                        PC <= nxtPC;
                        status <= `STATUS_IDLE;
                    end
                end
            end
        end
    end
end

endmodule