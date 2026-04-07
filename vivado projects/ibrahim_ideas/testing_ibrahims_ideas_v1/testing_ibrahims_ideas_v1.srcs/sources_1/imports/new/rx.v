`timescale 1ns / 1ps

module rx (
    input wire baud_tick,   // baud rate tick
    input wire sysclk,      // 12Mhz sysclk
    
    input wire reset,       // reset tx
    input wire full,       // fifo buffer is empty flag
    
    output wire wr_en,      // read from fifo flag
    
    output wire [7:0] rx_data, // 8-bit data from fifo
    input wire rx          // tx line
    );
    
        
    // states for UART-Rx FSM
    localparam [1:0]
      idle  = 2'b00,
      start = 2'b01,
      data  = 2'b10,
      stop  = 2'b11;
    
    reg [7:0] rx_reg, rx_next;
    reg [1:0] state, state_next;
    reg [2:0] cnt_8_reg, cnt_8_next;
    reg [3:0] cnt_15_reg, cnt_15_next;
    reg [7:0] shift_out_reg, shift_out_next;
    reg wr_en_reg, wr_en_next;
    
    
    always @(posedge sysclk, posedge reset) begin
        if (reset) begin
            state <= idle;
            cnt_15_reg <= 0;
            cnt_8_reg <= 0;
            shift_out_reg <= 0;
            rx_reg <= 0;
            wr_en_reg <= 1'b0;
        end else begin
            state <= state_next;
            cnt_15_reg <= cnt_15_next;
            cnt_8_reg <= cnt_8_next;
            shift_out_reg <= shift_out_next;
            rx_reg <= rx_next;
            wr_en_reg <= wr_en_next;
        end
    end
    
    always @* begin
    
        state_next = state;
        cnt_15_next = cnt_15_reg;
        cnt_8_next = cnt_8_reg;
        shift_out_next = shift_out_reg;
        rx_next = rx_reg;
        wr_en_next = 1'b0;
    
        case (state)
// ------------------------------------------------ IDLE -------------------------------------------------------
            idle: begin
                if (!rx) begin
                    state_next = start;
                    cnt_15_next = 0;
                end
            end
// ------------------------------------------------ START -------------------------------------------------------
            start: begin
                if (baud_tick) begin
                    if (cnt_15_reg == 7) begin
                        if (!rx) begin
                            state_next  = data;
                            cnt_15_next = 0;
                            cnt_8_next  = 0;
                        end else begin
                            state_next = idle; // false start, ignore
                            cnt_15_next = 0;
                        end
                    end else begin
                        cnt_15_next = cnt_15_reg + 1'b1;
                    end
                end
            end
// ------------------------------------------------ DATA -------------------------------------------------------
            data: begin
                if (baud_tick) begin
                    if (cnt_15_reg == 15) begin
                        cnt_15_next = 0;
                        shift_out_next = {rx, shift_out_reg[7:1]};
                        
                        if (cnt_8_reg == 7)
                            state_next = stop;
                        else
                            cnt_8_next = cnt_8_reg + 1'b1;
                    end
                    else
                        cnt_15_next = cnt_15_reg + 1'b1;
                end
            end
// ------------------------------------------------ STOP -------------------------------------------------------
            stop: begin
                
                if (baud_tick) begin
                    if (cnt_15_reg == 15) begin
                        cnt_15_next = 0;
                        state_next = idle;
                        
                        if (!full) begin
                            wr_en_next = 1'b1;
                            rx_next = shift_out_reg;
                        end 
                        
                    end else
                        cnt_15_next = cnt_15_reg + 1'b1;
                end
            end
       endcase
    end
    
    assign rx_data = rx_reg;
    assign wr_en = wr_en_reg;
    
endmodule
