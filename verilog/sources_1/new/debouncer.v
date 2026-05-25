module debouncer (
    input  wire clk,      // system clock
    input  wire btn1,     // raw button input
    output reg  btn_db    // debounced output
);

reg [19:0] counter = 0;   // adjust width for debounce time
reg btn_sync = 0;

always @(posedge clk) begin
    btn_sync <= btn1;     // simple synchronization

    if (btn_sync == btn_db) begin
        counter <= 0;     // no change detected
    end else begin
        counter <= counter + 1;
        if (counter == 20'hFFFFF) begin
            btn_db <= btn_sync; // update after stable period
        end
    end
end

endmodule