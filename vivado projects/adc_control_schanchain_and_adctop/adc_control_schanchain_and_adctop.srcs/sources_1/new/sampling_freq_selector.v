`timescale 1ns / 1ps

module sampling_freq_selector (
    input  wire [7:0] selection,
    input  wire       reset,
    input  wire       base_clk,
    output wire       clk_out,
    output wire       locked        // high when selected clock is locked
);

// =============================================================================
// Per-wizard power_down and locked signals
// =============================================================================
wire pd_500k, pd_1M, pd_2M, pd_3M, pd_4M, pd_5M, pd_6M, pd_7M, pd_8M, pd_9M, pd_10M;
wire lk_500k, lk_1M,  lk_2M,  lk_3M,  lk_4M,  lk_5M,  lk_6M,  lk_7M,  lk_8M,  lk_9M,  lk_10M;

// =============================================================================
// Clock output wires
// =============================================================================
wire clk_500k, clk_1M, clk_2M, clk_3M, clk_4M, clk_5M,
     clk_6M,   clk_7M, clk_8M, clk_9M, clk_10M;

// =============================================================================
// Power down everything except the selected wizard
// A wizard is powered UP (pd=0) only when its index matches selection
// =============================================================================
assign pd_500k = (selection == 8'd0)  ? 1'b0 : 1'b1;
assign pd_1M   = (selection == 8'd1)  ? 1'b0 : 1'b1;
assign pd_2M   = (selection == 8'd2)  ? 1'b0 : 1'b1;
assign pd_3M   = (selection == 8'd3)  ? 1'b0 : 1'b1;
assign pd_4M   = (selection == 8'd4)  ? 1'b0 : 1'b1;
assign pd_5M   = (selection == 8'd5)  ? 1'b0 : 1'b1;
assign pd_6M   = (selection == 8'd6)  ? 1'b0 : 1'b1;
assign pd_7M   = (selection == 8'd7)  ? 1'b0 : 1'b1;
assign pd_8M   = (selection == 8'd8)  ? 1'b0 : 1'b1;
assign pd_9M   = (selection == 8'd9)  ? 1'b0 : 1'b1;
assign pd_10M  = (selection == 8'd10) ? 1'b0 : 1'b1;

// =============================================================================
// Clocking wizard instantiations
// =============================================================================
clk_wiz_500k fs_500k ( .clk_in1(base_clk), .clk_out500k(clk_500k), .clk_out1M(clk_1M), .clk_out2M(clk_2M), .clk_out3M(clk_3M), .clk_out4M(clk_4M), .clk_out5M(clk_5M), .clk_out6M(clk_6M), .reset(reset), .power_down(pd_500k), .locked(lk_500k) );
// clk_wiz_1M   fs_1M   ( .clk_in1(base_clk), .clk_out1(clk_1M),   .reset(reset), .power_down(pd_1M),   .locked(lk_1M)   );
// clk_wiz_2M   fs_2M   ( .clk_in1(base_clk), .clk_out1(clk_2M),   .reset(reset), .power_down(pd_2M),   .locked(lk_2M)   );
// clk_wiz_3M   fs_3M   ( .clk_in1(base_clk), .clk_out1(clk_3M),   .reset(reset), .power_down(pd_3M),   .locked(lk_3M)   );
// clk_wiz_4M   fs_4M   ( .clk_in1(base_clk), .clk_out1(clk_4M),   .reset(reset), .power_down(pd_4M),   .locked(lk_4M)   );
// clk_wiz_5M   fs_5M   ( .clk_in1(base_clk), .clk_out1(clk_5M),   .reset(reset), .power_down(pd_5M),   .locked(lk_5M)   );
// clk_wiz_6M   fs_6M   ( .clk_in1(base_clk), .clk_out1(clk_6M),   .reset(reset), .power_down(pd_6M),   .locked(lk_6M)   );
clk_wiz_7M   fs_7M   ( .clk_in1(base_clk), .clk_out7M(clk_7M),.clk_out8M(clk_8M), .reset(reset), .power_down(pd_7M),   .locked(lk_7M)   );
//clk_wiz_8M   fs_8M   ( .clk_in1(base_clk), .clk_out1(clk_8M),   .reset(reset), .power_down(pd_8M),   .locked(lk_8M)   );
clk_wiz_9M   fs_9M   ( .clk_in1(base_clk), .clk_out1(clk_9M),   .reset(reset), .power_down(pd_9M),   .locked(lk_9M)   );
clk_wiz_10M  fs_10M  ( .clk_in1(base_clk), .clk_out1(clk_10M),  .reset(reset), .power_down(pd_10M),  .locked(lk_10M)  );

// =============================================================================
// Select which clock and locked signal to output
// BUFGMUX is the correct primitive for glitch-free clock switching on Xilinx.
// It waits for both clocks to be low before switching, preventing glitches.
//
// Because BUFGMUX is 2-input we chain them in a mux tree:
//   Level 1: pair up adjacent clocks        (6 muxes, 11 clocks -> 6 signals)
//   Level 2: pair up level-1 outputs        (3 muxes, 6 signals -> 3 signals)  
//   Level 3: pair up level-2 outputs        (2 muxes, 3 signals -> 2 signals)
//   Level 4: final mux                      (1 mux,   2 signals -> clk_out)
//
// The select bit fed to each BUFGMUX is derived from the relevant bit of
// the selection index so the right path is active for each value 0-10.
// =============================================================================

// --- Level 1 ---
wire mux_01, mux_23, mux_45, mux_67, mux_89, mux_10x;

// sel=0 -> clk_500k, sel=1 -> clk_1M
BUFGMUX mux_l1_01 ( .I0(clk_500k), .I1(clk_1M),  .S(selection[0]), .O(mux_01)  );
// sel=2 -> clk_2M,   sel=3 -> clk_3M
BUFGMUX mux_l1_23 ( .I0(clk_2M),   .I1(clk_3M),  .S(selection[0]), .O(mux_23)  );
// sel=4 -> clk_4M,   sel=5 -> clk_5M
BUFGMUX mux_l1_45 ( .I0(clk_4M),   .I1(clk_5M),  .S(selection[0]), .O(mux_45)  );
// sel=6 -> clk_6M,   sel=7 -> clk_7M
BUFGMUX mux_l1_67 ( .I0(clk_6M),   .I1(clk_7M),  .S(selection[0]), .O(mux_67)  );
// sel=8 -> clk_8M,   sel=9 -> clk_9M
BUFGMUX mux_l1_89 ( .I0(clk_8M),   .I1(clk_9M),  .S(selection[0]), .O(mux_89)  );
// sel=10 -> clk_10M  (no pair needed, pass through with S=0)
BUFGMUX mux_l1_10 ( .I0(clk_10M),  .I1(clk_10M), .S(1'b0),         .O(mux_10x) );

// --- Level 2 ---
wire mux_0123, mux_4567, mux_8910;

// sel 0-1 vs sel 2-3: differentiated by bit 1
BUFGMUX mux_l2_0123 ( .I0(mux_01), .I1(mux_23), .S(selection[1]), .O(mux_0123) );
// sel 4-5 vs sel 6-7: differentiated by bit 1
BUFGMUX mux_l2_4567 ( .I0(mux_45), .I1(mux_67), .S(selection[1]), .O(mux_4567) );
// sel 8-9 vs sel 10: differentiated by bit 1
BUFGMUX mux_l2_8910 ( .I0(mux_89), .I1(mux_10x),.S(selection[1]), .O(mux_8910) );

// --- Level 3 ---
wire mux_03, mux_47;

// sel 0-3 vs sel 4-7: differentiated by bit 2
BUFGMUX mux_l3_03 ( .I0(mux_0123), .I1(mux_4567), .S(selection[2]), .O(mux_03) );
// sel 8-10: feed same signal to both inputs, bit 2 doesn't matter here
BUFGMUX mux_l3_47 ( .I0(mux_8910), .I1(mux_8910), .S(1'b0),         .O(mux_47) );

// --- Level 4 (final) ---
// sel 0-7 vs sel 8-10: differentiated by bit 3
BUFGMUX mux_final ( .I0(mux_03), .I1(mux_47), .S(selection[3]), .O(clk_out) );

// =============================================================================
// Output the locked signal for whichever wizard is selected
// =============================================================================
reg locked_r;
always @(*) begin
    case (selection)
        8'd0:    locked_r = lk_500k;
        8'd1:    locked_r = lk_1M;
        8'd2:    locked_r = lk_2M;
        8'd3:    locked_r = lk_3M;
        8'd4:    locked_r = lk_4M;
        8'd5:    locked_r = lk_5M;
        8'd6:    locked_r = lk_6M;
        8'd7:    locked_r = lk_7M;
        8'd8:    locked_r = lk_8M;
        8'd9:    locked_r = lk_9M;
        8'd10:   locked_r = lk_10M;
        default: locked_r = 1'b0;
    endcase
end
assign locked = locked_r;

endmodule