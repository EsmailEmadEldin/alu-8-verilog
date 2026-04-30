// =============================================================================
// 8-Bit ALU — Structural Verilog Implementation
// Author: Esmail Emad El-Din Mohamed
// Cairo University — Computer Science & Artificial Intelligence
// =============================================================================

// -----------------------------------------------------------------------------
// Full Adder
// -----------------------------------------------------------------------------
module full_adder(output sum, output cout, input a, input b, input cin);
    assign {cout, sum} = a + b + cin;
endmodule

// -----------------------------------------------------------------------------
// 8-Bit Ripple-Carry Adder
// -----------------------------------------------------------------------------
module adder(output [7:0] S, output Cout,
             input [7:0] A, B, input Cin);
    wire [6:0] c;

    full_adder FA0(S[0], c[0], A[0], B[0], Cin);
    full_adder FA1(S[1], c[1], A[1], B[1], c[0]);
    full_adder FA2(S[2], c[2], A[2], B[2], c[1]);
    full_adder FA3(S[3], c[3], A[3], B[3], c[2]);
    full_adder FA4(S[4], c[4], A[4], B[4], c[3]);
    full_adder FA5(S[5], c[5], A[5], B[5], c[4]);
    full_adder FA6(S[6], c[6], A[6], B[6], c[5]);
    full_adder FA7(S[7], Cout, A[7], B[7], c[6]);
endmodule

// -----------------------------------------------------------------------------
// Multiplexers
// -----------------------------------------------------------------------------
module mux2to1(output [7:0] Y, input [7:0] A, B, input Sel);
    assign Y = Sel ? B : A;
endmodule

module mux4to1(output [7:0] Y,
               input [7:0] A, B, C, D,
               input [1:0] Sel);
    wire [7:0] m1, m2;

    mux2to1 M1(m1, A, B, Sel[0]);
    mux2to1 M2(m2, C, D, Sel[0]);
    mux2to1 M3(Y,  m1, m2, Sel[1]);
endmodule

module mux16to1(output [7:0] Y,
                input [7:0] D0,  D1,  D2,  D3,
                input [7:0] D4,  D5,  D6,  D7,
                input [7:0] D8,  D9,  D10, D11,
                input [7:0] D12, D13, D14, D15,
                input [3:0] Sel);
    wire [7:0] out0, out1, out2, out3;

    mux4to1 M0(out0, D0,  D1,  D2,  D3,  Sel[1:0]);
    mux4to1 M1(out1, D4,  D5,  D6,  D7,  Sel[1:0]);
    mux4to1 M2(out2, D8,  D9,  D10, D11, Sel[1:0]);
    mux4to1 M3(out3, D12, D13, D14, D15, Sel[1:0]);
    mux4to1 M4(Y,    out0, out1, out2, out3, Sel[3:2]);
endmodule

// -----------------------------------------------------------------------------
// Logic & Arithmetic Units
// -----------------------------------------------------------------------------
module and8(output [7:0] Y, input [7:0] A, B);
    assign Y = A & B;
endmodule

module or8(output [7:0] Y, input [7:0] A, B);
    assign Y = A | B;
endmodule

module not8(output [7:0] Y, input [7:0] A);
    assign Y = ~A;
endmodule

module nand8(output [7:0] Y, input [7:0] A, B);
    wire [7:0] temp;
    and8 ANDT(temp, A, B);
    not8 NOTT(Y, temp);
endmodule

module inc8(output [7:0] Y, input [7:0] A);
    wire cout;
    adder ADD(Y, cout, A, 8'b00000001, 1'b0);
endmodule

module eq8(output [7:0] Y, input [7:0] A, B);
    wire [7:0] xnor_bits;
    assign xnor_bits = ~(A ^ B);   // 1 where bits are equal
    wire equal = &xnor_bits;       // AND-reduce: 1 only if all bits equal
    assign Y = equal ? 8'b00000001 : 8'b00000000;
endmodule

module shl1(output [7:0] Y, input [7:0] B);
    assign Y = {B[6:0], 1'b0};     // logical shift left, fill 0
endmodule

module shr1(output [7:0] Y, input [7:0] B);
    assign Y = {B[7], B[7:1]};     // arithmetic shift right, preserve sign
endmodule

module rotl1(output [7:0] Y, input [7:0] A);
    assign Y = {A[6:0], A[7]};     // rotate left: MSB wraps to LSB
endmodule

module rotr1(output [7:0] Y, input [7:0] A);
    assign Y = {A[0], A[7:1]};     // rotate right: LSB wraps to MSB
endmodule

// -----------------------------------------------------------------------------
// Ops: Compute All Operations in Parallel
// -----------------------------------------------------------------------------
module ops(
    output [7:0] addAB, subBA, incA, eqAB,
                 shL, shR, rotL, rotR,
                 notA, andAB, orAB, nandAB,
    input [7:0] A, B
);
    wire cout1, cout2;

    // A + B
    adder ADDAB(addAB, cout1, A, B, 1'b0);

    // B - A  (using 2's complement: B + (~A + 1))
    wire [7:0] A_neg;
    assign A_neg = ~A + 1;
    adder SUBBA(subBA, cout2, B, A_neg, 1'b0);

    inc8  INC8 (incA,  A);
    eq8   EQ8  (eqAB,  A, B);
    shl1  SHL  (shL,   B);
    shr1  SHR  (shR,   B);
    rotl1 ROTL (rotL,  A);
    rotr1 ROTR (rotR,  A);
    not8  NOT8 (notA,  A);
    and8  AND8 (andAB, A, B);
    or8   OR8  (orAB,  A, B);
    nand8 NAND8(nandAB,A, B);
endmodule

// -----------------------------------------------------------------------------
// ALU_8 — Top-Level Module
// -----------------------------------------------------------------------------
module ALU_8(output [7:0] Result,
             output Zero, Negative, Overflow,
             input [7:0] A, B,
             input [3:0] AluOp);

    wire [7:0] addOut, subOut, incA,
               eqAB, shL, shR, rotL, rotR,
               notA, andAB, orAB, nandAB;
    wire addCout, subCout;

    ops OP(addOut, subOut, incA, eqAB,
           shL, shR, rotL, rotR,
           notA, andAB, orAB, nandAB,
           A, B);

    mux16to1 MUX(Result,
        addOut,  // 0000 : A + B
        subOut,  // 0001 : B - A
        incA,    // 0010 : A + 1
        8'd0,    // 0011 : unused
        8'd0,    // 0100 : unused
        eqAB,    // 0101 : A == B
        shL,     // 0110 : B << 1
        shR,     // 0111 : B >> 1 (arithmetic)
        notA,    // 1000 : NOT A
        andAB,   // 1001 : A AND B
        orAB,    // 1010 : A OR B
        nandAB,  // 1011 : A NAND B
        rotL,    // 1100 : rotate A left
        rotR,    // 1101 : rotate A right
        8'd0,    // 1110 : unused
        8'd0,    // 1111 : unused
        AluOp
    );

    assign Zero     = (Result == 8'b0);
    assign Negative = Result[7];
    assign Overflow =
        (AluOp == 4'b0000) ?
            ((A[7] == B[7]) && (Result[7] != A[7])) :
        (AluOp == 4'b0001) ?
            ((B[7] != A[7]) && (Result[7] != B[7])) :
        (AluOp == 4'b0010) ?
            ((A == 8'b01111111) ? 1'b1 : 1'b0) :
        1'b0;

endmodule

// -----------------------------------------------------------------------------
// Testbench
// -----------------------------------------------------------------------------
module ALU_8_tb;

    reg [7:0] A, B;
    reg [3:0] AluOp;

    wire [7:0] Result;
    wire Zero, Negative, Overflow;

    ALU_8 inst (
        .Result(Result),
        .Zero(Zero),
        .Negative(Negative),
        .Overflow(Overflow),
        .A(A),
        .B(B),
        .AluOp(AluOp)
    );

    initial begin
        A = 8'd13; // 00001101
        B = 8'd7;  // 00000111

        // 1. A + B
        AluOp = 4'b0000; #10;
        $display("A + B    = %0d,  Zero=%b, Neg=%b, Overflow=%b", $signed(Result), Zero, Negative, Overflow);

        // 2. B - A
        AluOp = 4'b0001; #10;
        $display("B - A    = %0d,  Zero=%b, Neg=%b, Overflow=%b", $signed(Result), Zero, Negative, Overflow);

        // 3. A + 1
        AluOp = 4'b0010; #10;
        $display("A + 1    = %0d,  Zero=%b, Neg=%b, Overflow=%b", $signed(Result), Zero, Negative, Overflow);

        // 4. A == B
        AluOp = 4'b0101; #10;
        $display("A == B   = %b, Zero=%b, Neg=%b, Overflow=%b", Result, Zero, Negative, Overflow);

        // 5. B << 1
        AluOp = 4'b0110; #10;
        $display("B <<< 1  = %b, Zero=%b, Neg=%b, Overflow=%b", Result, Zero, Negative, Overflow);

        // 6. B >> 1
        AluOp = 4'b0111; #10;
        $display("B >>> 1  = %b, Zero=%b, Neg=%b, Overflow=%b", Result, Zero, Negative, Overflow);

        // 7. Rotate A left
        AluOp = 4'b1100; #10;
        $display("rotL A   = %b, Zero=%b, Neg=%b, Overflow=%b", Result, Zero, Negative, Overflow);

        // 8. Rotate A right
        AluOp = 4'b1101; #10;
        $display("rotR A   = %b, Zero=%b, Neg=%b, Overflow=%b", Result, Zero, Negative, Overflow);

        // 9. NOT A
        AluOp = 4'b1000; #10;
        $display("NOT A    = %b, Zero=%b, Neg=%b, Overflow=%b", Result, Zero, Negative, Overflow);

        // 10. A AND B
        AluOp = 4'b1001; #10;
        $display("A AND B  = %b, Zero=%b, Neg=%b, Overflow=%b", Result, Zero, Negative, Overflow);

        // 11. A OR B
        AluOp = 4'b1010; #10;
        $display("A OR B   = %b, Zero=%b, Neg=%b, Overflow=%b", Result, Zero, Negative, Overflow);

        // 12. A NAND B
        AluOp = 4'b1011; #10;
        $display("A NAND B = %b, Zero=%b, Neg=%b, Overflow=%b", Result, Zero, Negative, Overflow);

        $finish;
    end

endmodule
