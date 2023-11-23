module instructionfetcher (
    input wire                      clk_in;
    input wire                      rst_in;
    input wire                      rdy_in;

    input wire [  `INST_TYPE]       inst;
    output reg [    `OP_TYPE]       opType;
    output reg [  `ADDR_TYPE]       nxtPC;
    output reg [  `_TYPE]       ;
);

endmodule