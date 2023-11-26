module memcontroller (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire                      io_buffer_full,
    input wire [         7:0]       mem_to_mc_din,
    output reg [         7:0]       mc_to_mem_dout,
    output reg [        31:0]       mc_to_mem_addr,
    output reg                      mc_to_mem_wr//read or write

    input wire [  `ADDR_TYPE]       if_to_mc_PC,
    input wire                      if_to_mc_ready,
    output reg [  `DATA_TYPE]       mc_to_if_result,
    output reg                      mc_to_if_ready
);

    reg        [        31:0]       memResult;

always @(*) begin
    
end

always @(posedge clk_in) begin
    if (rst) begin
        mc_to_if_ready = `FALSE;
        mc_to_if_result = 0;
    end
    else if (!rdy) begin

    end
    else begin
        mc_to_if_ready = `FALSE;
        mc_to_if_result = 0;

    end
end

endmodule