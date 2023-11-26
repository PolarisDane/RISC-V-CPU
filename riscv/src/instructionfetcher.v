module instructionfetcher (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire [  `INST_TYPE]       mc_to_if_inst,
    input wire                      mc_to_if_ready,
    input wire [  `ADDR_TYPE]       alterPC,
    output reg [  `ADDR_TYPE]       if_to_mc_PC,
    output reg                      if_to_mc_ready,

    output reg                      if_to_dc_ready,
    output reg [    `OP_TYPE]       if_to_dc_opType,
    output reg [`OPENUM_TYPE]       if_to_dc_op,
    output reg [  `ADDR_TYPE]       if_to_dc_PC,
    output reg [  `INST_TYPE]       if_to_dc_inst
);

    reg [  `ADDR_TYPE]  PC;
    reg [  `ADDR_TYPE]  nxtPC;

always @(*) begin
    case (if_to_dc_opType)
        `OP_BR begin
            nxtPC = PC + {{12{if_to_dc_inst[31]}}, if_to_dc_inst[7], if_to_dc_inst[30:25], if_to_dc_inst[11:8], 1'b0};
        end
        default;
    endcase
end

always @(*) begin
    if_to_dc_ready = `FALSE;
    if (rst_in) begin
        if_to_mc_ready = `FALSE;
        if_to_dc_ready = `FALSE;
        PC = `BLANK_ADDR;
        nxtPC = `BLANK_ADDR;
    end
    else if (!rdy) begin
        ;
    end
    else begin
        if (!mc_to_if_ready) begin
            if_to_dc_ready = `FALSE;
        end
        else begin
            if_to_dc_ready = `TRUE;
            if_to_dc_inst = mc_to_if_inst;
            if_to_dc_PC = PC;
            if_to_mc_PC = nxtPC;
            PC = nxtPC;
            if_to_dc_opType = mc_to_if_inst[`OPTYPE_RANGE];
            case (if_to_dc_opType)
                `OP_RC begin
                    if_to_dc_op = `OPENUM_ADD;
                end
                `OP_RI begin
                    if_to_dc_op = `OPENUM_ADDI;
                end
                `OP_BR begin
                    if_to_dc_op = `OPENUM_BNE;
                end
                `OP_LD begin
                    if_to_dc_op = `OPENUM_LD;
                end
                `OP_ST begin
                    if_to_dc_op = `OPENUM_ST;
                end
            endcase
        end
    end
end

endmodule