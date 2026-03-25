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
    output wire ROLL_SEL, // set low
    output wire ROLL_CLK,   // clk @ base_clk_en
    
    // SCAN CHAIN
    output wire SCAN_SEL, // set low for now
    output wire SCAN_CLK, // clk @ base_clk_en
    output wire SCAN_RSTB, // set high for now
    input wire SCAN_OUT,    // do nothing
    output wire SCAN_IN,     // set low for now

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
    output wire  SPI_SCLK, // SPI_CLK  PIO41
    output reg  DAC_SDI,  // DAC_SDI  PIO42
    output reg  DAC_CS,   // DAC_CS_1 PIO45
    inout wire  DAC_SDO,  // DAC_IO_1 PIO46
    output reg DAC_CS_2,

    // WCIS DOUT
    input  wire DOUT_TOP,
    input  wire DOUT_BOT,

    output wire Tx,
    input wire Rx,
    
    output wire EXT_ADC_CONV,
    input wire EXT_ADC_DATA,
    
    
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
    
    // ------------------------------------------------------------
    // Clocking and reset
    // ------------------------------------------------------------
    wire clk_300M;
    wire clk_200M;
    wire clk_100M;
    wire clk_locked;
    
    
    
    wire btn0_pulse, btn1_pulse;
    wire sample_trigger;
    reg cmd_sample_pulse;
    wire btn0_db, btn1_db;
    reg btn0_db_d, btn1_db_d;
    // instantiate debouncer
    debouncer db_btn1 (
        .clk(clk_300M),
        .btn1(btn1),
        .btn_db(btn1_db)
    );
    debouncer db_btn0 (
        .clk(clk_300M),
        .btn1(btn0),
        .btn_db(btn0_db)
    );
    
    
    
    
    
    // --- PLL reset: use sysclk-domain debounced button ---
    reg btn0_sysclk_d1, btn0_sysclk_d2;
    always @(posedge sysclk) begin
        btn0_sysclk_d1 <= btn0;
        btn0_sysclk_d2 <= btn0_sysclk_d1;
    end
    wire pll_reset = btn0_sysclk_d2;  // raw debounce on sysclk is fine here
    
    clk_wiz_0 u_100M_clk (
        .clk_out1 (clk_300M),
        .clk_in1  (sysclk),
        .reset    (pll_reset),   // <-- driven by sysclk domain
        .locked   (clk_locked)
    );
    
    // --- System reset: stretch locked de-assertion ---
    reg [3:0] rst_pipe = 4'hF;   // start in reset
    always @(posedge clk_300M) begin
        rst_pipe <= {rst_pipe[2:0], ~clk_locked};
    end
    wire reset = rst_pipe[3];  // replaces your existing reset wire
    
    
    
    
    
    
    
    
    
    
//    // edge detector for pulse
//    always @(posedge clk_300M) begin
//        btn1_db_d <= btn1_db;
//        btn0_db_d <= btn0_db;
//    end
    
//    assign btn0_pulse = btn0_db & ~btn0_db_d;
//    assign btn1_pulse = btn1_db & ~btn1_db_d;
    
    
//    wire reset;
//    assign reset = btn0_pulse;
    
    

//    clk_wiz_0 u_100M_clk (
//        .clk_out1 (clk_300M),
////        .clk_out2 (clk_300M),
////        .clk_out3 (clk_10M),
//        .clk_in1  (sysclk),
//        .reset    (reset),
//        .locked   (clk_locked)
//    );
    wire baud_tick;
    wire        rx_wr;
    reg         rx_rd;
    wire [7:0]  rx_data_in, rx_data_out;
    wire        rx_full, rx_empty;
    
    rx u_rx (
        .baud_tick(baud_tick),
        .sysclk(clk_300M),
        .reset(reset),
        .full(rx_full),
        .wr_en(rx_wr),
        .rx_data(rx_data_in),
        .rx(Rx)
    );
    

    
    reg [15:0] CNT_LIMIT = 16'd2;
    
    reg [23:0] rx_code = 0;
    reg [4:0] rx_cnt;
    reg [3:0] rx_cmd_state;
    reg [23:0] shift_rx;
    reg rx_valid;
    reg [15:0] NUM_SAMPLES = 16'd4096;
    wire dac_trigger;
    reg dac_pulse;
    
    localparam [3:0] 
        READ = 4'd0,
        EXECUTE = 4'd1;
    reg [1:0]  rx_state;     // 0 = waiting for cmd, 1/2 = data bytes
    reg [23:0] rx_code;
    reg [9:0] REF_LO = 10'b0101110111;
    reg [9:0] REF_HI= 10'b1100000111;
    
    wire SCAN_START;
    reg scan_start_pulse;
    assign SCAN_START = scan_start_pulse;
    reg [7:0] adc_setting;
    reg scan_sel_mode = 0;
    reg scan_rstb_pulse = 0;
    

    always @(posedge clk_300M) begin
        if (reset) begin
            rx_state  <= 0;
            rx_code   <= 0;
            CNT_LIMIT <= 16'd2;
            cmd_sample_pulse <= 0;
            dac_pulse <= 0;
            scan_start_pulse <= 0;
            scan_rstb_pulse <= 1'b0;
        end else begin
            cmd_sample_pulse <= 0;
            scan_start_pulse <= 0;
            scan_sel_mode <= 0;
            dac_pulse <= 0;
            scan_rstb_pulse <= 1'b0;
            if (rx_wr) begin  // <-- THIS IS YOUR rx_valid
                
                case (rx_state)
    
                    // -------- BYTE 0: COMMAND --------
                    0: begin
                        rx_code[23:16] <= rx_data_in;  // command
                        rx_state <= 1;
                        
                    end
    
                    // -------- BYTE 1: DATA HIGH --------
                    1: begin
                        rx_code[15:8] <= rx_data_in;
                        rx_state <= 2;
                    end
    
                    // -------- BYTE 2: DATA LOW --------
                    2: begin
                        rx_code[7:0] <= rx_data_in;
    
                        // EXECUTE immediately
                        case (rx_code[23:16])
    
                            8'h01: begin
                                CNT_LIMIT <= {rx_code[15:8], rx_data_in};
                            end
    
                            8'h02: begin
                                cmd_sample_pulse <= 1'b1;
                            end
                            
                            8'h03: begin
                                NUM_SAMPLES <= {rx_code[15:8], rx_data_in};
                            end
                            8'h04: begin // REF LOW
                                REF_LO <= {rx_code[9:8], rx_data_in}; 
                            end
                            8'h05: begin // REF HIGH
                                REF_HI <= {rx_code[9:8], rx_data_in}; 
                            end
                            8'h06: begin // DAC TRIGGER
                                dac_pulse <= 1'b1;
                            end
                            
                            8'h07: begin
                                scan_start_pulse <= 1'b1;
                                adc_setting <= {rx_data_in};
                            
                            end
                            8'h08: begin
                                scan_sel_mode <= 1'b1;
                            end
                            
                            8'h09: begin
                                scan_rstb_pulse <= 1'b1;
                            end
    
                            default: begin
                                // unknown
                            end
    
                        endcase
                        
                        rx_state <= 0; // ready for next command
                    end
    
                endcase
            end
        end
    end
    
    
    
    
    
    // ------------------------------------------------------------
    // WCIS clock enable
    // ------------------------------------------------------------
    reg [15:0] ce_cnt;
    reg wcis_ce;
    reg serdes_ce;
    
    
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
    
    
//    assign SCAN_RSTB = 1'b1;
//    assign SCAN_IN = 1'b0;
//    assign SCAN_SEL     =   1'b0;
    assign ROLL_SEL     =   1'b0;
    assign LEDB         = ~reset;
    
    
    // ------------------------------------------------------------
    // WCIS core
    // ------------------------------------------------------------
    wire        tx_wr;
    wire [7:0]  tx_data_in;
    wire        tx_full;
    wire sample_en;
    
    assign sample_trigger = btn1_pulse | cmd_sample_pulse;
//    assign dac_trigger = dac_pulse;
    
    adc_control u_adc (
        .clk_300M    (clk_300M),
        .base_clk_en (wcis_ce),
//        .serdes_ce (serdes_ce),
        .reset       (reset),

        .ADC_TEST_EN (ADC_TEST_EN),
        .ADC_ENC     (ADC_ENC),
        .ADC_SH      (ADC_SH),
        .ADC_PRE     (ADC_PRE),
        .ADC_CLK     (ADC_CLK),

        .DATA_SCLK   (DATA_SCLK),
        .DATA_LOAD   (DATA_LOAD),

        .DOUT_TOP    (DOUT_TOP),
        .DOUT_BOT    (DOUT_BOT),

        .tx_wr       (tx_wr),
        .tx_data_in  (tx_data_in),
        .tx_full     (tx_full),
        .sample_trigger(sample_trigger),
        .sample_en (sample_en),
        .NUM_SAMPLES (NUM_SAMPLES)
    );
    assign LEDR = ~sample_en;
    
    
    scan_chain_control scan_chain_controller(
    .SCAN_IN(SCAN_IN),
    .SCAN_CLK(SCAN_CLK),
    .SCAN_RSTB(SCAN_RSTB),
    .SCAN_SEL(SCAN_SEL),
    
    .SCAN_START(SCAN_START),
    .SCAN_OUT(SCAN_OUT),
    .adc_setting(adc_setting),
    .reset(reset),
    .sysclk(clk_300M),
    
    .scan_sel_mode(scan_sel_mode),
    .scan_rstb_pulse(scan_rstb_pulse)
    );

    // ------------------------------------------------------------
    // TX FIFO
    // ------------------------------------------------------------
    wire        tx_rd;
    wire [7:0]  tx_data_out;
    wire        tx_empty;

    tx_fifo u_tx_fifo (
        .clk   (clk_300M),
        .srst   (reset),
        .din   (tx_data_in),
        .wr_en (tx_wr),
        .rd_en (tx_rd),
        .dout  (tx_data_out),
        .full  (tx_full),
        .empty (tx_empty)
    );

    // ------------------------------------------------------------
    // Baud generator
    // ------------------------------------------------------------
    
    // 323.36842 - 
    baud_match #(
        .M(8) //651
    ) u_baud_match (
        .clk      (clk_300M),
        .reset    (reset),
        .baud_clk (baud_tick)
    );

    // ------------------------------------------------------------
    // UART TX
    // ------------------------------------------------------------
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



    //=========================================================================
    // DAC SPI State Machine (~190 kHz)
    // Runs fixed command sequence after each reset
    //=========================================================================
//    localparam SPI_IDLE   = 3'd0;
//    localparam SPI_START  = 3'd1;
//    localparam SPI_SHIFT  = 3'd2;
//    localparam SPI_DONE   = 3'd3;
//    localparam SPI_DONE_2 = 3'd4;
//    localparam DELAY = 3'd5;
    
    
    
//    reg [2:0] spi_state = SPI_IDLE;
//    reg [24:0] spi_shift_reg = 0;
//    reg [4:0]  spi_bit_count = 0;
//    reg [15:0] spi_delay = 0;
    
    localparam CMD_COUNT = 4'd6;
    
    reg [4:0] cmd_index = 0;
    reg       cmd_active = 0;
    
    assign dac_trigger = cmd_active | dac_pulse;
    
    
    // Command ROM (24-bit SPI words)
    function [24:0] dac_cmd;
        input [3:0] idx;
        begin
            case (idx)
                5'd1: dac_cmd = {8'h24, 1'b0, 1'b0, 1'b1, 4'b0001, 4'b1100, 4'b0000, 1'b0, 1'b0};                           // GPIO-CONFIG
                5'd2: dac_cmd = {8'h1F, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 2'b00, 1'b0, 2'b00, 1'b0, 2'b11, 1'b1, 1'b0};  // COMMON-CONFIG
                5'd3: dac_cmd = {8'h0F, 3'b000, 3'b001, 5'b00000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};                      // DAC-2-VOUT-CMP-CONFIG
                5'd4: dac_cmd = {8'h15, 3'b000, 3'b001, 5'b00000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};                      // DAC-3-VOUT-CMP-CONFIG
                5'd5: dac_cmd = {8'h1B, REF_LO, 6'b000000, 1'b0};                                                   // DAC-2-DATA-1.2V
                5'd6: dac_cmd = {8'h1C, REF_HI, 6'b000000, 1'b0};                                                   // DAC-3-DATA-2.5V
                
                5'd7: dac_cmd = {8'h1F, 16'h0249, 1'b0};                                                                    // COMMON-CONFIG
                // 0 0 0 0 00 1 00 1 00 1 00 1
                5'd8: dac_cmd = {8'h03, 16'h0400, 1'b0};                                                                    // DAC-0-VOUT-CMP-CONFIG
                // 0 000 01000 0 0 0 0 0 00
                5'd9: dac_cmd = {8'h24, 16'h01F3, 1'b0};                                                                    // DAC-0-VOUT-CMP-CONFIG
                5'd10: dac_cmd = {8'h02, 10'b0101110111, 6'b000000, 1'b0};                                                  // DAC-0-MARGIN-LOW - 1.2V
                5'd11: dac_cmd = {8'h01, 10'b1100000111, 6'b000000, 1'b0};                                                  // DAC-0-MARGIN-HIGH - 2.5V
                5'd12: dac_cmd = {8'h06, 1'b0, 1'b1, 1'b1, 2'b00, 3'b100, 1'b0, 3'b010, 4'b0110, 1'b0};                     // DAC-0-FUNC-CONFIG | linear slew
                
//                5'd7: dac_cmd = {8'h24, 1'b0, 1'b0, 1'b0, 4'b0000, 4'b0001, 4'b1010, 1'b1, 1'b0};                           // GPIO-CONFIG
//                5'd8: dac_cmd = {8'h1F, 1'b0, 1'b0, 1'b0, 1'b1, 2'b11, 1'b1, 2'b11, 1'b1, 2'b11, 1'b1, 2'b00, 1'b1, 1'b0};  // COMMON-CONFIG
//                5'd9: dac_cmd = {8'h03, 3'b000, 3'b001, 5'b00000, 1'b1, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0};                      // DAC-0-VOUT-CMP-CONFIG
//                5'd10: dac_cmd = {8'h06, 1'b0, 1'b1, 1'b1, 2'b00, 3'b100, 1'b0, 3'b010, 4'b0110, 1'b0};                     // DAC-0-FUNC-CONFIG | linear slew
//                5'd11: dac_cmd = {8'h01, 10'b1100000111, 6'b000000, 1'b0};                                                  // DAC-0-MARGIN-HIGH - 2.5V
//                5'd12: dac_cmd = {8'h02, 10'b0101110111, 6'b000000, 1'b0};                                                  // DAC-0-MARGIN-LOW - 1.2V
                
//                5'd13: dac_cmd = {8'h24, 1'b0, 1'b0, 1'b1, 4'b0001, 4'b1100, 4'b0000, 1'b0, 1'b0};


//                3'd0: dac_cmd = {24'b000111110001001001101101, 1'b0}; // COMMON-CONFIG
//                3'd1: dac_cmd = {24'b000011110000010000000000, 1'b0}; // DAC-2-VOUT-CMP-CONFIG
//                3'd2: dac_cmd = {24'b000101010000010000000000, 1'b0}; // DAC-3-VOUT-CMP-CONFIG
//                3'd3: dac_cmd = {24'b000110110101110111000000, 1'b0}; // DAC-2-DATA-1.2V
//                3'd4: dac_cmd = {24'b000111000101111111000000, 1'b0}; // DAC-2-DATA-1.5V
//                3'd4: dac_cmd = {24'b000111001100000111000000, 1'b0}; // DAC-3-DATA-2.5V    
//                3'd6: dac_cmd = {24'b000001100000010000110001, 1'b0}; // DAC-0-FUNC-CONFIG  


//                5'd0: dac_cmd = {8'h20, 4'b0000, 4'b1010, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};            // COMMON-TRIGGER
//                5'd0: dac_cmd = {8'h24, 1'b1, 1'b0, 1'b0, 4'b0000, 4'b1111, 4'b1000, 1'b1, 1'b0};                           // GPIO-CONFIG
//                5'd2: dac_cmd = {8'h03, 3'b000, 3'b001, 5'b00000, 1'b1, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0};                      // DAC-0-VOUT-CMP-CONFIG

//                5'd3: dac_cmd = {8'h06, 1'b0, 1'b1, 1'b1, 2'b00, 3'b100, 1'b0, 3'b010, 4'b0110, 1'b0};                      // DAC-0-FUNC-CONFIG | linear slew
////              5 4'd6: dac_cmd = {8'h06, 1'b0, 1'b0, 1'b0, 2'b00, 3'b100, 1'b1, 3'b010, 3'b010, 1'b0};                     // DAC-0-FUNC-CONFIG | log slew

//                5'd8: dac_cmd = {8'h01, 10'b1100000111, 6'b000000, 1'b0};                                                   // DAC-0-MARGIN-HIGH - 2.5V
//                5'd9: dac_cmd = {8'h02, 10'b0101110111, 6'b000000, 1'b0};                                                   // DAC-0-MARGIN-LOW - 1.2V



                default: dac_cmd = 25'd0;
            endcase
        end
    endfunction
    
    
    
    reg [8:0] spi_div;
    reg spi_tick;
    
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
    
    localparam IDLE  = 0;
    localparam INIT  = 1;
    localparam DELAY = 2;
    localparam SHIFT = 3;
    localparam DONE  = 4;
    localparam MARGIN_SET = 5;
    
    reg [3:0] WAVEFORM_STATE;
    reg [3:0] state;
    reg [4:0] bit_cnt;
    reg [24:0] shift_reg;
    reg dac_sdo;
    
    
    
    always @(posedge clk_300M) begin
        if (dac_pulse) begin
            cmd_active <= 1'b1;
        end
    
    
        DAC_CS_2 <= 1;
        if (reset) begin
            state <= IDLE;
            DAC_CS <= 1;
            DAC_SDI <= 0;
            bit_cnt <= 0;
            cmd_active <= 1;
            cmd_index <= 0;
        end 
        else if (spi_tick) begin
            case (state)
                IDLE: begin
                    DAC_CS <= 1;
                    
                    
                    if (cmd_active) begin
                        state <= SHIFT;
                        
                        spi_clk_en <= 1;
                    end
                end
                
                INIT: begin
                    cmd_active <= 0;
                    if (spi_clk == 1) begin
                        if(bit_cnt == 5'd24) begin
                            state <= DELAY;
                            bit_cnt <= 0;
                        end else
                            bit_cnt <= bit_cnt + 1;
                        DAC_CS <= 0;
                    end
                end
                
                DELAY: begin
                    DAC_CS <= 1;
                    DAC_SDI <= 0;
                    shift_reg <= dac_cmd(cmd_index);
                    
                    if (spi_clk == 0) begin
                        if (bit_cnt == 5'd24) begin
                            state <= SHIFT;
                            DAC_CS <= 0;
                            bit_cnt <= 0;
//                            spi_clk_en <= 0;
                        end else
                            bit_cnt <= bit_cnt + 1;
                        
                        
                    end
                    
                end
        
                SHIFT: begin
                    
                    if (spi_clk == 0) begin
                        // output data
                        DAC_SDI <= shift_reg[24];
                                            
                    end else begin
                        // shift on other edge
                        shift_reg <= {shift_reg[23:0],1'b0};
                        bit_cnt <= bit_cnt + 1;
                        
                        
                        if (bit_cnt == 5'd23) begin
                            bit_cnt <= 0;
                            if (cmd_index == CMD_COUNT) begin
                                state <= MARGIN_SET;
                                cmd_index <= 0;
                                
                            end else begin
                                state <= DELAY;
                                cmd_index <= cmd_index + 1;
                            end
                        end
                    end
                    
                    
                end
                
        
                DONE: begin
                    DAC_CS <= 1;
                    DAC_SDI <= 0;
                    state <= IDLE;
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
                            state <= DONE;
                        end
                    end
                    
                end
    
            endcase
        end
    end
    
    assign DAC_SDO = dac_sdo;
    assign ROLL_CLK = 1'b0;
    assign PWR_EN = 1'b1;
    assign TEST_EN = 1'b0;
    
    
    assign COL_EN = 0;
    assign VLN_EN = 0;            
    assign SHS_EN = 0;        
    assign SHR_EN = 0;
    assign ROW_COL_ADDR = 0;
    assign CLAMP_EN = 0;  
    assign EXT_ADC_CONV_2 = 0;    
    assign SPI_CLK_ADC_2 = 0;
    assign ROW_RST_EN = 0; 
    assign ROW_SEL_EN = 0;    
    assign ADDR_LATCH = 0;    
    assign EXT_ADC_CONV = 0;    
    assign EXT_ADC_DATA = 0;  
    
    
endmodule 
