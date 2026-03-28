`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2026 12:26:57 AM
// Design Name: 
// Module Name: scan_chain_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module scan_chain_control(
    output reg SCAN_IN,
    output reg SCAN_CLK,
    output reg SCAN_RSTB,
    output reg SCAN_SEL,
    
    input SCAN_START,
    input SCAN_OUT,
    input [7:0] adc_setting,
    input reset,
    input sysclk,
    input scan_sel_mode,
    input scan_rstb_pulse
    );
    
//    assign SCAN_RSTB = 1'b1;
    reg [15:0] scan_ce_cnt;
    reg scan_ce;
    reg [87:0] scan_chain = {20'd0, 8'd0, 31'd0, 8'b0, 11'd0};
    
    always @(posedge sysclk) begin
        if (reset) begin
            scan_ce_cnt  <= 7'd0;
            scan_ce <= 1'b0;
        end else if (scan_ce_cnt == 16'd250) begin
            scan_ce_cnt  <= 7'd0;
            scan_ce <= 1'b1;
        end else begin
            scan_ce_cnt  <= scan_ce_cnt + 1'b1;
            scan_ce <= 1'b0;
        end
    end
    
    reg [7:0] scan_bit_cnt;
    reg [3:0] scan_state;
    localparam [3:0]
        IDLE = 4'd0,
        RISE = 4'd1,
        FALL = 4'd2;
        
    reg scan_done;
    reg rstb_trig;
    
    always @(posedge sysclk) begin
    
        if (scan_sel_mode) begin
            SCAN_SEL <= 1'b0;
        end
        if (scan_rstb_pulse) begin
            rstb_trig <= 1'b1;
        end
        if (reset) begin
            SCAN_IN <= 1'b0;
            SCAN_SEL <= 1'b0;
            SCAN_CLK <= 1'b0;
//            scan_bit_cnt <= 8'd87;
            scan_bit_cnt <= 8'd0;
            scan_state <= IDLE;
            scan_chain <= {4'b0010, 16'd0, 8'd0, 11'b00100000100, 4'b0010, 16'd0, 8'b0, 11'b00100000100, 6'b001011, 4'b0100};
            scan_done <= 1'b0;
            rstb_trig <= 1'b0;
        end else begin
            case (scan_state)
                IDLE: begin
                    if (SCAN_START) begin
                        scan_state <= FALL;
//                        scan_bit_cnt <= 8'd87;
                        scan_bit_cnt <= 8'd0;
                        scan_done <= 1'b0;
                        rstb_trig <= 1'b0;
                        SCAN_SEL <= 1'b0;
                        SCAN_CLK <= 1'b0;
//                        scan_chain <= {19'd0, adc_setting, 31'd0, adc_setting, 11'd0};
//                            scan_chain <= {4'b0010, 16'd0, adc_setting, 11'b00100000100, 4'b0010, 16'd0, adc_setting, 11'b00100000100, 6'b001011, 4'b0100};
                            scan_chain <= {4'b0000, 16'd0, adc_setting, 11'b00000000000, 4'b0000, 16'd0, adc_setting, 11'b00000000000, 6'b001011, 4'b0100};
                    end else if (scan_ce) begin
//                        SCAN_SEL <= 1'b0;
                        if (scan_done) begin
                            SCAN_SEL <= 1'b1;
                            scan_done <= 1'b0;
                        end
                        if (rstb_trig) begin
                            SCAN_RSTB <= 1'b0;
                            rstb_trig <= 1'b0;
                        end else begin
                            SCAN_RSTB <= 1'b1;
                        end
                        SCAN_CLK <= 1'b0;
                    end
                end
            
                FALL: begin
                    if (scan_ce) begin
                        SCAN_CLK <= 1'b0;
                        scan_state <= RISE;
                        SCAN_IN <= {scan_chain[scan_bit_cnt]};
                        
                    end
                end
                
                RISE: begin
                    if (scan_ce) begin
                        SCAN_CLK <= 1'b1;
                        scan_state <= FALL;
                        scan_bit_cnt <= scan_bit_cnt + 1;
                        
//                        if (scan_bit_cnt == 8'd0) begin
                        if (scan_bit_cnt == 8'd87) begin
                            scan_state <= IDLE;
                            scan_done <= 1'b1;
//                            SCAN_SEL <= 1'b1;
                        end
                    end
                end
                
                
                
                default: scan_state <= IDLE;
            endcase
        end
    end
    
    
endmodule
