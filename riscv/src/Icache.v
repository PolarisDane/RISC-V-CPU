`include "def.v"

module Icache (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire  [  `ADDR_TYPE]      if_to_ic_fetch_addr,
    input wire  [  `ADDR_TYPE]      if_to_ic_update_addr,
    input wire  [  `INST_TYPE]      if_to_ic_inst,
    input wire                      if_to_ic_inst_valid,

    output wire                     ic_to_if_hit,
    output wire [  `INST_TYPE]      ic_to_if_hit_inst
);

reg [              `INST_TYPE]      cacheData[`ICACHE_SIZE - 1:0];
reg [       `ICACHE_TAG_RANGE]      cacheTag[`ICACHE_SIZE - 1:0];
reg                                 cacheValid[`ICACHE_SIZE - 1:0];                

wire [    `ICACHE_INDEX_RANGE]      fetch_index;
wire [      `ICACHE_TAG_RANGE]      fetch_tag;
wire [    `ICACHE_INDEX_RANGE]      update_index;
wire [      `ICACHE_TAG_RANGE]      update_tag;

assign fetch_index = if_to_ic_fetch_addr[`ICACHE_INDEX_RANGE];
assign fetch_tag = if_to_ic_fetch_addr[`ICACHE_TAG_RANGE];
assign update_index = if_to_ic_update_addr[`ICACHE_INDEX_RANGE];
assign update_tag = if_to_ic_update_addr[`ICACHE_TAG_RANGE];
assign ic_to_if_hit = cacheValid[fetch_index] && (cacheTag[fetch_index] == fetch_tag);
assign ic_to_if_hit_inst = cacheData[fetch_index];

integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        for (i = 0; i < `ICACHE_SIZE; i= i + 1) begin
            cacheData[i] <= 0;
            cacheTag[i] <= 0;
            cacheValid[i] <= 0;
        end
    end
    else if (!rdy_in) begin
        ;
    end
    else begin
        if (if_to_ic_inst_valid) begin
            cacheData[update_index] <= if_to_ic_inst;
            cacheValid[update_index] <= 1'b1;
            cacheTag[update_index] <= update_tag;
        end
    end
end

endmodule