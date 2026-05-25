`timescale 1ns / 1ps


module tx(
    input wire baud_tick,   // baud rate tick
    input wire sysclk,      // 100Mhz sysclk
    
    input wire reset,       // reset tx
    input wire empty,       // fifo buffer is empty flag
    input wire full,
    
    output wire rd_en,      // read from fifo flag
    
    input wire [7:0] fifo_data, // 8-bit data from fifo
    output wire tx,          // tx line
    
    output wire [1:0] tx_state,
    output wire [7:0] tx_data
    );
    
    // states for UART-Tx FSM
    localparam [1:0]
      idle  = 2'b00,
      start = 2'b01,
      data  = 2'b10,
      stop  = 2'b11;
      
    localparam [2:0] load_fifo = 3'b100;
    reg [2:0] cnt_read_reg, cnt_read_next;
    
    reg tx_reg=1'b1, tx_next=1'b1;
    reg [1:0] state, state_next;
    reg [2:0] cnt_8_reg, cnt_8_next;
    reg [3:0] cnt_15_reg, cnt_15_next;
    reg [7:0] shift_out_reg, shift_out_next;
    reg rd_en_reg, rd_en_next;
    
    
    always @(posedge sysclk, posedge reset) begin
        if (reset) begin
            state <= idle;
            cnt_15_reg <= 4'b0000;
            cnt_8_reg <= 3'b000;
            shift_out_reg <= 8'b00000000;
            tx_reg <= 1'b1;
            rd_en_reg <= 1'b0;
            cnt_read_reg <= 0;
        end else begin
            tx_reg <= tx_next;
            state <= state_next;
            shift_out_reg <= shift_out_next;
            cnt_8_reg <= cnt_8_next;
            cnt_15_reg <= cnt_15_next;
            rd_en_reg <= rd_en_next;
            cnt_read_reg <= cnt_read_next;
        end
    end
    
    always @* begin
    
        state_next = state;
        cnt_15_next = cnt_15_reg;
        cnt_8_next = cnt_8_reg;
        shift_out_next = shift_out_reg;
        tx_next = tx_reg;
        rd_en_next = 1'b0;
        cnt_read_next = cnt_read_reg;
        
        case (state)
// ------------------------------------------------ IDLE -------------------------------------------------------
            idle: begin
                if (!empty) begin
                    state_next = start; // start
                    rd_en_next = 1'b1;
                    cnt_15_next = 0;
                    
                end else begin
                    state_next = idle;
                    tx_next = 1'b1;
                    rd_en_next = 1'b0;
                end
            end
            
//            load_fifo: begin
//                if (cnt_15_reg == 0) begin
//                    if (cnt_read_reg == 0) begin    rd_en_next = 1'b1;          cnt_read_next = cnt_read_reg + 1;   end
//                    if (cnt_read_reg == 1) begin                                cnt_read_next = cnt_read_reg + 1;   end
//                    if (cnt_read_reg == 2) begin    shift_out_next = fifo_data; cnt_read_next = cnt_read_reg + 1;   end
//                    if (cnt_read_reg == 3) begin    state_next = start;         cnt_read_next = cnt_read_reg + 1;   end
//                end
//            end
            
// ------------------------------------------------ START -------------------------------------------------------
            start: begin
                if (cnt_15_reg == 0)
                    shift_out_next = fifo_data;
                    
                
                tx_next = 1'b0;
                
                if (baud_tick) begin
                    if (cnt_15_reg == 15) begin
                        state_next = data;
                        cnt_15_next = 0;
                        cnt_8_next = 0;
                    end else begin
                    cnt_15_next = cnt_15_reg + 1'b1;
                    end
                end
            end
            
            
// ------------------------------------------------ DATA -------------------------------------------------------
            data: begin
                tx_next = shift_out_reg[0];
                
                if (baud_tick) begin
                    if (cnt_15_reg == 15) begin
                        cnt_15_next = 0;
                        shift_out_next = shift_out_reg >> 1;
                        if (cnt_8_reg == 7)
                            state_next = stop;
                        else
                            cnt_8_next = cnt_8_reg + 1'b1;
                    end else begin
                    cnt_15_next = cnt_15_reg + 1'b1;
                end
                end
            end
            
// ------------------------------------------------ STOP -------------------------------------------------------
            stop: begin
                tx_next = 1'b1;
                if (baud_tick) begin
                    if (cnt_15_reg == 15) begin
                        state_next = idle;
                        cnt_15_next = 0;
                        cnt_8_next = 0;
                    end else begin
                    cnt_15_next = cnt_15_reg + 1'b1;
                    end
                end
            end
        endcase
    end
        
    assign tx = tx_reg;
    assign rd_en = rd_en_reg;
    
    assign tx_state = state;
    assign tx_data = shift_out_reg;
    
    
endmodule
