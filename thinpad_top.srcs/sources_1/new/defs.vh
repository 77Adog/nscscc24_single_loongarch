`define IMM_SI12_INDEX   0
`define IMM_UI12_INDEX   1
`define IMM_OFFS16_INDEX 2
`define IMM_OFFS26_INDEX 3
`define IMM_UI5_INDEX    4
`define IMM_SI20_INDEX   5

`define IMM_SI12   3'd0
`define IMM_UI12   3'd1
`define IMM_OFFS16 3'd2
`define IMM_OFFS26 3'd3
`define IMM_UI5    3'd4
`define IMM_SI20   3'd5

`define FU_IDLE     4'd0
`define FU_LSUnit   4'd1
`define FU_MUL      4'd2
`define FU_ALU      4'd3
`define FU_BJUnit   4'd4

`define LSUnit_OP_LB  4'd0
`define LSUnit_OP_LW  4'd1
`define LSUnit_OP_SB  4'd2
`define LSUnit_OP_SW  4'd3

`define ALU_OP_ADD    4'd0
`define ALU_OP_SUB    4'd1
`define ALU_OP_SLT    4'd2
`define ALU_OP_SLTU   4'd3
`define ALU_OP_AND    4'd4
`define ALU_OP_OR     4'd5
`define ALU_OP_XOR    4'd6
`define ALU_OP_SLL    4'd7
`define ALU_OP_SRL    4'd8
`define ALU_OP_SRA    4'd9
`define ALU_OP_RS2    4'd10
`define ALU_OP_PCADD4 4'd11
`define ALU_OP_MUL    4'd12

`define BJUnit_OP_BEQ  4'd0
`define BJUnit_OP_BNE  4'd1
`define BJUnit_OP_BLT  4'd2
`define BJUnit_OP_BGE  4'd3
`define BJUnit_OP_BLTU 4'd4
`define BJUnit_OP_BGEU 4'd5
`define BJUnit_OP_B    4'd6
`define BJUnit_OP_BL   4'd7
`define BJUnit_OP_JIRL 4'd8
`define BJUnit_OP_NOP  4'd9

`define FU_RINFO_VAL_L 0
`define FU_RINFO_VAL_H 31
`define FU_RINFO_DEP_L 32
`define FU_RINFO_DEP_H 35
`define FU_RINFO_END   35

`define ICACHE_SIZE      16
`define ICACHE_INDEX_LEN 4

`define DCACHE_SIZE      16
`define DCACHE_INDEX_LEN 4

`define BRANCH_PREDICTOR_SIZE 16
`define BRANCH_PREDICTOR_INDEX_LEN 4

`define SRAM_ACCESS_CNT 2'b01 // when cnt == `SRAM_ACCESS_CNT, return IDLE state. access cnt = SRAM_ACCESS_CNT + 1