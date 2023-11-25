module memcontroller (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire                      io_buffer_full,
    input wire [         7:0]       mem_din,
    output reg [         7:0]       mem_dout,
    output reg [        31:0]       mem_addr,
    output reg                      mem_wr

    input wire [  `ADDR_TYPE]       if_to_mc_PC,
    output reg [  `DATA_TYPE]       mc_to_if_result,
    output reg                      mc_to_if_ready,
);

    reg        [        31:0]       memResult;

always @(*) begin
    mem_dout = 8'b0;
    mem_addr = 32'b0;
    mem_wr = 1'b0;
end

always @(posedge clk_in) begin
    if (rst) begin

    end
    else if (!rdy) begin

    end
    else begin
    
    end
end

endmodule