`timescale 1ns / 1ps

module adc_control(
    input  wire clk_300M,
    input  wire base_clk_en,
    input wire serdes_ce,
    input  wire reset,
    
    // ADC
    output wire ADC_TEST_EN,
    output reg  ADC_ENC,
    output reg  ADC_SH,
    output reg  ADC_PRE,
    output reg  ADC_CLK,
    
    // SERDES
    output reg  DATA_SCLK,
    output reg  DATA_LOAD,
    
    // WCIS DOUT
    input  wire DOUT_TOP,
    input  wire DOUT_BOT,
    
    output reg tx_wr, 
    output reg [7:0] tx_data_in, 
    input wire tx_full,
    input wire tx_empty,
    
    input wire sample_trigger,
    output reg sample_en,
    input wire [15:0] NUM_SAMPLES
);

assign ADC_TEST_EN = 1'b1;


// -----------------------------------------------------------------------------
// Synchronize DOUT_TOP to clk_100M
// -----------------------------------------------------------------------------
reg dout_top_sync0, dout_top_sync1;

always @(posedge clk_300M) begin
    dout_top_sync0 <= DOUT_TOP;
    dout_top_sync1 <= dout_top_sync0;
end

wire DOUT_TOP_SYNC = dout_top_sync1;


reg [3:0] state;
reg [4:0] serdes_cnt;
reg [4:0] adc_state;
reg [7:0] shift_reg;
reg [15:0] tx_cnt;




// -----------------------------------------------------------------------------
// Main FSM
// -----------------------------------------------------------------------------
always @(posedge clk_300M) begin
    if(sample_trigger) begin
        sample_en <= 1'b1;
        tx_cnt <= 0;
    end

    if (reset) begin
        serdes_cnt  <= 0;

        ADC_PRE     <= 1'b0;
        ADC_ENC     <= 1'b0;
        ADC_CLK     <= 1'b0;
        ADC_SH      <= 1'b0;
        DATA_SCLK   <= 1'b0;
        DATA_LOAD   <= 1'b0;
        tx_wr <= 1'b0;
        tx_data_in <= 0;
        shift_reg <= 0;
        tx_cnt <= 0;
        sample_en <= 0;
        
        adc_state <= 0;

    end else begin
        case (adc_state)
            5'd0: begin
//                if (base_clk_en) begin
                        DATA_SCLK <= 1'b1;
                        
                        if (!tx_full && sample_en) begin
                            tx_data_in <= shift_reg;
                            tx_wr <= 1'b1;
                            
                            if (tx_cnt == NUM_SAMPLES) begin
                                sample_en <= 0;
                                adc_state <= 0;
                                tx_cnt <= 0;
                                tx_wr <= 1'b0;
                            end else begin 
                                tx_cnt <= tx_cnt + 1;
                            end
                        end
                        
                        adc_state <= adc_state + 1;
//                end
            end
            
            5'd1: begin
                tx_wr <= 1'b0;
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b0;
                    
                    ADC_SH <= 1'b1;
                    ADC_PRE <= 1'b0;
                    ADC_ENC <= 1'b0;
                    ADC_CLK <= 1'b0;
                    DATA_LOAD <= 1'b0;
                    
                    // BIT 1
                    shift_reg <= {shift_reg[6:0], DOUT_TOP};
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd2: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b1;
                    
                    
                    
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd3: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b0;
                    
                    
                    // BIT 2
                    shift_reg <= {shift_reg[6:0], DOUT_TOP};
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd4: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b1;
                    
                    
                    
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd5: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b0;
                    
                    // BIT 3
                    shift_reg <= {shift_reg[6:0], DOUT_TOP};
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd6: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b1;
                    
                    
                    
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd7: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b0;
                    
                    // BIT 4
                    shift_reg <= {shift_reg[6:0], DOUT_TOP};
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd8: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b1;
                    
                    
                    
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd9: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b0;
                    
                    
                    
                    // BIT 5
                    shift_reg <= {shift_reg[6:0], DOUT_TOP};
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd10: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b1;
                    
                    
                    
                    adc_state <= adc_state + 1;
//                end
            end
            
            
            5'd11: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b0;
                    
//                    ADC_SH <= 1'b1;
                    
                    
                    
                    // BIT 6
                    shift_reg <= {shift_reg[6:0], DOUT_TOP};
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd12: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b1;
                    
                    ADC_SH <= 1'b0;
                    ADC_PRE <= 1'b1;
                    
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd13: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b0;
                    
                    
                    ADC_ENC <= 1'b1;
                    
                    
                    // BIT 7
                    shift_reg <= {shift_reg[6:0], DOUT_TOP};
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd14: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b1;
                    
                    ADC_CLK <= 1'b1;
                    
                    adc_state <= adc_state + 1;
//                end
            end
            
            5'd15: begin
//                if (base_clk_en) begin
                    DATA_SCLK <= 1'b0;
                    
                    DATA_LOAD <= 1'b1;
                    
                    
                    // BIT 8
                    shift_reg <= {shift_reg[6:0], DOUT_TOP};
                    adc_state <= 0;
//                end
            end
            
            
            default: adc_state <= 0;
        endcase
    end
end

endmodule