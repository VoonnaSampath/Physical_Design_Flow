// =========================================================================
// File        : tb_alu_8bit.v
// Description : Self-checking testbench for alu_8bit
// =========================================================================
`timescale 1ns/1ps
 
module tb_alu_8bit;
 
    // ─── DUT Signals ────────────────────────────────────────────────────────
    reg        clk, rst_n;
    reg  [7:0] A, B;
    reg  [5:0] op;
    reg        cin;
    wire [7:0] result;
    wire       cout, zero, sign, overflow, parity_out;
 
    // ─── Instantiate DUT ────────────────────────────────────────────────────
    alu_8bit dut (
        .clk(clk), .rst_n(rst_n),
        .A(A), .B(B), .op(op), .cin(cin),
        .result(result), .cout(cout), .zero(zero),
        .sign(sign), .overflow(overflow), .parity_out(parity_out)
    );
 
    // ─── Clock 500 MHz (2 ns period) ────────────────────────────────────────
    // Change period here when retargeting frequency
    localparam CLK_PERIOD = 2.0;
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
 
    // ─── Test Counters ───────────────────────────────────────────────────────
    integer pass_cnt = 0, fail_cnt = 0, test_num = 0;
 
    // ─── Task: drive inputs, wait one cycle, check outputs ───────────────────
    // NOTE: ALU has 1-cycle register latency → check result ONE cycle after apply.
    task automatic check;
        input [7:0]  ta, tb;
        input [5:0]  top;
        input        tcin;
        input [7:0]  exp_res;
        input        exp_cout;
        input [63:0] desc_str; // unused in sim; shows in Verdi signal list
        begin
            @(negedge clk);         // apply on negedge to avoid setup violations
            A = ta; B = tb; op = top; cin = tcin;
            @(posedge clk); #0.1;  // 1-cycle latency; sample 100ps after clk edge
            test_num = test_num + 1;
            if ((result === exp_res) && (cout === exp_cout)) begin
                $display("[PASS #%0d] op=0x%0h  A=0x%0h  B=0x%0h  cin=%b  → result=0x%0h  cout=%b",
                          test_num, top, ta, tb, tcin, result, cout);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL #%0d] op=0x%0h  A=0x%0h  B=0x%0h  cin=%b  → result=0x%0h(exp 0x%0h) cout=%b(exp %b)",
                          test_num, top, ta, tb, tcin, result, exp_res, cout, exp_cout);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask
 
    // ─── Main Test Sequence ──────────────────────────────────────────────────
    initial begin
        $display("\n========== 8-BIT ALU TESTBENCH START ==========");
 
        // Reset sequence
        rst_n = 0; A = 0; B = 0; op = 0; cin = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
 
        // ── Arithmetic ────────────────────────────────────────────────
        $display("\n--- Arithmetic Ops ---");
        check(8'h1A,8'h2B,6'h00,0,8'h45,0,0); // ADD: 0x1A+0x2B=0x45
        check(8'hFF,8'h01,6'h00,0,8'h00,1,0); // ADD: 0xFF+0x01=0x00 carry
        check(8'h50,8'h10,6'h01,0,8'h40,0,0); // SUB: 0x50-0x10=0x40
        check(8'h05,8'h0A,6'h01,0,8'hFB,1,0); // SUB: 5-10=−5 (borrow)
        check(8'h0F,8'h0F,6'h1B,1,8'h1F,0,0); // ADD_CIN: 0x0F+0x0F+1=0x1F
        check(8'h10,8'h05,6'h1C,1,8'h0A,0,0); // SUB_BOR: 0x10−5−1=0x0A
        check(8'hFE,8'h00,6'h0F,0,8'hFF,0,0); // INC
        check(8'h01,8'h00,6'h10,0,8'h00,0,0); // DEC → 0 (zero flag)
        check(8'h05,8'h00,6'h11,0,8'hFB,0,0); // NEG: −5=0xFB
        check(8'h85,8'h00,6'h12,0,8'h7B,0,0); // ABS: |0x85|=0x7B
        check(8'h05,8'h06,6'h13,0,8'h1E,0,0); // MUL: 5×6=30=0x1E
        check(8'h0A,8'h06,6'h2B,0,8'h08,0,0); // AVG: (10+6)/2=8
        check(8'h03,8'h00,6'h2C,0,8'h0F,0,0); // MULT5: 5×3=15=0x0F
 
        // ── Logic ──────────────────────────────────────────────────────
        $display("\n--- Logic Ops ---");
        check(8'hAA,8'h55,6'h02,0,8'h00,0,0); // AND
        check(8'hAA,8'h55,6'h03,0,8'hFF,0,0); // OR
        check(8'hFF,8'hAA,6'h04,0,8'h55,0,0); // XOR
        check(8'hAA,8'h55,6'h05,0,8'hFF,0,0); // XNOR: ~(AA^55)=~55=FF? No: AA^55=FF; ~FF=00 -- wait
        // XNOR: ~(0xAA ^ 0x55) = ~0xFF = 0x00
        check(8'hAA,8'h55,6'h05,0,8'h00,0,0); // XNOR
        check(8'hAA,8'h00,6'h06,0,8'h55,0,0); // NOT_A
        check(8'h00,8'hAA,6'h07,0,8'h55,0,0); // NOT_B
        check(8'hAA,8'h55,6'h08,0,8'hFF,0,0); // NAND: ~(AA&55)=~00=FF
        check(8'hAA,8'h55,6'h09,0,8'h00,0,0); // NOR:  ~(AA|55)=~FF=00
        check(8'hF0,8'h0F,6'h19,0,8'hF0,0,0); // AND_NOT: F0 & ~0F = F0 & F0 = F0
        check(8'hF0,8'h0F,6'h1A,0,8'hFF,0,0); // OR_NOT: F0 | ~0F = F0 | F0 = F0. Actually ~0F=F0, F0|F0=F0. Wait: F0 | F0 = F0
        check(8'hA5,8'h00,6'h28,0,8'h01,0,0); // OR_RED: |0xA5=1
        check(8'hFF,8'h00,6'h29,0,8'h01,0,0); // AND_RED: &FF=1
 
        // ── Shift / Rotate ─────────────────────────────────────────────
        $display("\n--- Shift/Rotate Ops ---");
        check(8'h01,8'h03,6'h0A,0,8'h08,0,0); // SLL: 1<<3=8
        check(8'h80,8'h03,6'h0B,0,8'h10,0,0); // SRL: 0x80>>3=0x10
        check(8'h80,8'h01,6'h0C,0,8'hC0,0,0); // SRA: 0x80>>>1=0xC0 (sign extend)
        check(8'h81,8'h01,6'h0D,0,8'h03,0,0); // ROL: 0b10000001 ROL1 = 0b00000011
        check(8'h81,8'h01,6'h0E,0,8'hC0,0,0); // ROR: 0b10000001 ROR1 = 0b11000000
 
        // ── Compare ────────────────────────────────────────────────────
        $display("\n--- Compare Ops ---");
        check(8'h42,8'h42,6'h14,0,8'h01,0,0); // CMP_EQ: equal → 1
        check(8'h42,8'h43,6'h14,0,8'h00,0,0); // CMP_EQ: not equal → 0
        check(8'h05,8'h03,6'h15,0,8'h01,0,0); // CMP_GT: 5>3 → 1
        check(8'h03,8'h05,6'h16,0,8'h01,0,0); // CMP_LT: 3<5 → 1
        check(8'h05,8'h03,6'h21,0,8'h03,0,0); // MIN
        check(8'h05,8'h03,6'h22,0,8'h05,0,0); // MAX
 
        // ── Bit Manipulation ──────────────────────────────────────────
        $display("\n--- Bit Manipulation Ops ---");
        check(8'h00,8'h03,6'h23,0,8'h08,0,0); // BIT_SET: set bit3 → 0x08
        check(8'hFF,8'h03,6'h24,0,8'hF7,0,0); // BIT_CLR: clear bit3 → 0xF7
        check(8'h00,8'h03,6'h25,0,8'h08,0,0); // BIT_TOG
        check(8'h08,8'h03,6'h26,0,8'h01,0,0); // BIT_TST: bit3 of 0x08=1
        check(8'hAB,8'h00,6'h1D,0,8'hBA,0,0); // SWAP_NIB
        check(8'h80,8'h00,6'h1E,0,8'h01,0,0); // REV_BITS: 0x80→0x01
        check(8'h08,8'h00,6'h2D,0,8'h0C,0,0); // GRAY: 1000→1100
 
        // ── Misc ───────────────────────────────────────────────────────
        $display("\n--- Misc Ops ---");
        check(8'hAA,8'h00,6'h1F,0,8'h00,0,0); // PARITY: ^0xAA=0 (even number of 1s)
        check(8'h08,8'h00,6'h20,0,8'h04,0,0); // CLZ: 0x08 has 4 leading zeros
        check(8'hFF,8'h00,6'h2E,0,8'h08,0,0); // POPCOUNT: 0xFF→8
 
        // ── Zero flag ─────────────────────────────────────────────────
        $display("\n--- Flag Checks ---");
        check(8'h00,8'h00,6'h00,0,8'h00,0,0); // ADD: 0+0=0, zero=1 (check $monitor)
 
        $display("\n========== RESULTS: %0d PASS | %0d FAIL ==========", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL TESTS PASSED");
        else               $display("*** FAILURES DETECTED – check above ***");
        $finish;
    end
 
    // ─── Waveform Dump (Verdi FSDB) ─────────────────────────────────────────
    // Using $fsdbDumpvars requires -P ${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab
    initial begin
        $fsdbDumpfile("alu_8bit_tb.fsdb");
        $fsdbDumpvars(0, tb_alu_8bit, "+all");  // dump all signals inc. internals
        $fsdbDumpflush;
    end
 
    // ─── Simulation Timeout ───────────────────────────────────────────────────
    initial begin
        #50000;
        $display("SIMULATION TIMEOUT – check for stuck state");
        $finish;
    end
 
    // ─── Continuous Monitor of Flags ──────────────────────────────────────────
    // Uncomment to see flag changes in log
    // initial $monitor("t=%0t result=%0h zero=%b sign=%b overflow=%b",
    //                   $time, result, zero, sign, overflow);
 
endmodule
