`include "def.v"

`define STATUS_IDLE 3'b000
`define STATUS_LOAD 3'b001
`define STATUS_STORE 3'b010
`define STATUS_IF 3'b011
`define STATUS_STALL 3'b100

module MemController (
    input wire                      clk_in,
    input wire                      rst_in,
    input wire                      rdy_in,
    input wire                      clr_in,

    input wire                      io_buffer_full,
    input wire [              7:0]  mem_to_mc_din,
    output reg [              7:0]  mc_to_mem_dout,
    output reg [             31:0]  mc_to_mem_addr,
    output reg                      mc_to_mem_wr,//read or write

    input wire [       `ADDR_TYPE]  if_to_mc_PC,
    input wire                      if_to_mc_ready,
    output reg [       `DATA_TYPE]  mc_to_if_inst,
    output reg                      mc_to_if_ready,

    input wire                      lsb_to_mc_ready,
    input wire [        `LEN_TYPE]  lsb_to_mc_len,
    input wire [         `OP_TYPE]  lsb_to_mc_opType,
    input wire [       `DATA_TYPE]  lsb_to_mc_data,
    input wire [       `ADDR_TYPE]  lsb_to_mc_addr,
    output reg                      mc_to_lsb_ld_done,
    output reg                      mc_to_lsb_st_done,
    output reg [       `DATA_TYPE]  mc_to_lsb_result
);

reg [                         2:0]  status;
reg [                         2:0]  byte_index;

integer file_p;

// initial begin
//     file_p = $fopen("mc.txt");
// end

always @(posedge clk_in) begin
    if (rst_in) begin
        status <= `STATUS_IDLE;
        mc_to_if_ready <= `FALSE;
        mc_to_lsb_ld_done <= `FALSE;
        mc_to_lsb_st_done <= `FALSE;
        mc_to_if_inst <= 0;
        mc_to_mem_dout <= 0;
        mc_to_mem_addr <= 0;
        mc_to_mem_wr <= 0;
    end
    else if (!rdy_in) begin
        ;
    end
    else begin
        if (status == `STATUS_IDLE) begin
            byte_index <= 3'b000;
            mc_to_if_ready <= `FALSE;
            mc_to_lsb_ld_done <= `FALSE;
            mc_to_lsb_st_done <= `FALSE;
            mc_to_mem_dout <= 0;
            mc_to_mem_addr <= 0;
            mc_to_mem_wr <= 0;
            //LSB goes first
            if (lsb_to_mc_ready && lsb_to_mc_opType == `OP_LD) begin
                mc_to_mem_addr <= lsb_to_mc_addr;
                mc_to_mem_wr <= 0;
                status <= `STATUS_LOAD;
            end
            else if (lsb_to_mc_ready && lsb_to_mc_opType == `OP_ST) begin
                mc_to_mem_dout <= lsb_to_mc_data[7:0];
                mc_to_mem_addr <= lsb_to_mc_addr;
                mc_to_mem_wr <= 1;
                status <= `STATUS_STORE;
            end
            else if (if_to_mc_ready) begin
                mc_to_mem_addr <= if_to_mc_PC;
                mc_to_mem_wr <= 0;
                status <= `STATUS_IF;
            end
        end
        else if (status == `STATUS_LOAD) begin
            case (byte_index)
                3'b000: begin
                    byte_index <= 3'b001;
                end
                3'b001: begin
                    mc_to_lsb_result[7:0] <= mem_to_mc_din;
                    byte_index <= 3'b010;
                    if (lsb_to_mc_len == 3'b001) begin
                        mc_to_lsb_result[31:8] <= 24'b0;
                        mc_to_lsb_ld_done <= `TRUE;
                        status <= `STATUS_STALL;
                    end
                end
                3'b010: begin
                    mc_to_lsb_result[15:8] <= mem_to_mc_din;
                    byte_index <= 3'b011;
                    if (lsb_to_mc_len == 3'b010) begin
                        mc_to_lsb_result[31:16] <= 16'b0;
                        mc_to_lsb_ld_done <= `TRUE;
                        status <= `STATUS_STALL;
                    end
                end
                3'b011: begin
                    mc_to_lsb_result[23:16] <= mem_to_mc_din;
                    byte_index <= 3'b100;
                end
                3'b100: begin
                    mc_to_lsb_result[31:24] <= mem_to_mc_din;
                    mc_to_lsb_ld_done <= `TRUE;
                    status <= `STATUS_STALL;
                end
            endcase
            mc_to_mem_addr <= mc_to_mem_addr + 1;
        end
        else if (status == `STATUS_STORE) begin
            if (lsb_to_mc_len == 3'b001) begin
                mc_to_lsb_st_done <= `TRUE;
                status <= `STATUS_STALL;
            end
            else begin
                mc_to_mem_addr <= mc_to_mem_addr + 1;
                case (byte_index) 
                    3'b000: begin
                        mc_to_mem_dout <= lsb_to_mc_data[15:8];
                        byte_index <= 3'b001;
                        if (lsb_to_mc_len == 3'b010) begin
                            mc_to_lsb_st_done <= `TRUE;
                            status <= `STATUS_STALL;
                        end
                    end
                    3'b001: begin
                        mc_to_mem_dout <= lsb_to_mc_data[23:16];
                        byte_index <= 3'b010;
                    end
                    3'b010: begin
                        mc_to_mem_dout <= lsb_to_mc_data[31:24];
                        mc_to_lsb_st_done <= `TRUE;
                        status <= `STATUS_STALL;
                    end
                endcase
            end
        end
        else if (status == `STATUS_IF) begin
            if (clr_in) begin
                status <= `STATUS_IDLE;
            end
            else begin
                case (byte_index)
                    3'b000: begin
                        byte_index <= 3'b001;
                    end
                    3'b001: begin
                        mc_to_if_inst[7:0] <= mem_to_mc_din;
                        byte_index <= 3'b010;
                    end
                    3'b010: begin
                        mc_to_if_inst[15:8] <= mem_to_mc_din;
                        byte_index <= 3'b011;
                    end
                    3'b011: begin
                        mc_to_if_inst[23:16] <= mem_to_mc_din;
                        byte_index <= 3'b100;
                    end
                    3'b100: begin
                        mc_to_if_inst[31:24] <= mem_to_mc_din;
                        status <= `STATUS_STALL;
                        mc_to_if_ready <= `TRUE;
                    end
                endcase
                mc_to_mem_addr <= mc_to_mem_addr + 1;
            end
        end
        else begin
            status <= `STATUS_IDLE;
            mc_to_lsb_ld_done <= `FALSE;
            mc_to_lsb_st_done <= `FALSE;
            mc_to_if_ready <= `FALSE;
        end
    end
end

endmodule