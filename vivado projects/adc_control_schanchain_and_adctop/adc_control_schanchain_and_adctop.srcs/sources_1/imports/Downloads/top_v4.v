`timescale 1ns / 1ps

module top_v3(
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
    output wire SPI_SCLK,
    output reg  DAC_SDI,
    output reg  DAC_CS,
    inout  wire DAC_SDO,
    output reg  DAC_CS_2,

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

    // ==========================================================================
    // Clocking and reset
    // ==========================================================================

    // Base clock: 12MHz sysclk -> 100MHz
    wire clk_100M;
    wire clk_locked;

    clk_wiz_base base (
        .clk_in1  (sysclk),
        .clk_out1 (clk_100M),
        .locked   (clk_locked)
    );

    // Power-on reset
    // Holds reset high until clk_wiz_base is locked AND 255 cycles have passed.
    // After that, btn0 acts as manual reset.
    reg [7:0] por_cnt = 0;
    wire por_reset = ~clk_locked | (por_cnt < 8'd255);

    always @(posedge clk_100M) begin
        if (clk_locked && por_cnt < 8'd255)
            por_cnt <= por_cnt + 1;
    end

    // Button debounce on 100MHz
    wire btn0_db, btn1_db;
    wire btn0_pulse, btn1_pulse;
    reg  btn0_db_d, btn1_db_d;

    debouncer db_btn0 (
        .clk    (clk_100M),
        .btn1   (btn0),
        .btn_db (btn0_db)
    );

    debouncer db_btn1 (
        .clk    (clk_100M),
        .btn1   (btn1),
        .btn_db (btn1_db)
    );

    always @(posedge clk_100M) begin
        btn0_db_d <= btn0_db;
        btn1_db_d <= btn1_db;
    end

    assign btn0_pulse = btn0_db & ~btn0_db_d;
    assign btn1_pulse = btn1_db & ~btn1_db_d;

    // Dynamic clock selector
    // clk_300M is the variable output clock (named 300M for legacy reasons)
    wire clk_300M;
    wire clk_sel_locked;
    reg  [7:0] freq_sel = 8'd0;
    wire resetn;

    clk_selector u_clk_sel (
        .clk_100mhz (clk_100M),
        .resetn     (resetn),
        .freq_sel   (freq_sel),
        .clk_out    (clk_300M),
        .locked     (clk_sel_locked)
    );

    // Final reset — held high until base clock locked, selector locked,
    // power-on counter elapsed, or button pressed
    wire reset = btn0_pulse | por_reset | ~clk_sel_locked;
    assign resetn = ~reset;

    // ==========================================================================
    // UART RX
    // ==========================================================================
    wire        baud_tick;
    wire        rx_wr;
    reg         rx_rd;
    wire [7:0]  rx_data_in;
    wire        rx_full, rx_empty;

    rx u_rx (
        .baud_tick (baud_tick),
        .sysclk    (clk_300M),
        .reset     (reset),
        .full      (rx_full),
        .wr_en     (rx_wr),
        .rx_data   (rx_data_in),
        .rx        (Rx)
    );

    // ==========================================================================
    // Command decoder
    // ==========================================================================
    reg [15:0] CNT_LIMIT    = 16'd2;
    reg [4:0]  rx_cnt;
    reg [3:0]  rx_cmd_state;
    reg [23:0] shift_rx;
    reg        rx_valid;
    reg [15:0] NUM_SAMPLES  = 16'd4096;
    wire       dac_trigger;
    reg        dac_pulse;

    localparam [3:0]
        READ    = 4'd0,
        EXECUTE = 4'd1;

    reg [1:0]  rx_state;
    reg [23:0] rx_code = 0;
    reg [9:0]  REF_LO = 10'b0101110111;
    reg [9:0]  REF_HI = 10'b1100000111;

    wire SCAN_START;
    reg  scan_start_pulse;
    assign SCAN_START = scan_start_pulse;
    reg [7:0] adc_setting;
    reg       scan_sel_mode  = 0;
    reg       scan_rstb_pulse = 0;

    wire sample_trigger;
    reg  cmd_sample_pulse;

    always @(posedge clk_300M) begin
        if (reset) begin
            rx_state         <= 0;
            rx_code          <= 0;
            CNT_LIMIT        <= 16'd2;
            cmd_sample_pulse <= 0;
            dac_pulse        <= 0;
            scan_start_pulse <= 0;
            scan_rstb_pulse  <= 1'b0;
        end else begin
            cmd_sample_pulse <= 0;
            scan_start_pulse <= 0;
            scan_sel_mode    <= 0;
            dac_pulse        <= 0;
            scan_rstb_pulse  <= 1'b0;

            if (rx_wr) begin
                case (rx_state)

                    0: begin  // BYTE 0: COMMAND
                        rx_code[23:16] <= rx_data_in;
                        rx_state       <= 1;
                    end

                    1: begin  // BYTE 1: DATA HIGH
                        rx_code[15:8] <= rx_data_in;
                        rx_state      <= 2;
                    end

                    2: begin  // BYTE 2: DATA LOW
                        rx_code[7:0] <= rx_data_in;

                        case (rx_code[23:16])
                            8'h01: freq_sel          <= rx_data_in;
                            8'h02: cmd_sample_pulse  <= 1'b1;
                            8'h03: NUM_SAMPLES       <= {rx_code[15:8], rx_data_in};
                            8'h04: REF_LO            <= {rx_code[9:8], rx_data_in};
                            8'h05: REF_HI            <= {rx_code[9:8], rx_data_in};
                            8'h06: dac_pulse         <= 1'b1;
                            8'h07: begin
                                scan_start_pulse <= 1'b1;
                                adc_setting      <= rx_data_in;
                            end
                            8'h08: scan_sel_mode     <= 1'b1;
                            8'h09: scan_rstb_pulse   <= 1'b1;
                            default: ;
                        endcase

                        rx_state <= 0;
                    end

                endcase
            end
        end
    end

    // ==========================================================================
    // WCIS clock enable
    // ==========================================================================
    reg [15:0] ce_cnt;
    reg        wcis_ce;
    reg        serdes_ce;

    always @(posedge clk_300M) begin
        if (reset) begin
            ce_cnt  <= 7'd0;
            wcis_ce <= 1'b0;
        end else if (ce_cnt == CNT_LIMIT) begin
            ce_cnt  <= 7'd0;
            wcis_ce <= 1'b1;
        end else begin
            ce_cnt  <= ce_cnt + 1'b1;
            wcis_ce <= 1'b0;
        end
    end

    assign ROLL_SEL = 1'b0;
    assign LEDB     = ~reset;

    // ==========================================================================
    // ADC control
    // ==========================================================================
    wire       tx_wr;
    wire [7:0] tx_data_in;
    wire       tx_full;
    wire       sample_en;

    assign sample_trigger = btn1_pulse | cmd_sample_pulse;

    adc_control u_adc (
        .clk_300M     (clk_300M),
        .base_clk_en  (wcis_ce),
        .reset        (reset),
        .ADC_TEST_EN  (ADC_TEST_EN),
        .ADC_ENC      (ADC_ENC),
        .ADC_SH       (ADC_SH),
        .ADC_PRE      (ADC_PRE),
        .ADC_CLK      (ADC_CLK),
        .DATA_SCLK    (DATA_SCLK),
        .DATA_LOAD    (DATA_LOAD),
        .DOUT_TOP     (DOUT_TOP),
        .DOUT_BOT     (DOUT_BOT),
        .tx_wr        (tx_wr),
        .tx_data_in   (tx_data_in),
        .tx_full      (tx_full),
        .sample_trigger(sample_trigger),
        .sample_en    (sample_en),
        .NUM_SAMPLES  (NUM_SAMPLES)
    );

    assign LEDR = ~sample_en;

    // ==========================================================================
    // Scan chain
    // ==========================================================================
    scan_chain_control scan_chain_controller (
        .SCAN_IN        (SCAN_IN),
        .SCAN_CLK       (SCAN_CLK),
        .SCAN_RSTB      (SCAN_RSTB),
        .SCAN_SEL       (SCAN_SEL),
        .SCAN_START     (SCAN_START),
        .SCAN_OUT       (SCAN_OUT),
        .adc_setting    (adc_setting),
        .reset          (reset),
        .sysclk         (clk_300M),
        .scan_sel_mode  (scan_sel_mode),
        .scan_rstb_pulse(scan_rstb_pulse)
    );

    // ==========================================================================
    // TX FIFO
    // ==========================================================================
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

    // ==========================================================================
    // Baud generator
    // ==========================================================================
    baud_match #(
        .M(4)
    ) u_baud_match (
        .clk      (clk_300M),
        .reset    (reset),
        .baud_clk (baud_tick)
    );

    // ==========================================================================
    // UART TX
    // ==========================================================================
    wire [3:0] tx_state;
    wire [7:0] tx_data;

    tx u_tx (
        .baud_tick (baud_tick),
        .sysclk    (clk_300M),
        .reset     (reset),
        .empty     (tx_empty),
        .full      (tx_full),
        .rd_en     (tx_rd),
        .fifo_data (tx_data_out),
        .tx        (Tx),
        .tx_state  (tx_state),
        .tx_data   (tx_data)
    );

    assign LEDG = tx_full;

    // ==========================================================================
    // DAC SPI state machine
    // ==========================================================================
    localparam CMD_COUNT = 4'd6;

    reg [4:0]  cmd_index  = 0;
    reg        cmd_active = 0;

    assign dac_trigger = cmd_active | dac_pulse;

    function [24:0] dac_cmd;
        input [3:0] idx;
        begin
            case (idx)
                5'd1:  dac_cmd = {8'h24, 1'b0, 1'b0, 1'b1, 4'b0001, 4'b1100, 4'b0000, 1'b0, 1'b0};
                5'd2:  dac_cmd = {8'h1F, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 2'b00, 1'b0, 2'b00, 1'b0, 2'b11, 1'b1, 1'b0};
                5'd3:  dac_cmd = {8'h0F, 3'b000, 3'b001, 5'b00000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                5'd4:  dac_cmd = {8'h15, 3'b000, 3'b001, 5'b00000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                5'd5:  dac_cmd = {8'h1B, REF_LO, 6'b000000, 1'b0};
                5'd6:  dac_cmd = {8'h1C, REF_HI, 6'b000000, 1'b0};
                5'd7:  dac_cmd = {8'h1F, 16'h0249, 1'b0};
                5'd8:  dac_cmd = {8'h03, 16'h0400, 1'b0};
                5'd9:  dac_cmd = {8'h24, 16'h01F3, 1'b0};
                5'd10: dac_cmd = {8'h02, 10'b0101110111, 6'b000000, 1'b0};
                5'd11: dac_cmd = {8'h01, 10'b1100000111, 6'b000000, 1'b0};
                5'd12: dac_cmd = {8'h06, 1'b0, 1'b1, 1'b1, 2'b00, 3'b100, 1'b0, 3'b010, 4'b0110, 1'b0};
                default: dac_cmd = 25'd0;
            endcase
        end
    endfunction

    reg [8:0] spi_div;
    reg       spi_tick;

    always @(posedge clk_300M) begin
        if (reset) begin
            spi_div  <= 0;
            spi_tick <= 0;
        end else if (spi_div == 50) begin
            spi_div  <= 0;
            spi_tick <= 1;
        end else begin
            spi_div  <= spi_div + 1;
            spi_tick <= 0;
        end
    end

    reg spi_clk;
    reg spi_clk_en = 0;

    always @(posedge clk_300M) begin
        if (reset || !spi_clk_en)
            spi_clk <= 0;
        else if (spi_tick)
            spi_clk <= ~spi_clk;
    end

    assign SPI_SCLK = spi_clk;

    localparam IDLE       = 0;
    localparam INIT       = 1;
    localparam DELAY      = 2;
    localparam SHIFT      = 3;
    localparam DONE       = 4;
    localparam MARGIN_SET = 5;

    reg [3:0]  state;
    reg [4:0]  bit_cnt;
    reg [24:0] shift_reg;
    reg        dac_sdo;

    always @(posedge clk_300M) begin
        if (dac_pulse)
            cmd_active <= 1'b1;

        DAC_CS_2 <= 1;

        if (reset) begin
            state      <= IDLE;
            DAC_CS     <= 1;
            DAC_SDI    <= 0;
            bit_cnt    <= 0;
            cmd_active <= 1;
            cmd_index  <= 0;
        end else if (spi_tick) begin
            case (state)
                IDLE: begin
                    DAC_CS <= 1;
                    if (cmd_active) begin
                        state      <= SHIFT;
                        spi_clk_en <= 1;
                    end
                end

                INIT: begin
                    cmd_active <= 0;
                    if (spi_clk == 1) begin
                        if (bit_cnt == 5'd24) begin
                            state   <= DELAY;
                            bit_cnt <= 0;
                        end else
                            bit_cnt <= bit_cnt + 1;
                        DAC_CS <= 0;
                    end
                end

                DELAY: begin
                    DAC_CS    <= 1;
                    DAC_SDI   <= 0;
                    shift_reg <= dac_cmd(cmd_index);
                    if (spi_clk == 0) begin
                        if (bit_cnt == 5'd24) begin
                            state   <= SHIFT;
                            DAC_CS  <= 0;
                            bit_cnt <= 0;
                        end else
                            bit_cnt <= bit_cnt + 1;
                    end
                end

                SHIFT: begin
                    if (spi_clk == 0) begin
                        DAC_SDI <= shift_reg[24];
                    end else begin
                        shift_reg <= {shift_reg[23:0], 1'b0};
                        bit_cnt   <= bit_cnt + 1;
                        if (bit_cnt == 5'd23) begin
                            bit_cnt <= 0;
                            if (cmd_index == CMD_COUNT) begin
                                state     <= MARGIN_SET;
                                cmd_index <= 0;
                            end else begin
                                state     <= DELAY;
                                cmd_index <= cmd_index + 1;
                            end
                        end
                    end
                end

                DONE: begin
                    DAC_CS     <= 1;
                    DAC_SDI    <= 0;
                    state      <= IDLE;
                    cmd_active <= 0;
                    spi_clk_en <= 0;
                end

                MARGIN_SET: begin
                    DAC_CS <= 1;
                    if (spi_clk == 1) begin
                        dac_sdo <= DAC_SDO;
                        if (bit_cnt <= 0) begin
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

            endcase
        end
    end

    assign DAC_SDO   = dac_sdo;
    assign ROLL_CLK  = 1'b0;
    assign PWR_EN    = 1'b1;
    assign TEST_EN   = 1'b0;

    assign COL_EN        = 0;
    assign VLN_EN        = 0;
    assign SHS_EN        = 0;
    assign SHR_EN        = 0;
    assign ROW_COL_ADDR  = 0;
    assign CLAMP_EN      = 0;
    assign EXT_ADC_CONV_2 = 0;
    assign SPI_CLK_ADC_2 = 0;
    assign ROW_RST_EN    = 0;
    assign ROW_SEL_EN    = 0;
    assign ADDR_LATCH    = 0;
    assign EXT_ADC_CONV  = 0;

endmodule
