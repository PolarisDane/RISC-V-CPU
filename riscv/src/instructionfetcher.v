module instructionfetcher (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire [  `INST_TYPE]       mc_to_if_inst,
    output reg [  `ADDR_TYPE]       if_to_mc_PC,

    output reg                      if_to_dc_ready,
    output reg [    `OP_TYPE]       if_to_dc_opType,
    output reg [`OPENUM_TYPE]       if_to_dc_op,
    output reg [  `ADDR_TYPE]       if_to_dc_PC,
    output reg [  `INST_TYPE]       if_to_dc_inst
);

    reg [  `ADDR_TYPE]  PC;

always @(*) begin

end

endmodule