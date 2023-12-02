`define ICACHE_TAG_RANGE 10:2
`define ICACHE_INDEX_RANGE 31:11
`define IACHE_SIZE 128

module Icache (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire  [  `ADDR_TYPE]      if_to_ic_inst_addr,
    input wire  [  `INST_TYPE]      if_to_ic_inst,
    input wire                      if_to_ic_inst_valid,
    input wire                      if_to_ic_ready,

    output wire                     ic_to_if_hit,
    output wire [  `INST_TYPE]      ic_to_if_hit_inst
)

reg [              `INST_TYPE]      cacheData[`ICACHE_SIZE - 1:0];
reg [       `ICACHE_TAG_RANGE]      cacheTag[`ICACHE_SIZE - 1:0];
reg                                 cacheValid[`ICACHE_SIZE - 1:0];                

wire [    `ICACHE_INDEX_RANGE]      index;

assign index = if_to_ic_inst_addr[`ICACHE_INDEX_RANGE];
assign ic_to_if_hit = if_to_ic_ready && (cacheTag[`ICACHE_INDEX_RANGE] == if_to_ic_inst_addr[`ICACHE_TAG_RANGE]) && cacheValid[index];
assign ic_to_if_inst = cacheData[if_to_ic_inst_addr[`ICACHE_TAG_RANGE]];

integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        for (i = 0; i < ICACHE_SIZE; i= i + 1) begin
            cacheData[i] <= 0;
            cacheTag[i] <= 0;
            cacheValid[i] <= 0;
        end
    end
    else if (!rdy) begin
        ;
    end
    else begin
        cacheData[index] <= if_to_ic_inst;
        cacheValid[index] <= 1'b1;
        cacheTag[index] <= if_to_ic_inst_addr[`ICACHE_TAG_RANGE];
    end
end

endmodule