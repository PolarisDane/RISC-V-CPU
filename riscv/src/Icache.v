`define TAG_RANGE 10:2
`define CACHE_SIZE 128

module Icache(
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire  [  `ADDR_TYPE]      inst_addr,
    input wire  [  `INST_TYPE]      inst,
    input wire                      if_to_ic_ready,


    output wire                     hit,
    output wire [  `INST_TYPE]      hit_result
)

reg []                              cacheData[CACHE_SIZE - 1:0];
reg []                              cacheTag[CACHE_SIZE - 1:0];
reg                                 cacheValid[CACHE_SIZE - 1:0];                

wire                                cacheIndex;

assign hit = if_to_ic_ready && (tag[] == inst_addr[`TAG_RANGE]) && cacheValid[inst_addr[`TAG_RANGE]];
assign hit_result = cacheData[inst_addr[`TAG_RANGE]];

integer i;

always @(posedge clk_in) begin
    if (rst_in) begin
        for (i = 0; i < CACHE_SIZE; i= i + 1) begin
            cacheData[i] <= 0;
            cacheTag[i] <= 0;
            cacheValid[i] <= 0;
        end
    end
    else if (!rdy) begin
        ;
    end
    else begin
        cacheData[cacheIndex] <= inst;
        cacheValid[cacheIndex] <= 1'b1;
        cacheTag[cacheIndex] <= inst_addr[`TAG_RANGE];
    end
end

endmodule