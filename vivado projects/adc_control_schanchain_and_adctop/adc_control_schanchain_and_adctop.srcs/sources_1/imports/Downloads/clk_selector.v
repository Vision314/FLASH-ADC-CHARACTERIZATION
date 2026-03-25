// =============================================================================
// clk_selector.v
//
// Wraps clk_reconfig and provides a simple 8-bit frequency select input.
// The module contains a lookup table of (multiply, divclk, divide) tuples
// for each target frequency, pre-verified against the MMCM constraints
// (VCO must be 600-1600 MHz for 7-series / Zynq).
//
// Input clock assumed: 100 MHz
//
// Frequency table:
//   Sel  |  Frequency  | mult | divclk | divide | VCO
//   -----|-------------|------|--------|--------|------
//    0   |  160.0 MHz  |   8  |   1    |    5   | 800 MHz
//    1   |  144.0 MHz  |  36  |   5    |    5   | 720 MHz
//    2   |  128.0 MHz  |  32  |   5    |    5   | 640 MHz
//    3   |  112.0 MHz  |  56  |   5    |   10   | 1120 MHz
//    4   |   96.0 MHz  |  48  |   5    |   10   | 960 MHz
//    5   |   80.0 MHz  |   8  |   1    |   10   | 800 MHz
//    6   |   64.0 MHz  |  32  |   5    |   10   | 640 MHz
//    7   |   48.0 MHz  |  48  |   5    |   20   | 960 MHz
//    8   |   32.0 MHz  |  32  |   5    |   20   | 640 MHz
//    9   |   16.0 MHz  |  32  |   5    |   40   | 640 MHz
//   10   |    8.0 MHz  |  32  |   5    |   80   | 640 MHz
//
// HOW TO USE:
//   1. Set freq_sel to your desired frequency index (0-10).
//   2. The module detects the change and triggers a reconfiguration automatically.
//   3. Wait for locked to go high before using clk_out.
//   4. clk_out is held in reset (via locked) during the transition.
// =============================================================================

module clk_selector (
    input  wire       clk_100mhz,    // 100 MHz clock (from your existing clk_wiz_0)
    input  wire       resetn,         // Active-low reset

    input  wire [7:0] freq_sel,       // Frequency select (0-10, see table above)

    output wire       clk_out,        // Output clock at selected frequency
    output wire       locked          // High when clk_out is stable and valid
);

// =============================================================================
// Lookup table - (multiply, divclk, divide) per frequency
// =============================================================================
reg [7:0] lut_multiply [0:10];
reg [7:0] lut_divclk   [0:10];
reg [7:0] lut_divide   [0:10];

initial begin
    //               multiply  divclk  divide
    lut_multiply[10]  =  8;  lut_divclk[0]  = 1;  lut_divide[0]  =  5; // 160 MHz
    lut_multiply[1]  = 36;  lut_divclk[1]  = 5;  lut_divide[1]  =  5; // 144 MHz
    lut_multiply[2]  = 32;  lut_divclk[2]  = 5;  lut_divide[2]  =  5; // 128 MHz
    lut_multiply[3]  = 56;  lut_divclk[3]  = 5;  lut_divide[3]  = 10; // 112 MHz
    lut_multiply[4]  = 48;  lut_divclk[4]  = 5;  lut_divide[4]  = 10; //  96 MHz
    lut_multiply[5]  =  8;  lut_divclk[5]  = 1;  lut_divide[5]  = 10; //  80 MHz
    lut_multiply[6]  = 32;  lut_divclk[6]  = 5;  lut_divide[6]  = 10; //  64 MHz
    lut_multiply[7]  = 48;  lut_divclk[7]  = 5;  lut_divide[7]  = 20; //  48 MHz
    lut_multiply[8]  = 32;  lut_divclk[8]  = 5;  lut_divide[8]  = 20; //  32 MHz
    lut_multiply[9]  = 32;  lut_divclk[9]  = 5;  lut_divide[9]  = 40; //  16 MHz
    lut_multiply[0] = 32;  lut_divclk[10] = 5;  lut_divide[10] = 80; //   8 MHz
end

// =============================================================================
// Clamp freq_sel to valid range (0-10)
// =============================================================================
wire [7:0] freq_sel_safe = (freq_sel > 8'd10) ? 8'd0 : freq_sel;

// =============================================================================
// Reconfig interface signals
// =============================================================================
reg        reconfig_valid;
wire       reconfig_ready;
reg [7:0]  new_multiply;
reg [7:0]  new_divclk;
reg [7:0]  new_divide;

// =============================================================================
// FSM
// S_IDLE:  watch for freq_sel change
// S_LOAD:  load LUT values into registers (one cycle for regs to settle)
// S_FIRE:  pulse reconfig_valid now that registers hold correct values
// S_WAIT:  wait for reconfig_ready
// =============================================================================
localparam
    S_IDLE  = 2'd0,
    S_LOAD  = 2'd1,
    S_FIRE  = 2'd2,
    S_WAIT  = 2'd3;

reg [1:0] state;
reg [7:0] freq_sel_prev;
reg [7:0] freq_sel_lat;

always @(posedge clk_100mhz or negedge resetn) begin
    if (!resetn) begin
        state          <= S_IDLE;
        reconfig_valid <= 0;
        freq_sel_prev  <= 8'hFF;  // force reconfig on first cycle after reset
        freq_sel_lat   <= 8'd0;
        new_multiply   <= 8'd0;
        new_divclk     <= 8'd0;
        new_divide     <= 8'd0;
    end else begin
        reconfig_valid <= 0; // default: deasserted

        case (state)

            // -----------------------------------------------------------------
            // Watch for any change on freq_sel
            // -----------------------------------------------------------------
            S_IDLE: begin
                if (freq_sel_safe != freq_sel_prev) begin
                    freq_sel_lat  <= freq_sel_safe;
                    freq_sel_prev <= freq_sel_safe;
                    state         <= S_LOAD;
                end
            end

            // -----------------------------------------------------------------
            // Load LUT values into registers.
            // We wait one full cycle here so that new_multiply/divclk/divide
            // are stable and correct BEFORE we pulse reconfig_valid.
            // -----------------------------------------------------------------
            S_LOAD: begin
                new_multiply <= lut_multiply[freq_sel_lat];
                new_divclk   <= lut_divclk  [freq_sel_lat];
                new_divide   <= lut_divide  [freq_sel_lat];
                state        <= S_FIRE;
            end

            // -----------------------------------------------------------------
            // Registers have now settled - safe to pulse valid.
            // clk_reconfig latches new_multiply/divclk/divide on this pulse.
            // -----------------------------------------------------------------
            S_FIRE: begin
                reconfig_valid <= 1;
                state          <= S_WAIT;
            end

            // -----------------------------------------------------------------
            // Wait for clk_reconfig to finish and signal ready.
            // If freq_sel changed again while we were busy, go straight back.
            // -----------------------------------------------------------------
            S_WAIT: begin
                if (reconfig_ready) begin
                    if (freq_sel_safe != freq_sel_prev)
                        state <= S_LOAD;
                    else
                        state <= S_IDLE;
                end
            end

        endcase
    end
end

// =============================================================================
// clk_reconfig instantiation
// NOTE: clk_reconfig.v instantiates clk_wiz_dyn internally.
//       Make sure your Vivado IP is named clk_wiz_dyn.
// =============================================================================
clk_reconfig #(
    .DEFAULT_DIVIDE  (5),   // matches sel=0: 160 MHz
    .DEFAULT_MULTIPLY(8),
    .DEFAULT_DIVCLK  (1)
) u_clk_reconfig (
    .s_axi_aclk     (clk_100mhz),
    .s_axi_aresetn  (resetn),
    .clk_in         (clk_100mhz),
    .clk_out        (clk_out),
    .locked         (locked),
    .reconfig_valid (reconfig_valid),
    .reconfig_ready (reconfig_ready),
    .new_divide     (new_divide),
    .new_multiply   (new_multiply),
    .new_divclk     (new_divclk)
);

endmodule
