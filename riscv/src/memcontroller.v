`define STATUS_IDLE 2'b00
`define STATUS_LOAD 2'b01
`define STATUS_STORE 2'b10
`define STATUS_IF 2'b11

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
    output reg [  `DATA_TYPE]       mc_to_if_inst,
    output reg                      mc_to_if_ready,

    //...
    input wire                      lsb_to_mc_ready,
    input wire                      lsb_to_mc_op,
    input wire                      lsb_to_mc_opType
);

reg [                   31:0]       memResult;
reg [                    2:0]       status;
reg [                    2:0]       byte_index;
reg 

always @(*) begin
    
end

always @(posedge clk_in) begin
    if (rst) begin
        mc_to_if_ready <= `FALSE;
        mc_to_if_inst <= 0;
    end
    else if (!rdy) begin
        ;
    end
    else begin
        if (status == `STATUS_IDLE) begin
            byte_index = 2'b00;
            //LSB and IF, who goes first?
            if (if_to_mc_ready) begin
                mc_to_mem_addr = if_to_mc_PC;
            end
            else if (lsb_to_mc_ready) begin
                
            end
        end
        else if (status == `STATUS_LOAD) begin
            mc_to_mem_wr = 0;
            
        end
        else if (status == `STATUS_STORE) begin
            mc_to_mem_wr = 1;

        end
        else if (status == `STATUS_IF) begin
            mc_to_mem_wr = 0;
            mc_to_if_inst[(byte_index + 1) * 8 - 1:byte_index * 8] = mem_to_mc_din;
            if (byte_index == 2'b11) begin
                mc_to_if_ready = `TRUE;
                status = `STATUS_IDLE;
            end
            byte_index = byte_index + 1;
        end
    end
end

endmodule