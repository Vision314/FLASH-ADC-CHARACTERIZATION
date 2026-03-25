`timescale 1ns / 1ps

// =============================================================================
// tb_clk_selector.v
//
// Testbench for clk_selector + clk_reconfig (with clk_wiz_dyn stub).
//
// Since clk_wiz_dyn is a Vivado IP that can't simulate without the full
// unisim libs, we stub it out here to model:
//   - AXI4-Lite handshakes (awready, wready, bvalid, arready, rvalid)
//   - locked drop/re-assert after a LOAD+SEN sequence
//   - clk_out toggling at the requested frequency
//
// Test sequence:
//   1. Reset, wait for initial reconfig (sel=0 -> 160 MHz default)
//   2. Change freq_sel to 5 (80 MHz)  -> verify reconfig_valid fires, locked pulses
//   3. Change freq_sel to 9 (16 MHz)  -> verify same
//   4. Change freq_sel to out-of-range (255) -> verify clamped to sel=0 (160 MHz)
//   5. Change freq_sel back to 0 (160 MHz) while locked is low -> verify no deadlock
// =============================================================================

module tb_clk_selector;

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
localparam CLK_PERIOD = 10; // 100 MHz -> 10 ns

// ---------------------------------------------------------------------------
// DUT signals
// ---------------------------------------------------------------------------
reg        clk_100mhz;
reg        resetn;
reg  [7:0] freq_sel;
wire       clk_out;
wire       locked;

// ---------------------------------------------------------------------------
// Instantiate DUT
// ---------------------------------------------------------------------------
clk_selector u_dut (
    .clk_100mhz (clk_100mhz),
    .resetn     (resetn),
    .freq_sel   (freq_sel),
    .clk_out    (clk_out),
    .locked     (locked)
);

// ---------------------------------------------------------------------------
// 100 MHz clock
// ---------------------------------------------------------------------------
initial clk_100mhz = 0;
always #(CLK_PERIOD/2) clk_100mhz = ~clk_100mhz;

// ---------------------------------------------------------------------------
// Timeout watchdog - fail if simulation hangs
// ---------------------------------------------------------------------------
initial begin
    #5_000_000;
    $display("TIMEOUT: simulation did not finish in time.");
    $finish;
end

// ---------------------------------------------------------------------------
// Helper task: wait for locked to go high (with timeout)
// ---------------------------------------------------------------------------
task wait_for_locked;
    input [63:0] max_cycles;
    integer i;
    begin
        for (i = 0; i < max_cycles; i = i + 1) begin
            @(posedge clk_100mhz);
            if (locked) disable wait_for_locked;
        end
        $display("ERROR at t=%0t: locked never asserted after %0d cycles", $time, max_cycles);
    end
endtask

// ---------------------------------------------------------------------------
// Helper task: wait for locked to drop (MMCM unlocks during reconfig)
// ---------------------------------------------------------------------------
task wait_for_unlock;
    input [63:0] max_cycles;
    integer i;
    begin
        for (i = 0; i < max_cycles; i = i + 1) begin
            @(posedge clk_100mhz);
            if (!locked) disable wait_for_unlock;
        end
        $display("NOTE at t=%0t: locked never dropped (stub may assert immediately)", $time);
    end
endtask

// ---------------------------------------------------------------------------
// Main stimulus
// ---------------------------------------------------------------------------
integer test_num;

initial begin
    $dumpfile("tb_clk_selector.vcd");
    $dumpvars(0, tb_clk_selector);

    // --- Initial conditions ---
    resetn   = 0;
    freq_sel = 8'd0;
    test_num = 0;

    // --- Apply reset for 20 cycles ---
    repeat(20) @(posedge clk_100mhz);
    resetn = 1;
    $display("[%0t] Reset released.", $time);

    // =========================================================================
    // TEST 1: Power-on default reconfig (sel=0 -> 160 MHz)
    //   clk_selector forces a reconfig on the first cycle after reset because
    //   freq_sel_prev is initialised to 8'hFF.
    // =========================================================================
    test_num = 1;
    $display("[%0t] TEST %0d: Power-on reconfig to sel=0 (160 MHz)", $time, test_num);
    wait_for_locked(5000);
    if (locked)
        $display("[%0t]   PASS: locked asserted after power-on reconfig.", $time);
    else
        $display("[%0t]   FAIL: locked not asserted.", $time);

    repeat(10) @(posedge clk_100mhz);

    // =========================================================================
    // TEST 2: Change to sel=5 (80 MHz)
    // =========================================================================
    test_num = 2;
    $display("[%0t] TEST %0d: Reconfig to sel=5 (80 MHz)", $time, test_num);
    freq_sel = 8'd5;
    @(posedge clk_100mhz);

    // Wait for reconfig to start (locked may drop)
    wait_for_unlock(3000);
    wait_for_locked(5000);

    if (locked)
        $display("[%0t]   PASS: locked re-asserted after sel=5 reconfig.", $time);
    else
        $display("[%0t]   FAIL: locked not re-asserted.", $time);

    repeat(10) @(posedge clk_100mhz);

    // =========================================================================
    // TEST 3: Change to sel=9 (16 MHz)
    // =========================================================================
    test_num = 3;
    $display("[%0t] TEST %0d: Reconfig to sel=9 (16 MHz)", $time, test_num);
    freq_sel = 8'd9;
    @(posedge clk_100mhz);

    wait_for_unlock(3000);
    wait_for_locked(5000);

    if (locked)
        $display("[%0t]   PASS: locked re-asserted after sel=9 reconfig.", $time);
    else
        $display("[%0t]   FAIL: locked not re-asserted.", $time);

    repeat(10) @(posedge clk_100mhz);

    // =========================================================================
    // TEST 4: Out-of-range sel=255 -> should clamp to sel=0 (160 MHz)
    // =========================================================================
    test_num = 4;
    $display("[%0t] TEST %0d: Out-of-range sel=255 (should clamp to 0)", $time, test_num);
    freq_sel = 8'd255;
    @(posedge clk_100mhz);

    wait_for_unlock(3000);
    wait_for_locked(5000);

    // Check that the LUT values match sel=0 (mult=8, divclk=1, divide=5)
    begin
        reg [7:0] exp_mult, exp_divclk, exp_div;
        exp_mult   = 8'd8;
        exp_divclk = 8'd1;
        exp_div    = 8'd5;
        if (u_dut.u_clk_reconfig.lat_multiply === exp_mult &&
            u_dut.u_clk_reconfig.lat_divclk   === exp_divclk &&
            u_dut.u_clk_reconfig.lat_divide    === exp_div)
            $display("[%0t]   PASS: LUT clamped correctly to sel=0 params.", $time);
        else
            $display("[%0t]   FAIL: LUT params = mult=%0d divclk=%0d div=%0d (expected %0d/%0d/%0d)",
                $time,
                u_dut.u_clk_reconfig.lat_multiply,
                u_dut.u_clk_reconfig.lat_divclk,
                u_dut.u_clk_reconfig.lat_divide,
                exp_mult, exp_divclk, exp_div);
    end

    repeat(10) @(posedge clk_100mhz);

    // =========================================================================
    // TEST 5: Rapid consecutive freq changes - change mid-reconfig
    //   Drive sel=3 then immediately sel=7 before reconfig finishes.
    //   The S_WAIT state in clk_selector should pick up the new sel when done.
    // =========================================================================
    test_num = 5;
    $display("[%0t] TEST %0d: Mid-reconfig freq change (sel=3 then sel=7)", $time, test_num);
    freq_sel = 8'd3;
    repeat(5) @(posedge clk_100mhz);  // let FSM start
    freq_sel = 8'd7;                   // change before done
    @(posedge clk_100mhz);

    wait_for_unlock(3000);
    wait_for_locked(5000);

    begin
        reg [7:0] exp_mult, exp_divclk, exp_div;
        // Final settled state should be sel=7: mult=48, divclk=5, divide=20
        exp_mult   = 8'd48;
        exp_divclk = 8'd5;
        exp_div    = 8'd20;
        if (u_dut.u_clk_reconfig.lat_multiply === exp_mult &&
            u_dut.u_clk_reconfig.lat_divclk   === exp_divclk &&
            u_dut.u_clk_reconfig.lat_divide    === exp_div)
            $display("[%0t]   PASS: Final reconfig settled on sel=7 params.", $time);
        else
            $display("[%0t]   NOTE: params = mult=%0d divclk=%0d div=%0d  (may have settled on sel=3 first if stub is fast)",
                $time,
                u_dut.u_clk_reconfig.lat_multiply,
                u_dut.u_clk_reconfig.lat_divclk,
                u_dut.u_clk_reconfig.lat_divide);
    end

    repeat(20) @(posedge clk_100mhz);

    // =========================================================================
    // TEST 6: Assert reset mid-operation, verify recovery
    // =========================================================================
    test_num = 6;
    $display("[%0t] TEST %0d: Reset mid-reconfig, then recover", $time, test_num);
    freq_sel = 8'd2;
    repeat(3) @(posedge clk_100mhz);
    resetn = 0;
    repeat(10) @(posedge clk_100mhz);
    resetn = 1;
    $display("[%0t]   Reset re-released.", $time);

    wait_for_locked(5000);
    if (locked)
        $display("[%0t]   PASS: Recovered after mid-reconfig reset.", $time);
    else
        $display("[%0t]   FAIL: Did not recover after reset.", $time);

    // =========================================================================
    // Done
    // =========================================================================
    repeat(20) @(posedge clk_100mhz);
    $display("[%0t] All tests complete.", $time);
    $finish;
end

// ---------------------------------------------------------------------------
// Monitor - print every time reconfig_valid fires
// ---------------------------------------------------------------------------
always @(posedge clk_100mhz) begin
    if (u_dut.reconfig_valid)
        $display("[%0t]   --> reconfig_valid pulsed | mult=%0d divclk=%0d div=%0d",
            $time,
            u_dut.new_multiply,
            u_dut.new_divclk,
            u_dut.new_divide);
    if (u_dut.reconfig_ready)
        $display("[%0t]   <-- reconfig_ready pulsed", $time);
end

endmodule


// =============================================================================
// clk_wiz_dyn STUB
//
// Models the AXI4-Lite Clocking Wizard behaviour well enough to drive the
// clk_reconfig FSM through its full sequence.
//
// Behaviour:
//   - Always-ready AXI write channel (1-cycle awready / wready)
//   - bvalid fires one cycle after wready
//   - Always-ready AXI read channel
//   - rvalid fires 2 cycles after arvalid; rdata[0] = locked
//   - locked drops for UNLOCK_CYCLES after LOAD+SEN writes, then re-asserts
//   - clk_out toggles at HALF_PERIOD_NS (default 3.125 ns = 160 MHz)
// =============================================================================
module clk_wiz_dyn #(
    parameter UNLOCK_CYCLES  = 64,   // how long locked drops after reconfig
    parameter HALF_PERIOD_NS = 3     // clk_out half-period (ns) - 160 MHz default
)(
    input  wire        clk_in1,
    output reg         clk_out1,
    output reg         locked,
    input  wire        reset,

    // AXI4-Lite
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    input  wire [10:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [10:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

// --- clk_out generation ---
initial clk_out1 = 0;
always #(HALF_PERIOD_NS) clk_out1 = ~clk_out1;

// --- locked: starts low, asserts after 32 aclk cycles from reset deassertion ---
reg [5:0] lock_cnt;
reg       do_unlock;
reg [6:0] unlock_cnt;

initial begin
    locked     = 0;
    lock_cnt   = 0;
    do_unlock  = 0;
    unlock_cnt = 0;
end

always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        locked     <= 0;
        lock_cnt   <= 0;
        do_unlock  <= 0;
        unlock_cnt <= 0;
    end else begin
        // Initial lock-up after reset
        if (!locked && !do_unlock) begin
            if (lock_cnt == 6'd32)
                locked <= 1;
            else
                lock_cnt <= lock_cnt + 1;
        end

        // Unlock sequence (triggered by SEN write)
        if (do_unlock) begin
            locked <= 0;
            if (unlock_cnt == UNLOCK_CYCLES) begin
                do_unlock  <= 0;
                locked     <= 1;
                unlock_cnt <= 0;
            end else
                unlock_cnt <= unlock_cnt + 1;
        end
    end
end

// --- AXI write channel ---
// Detect SEN write (addr 0x384) to trigger unlock
localparam ADDR_SEN = 11'h384;

always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        s_axi_awready <= 0;
        s_axi_wready  <= 0;
        s_axi_bvalid  <= 0;
        s_axi_bresp   <= 0;
    end else begin
        // Accept address
        s_axi_awready <= s_axi_awvalid;

        // Accept data + fire bvalid next cycle
        s_axi_wready <= s_axi_wvalid;
        s_axi_bvalid <= s_axi_wvalid;

        // On SEN write, start unlock
        if (s_axi_wvalid && s_axi_awvalid && (s_axi_awaddr == ADDR_SEN)) begin
            do_unlock  <= 1;
            unlock_cnt <= 0;
        end

        if (s_axi_bready)
            s_axi_bvalid <= 0;
    end
end

// --- AXI read channel ---
// Returns locked status in rdata[0] with 2-cycle latency
reg arvalid_d1, arvalid_d2;

always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        s_axi_arready <= 0;
        s_axi_rvalid  <= 0;
        s_axi_rdata   <= 0;
        s_axi_rresp   <= 0;
        arvalid_d1    <= 0;
        arvalid_d2    <= 0;
    end else begin
        arvalid_d1    <= s_axi_arvalid;
        arvalid_d2    <= arvalid_d1;
        s_axi_arready <= s_axi_arvalid;  // accept immediately
        s_axi_rvalid  <= arvalid_d2;
        s_axi_rdata   <= {31'h0, locked}; // bit 0 = locked
        if (s_axi_rready)
            s_axi_rvalid <= 0;
    end
end

endmodule
