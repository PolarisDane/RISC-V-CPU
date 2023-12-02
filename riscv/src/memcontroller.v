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
    input wire                      lsb_to_mc_ready
);

reg [                   31:0]       memResult;
reg [                    2:0]       status;
reg [                    2:0]       if_byte_index;
reg [                    2:0]       lsb_byte_index;

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
            lsb_byte_index = 2'b00;
        end
        else begin
            //...
            lsb_byte_index = lsb_byte_index + 1;
        end
        if () begin
            mc_to_if_ready = 0;
            if_byte_index = 0;
        end
        if (if_to_mc_ready) begin
            mc_to_if_inst[(byte_index + 1) * 8 - 1:byte_index * 8] = mem_to_mc_din;
            if (byte_index == 2'b11) begin
                mc_to_if_ready = `TRUE;
                if_byte_index = 2'b00;
            end
            else begin
                if_byte_index = if_byte_index + 1;
            end
        end
    end
end

endmodule