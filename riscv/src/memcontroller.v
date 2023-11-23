module memcontroller (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,

    input wire                      io_buffer_full,
    input wire [         7:0]       mem_din,
    output reg [         7:0]       mem_dout,
    output reg [        31:0]       mem_addr,
    output reg                      mem_wr
);

    reg        [        31:0]       memResult;

always @(*) begin
    mem_dout = 8'b0;
    mem_addr = 32'b0;
    mem_wr = 1'b0;
end

endmodule