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
    input  wire       clk_100mhz,    // 100 MHz board oscillator (stable reference)
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
    lut_multiply[0]  =  8;  lut_divclk[0]  = 1;  lut_divide[0]  =  5; // 160 MHz
    lut_multiply[1]  = 36;  lut_divclk[1]  = 5;  lut_divide[1]  =  5; // 144 MHz
    lut_multiply[2]  = 32;  lut_divclk[2]  = 5;  lut_divide[2]  =  5; // 128 MHz
    lut_multiply[3]  = 56;  lut_divclk[3]  = 5;  lut_divide[3]  = 10; // 112 MHz
    lut_multiply[4]  = 48;  lut_divclk[4]  = 5;  lut_divide[4]  = 10; //  96 MHz
    lut_multiply[5]  =  8;  lut_divclk[5]  = 1;  lut_divide[5]  = 10; //  80 MHz
    lut_multiply[6]  = 32;  lut_divclk[6]  = 5;  lut_divide[6]  = 10; //  64 MHz
    lut_multiply[7]  = 48;  lut_divclk[7]  = 5;  lut_divide[7]  = 20; //  48 MHz
    lut_multiply[8]  = 32;  lut_divclk[8]  = 5;  lut_divide[8]  = 20; //  32 MHz
    lut_multiply[9]  = 32;  lut_divclk[9]  = 5;  lut_divide[9]  = 40; //  16 MHz
    lut_multiply[10] = 32;  lut_divclk[10] = 5;  lut_divide[10] = 80; //   8 MHz
end

// =============================================================================
// Detect change on freq_sel and trigger reconfig
// =============================================================================
reg [7:0] freq_sel_prev;
reg [7:0] freq_sel_lat;   // latched after sanitising

wire sel_changed = (freq_sel != freq_sel_prev);

// Clamp sel to valid range (0-10) so an out-of-range input doesn't
// index garbage from the LUT
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
// FSM - waits for a freq_sel change, looks up params, fires reconfig
// =============================================================================
localparam
    S_IDLE    = 2'd0,   // watching for freq_sel change
    S_LATCH   = 2'd1,   // grab values from LUT and assert valid
    S_WAIT    = 2'd2;   // wait for reconfig_ready

reg [1:0] state;

always @(posedge clk_100mhz or negedge resetn) begin
    if (!resetn) begin
        state          <= S_IDLE;
        reconfig_valid <= 0;
        freq_sel_prev  <= 8'hFF; // force a reconfig on first cycle
        new_multiply   <= 8'd8;
        new_divclk     <= 8'd1;
        new_divide     <= 8'd5;
    end else begin
        reconfig_valid <= 0; // default

        case (state)
            // -----------------------------------------------------------------
            S_IDLE: begin
                if (sel_changed) begin
                    freq_sel_prev <= freq_sel_safe;
                    freq_sel_lat  <= freq_sel_safe;
                    state         <= S_LATCH;
                end
            end

            // -----------------------------------------------------------------
            S_LATCH: begin
                // Read the LUT and fire reconfig in the same cycle.
                // reconfig module latches these on the valid pulse.
                new_multiply   <= lut_multiply[freq_sel_lat];
                new_divclk     <= lut_divclk  [freq_sel_lat];
                new_divide     <= lut_divide  [freq_sel_lat];
                reconfig_valid <= 1;
                state          <= S_WAIT;
            end

            // -----------------------------------------------------------------
            S_WAIT: begin
                if (reconfig_ready) begin
                    // Check if freq_sel changed again while we were busy
                    if (freq_sel_safe != freq_sel_prev)
                        state <= S_LATCH; // immediately re-trigger
                    else
                        state <= S_IDLE;
                end
            end

        endcase
    end
end

// =============================================================================
// clk_reconfig instantiation
// =============================================================================
clk_reconfig #(
    .DEFAULT_DIVIDE  (5),    // boot at 160 MHz (sel=0)
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