`timescale 1ns / 1ps

// =============================================================================
// reset_gen
// Stretches the PLL lock signal into a synchronous system reset.
// Input:  clk_300M, clk_locked (from clk_wiz)
// Output: reset (active-high, held until PLL locked + 4 cycles)
// =============================================================================
module reset_gen (
    input  wire clk_300M,
    input  wire clk_locked,
    output wire reset
);
    reg [3:0] rst_pipe = 4'hF;
    always @(posedge clk_300M)
        rst_pipe <= {rst_pipe[2:0], ~clk_locked};
    assign reset = rst_pipe[3];
endmodule


// =============================================================================
// uart_cmd_parser
// Receives 3-byte UART frames and decodes them into command pulses/registers.
//
// Protocol: [CMD_BYTE] [DATA_HI] [DATA_LO]
//   0x01 -> CNT_LIMIT
//   0x02 -> cmd_sample_pulse
//   0x03 -> NUM_SAMPLES
//   0x04 -> REF_LO
//   0x05 -> REF_HI                                                                                         
//   0x06 -> dac_pulse
//   0x07 -> scan_start_pulse + adc_setting
//   0x08 -> scan_sel_mode
//   0x09 -> scan_rstb_pulse
//   0x0A -> dout_sel
// =============================================================================
module uart_cmd_parser (
    input  wire        clk_300M,
    input  wire        reset,

    // From UART RX
    input  wire        rx_wr,       // byte-valid strobe from RX module
    input  wire [7:0]  rx_data_in,  // received byte

    // Decoded outputs
    output reg  [15:0] CNT_LIMIT,
    output reg         cmd_sample_pulse,
    output reg  [15:0] NUM_SAMPLES,
    output reg  [9:0]  REF_LO,
    output reg  [9:0]  REF_HI,
    output reg         dac_pulse,
    output reg         scan_start_pulse,
    output reg  [7:0]  adc_setting,
    output reg         scan_sel_mode,
    output reg         scan_rstb_pulse,
    output reg         dout_sel
);
    reg [1:0]  rx_state;
    reg [23:0] rx_code;

    always @(posedge clk_300M) begin
        if (reset) begin
            rx_state         <= 0;
            rx_code          <= 0;
            CNT_LIMIT        <= 16'd2;
            NUM_SAMPLES      <= 16'd4096;
            REF_LO           <= 10'b0101110111;
            REF_HI           <= 10'b1100000111;
            cmd_sample_pulse <= 0;
            dac_pulse        <= 0;
            scan_start_pulse <= 0;
            scan_rstb_pulse  <= 0;
            scan_sel_mode    <= 0;
            dout_sel         <= 0;
            adc_setting      <= 0;
        end else begin
            // Default single-cycle pulses
            cmd_sample_pulse <= 0;
            dac_pulse        <= 0;
            scan_start_pulse <= 0;
            scan_rstb_pulse  <= 0;
            scan_sel_mode    <= 0;

            if (rx_wr) begin
                case (rx_state)
                    // ---- BYTE 0: command ----
                    2'd0: begin
                        rx_code[23:16] <= rx_data_in;
                        rx_state <= 2'd1;
                    end

                    // ---- BYTE 1: data high ----
                    2'd1: begin
                        rx_code[15:8] <= rx_data_in;
                        rx_state <= 2'd2;
                    end

                    // ---- BYTE 2: data low - execute ----
                    2'd2: begin
                        rx_code[7:0] <= rx_data_in;

                        case (rx_code[23:16])
                            8'h01: CNT_LIMIT        <= {rx_code[15:8], rx_data_in};
                            8'h02: cmd_sample_pulse <= 1'b1;
                            8'h03: NUM_SAMPLES      <= {rx_code[15:8], rx_data_in};
                            8'h04: REF_LO           <= {rx_code[9:8],  rx_data_in};
                            8'h05: REF_HI           <= {rx_code[9:8],  rx_data_in};
                            8'h06: dac_pulse        <= 1'b1;
                            8'h07: begin
                                scan_start_pulse <= 1'b1;
                                adc_setting      <= rx_data_in;
                            end
                            8'h08: scan_sel_mode    <= 1'b1;
                            8'h09: scan_rstb_pulse  <= 1'b1;
                            8'h0A: dout_sel         <= rx_data_in[0];
                            default: ;
                        endcase

                        rx_state <= 2'd0;
                    end

                    default: rx_state <= 2'd0;
                endcase
            end
        end
    end
endmodule


// =============================================================================
// wcis_ce_gen
// Divides clk_300M by (CNT_LIMIT+1) to produce a single-cycle enable pulse
// used as the WCIS base clock enable.
// =============================================================================
module wcis_ce_gen (
    input  wire        clk_300M,
    input  wire        reset,
    input  wire [15:0] CNT_LIMIT,
    output reg         wcis_ce
);
    reg [15:0] ce_cnt;

    always @(posedge clk_300M) begin
        if (reset) begin
            ce_cnt  <= 0;
            wcis_ce <= 0;
        end else if (ce_cnt == CNT_LIMIT) begin
            ce_cnt  <= 0;
            wcis_ce <= 1'b1;
        end else begin
            ce_cnt  <= ce_cnt + 1'b1;
            wcis_ce <= 1'b0;
        end
    end
endmodule


// =============================================================================
// dac_spi_ctrl
// Drives the DAC53204 over SPI.
// On reset (or after a dac_pulse), sends a fixed 6-command init sequence
// (CMD_COUNT = 6), then waits in MARGIN_SET / DONE.
//
// SPI clock: clk_300M / (2*(SPI_DIV+1)) ~190 kHz at SPI_DIV=50
// =============================================================================
module dac_spi_ctrl (
    input  wire        clk_300M,
    input  wire        reset,

    // Trigger a new DAC programming sequence
    input  wire        dac_pulse,

    // Reference voltages (fed into DAC-2/DAC-3 data words)
    input  wire [9:0]  REF_LO,
    input  wire [9:0]  REF_HI,

    // SPI bus
    output wire        SPI_SCLK,
    output reg         DAC_SDI,
    output reg         DAC_CS,
    output wire        DAC_SDO,   // driven by internal dac_sdo reg (loopback read via top-level inout)
    output reg         DAC_CS_2
);
    // -------------------------------------------------------------------------
    // SPI clock divider (~190 kHz)
    // -------------------------------------------------------------------------
    localparam SPI_DIV = 9'd50;

    reg [8:0] spi_div_cnt;
    reg       spi_tick;

    always @(posedge clk_300M) begin
        if (reset) begin
            spi_div_cnt <= 0;
            spi_tick    <= 0;
        end else if (spi_div_cnt == SPI_DIV) begin
            spi_div_cnt <= 0;
            spi_tick    <= 1;
        end else begin
            spi_div_cnt <= spi_div_cnt + 1;
            spi_tick    <= 0;
        end
    end

    // -------------------------------------------------------------------------
    // SPI clock toggle
    // -------------------------------------------------------------------------
    reg spi_clk;
    reg spi_clk_en;

    always @(posedge clk_300M) begin
        if (reset || !spi_clk_en)
            spi_clk <= 0;
        else if (spi_tick)
            spi_clk <= ~spi_clk;
    end

    assign SPI_SCLK = spi_clk;

    // -------------------------------------------------------------------------
    // Command ROM
    // -------------------------------------------------------------------------
    localparam CMD_COUNT = 4'd6;

    function [24:0] dac_cmd;
        input [3:0] idx;
        begin
            case (idx)
                4'd1: dac_cmd = {8'h24, 1'b0, 1'b0, 1'b1, 4'b0001, 4'b1100, 4'b0000, 1'b0, 1'b0};                            // GPIO-CONFIG
                4'd2: dac_cmd = {8'h1F, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 2'b00, 1'b0, 2'b00, 1'b0, 2'b11, 1'b1, 1'b0};   // COMMON-CONFIG
                4'd3: dac_cmd = {8'h0F, 3'b000, 3'b001, 5'b00000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};                       // DAC-2-VOUT-CMP-CONFIG
                4'd4: dac_cmd = {8'h15, 3'b000, 3'b001, 5'b00000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};                       // DAC-3-VOUT-CMP-CONFIG
                4'd5: dac_cmd = {8'h1B, REF_LO, 6'b000000, 1'b0};                                                              // DAC-2-DATA (REF_LO)
                4'd6: dac_cmd = {8'h1C, REF_HI, 6'b000000, 1'b0};                                                              // DAC-3-DATA (REF_HI)
                default: dac_cmd = 25'd0;
            endcase
        end
    endfunction

    // -------------------------------------------------------------------------
    // DAC SPI state machine
    // -------------------------------------------------------------------------
    localparam IDLE       = 3'd0;
    localparam SHIFT      = 3'd1;
    localparam DELAY      = 3'd2;
    localparam DONE       = 3'd3;
    localparam MARGIN_SET = 3'd4;

    reg [2:0]  state;
    reg [4:0]  bit_cnt;
    reg [24:0] shift_reg;
    reg [3:0]  cmd_index;
    reg        cmd_active;
    reg        dac_sdo;

    always @(posedge clk_300M) begin
        // Latch dac_pulse outside the tick gate so it isn't missed
        if (dac_pulse)
            cmd_active <= 1'b1;

        DAC_CS_2 <= 1;

        if (reset) begin
            state      <= IDLE;
            DAC_CS     <= 1;
            DAC_SDI    <= 0;
            bit_cnt    <= 0;
            cmd_active <= 1;      // run init sequence on power-up
            cmd_index  <= 0;
            spi_clk_en <= 0;
        end else if (spi_tick) begin
            case (state)

                IDLE: begin
                    DAC_CS <= 1;
                    if (cmd_active) begin
                        spi_clk_en <= 1;
                        state      <= SHIFT;
                    end
                end

                SHIFT: begin
                    if (spi_clk == 0) begin
                        // Present MSB on falling edge
                        DAC_SDI   <= shift_reg[24];
                    end else begin
                        // Shift and count on rising edge
                        shift_reg <= {shift_reg[23:0], 1'b0};
                        bit_cnt   <= bit_cnt + 1;

                        if (bit_cnt == 5'd23) begin
                            bit_cnt <= 0;
                            if (cmd_index == CMD_COUNT) begin
                                cmd_index <= 0;
                                state     <= MARGIN_SET;
                            end else begin
                                cmd_index <= cmd_index + 1;
                                state     <= DELAY;
                            end
                        end
                    end
                end

                DELAY: begin
                    DAC_CS    <= 1;
                    DAC_SDI   <= 0;
                    shift_reg <= dac_cmd(cmd_index);

                    if (spi_clk == 0) begin
                        if (bit_cnt == 5'd24) begin
                            DAC_CS  <= 0;
                            bit_cnt <= 0;
                            state   <= SHIFT;
                        end else
                            bit_cnt <= bit_cnt + 1;
                    end
                end

                DONE: begin
                    DAC_CS     <= 1;
                    DAC_SDI    <= 0;
                    cmd_active <= 0;
                    spi_clk_en <= 0;
                    state      <= IDLE;
                end

                MARGIN_SET: begin
                    DAC_CS <= 1;
                    if (spi_clk == 1) begin
                        dac_sdo <= DAC_SDO;
                        if (bit_cnt == 0) begin
                            dac_sdo <= DAC_SDO;
                            bit_cnt <= bit_cnt + 1;
                        end else if (bit_cnt == 1) begin
                            dac_sdo <= ~dac_sdo;
                            bit_cnt <= bit_cnt + 1;
                        end else begin
                            dac_sdo <= ~dac_sdo;
                            bit_cnt <= 0;
                            state   <= DONE;
                        end
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

    assign DAC_SDO = dac_sdo;
endmodule


// =============================================================================
// top_v4
// Thin top-level: instantiates all submodules and routes I/O.
// =============================================================================
module top_v4 (
    input  wire sysclk,
    input  wire btn0,
    input  wire btn1,
    output wire LEDB,
    output wire LEDG,
    output wire LEDR,

    output wire PWR_EN,
    output wire TEST_EN,

    // CRIPTO
    output wire ROLL_SEL,
    output wire ROLL_CLK,

    // SCAN CHAIN
    output wire SCAN_SEL,
    output wire SCAN_CLK,
    output wire SCAN_RSTB,
    input  wire SCAN_OUT,
    output wire SCAN_IN,

    // ADC
    output wire ADC_TEST_EN,
    output wire ADC_ENC,
    output wire ADC_SH,
    output wire ADC_PRE,
    output wire ADC_CLK,

    // SERDES
    output wire DATA_SCLK,
    output wire DATA_LOAD,

    // DAC53204 SPI
    output wire       SPI_SCLK,
    output wire       DAC_SDI,
    output wire       DAC_CS,
    inout  wire       DAC_SDO,
    output wire       DAC_CS_2,

    // WCIS DOUT
    input  wire DOUT_TOP,
    input  wire DOUT_BOT,

    output wire Tx,
    input  wire Rx,

    output wire EXT_ADC_CONV,
    input  wire EXT_ADC_DATA,

    // UNUSED
    output wire COL_EN,
    output wire VLN_EN,
    output wire SHS_EN,
    output wire SHR_EN,
    output wire [7:0] ROW_COL_ADDR,
    output wire CLAMP_EN,
    output wire EXT_ADC_CONV_2,
    output wire SPI_CLK_ADC_2,
    output wire ROW_RST_EN,
    output wire ROW_SEL_EN,
    output wire ADDR_LATCH
);

    // -------------------------------------------------------------------------
    // PLL  (clk_wiz_0 stays at top level per user preference)
    // -------------------------------------------------------------------------
    wire clk_300M;
    wire clk_locked;

    // sysclk-domain sync for PLL reset button
    reg btn0_sysclk_d1, btn0_sysclk_d2;
    always @(posedge sysclk) begin
        btn0_sysclk_d1 <= btn0;
        btn0_sysclk_d2 <= btn0_sysclk_d1;
    end
    wire pll_reset = btn0_sysclk_d2;

    clk_wiz_0 u_clk_wiz (
        .clk_out1 (clk_300M),
        .clk_in1  (sysclk),
        .reset    (pll_reset),
        .locked   (clk_locked)
    );

    // -------------------------------------------------------------------------
    // Reset stretcher
    // -------------------------------------------------------------------------
    wire reset;

    reset_gen u_reset_gen (
        .clk_300M  (clk_300M),
        .clk_locked(clk_locked),
        .reset     (reset)
    );

    // -------------------------------------------------------------------------
    // Debouncer (btn1 used as manual sample trigger)
    // -------------------------------------------------------------------------
    wire btn1_db;

    debouncer db_btn1 (
        .clk    (clk_300M),
        .btn1   (btn1),
        .btn_db (btn1_db)
    );

    // -------------------------------------------------------------------------
    // UART RX
    // -------------------------------------------------------------------------
    wire       baud_tick;
    wire       rx_wr;
    wire [7:0] rx_data_in;
    wire       rx_full;

    baud_match #(.M(8)) u_baud_match (
        .clk      (clk_300M),
        .reset    (reset),
        .baud_clk (baud_tick)
    );

    rx u_rx (
        .baud_tick (baud_tick),
        .sysclk    (clk_300M),
        .reset     (reset),
        .full      (rx_full),
        .wr_en     (rx_wr),
        .rx_data   (rx_data_in),
        .rx        (Rx)
    );

    // -------------------------------------------------------------------------
    // UART command parser
    // -------------------------------------------------------------------------
    wire [15:0] CNT_LIMIT;
    wire        cmd_sample_pulse;
    wire [15:0] NUM_SAMPLES;
    wire [9:0]  REF_LO;
    wire [9:0]  REF_HI;
    wire        dac_pulse;
    wire        scan_start_pulse;
    wire [7:0]  adc_setting;
    wire        scan_sel_mode;
    wire        scan_rstb_pulse;
    wire        dout_sel;

    uart_cmd_parser u_cmd_parser (
        .clk_300M        (clk_300M),
        .reset           (reset),
        .rx_wr           (rx_wr),
        .rx_data_in      (rx_data_in),
        .CNT_LIMIT       (CNT_LIMIT),
        .cmd_sample_pulse(cmd_sample_pulse),
        .NUM_SAMPLES     (NUM_SAMPLES),
        .REF_LO          (REF_LO),
        .REF_HI          (REF_HI),
        .dac_pulse       (dac_pulse),
        .scan_start_pulse(scan_start_pulse),
        .adc_setting     (adc_setting),
        .scan_sel_mode   (scan_sel_mode),
        .scan_rstb_pulse (scan_rstb_pulse),
        .dout_sel        (dout_sel)
    );

    // -------------------------------------------------------------------------
    // WCIS clock-enable generator
    // -------------------------------------------------------------------------
    wire wcis_ce;

    wcis_ce_gen u_wcis_ce_gen (
        .clk_300M (clk_300M),
        .reset    (reset),
        .CNT_LIMIT(CNT_LIMIT),
        .wcis_ce  (wcis_ce)
    );

    // -------------------------------------------------------------------------
    // DOUT mux
    // -------------------------------------------------------------------------
    wire dout_mux;
    assign dout_mux = dout_sel ? DOUT_BOT : DOUT_TOP;

    // -------------------------------------------------------------------------
    // ADC control
    // -------------------------------------------------------------------------
    wire       tx_wr;
    wire [7:0] tx_data_in;
    wire       tx_full;
    wire       sample_en;
    wire       sample_trigger;

    assign sample_trigger = cmd_sample_pulse; // btn1_pulse removed (no edge-det here)

    adc_control u_adc (
        .clk_300M      (clk_300M),
        .base_clk_en   (wcis_ce),
        .reset         (reset),
        .ADC_TEST_EN   (ADC_TEST_EN),
        .ADC_ENC       (ADC_ENC),
        .ADC_SH        (ADC_SH),
        .ADC_PRE       (ADC_PRE),
        .ADC_CLK       (ADC_CLK),
        .DATA_SCLK     (DATA_SCLK),
        .DATA_LOAD     (DATA_LOAD),
        .DOUT_TOP      (dout_mux),
        .tx_wr         (tx_wr),
        .tx_data_in    (tx_data_in),
        .tx_full       (tx_full),
        .sample_trigger(sample_trigger),
        .sample_en     (sample_en),
        .NUM_SAMPLES   (NUM_SAMPLES)
    );

    // -------------------------------------------------------------------------
    // Scan chain controller
    // -------------------------------------------------------------------------
    scan_chain_control u_scan_chain (
        .SCAN_IN        (SCAN_IN),
        .SCAN_CLK       (SCAN_CLK),
        .SCAN_RSTB      (SCAN_RSTB),
        .SCAN_SEL       (SCAN_SEL),
        .SCAN_START     (scan_start_pulse),
        .SCAN_OUT       (SCAN_OUT),
        .adc_setting    (adc_setting),
        .reset          (reset),
        .sysclk         (clk_300M),
        .scan_sel_mode  (scan_sel_mode),
        .scan_rstb_pulse(scan_rstb_pulse)
    );

    // -------------------------------------------------------------------------
    // TX FIFO
    // -------------------------------------------------------------------------
    wire       tx_rd;
    wire [7:0] tx_data_out;
    wire       tx_empty;

    tx_fifo u_tx_fifo (
        .clk   (clk_300M),
        .srst  (reset),
        .din   (tx_data_in),
        .wr_en (tx_wr),
        .rd_en (tx_rd),
        .dout  (tx_data_out),
        .full  (tx_full),
        .empty (tx_empty)
    );

    // -------------------------------------------------------------------------
    // UART TX
    // -------------------------------------------------------------------------
    tx u_tx (
        .baud_tick (baud_tick),
        .sysclk    (clk_300M),
        .reset     (reset),
        .empty     (tx_empty),
        .full      (tx_full),
        .rd_en     (tx_rd),
        .fifo_data (tx_data_out),
        .tx        (Tx)
    );

    // -------------------------------------------------------------------------
    // DAC SPI controller
    // -------------------------------------------------------------------------
    // Intermediate wires: submodule drives regs internally; top ports are wire.
    wire dac_sdi_w;
    wire dac_cs_w;
    wire dac_cs2_w;

    assign DAC_SDI  = dac_sdi_w;
    assign DAC_CS   = dac_cs_w;
    assign DAC_CS_2 = dac_cs2_w;

    dac_spi_ctrl u_dac_spi (
        .clk_300M  (clk_300M),
        .reset     (reset),
        .dac_pulse (dac_pulse),
        .REF_LO    (REF_LO),
        .REF_HI    (REF_HI),
        .SPI_SCLK  (SPI_SCLK),
        .DAC_SDI   (dac_sdi_w),
        .DAC_CS    (dac_cs_w),
        .DAC_SDO   (DAC_SDO),
        .DAC_CS_2  (dac_cs2_w)
    );

    // -------------------------------------------------------------------------
    // Static assignments
    // -------------------------------------------------------------------------
    assign LEDB     = ~reset;
    assign LEDR     = ~sample_en;
    assign LEDG     = tx_full;

    assign PWR_EN   = 1'b1;
    assign TEST_EN  = 1'b0;
    assign ROLL_SEL = 1'b0;
    assign ROLL_CLK = 1'b0;

    assign COL_EN        = 0;
    assign VLN_EN        = 0;
    assign SHS_EN        = 0;
    assign SHR_EN        = 0;
    assign ROW_COL_ADDR  = 0;
    assign CLAMP_EN      = 0;
    assign EXT_ADC_CONV  = 0;
    assign EXT_ADC_CONV_2= 0;
    assign SPI_CLK_ADC_2 = 0;
    assign ROW_RST_EN    = 0;
    assign ROW_SEL_EN    = 0;
    assign ADDR_LATCH    = 0;

endmodule