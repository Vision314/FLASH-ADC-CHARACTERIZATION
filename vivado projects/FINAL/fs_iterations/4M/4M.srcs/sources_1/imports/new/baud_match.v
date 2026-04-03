`timescale 1ns / 1ps


module baud_match #(M=54) ( // mod - M | M = clk_freq / (16 * baud_rate) => 78
                            // 100,000,000 / (16 * 12,000,000) = M = 520.8 = 521
    input wire clk,
    input wire reset,
    input wire baud_clk
    );
    
    localparam N = log2(M); // number of bits neaded in the counter NOT SURE IF CLOG2() IS RIGHT!!
    reg [N-1:0] r_reg;
    wire [N-1:0] r_next;
    
    always @(posedge clk, posedge reset) begin
        if (reset)
            r_reg <= 0;
        else
            r_reg <= r_next;
            
    end
    
    assign r_next = (r_reg == (M-1)) ? 1'b0 : r_reg+1'b1;
    
    assign baud_clk = (r_reg == (M-1)) ? 1'b1 : 1'b0;
    
    
      //function to calculate the bits for the counter according to the size of M
  function integer log2(input integer n);
    integer i;
    begin
      log2=1;
      for (i=0; 2**i < n; i=i+1)
        log2=i+1;
    end
  endfunction
endmodule
