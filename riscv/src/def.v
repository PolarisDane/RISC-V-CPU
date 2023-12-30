`ifndef DEF_V
`define DEF_V

`define TRUE 1'b1
`define FALSE 1'b0

`define ROB_SIZE 32'd32
`define LSB_SIZE 32'd16
`define RS_SIZE 32'd16
`define REG_SIZE 32'd32
`define ICACHE_SIZE 32'd512
`define PREDICTOR_SIZE 32'd128

`define DATA_TYPE 31:0
`define ADDR_TYPE 31:0
`define INST_TYPE 31:0
`define ROB_INDEX_TYPE 4:0
`define LSB_INDEX_TYPE 3:0
`define REG_INDEX_TYPE 4:0
`define OP_TYPE 6:0
`define OPENUM_TYPE 5:0
`define STATUS_TYPE 1:0

`define RS1_RANGE 19:15
`define RS2_RANGE 24:20
`define RD_RANGE 11:7
`define FUNC3_RANGE 14:12
`define FUNC7_RANGE 31:25
`define ICACHE_TAG_RANGE 31:11
`define ICACHE_INDEX_RANGE 10:2
`define PREDICTOR_INDEX_RANGE 6:0
`define OPTYPE_RANGE 6:0
`define LEN_TYPE 2:0

`define FUNC3_ADD_SUB 3'b000
`define FUNC3_SLL 3'b001
`define FUNC3_SLT 3'b010
`define FUNC3_SLTU 3'b011
`define FUNC3_XOR 3'b100
`define FUNC3_SRL_SRA 3'b101
`define FUNC3_OR 3'b110
`define FUNC3_AND 3'b111
`define FUNC3_ADDI 3'b000
`define FUNC3_SLLI 3'b001
`define FUNC3_SLTI 3'b010
`define FUNC3_SLTIU 3'b011
`define FUNC3_XORI 3'b100
`define FUNC3_SRLI_SRAI 3'b101
`define FUNC3_ORI 3'b110
`define FUNC3_ANDI 3'b111
`define FUNC3_BEQ 3'b000
`define FUNC3_BNE 3'b001
`define FUNC3_BLT 3'b100
`define FUNC3_BGE 3'b101
`define FUNC3_BLTU 3'b110
`define FUNC3_BGEU 3'b111
`define FUNC3_LB 3'b000
`define FUNC3_LH 3'b001
`define FUNC3_LW 3'b010
`define FUNC3_LBU 3'b100
`define FUNC3_LHU 3'b101
`define FUNC3_SB 3'b000
`define FUNC3_SH 3'b001
`define FUNC3_SW 3'b010

`define FUNC7_ADD 7'b0000000
`define FUNC7_SUB 7'b0100000
`define FUNC7_SRL 7'b0000000
`define FUNC7_SRA 7'b0100000
`define FUNC7_SRLI 7'b0000000
`define FUNC7_SRAI 7'b0100000

`define OP_LUI 7'b0110111
`define OP_AUIPC 7'b0010111
`define OP_JAL 7'b1101111
`define OP_JALR 7'b1100111
`define OP_BR 7'b1100011
`define OP_LD 7'b0000011
`define OP_ST 7'b0100011
`define OP_RI 7'b0010011
`define OP_RC 7'b0110011

`define OPENUM_NOP 6'd0
`define OPENUM_LUI 6'd1
`define OPENUM_AUIPC 6'd2
`define OPENUM_JAL 6'd3
`define OPENUM_JALR 6'd4
`define OPENUM_BEQ 6'd5
`define OPENUM_BNE 6'd6
`define OPENUM_BLT 6'd7
`define OPENUM_BGE 6'd8
`define OPENUM_BLTU 6'd9
`define OPENUM_BGEU 6'd10
`define OPENUM_LB 6'd11
`define OPENUM_LH 6'd12
`define OPENUM_LW 6'd13
`define OPENUM_LBU 6'd14
`define OPENUM_LHU 6'd15
`define OPENUM_SB 6'd16
`define OPENUM_SH 6'd17
`define OPENUM_SW 6'd18
`define OPENUM_ADDI 6'd19
`define OPENUM_SLTI 6'd20
`define OPENUM_SLTIU 6'd21
`define OPENUM_XORI 6'd22
`define OPENUM_ORI 6'd23
`define OPENUM_ANDI 6'd24
`define OPENUM_SLLI 6'd25
`define OPENUM_SRLI 6'd26
`define OPENUM_SRAI 6'd27
`define OPENUM_ADD 6'd28
`define OPENUM_SUB 6'd29
`define OPENUM_SLL 6'd30
`define OPENUM_SLT 6'd31
`define OPENUM_SLTU 6'd32
`define OPENUM_XOR 6'd33
`define OPENUM_SRL 6'd34
`define OPENUM_SRA 6'd35
`define OPENUM_OR 6'd36
`define OPENUM_AND 6'd37

`endif