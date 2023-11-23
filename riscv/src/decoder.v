module decoder(
    input wire                      clk_in;
    input wire                      rst_in;
    input wire                      rdy_in;

    input wire [  `ADDR_TYPE]       PC;
    input wire [  `]
);

always @(*) begin
    output reg [  `OP_TYPE]         opType;
    output reg [  `DATA_TYPE]       rs1;
    output reg [  `DATA_TYPE]       rs2;
    output reg [  `REG_INDEX_TYPE]  rd;
    output reg [  `DATA_TYPE]       imm;
end
endmodule