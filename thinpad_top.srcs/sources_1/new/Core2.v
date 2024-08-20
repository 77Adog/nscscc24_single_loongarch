`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/01 13:47:13
// Design Name: 
// Module Name: Core2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defs.vh"

module Core2(
        input wire clk,
        input wire rst,

        // Face IMEM
        output wire [31:0] pc1,
        output wire inst_ren1,
        output wire [31:0] pc2,
        output wire inst_ren2,
        input wire [31:0] inst1,
        input wire [31:0] inst2,
        input wire imem_stall,

        // Face DMEM
        output wire [31:0] dmem_addr,
        output wire [31:0] dmem_wdata,
        output wire dmem_wen,
        output wire dmem_ren,
        output wire [3:0] be,
        input  wire [31:0] dmem_rdata,
        input  wire dmem_stall
    );

    /****************** Declaration ******************/

    // IF
    reg [31:0] pc;

    wire if_predict_branch1, if_predict_branch2;
    wire [31:0] if_predict_branch_target1, if_predict_branch_target2;

    wire if_stall;

    // ID

    reg [31:0] ifid1_pc, ifid2_pc, ifid1_inst, ifid2_inst;
    reg ifid1_valid, ifid2_valid;

    wire id2_data_stall;
    wire id1_stall, id2_stall;

    wire [4:0] id1_rs1, id1_rs2, id1_rd, id2_rs1, id2_rs2, id2_rd;
    wire id1_reg_wen, id2_reg_wen;
    wire [2:0] id1_imm_sel, id2_imm_sel;
    wire [3:0] id1_alu_op, id2_alu_op;
    wire id1_alu_srcA, id1_alu_srcB, id2_alu_srcA, id2_alu_srcB;
    wire id1_dmem_ren, id2_dmem_ren, id1_dmem_wen, id2_dmem_wen;
    wire id1_dmem_byte_addr, id2_dmem_byte_addr;
    wire [3:0] id1_cmp_op, id2_cmp_op;
    wire id1_datatoreg, id2_datatoreg;
    wire id1_use_rs1, id1_use_rs2, id2_use_rs1, id2_use_rs2;
    wire id1_is_branch, id2_is_branch;

    wire [31:0] id1_imm, id2_imm;

    wire [31:0] id1_rs1_val, id1_rs2_val, id2_rs1_val, id2_rs2_val;

    wire [31:0] id1_rs1_val_f, id1_rs2_val_f, id2_rs1_val_f, id2_rs2_val_f;


    // EX
    reg [31:0] idex1_pc, idex2_pc;
    reg idex1_valid, idex2_valid;
    reg [31:0] idex1_rs1_val, idex1_rs2_val, idex2_rs1_val, idex2_rs2_val;
    reg idex1_alu_srcA, idex1_alu_srcB, idex2_alu_srcA, idex2_alu_srcB;
    reg [4:0] idex1_rd, idex2_rd;
    reg idex1_reg_wen, idex2_reg_wen;
    reg idex1_dmem_ren, idex2_dmem_ren, idex1_dmem_wen, idex2_dmem_wen;
    reg idex1_dmem_byte_addr, idex2_dmem_byte_addr;
    reg idex1_datatoreg, idex2_datatoreg;
    reg [3:0] idex1_alu_op, idex2_alu_op;
    reg [31:0] idex1_imm, idex2_imm;
    reg [3:0] idex1_cmp_op, idex2_cmp_op;
    reg idex1_is_branch, idex2_is_branch;
    
    wire [31:0] ex1_alu_out, ex2_alu_out;
    wire ex1_stall, ex2_stall;
    wire ex1_alu_stall, ex2_alu_stall;

    wire ex1_do_branch, ex2_do_branch;
    wire [31:0] ex1_branch_target, ex2_branch_target;
    wire cmp_res1, cmp_res2;

    wire ex1_fit_branch, ex2_fit_branch;
    wire [31:0] ex1_fit_branch_target, ex2_fit_branch_target;
    wire fit_branch;
    wire [31:0] fit_branch_target;
    wire ex2_branch_stall;

    wire ex1_dmem_wen, ex2_dmem_wen, ex1_dmem_ren, ex2_dmem_ren;
    wire ex1_mem_access, ex2_mem_access;
    wire [31:0] ex1_mem_wdata, ex2_mem_wdata;
    wire [4:0] ex1_mem_be, ex2_mem_be;
    wire ex_dmem_byte_addr;
    wire ex1_mem_stall, ex2_mem_stall;
    wire [31:0] dmem_rdata_be;

    // WB
    reg [4:0] wb1_rd, wb2_rd;
    reg wb1_reg_wen, wb2_reg_wen;
    reg [31:0] wb1_reg_wdata, wb2_reg_wdata;


    /****************** Implementation ******************/

    // IF
    always @ (posedge clk) begin
        if (rst) begin
            pc <= 32'h80000000;
        end
        else if (fit_branch) begin
            pc <= fit_branch_target;
        end
        else if (~if_stall) begin
            if (if_predict_branch1 || if_predict_branch2) begin
                pc <= (if_predict_branch1)? if_predict_branch_target1: if_predict_branch_target2;
            end
            else begin
                pc <= pc + 32'h8;
            end
        end
    end

    assign pc1 = pc;
    assign pc2 = pc + 32'h4;
    assign inst_ren1 = 1'b1;
    assign inst_ren2 = 1'b1;

    assign if_stall = imem_stall | id2_stall;

    BranchPredictor bp (
        .clk(clk),
        .rst(rst),
        .pc1(pc1),
        .pc2(pc2),

        .if_do_branch1(if_predict_branch1),
        .if_do_branch2(if_predict_branch2),
        .if_branch_target1(if_predict_branch_target1),
        .if_branch_target2(if_predict_branch_target2),

        .ex_pc1(idex1_pc),
        .ex_pc2(idex2_pc),
        .ex1_do_branch(ex1_do_branch),
        .ex2_do_branch(ex2_do_branch),
        .ex1_is_branch(ex1_is_branch),
        .ex2_is_branch(ex2_is_branch),
        .ex1_branch_target(ex1_branch_target),
        .ex2_branch_target(ex2_branch_target),
        .fit_branch1(ex1_fit_branch),
        .fit_branch2(ex2_fit_branch),
        .fit_branch_target1(ex1_fit_branch_target),
        .fit_branch_target2(ex2_fit_branch_target)
    );

    // ID

    // IFID1
    always @ (posedge clk) begin
        if (rst) begin
            ifid1_valid <= 1'b0;
        end
        else if (fit_branch) begin
            ifid1_valid <= 1'b0;
        end
        else if (~id1_stall) begin
            if (if_stall) begin
                ifid1_valid <= 1'b0;
            end
            else begin
                ifid1_valid <= 1'b1;
            end
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            ifid1_pc <= 32'h0;
            ifid1_inst <= 32'h0;
        end
        else if (~id1_stall) begin
            ifid1_pc <= pc1;
            ifid1_inst <= inst1;
        end
    end

    // IFID2
    always @ (posedge clk) begin
        if (rst) begin
            ifid2_valid <= 1'b0;
        end
        else if (fit_branch) begin
            ifid2_valid <= 1'b0;
        end
        else if (~id2_stall) begin
            if (if_stall || if_predict_branch1) begin
                ifid2_valid <= 1'b0;
            end
            else begin
                ifid2_valid <= 1'b1;
            end
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            ifid2_pc <= 32'h0;
            ifid2_inst <= 32'h0;
        end
        else if (~id2_stall) begin
            ifid2_pc <= pc2;
            ifid2_inst <= inst2;
        end
    end

    CtrlUnit ctrl1 (
        .inst(ifid1_inst),
        .rs1(id1_rs1),
        .rs2(id1_rs2),
        .rd(id1_rd),
        .reg_wen(id1_reg_wen),
        .imm_sel(id1_imm_sel),
        .alu_op(id1_alu_op),
        .alu_srcA(id1_alu_srcA),
        .alu_srcB(id1_alu_srcB),
        .dmem_ren(id1_dmem_ren),
        .dmem_wen(id1_dmem_wen),
        .dmem_byte_address(id1_dmem_byte_addr),
        .cmp_op(id1_cmp_op),
        .data_to_regfile(id1_datatoreg),
        .use_rs1(id1_use_rs1),
        .use_rs2(id1_use_rs2),
        .is_branch_type(id1_is_branch)
    );

    CtrlUnit ctrl2 (
        .inst(ifid2_inst),
        .rs1(id2_rs1),
        .rs2(id2_rs2),
        .rd(id2_rd),
        .reg_wen(id2_reg_wen),
        .imm_sel(id2_imm_sel),
        .alu_op(id2_alu_op),
        .alu_srcA(id2_alu_srcA),
        .alu_srcB(id2_alu_srcB),
        .dmem_ren(id2_dmem_ren),
        .dmem_wen(id2_dmem_wen),
        .dmem_byte_address(id2_dmem_byte_addr),
        .cmp_op(id2_cmp_op),
        .data_to_regfile(id2_datatoreg),
        .use_rs1(id2_use_rs1),
        .use_rs2(id2_use_rs2),
        .is_branch_type(id2_is_branch)
    );

    ImmGen immgen1 (
        .inst(ifid1_inst),
        .imm_sel(id1_imm_sel),
        .imm(id1_imm)
    );

    ImmGen immgen2 (
        .inst(ifid2_inst),
        .imm_sel(id2_imm_sel),
        .imm(id2_imm)
    );

    RegFile2 regfile (
        .clk(clk),
        .rst(rst),

        .rs1_line1(id1_rs1),
        .rs2_line1(id1_rs2),
        .rd_line1(wb1_rd),
        .i_data_line1(wb1_reg_wdata),
        .reg_wen_line1(wb1_reg_wen),
        .rs1_val_line1(id1_rs1_val),
        .rs2_val_line1(id1_rs2_val),

        .rs1_line2(id2_rs1),
        .rs2_line2(id2_rs2),
        .rd_line2(wb2_rd),
        .i_data_line2(wb2_reg_wdata),
        .reg_wen_line2(wb2_reg_wen),
        .rs1_val_line2(id2_rs1_val),
        .rs2_val_line2(id2_rs2_val)
    );

    ForwardUnit2 fu (
        .id1_rs1(id1_rs1),
        .id1_rs2(id1_rs2),
        .id2_rs1(id2_rs1),
        .id2_rs2(id2_rs2),
        .id1_rs1_val(id1_rs1_val),
        .id1_rs2_val(id1_rs2_val),
        .id2_rs1_val(id2_rs1_val),
        .id2_rs2_val(id2_rs2_val),

        .ex1_valid(idex1_valid),
        .ex2_valid(idex2_valid),
        .ex1_rd(idex1_rd),
        .ex2_rd(idex2_rd),
        .ex1_reg_wen(idex1_reg_wen),
        .ex2_reg_wen(idex2_reg_wen),
        .ex1_alu_out(ex1_alu_out),
        .ex2_alu_out(ex2_alu_out),
        .ex1_datatoreg(idex1_datatoreg),
        .ex2_datatoreg(idex2_datatoreg),
        .dmem_rdata(dmem_rdata_be),

        .id1_rs1_val_f(id1_rs1_val_f),
        .id1_rs2_val_f(id1_rs2_val_f),
        .id2_rs1_val_f(id2_rs1_val_f),
        .id2_rs2_val_f(id2_rs2_val_f)
    );

    IDHazardDetect idhd (
        .id2_use_rs1(id2_use_rs1),
        .id2_use_rs2(id2_use_rs2),

        .ifid1_valid(ifid1_valid),
        .ifid2_valid(ifid2_valid),

        .id1_rd(id1_rd),
        .id1_reg_wen(id1_reg_wen),
        .id2_rs1(id2_rs1),
        .id2_rs2(id2_rs2),

        .id2_data_stall(id2_data_stall)
    );

    assign id1_stall = ex2_stall;
    assign id2_stall = id2_data_stall | id1_stall;

    // EX

    // IDEX1
    always @ (posedge clk) begin
        if (rst) begin
            idex1_valid <= 1'b0;
        end
        else if (fit_branch) begin
            idex1_valid <= 1'b0;
        end
        else if (~ex1_stall) begin
            if (id1_stall) begin
                idex1_valid <= 1'b0;
            end
            else begin
                idex1_valid <= ifid1_valid;
            end
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            idex1_pc <= 32'b0;
            idex1_rs1_val <= 32'b0;
            idex1_rs2_val <= 32'b0;
            idex1_alu_srcA <= 1'b0;
            idex1_alu_srcB <= 1'b0;
            idex1_rd <= 5'b0;
            idex1_reg_wen <= 1'b0;
            idex1_dmem_ren <= 1'b0;
            idex1_dmem_wen <= 1'b0;
            idex1_dmem_byte_addr <= 1'b0;
            idex1_datatoreg <= 1'b0;
            idex1_alu_op <= 4'b0;
            idex1_imm <= 32'b0;
            idex1_cmp_op <= 4'b0;
            idex1_is_branch <= 1'b0;
        end
        else if (~ex1_stall) begin
            idex1_pc <= ifid1_pc;
            idex1_rs1_val <= id1_rs1_val_f;
            idex1_rs2_val <= id1_rs2_val_f;
            idex1_alu_srcA <= id1_alu_srcA;
            idex1_alu_srcB <= id1_alu_srcB;
            idex1_rd <= id1_rd;
            idex1_reg_wen <= id1_reg_wen;
            idex1_dmem_ren <= id1_dmem_ren;
            idex1_dmem_wen <= id1_dmem_wen;
            idex1_dmem_byte_addr <= id1_dmem_byte_addr;
            idex1_datatoreg <= id1_datatoreg;
            idex1_alu_op <= id1_alu_op;
            idex1_imm <= id1_imm;
            idex1_cmp_op <= id1_cmp_op;
            idex1_is_branch <= id1_is_branch;
        end
    end

    // IDEX2
    always @ (posedge clk) begin
        if (rst) begin
            idex2_valid <= 1'b0;
        end
        else if (fit_branch) begin
            idex2_valid <= 1'b0;
        end
        else if (~ex2_stall) begin
            if (id2_stall) begin
                idex2_valid <= 1'b0;
            end
            else begin
                idex2_valid <= ifid2_valid;
            end
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            idex2_pc <= 32'b0;
            idex2_rs1_val <= 32'b0;
            idex2_rs2_val <= 32'b0;
            idex2_alu_srcA <= 1'b0;
            idex2_alu_srcB <= 1'b0;
            idex2_rd <= 5'b0;
            idex2_reg_wen <= 1'b0;
            idex2_dmem_ren <= 1'b0;
            idex2_dmem_wen <= 1'b0;
            idex2_dmem_byte_addr <= 1'b0;
            idex2_datatoreg <= 1'b0;
            idex2_alu_op <= 4'b0;
            idex2_imm <= 32'b0;
            idex2_cmp_op <= 4'b0;
            idex2_is_branch <= 1'b0;
        end
        else if (~ex2_stall) begin
            idex2_pc <= ifid2_pc;
            idex2_rs1_val <= id2_rs1_val_f;
            idex2_rs2_val <= id2_rs2_val_f;
            idex2_alu_srcA <= id2_alu_srcA;
            idex2_alu_srcB <= id2_alu_srcB;
            idex2_rd <= id2_rd;
            idex2_reg_wen <= id2_reg_wen;
            idex2_dmem_ren <= id2_dmem_ren;
            idex2_dmem_wen <= id2_dmem_wen;
            idex2_dmem_byte_addr <= id2_dmem_byte_addr;
            idex2_datatoreg <= id2_datatoreg;
            idex2_alu_op <= id2_alu_op;
            idex2_imm <= id2_imm;
            idex2_cmp_op <= id2_cmp_op;
            idex2_is_branch <= id2_is_branch;
        end
    end

    wire [31:0] alu1_a_val, alu1_b_val;

    assign alu1_a_val = (idex1_alu_srcA)? idex1_pc: idex1_rs1_val;
    assign alu1_b_val = (idex1_alu_srcB)? idex1_imm: idex1_rs2_val;
 
    ALU alu1 (
        .clk(clk),
        .rst(rst),
        .a(alu1_a_val),
        .b(alu1_b_val),
        .alu_op(idex1_alu_op),
        .valid(idex1_valid),
        .ex_stall(ex1_stall),
        .out(ex1_alu_out),
        .alu_stall(ex1_alu_stall)
    );

    wire [31:0] alu2_a_val, alu2_b_val;

    assign alu2_a_val = (idex2_alu_srcA)? idex2_pc: idex2_rs1_val;
    assign alu2_b_val = (idex2_alu_srcB)? idex2_imm: idex2_rs2_val;

    ALU alu2 (
        .clk(clk),
        .rst(rst),
        .a(alu2_a_val),
        .b(alu2_b_val),
        .alu_op(idex2_alu_op),
        .valid(idex2_valid),
        .ex_stall(ex2_stall),
        .out(ex2_alu_out),
        .alu_stall(ex2_alu_stall)
    );

    BJCmp cmp1 (
        .a_val(idex1_rs1_val),
        .b_val(idex1_rs2_val),
        .op(idex1_cmp_op),
        .cmp_res(cmp_res1)
    );

    BJCmp cmp2 (
        .a_val(idex2_rs1_val),
        .b_val(idex2_rs2_val),
        .op(idex2_cmp_op),
        .cmp_res(cmp_res2)
    );

    // BranchCtrl
    assign ex1_is_branch = idex1_is_branch & idex1_valid & (~ex1_stall);
    assign ex2_is_branch = idex2_is_branch & idex2_valid & (~ex2_stall);

    assign ex1_do_branch = cmp_res1 & idex1_valid & (~ex1_stall);
    assign ex2_do_branch = cmp_res2 & idex2_valid & (~ex2_stall);

    assign ex1_branch_target = (|(idex1_cmp_op ^ `BJUnit_OP_JIRL))? (idex1_pc + idex1_imm): (idex1_rs1_val + idex1_imm);
    assign ex2_branch_target = (|(idex2_cmp_op ^ `BJUnit_OP_JIRL))? (idex2_pc + idex2_imm): (idex2_rs1_val + idex2_imm);

    assign fit_branch = ex1_fit_branch | ex2_fit_branch;
    assign fit_branch_target = (ex1_fit_branch)? ex1_fit_branch_target: ex2_fit_branch_target;

    assign ex2_branch_stall = idex1_is_branch & idex1_valid & idex2_valid & idex2_dmem_wen;


    // MACtrl
    assign ex1_dmem_wen = idex1_dmem_wen & idex1_valid;
    assign ex2_dmem_wen = idex2_dmem_wen & idex2_valid & (~ex2_branch_stall);
    assign ex1_dmem_ren = idex1_dmem_ren & idex1_valid;
    assign ex2_dmem_ren = idex2_dmem_ren & idex2_valid;

    assign ex1_mem_access = ex1_dmem_wen | ex1_dmem_ren;
    assign ex2_mem_access = ex2_dmem_wen | ex2_dmem_ren;

    assign dmem_wen = (ex1_mem_access)? ex1_dmem_wen: ex2_dmem_wen;
    assign dmem_ren = (ex1_mem_access)? ex1_dmem_ren: ex2_dmem_ren;
    assign dmem_addr = (ex1_mem_access)? idex1_rs1_val + idex1_imm: idex2_rs1_val + idex2_imm;

    assign ex1_mem_wdata = (idex1_dmem_byte_addr)? {idex1_rs2_val[7:0], idex1_rs2_val[7:0], idex1_rs2_val[7:0], idex1_rs2_val[7:0]}: idex1_rs2_val;
    assign ex2_mem_wdata = (idex2_dmem_byte_addr)? {idex2_rs2_val[7:0], idex2_rs2_val[7:0], idex2_rs2_val[7:0], idex2_rs2_val[7:0]}: idex2_rs2_val;
    assign dmem_wdata = (ex1_mem_access)? ex1_mem_wdata: ex2_mem_wdata;

    assign ex_dmem_byte_addr = (ex1_mem_access)? idex1_dmem_byte_addr: idex2_dmem_byte_addr;

    assign be = (~ex_dmem_byte_addr)? 4'b0000:
                (~|(dmem_addr[1:0] ^ 2'b00))?   4'b1110:
                (~|(dmem_addr[1:0] ^ 2'b01))?   4'b1101:
                (~|(dmem_addr[1:0] ^ 2'b10))?   4'b1011:
                                                4'b0111;

    assign dmem_rdata_be =  (~|(be))? dmem_rdata:
                            (~|(be ^ 4'b1110))? {{24{dmem_rdata[7]}}, dmem_rdata[7:0]}:
                            (~|(be ^ 4'b1101))? {{24{dmem_rdata[15]}}, dmem_rdata[15:8]}:
                            (~|(be ^ 4'b1011))? {{24{dmem_rdata[23]}}, dmem_rdata[23:16]}:
                                                {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};

    assign ex1_mem_stall = ex1_mem_access & dmem_stall;
    assign ex2_mem_stall = (ex1_mem_access & ex2_mem_access) | (ex2_mem_access & dmem_stall);

    assign ex1_stall = ex1_alu_stall | ex1_mem_stall;
    assign ex2_stall = ex1_stall | ex2_mem_stall | ex2_alu_stall | ex2_branch_stall;

    // WB

    // EXWB1
    always @ (posedge clk) begin
        if (rst) begin
            wb1_rd <= 5'h0;
            wb1_reg_wen <= 1'b0;
            wb1_reg_wdata <= 32'h0;
        end
        else if (~ex1_stall) begin
            wb1_rd <= idex1_rd;
            wb1_reg_wen <= idex1_reg_wen & idex1_valid;
            wb1_reg_wdata <= (idex1_datatoreg)? dmem_rdata_be: ex1_alu_out;
        end
    end

    // EXWB2
    always @ (posedge clk) begin
        if (rst) begin
            wb2_rd <= 5'h0;
            wb2_reg_wen <= 1'b0;
            wb2_reg_wdata <= 32'h0;
        end
        else if (ex1_fit_branch) begin
            wb2_reg_wen <= 1'b0;
        end
        else if (~ex2_stall) begin
            wb2_rd <= idex2_rd;
            wb2_reg_wen <= idex2_reg_wen & idex2_valid;
            wb2_reg_wdata <= (idex2_datatoreg)? dmem_rdata_be: ex2_alu_out;
        end
    end
    
    

endmodule
