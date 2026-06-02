// =========================================================================
// File        : alu_8bit.v
// Description : 8-bit Registered ALU – 46 Operations
// Technology  : SAED 14nm Educational PDK
// Notes       : All outputs registered on posedge clk (1-cycle latency).
//               6-bit opcode → 64 encodings; 46 are defined here.
//               Used as a hard macro inside alu_32bit (hierarchical PD).
// =========================================================================
`timescale 1ns/1ps
 
module alu_8bit (
    // ----- Clock & Reset -----
    input  wire        clk,        // System clock – posedge triggered
    input  wire        rst_n,      // Active-LOW synchronous reset
                                   // Change to async if your std-cell has async reset pins
 
    // ----- Operand Inputs -----
    input  wire [7:0]  A,          // Operand A
    input  wire [7:0]  B,          // Operand B  (also encodes shift/bit-position via B[2:0])
    input  wire [5:0]  op,         // 6-bit operation select (see localparams)
    input  wire        cin,        // Carry/borrow-in  (for multi-word arithmetic in 32-bit parent)
 
    // ----- Result & Flags -----
    output reg  [7:0]  result,     // 8-bit result (registered)
    output reg         cout,       // Carry-out / borrow flag
    output reg         zero,       // 1 when result == 0
    output reg         sign,       // MSB of result (signed indicator)
    output reg         overflow,   // Signed arithmetic overflow
    output reg         parity_out  // Even parity of result
);
 
// ─── OPERATION ENCODINGS ──────────────────────────────────────────────────
// ── Arithmetic ──
localparam ADD      = 6'h00; // A + B
localparam SUB      = 6'h01; // A − B
localparam ADD_CIN  = 6'h1B; // A + B + cin          (ripple-carry in 32-bit ALU)
localparam SUB_BOR  = 6'h1C; // A − B − cin          (ripple-borrow)
localparam INC      = 6'h0F; // A + 1
localparam DEC      = 6'h10; // A − 1
localparam NEG      = 6'h11; // −A  (two's complement)
localparam ABS_OP   = 6'h12; // |A| (signed absolute value)
localparam MUL      = 6'h13; // (A × B)[7:0]         (lower byte; synthesiser infers multiplier)
localparam AVERAGE  = 6'h2B; // (A + B) >> 1
localparam MULT5    = 6'h2C; // 5×A  via shift-add   (no multiplier cell needed)
// ── Bitwise Logic ──
localparam AND_OP   = 6'h02; // A & B
localparam OR_OP    = 6'h03; // A | B
localparam XOR_OP   = 6'h04; // A ^ B
localparam XNOR_OP  = 6'h05; // ~(A ^ B)
localparam NOT_A    = 6'h06; // ~A
localparam NOT_B    = 6'h07; // ~B
localparam NAND_OP  = 6'h08; // ~(A & B)
localparam NOR_OP   = 6'h09; // ~(A | B)
localparam AND_NOT  = 6'h19; // A & ~B  (bit-clear mask)
localparam OR_NOT   = 6'h1A; // A | ~B
localparam OR_RED   = 6'h28; // |A   (OR  reduction → 1 bit)
localparam AND_RED  = 6'h29; // &A   (AND reduction → 1 bit)
localparam XOR3_OP  = 6'h2A; // A ^ B ^ ~A  (3-operand; result always = ~B; shows 3-input gate)
// ── Shift / Rotate ──
localparam SLL      = 6'h0A; // A << B[2:0]          logical left shift
localparam SRL      = 6'h0B; // A >> B[2:0]          logical right shift
localparam SRA      = 6'h0C; // $signed(A) >>> B[2:0] arithmetic right (sign-extends)
localparam ROL      = 6'h0D; // rotate A left  by B[2:0]
localparam ROR      = 6'h0E; // rotate A right by B[2:0]
// ── Data Transfer ──
localparam PASS_A   = 6'h17; // result = A
localparam PASS_B   = 6'h18; // result = B
localparam SWAP_NIB = 6'h1D; // swap nibbles: {A[3:0], A[7:4]}
localparam REV_BITS = 6'h1E; // bit-reverse A
localparam GRAY_COD = 6'h2D; // binary → Gray code: A ^ (A>>1)
// ── Comparison ──
localparam CMP_EQ   = 6'h14; // result = (A == B) ? 1 : 0
localparam CMP_GT   = 6'h15; // result = (A >  B) ? 1 : 0  (unsigned)
localparam CMP_LT   = 6'h16; // result = (A <  B) ? 1 : 0  (unsigned)
localparam MIN_OP   = 6'h21; // min(A, B)  unsigned
localparam MAX_OP   = 6'h22; // max(A, B)  unsigned
// ── Bit Manipulation ──
localparam BIT_SET  = 6'h23; // A | (1 << B[2:0])    set bit
localparam BIT_CLR  = 6'h24; // A & ~(1 << B[2:0])   clear bit
localparam BIT_TOG  = 6'h25; // A ^ (1 << B[2:0])    toggle bit
localparam BIT_TST  = 6'h26; // {7'd0, A[B[2:0]]}    test bit → 0 or 1
localparam SIGN_EXT = 6'h27; // sign-extend A from bit B[2:0]
// ── Misc ──
localparam PAR_OP   = 6'h1F; // even parity: ^A
localparam CLZ_OP   = 6'h20; // count leading zeros
localparam POPCOUNT = 6'h2E; // population count (count 1s)
 
// ─── FUNCTIONS ────────────────────────────────────────────────────────────
// Count leading zeros (CLZ) – priority encoder
function automatic [7:0] fn_clz;
    input [7:0] v;
    begin
        if      (v[7]) fn_clz = 8'd0;
        else if (v[6]) fn_clz = 8'd1;
        else if (v[5]) fn_clz = 8'd2;
        else if (v[4]) fn_clz = 8'd3;
        else if (v[3]) fn_clz = 8'd4;
        else if (v[2]) fn_clz = 8'd5;
        else if (v[1]) fn_clz = 8'd6;
        else if (v[0]) fn_clz = 8'd7;
        else           fn_clz = 8'd8;
    end
endfunction
 
// Population count – parallel adder tree
function automatic [7:0] fn_pop;
    input [7:0] v;
    begin
        fn_pop = {7'd0,v[0]}+{7'd0,v[1]}+{7'd0,v[2]}+{7'd0,v[3]}+
                 {7'd0,v[4]}+{7'd0,v[5]}+{7'd0,v[6]}+{7'd0,v[7]};
    end
endfunction
 
// Rotate left by shamt (0-7)
function automatic [7:0] fn_rol;
    input [7:0] v; input [2:0] sh;
    begin fn_rol = (v << sh) | (v >> (3'd0 - sh)); end
endfunction
 
// Rotate right by shamt (0-7)
function automatic [7:0] fn_ror;
    input [7:0] v; input [2:0] sh;
    begin fn_ror = (v >> sh) | (v << (3'd0 - sh)); end
endfunction
 
// Sign extend A from bit position 'pos'
function automatic [7:0] fn_sext;
    input [7:0] v; input [2:0] pos;
    reg [7:0] mask;
    begin
        mask = 8'hFF << (pos + 1'b1);
        fn_sext = v[pos] ? (v | mask) : (v & ~mask);
    end
endfunction
 
// ─── COMBINATIONAL ALU ────────────────────────────────────────────────────
reg [8:0]  t9;        // 9-bit temporary for carry detection
reg [7:0]  c_res;     // combinational result
reg        c_cout;
reg        c_ovf;
 
always @(*) begin
    t9     = 9'h0;
    c_res  = 8'h0;
    c_cout = 1'b0;
    c_ovf  = 1'b0;
 
    case (op)
        // ── Arithmetic ──────────────────────────────────────────────────
        ADD     : begin
                    t9 = {1'b0,A} + {1'b0,B};
                    c_res  = t9[7:0];
                    c_cout = t9[8];
                    // Signed overflow: (+)+(+)=(-) or (-)+(-)=(+)
                    c_ovf  = (~A[7]&~B[7]& t9[7]) | (A[7]& B[7]&~t9[7]);
                  end
        SUB     : begin
                    t9 = {1'b0,A} - {1'b0,B};
                    c_res  = t9[7:0];
                    c_cout = t9[8];   // borrow
                    c_ovf  = (~A[7]& B[7]& t9[7]) | (A[7]&~B[7]&~t9[7]);
                  end
        ADD_CIN : begin
                    t9 = {1'b0,A} + {1'b0,B} + {8'd0,cin};
                    c_res  = t9[7:0];  c_cout = t9[8];
                    c_ovf  = (~A[7]&~B[7]& t9[7]) | (A[7]& B[7]&~t9[7]);
                  end
        SUB_BOR : begin
                    t9 = {1'b0,A} - {1'b0,B} - {8'd0,cin};
                    c_res  = t9[7:0];  c_cout = t9[8];
                    c_ovf  = (~A[7]& B[7]& t9[7]) | (A[7]&~B[7]&~t9[7]);
                  end
        INC     : begin t9 = {1'b0,A}+9'd1; c_res=t9[7:0]; c_cout=t9[8]; end
        DEC     : begin t9 = {1'b0,A}-9'd1; c_res=t9[7:0]; c_cout=t9[8]; end
        NEG     : begin t9 = 9'd0 - {1'b0,A}; c_res=t9[7:0]; c_cout=t9[8]; end
        ABS_OP  : c_res = A[7] ? (~A + 8'd1) : A; // if neg, negate; else pass
        MUL     : c_res = A * B;                   // synthesiser maps to multiplier
        AVERAGE : begin t9={1'b0,A}+{1'b0,B}; c_res=t9[8:1]; end // (A+B)>>1
        MULT5   : c_res = A + (A << 2);            // 5×A, no dedicated MUL cell
        // ── Bitwise Logic ────────────────────────────────────────────────
        AND_OP  : c_res = A & B;
        OR_OP   : c_res = A | B;
        XOR_OP  : c_res = A ^ B;
        XNOR_OP : c_res = ~(A ^ B);
        NOT_A   : c_res = ~A;
        NOT_B   : c_res = ~B;
        NAND_OP : c_res = ~(A & B);
        NOR_OP  : c_res = ~(A | B);
        AND_NOT : c_res = A & ~B;
        OR_NOT  : c_res = A | ~B;
        OR_RED  : c_res = {7'd0, |A};
        AND_RED : c_res = {7'd0, &A};
        XOR3_OP : c_res = A ^ B ^ ~A;              // effectively ~B; demos 3-input XOR
        // ── Shift / Rotate ────────────────────────────────────────────────
        SLL     : c_res = A << B[2:0];
        SRL     : c_res = A >> B[2:0];
        SRA     : c_res = $signed(A) >>> B[2:0];   // arithmetic: fills with sign bit
        ROL     : c_res = fn_rol(A, B[2:0]);
        ROR     : c_res = fn_ror(A, B[2:0]);
        // ── Data Transfer ─────────────────────────────────────────────────
        PASS_A  : c_res = A;
        PASS_B  : c_res = B;
        SWAP_NIB: c_res = {A[3:0], A[7:4]};
        REV_BITS: c_res = {A[0],A[1],A[2],A[3],A[4],A[5],A[6],A[7]};
        GRAY_COD: c_res = A ^ (A >> 1);            // standard binary-to-Gray
        // ── Comparison ────────────────────────────────────────────────────
        CMP_EQ  : c_res = (A == B) ? 8'd1 : 8'd0;
        CMP_GT  : c_res = (A >  B) ? 8'd1 : 8'd0; // unsigned
        CMP_LT  : c_res = (A <  B) ? 8'd1 : 8'd0; // unsigned
        MIN_OP  : c_res = (A <  B) ? A : B;
        MAX_OP  : c_res = (A >  B) ? A : B;
        // ── Bit Manipulation ──────────────────────────────────────────────
        BIT_SET : c_res = A | (8'd1 << B[2:0]);
        BIT_CLR : c_res = A & ~(8'd1 << B[2:0]);
        BIT_TOG : c_res = A ^ (8'd1 << B[2:0]);
        BIT_TST : c_res = {7'd0, A[B[2:0]]};       // isolate single bit
        SIGN_EXT: c_res = fn_sext(A, B[2:0]);
        // ── Misc ──────────────────────────────────────────────────────────
        PAR_OP  : c_res = {7'd0, ^A};              // 1 = odd number of 1s (even parity flag)
        CLZ_OP  : c_res = fn_clz(A);
        POPCOUNT: c_res = fn_pop(A);
        default : c_res = 8'h00;                   // X for simulation debug visibility
    endcase
end
 
// ─── OUTPUT REGISTER ──────────────────────────────────────────────────────
// All outputs registered → single clock latency.
// Synchronous reset preferred for SAED32 scan insertion compatibility.
always @(posedge clk) begin
    if (!rst_n) begin
        result     <= 8'h00;
        cout       <= 1'b0;
        zero       <= 1'b0;
        sign       <= 1'b0;
        overflow   <= 1'b0;
        parity_out <= 1'b0;
    end else begin
        result     <= c_res;
        cout       <= c_cout;
        zero       <= (c_res == 8'h00);
        sign       <= c_res[7];
        overflow   <= c_ovf;
        parity_out <= ^c_res;   // even parity of the registered result
    end
end
 
endmodule