`define STATUS_IDLE 2'b00
`define STATUS_LOAD 2'b01
`define STATUS_STORE 2'b10
`define STATUS_IF 2'b11

module MemController (
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

    input wire                      lsb_to_mc_ready,
    input wire [   `LEN_TYPE]       lsb_to_mc_len,
    input wire [    `OP_TYPE]       lsb_to_mc_opType,
    input wire [  `DATA_TYPE]       lsb_to_mc_data,
    input wire [  `ADDR_TYPE]       lsb_to_mc_addr,
    output reg                      mc_to_lsb_ld_done,
    output reg                      mc_to_lsb_st_done,
    output reg [  `DATA_TYPE]       mc_to_lsb_result
);

reg [                   31:0]       memResult;
reg [                    1:0]       status;
reg [                    1:0]       byte_index;

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
            byte_index <= 2'b00;
            mc_to_if_ready <= `FALSE;
            mc_to_lsb_ld_done <= `FALSE;
            mc_to_lsb_st_done <= `FALSE;
            //LSB goes first
            if (if_to_mc_ready) begin
                mc_to_mem_addr <= if_to_mc_PC;
                mc_to_mem_wr <= 0;
            end
            else if (lsb_to_mc_ready) begin
                if (lsb_to_mc_opType == `OP_LD) begin
                    mc_to_mem_addr <= lsb_to_mc_addr;
                    mc_to_mem_wr <= 0;
                    status <= `STATUS_LOAD;
                end
                else begin
                    mc_to_mem_addr = lsb_to_mc_addr;
                    mc_to_mem_wr <= 1;
                    status <= `STATUS_STORE;
                end
            end
        end
        else if (status == `STATUS_LOAD) begin
            case (byte_index)
                2'b00 begin
                    mc_to_lsb_result[7:0] <= mem_to_mc_din;
                    if (lsb_to_mc_len == 2'b01) begin
                        mc_to_lsb_result[31:8] <= 24'b0;
                        mc_to_lsb_ld_done <= `TRUE;
                        status <= `STATUS_IDLE;
                    end
                end
                2'b01 begin
                    mc_to_lsb_result[15:8] <= mem_to_mc_din;
                    if (lsb_to_mc_len == 2'b10) begin
                        mc_to_lsb_result[31:16] <= 16'b0;
                        mc_to_lsb_ld_done <= `TRUE;
                        status <= `STATUS_IDLE;
                    end
                end
                2'b10 begin
                    mc_to_lsb_result[23:16] <= mem_to_mc_din;
                end
                2'b11 begin
                    mc_to_lsb_result[31:24] <= mem_to_mc_din;
                    mc_to_lsb_ld_done <= `TRUE;
                    status <= `STATUS_IDLE;
                end
            endcase
            mc_to_mem_addr = mc_to_mem_addr + 1;
        end
        else if (status == `STATUS_STORE) begin
            case (byte_index) 
                2'b00 begin
                    mc_to_mem_dout <= lsb_to_mc_data[7:0];
                    if (lsb_to_mc_len == 2'b01) begin
                        mc_to_lsb_st_done <= `TRUE;
                        status <= `STATUS_IDLE;
                    end
                end
                2'b01 begin
                    mc_to_mem_dout <= lsb_to_mc_data[15:8];
                    if (lsb_to_mc_len == 2'b10) begin
                        mc_to_lsb_st_done <= `TRUE;
                        status <= `STATUS_IDLE;
                    end
                end
                2'b10 begin
                    mc_to_mem_dout <= lsb_to_mc_data[23:16];
                end
                2'b11 begin
                    mc_to_mem_dout <= lsb_to_mc_data[31:24];
                    mc_to_lsb_st_done <= `TRUE;
                    status <= `STATUS_IDLE;
                end
            endcase
            mc_to_mem_addr = mc_to_mem_addr + 1;
        end
        else if (status == `STATUS_IF) begin
            case (byte_index)
                2'b00 begin
                    mc_to_if_inst[7:0] <= mem_to_mc_din;
                    byte_index <= 2'b01;
                end
                2'b01 begin
                    mc_to_if_inst[15:8] <= mem_to_mc_din;
                    byte_index <= 2'b10;
                end
                2'b10 begin
                    mc_to_if_inst[23:16] <= mem_to_mc_din;
                    byte_index <= 2'b11;
                end
                2'b11 begin
                    mc_to_if_inst[31:24] <= mem_to_mc_din;
                    status <= `STATUS_IDLE;
                    mc_to_if_ready <= `TRUE;
                end
            endcase
            mc_to_mem_addr = mc_to_mem_addr + 1;
        end
    end
end

endmodule