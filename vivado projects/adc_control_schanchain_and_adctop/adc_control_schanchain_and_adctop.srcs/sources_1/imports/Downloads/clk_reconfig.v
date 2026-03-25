// =============================================================================
// clk_reconfig.v
//
// AXI4-Lite master FSM that wraps clk_wiz_dyn.
// clk_wiz_dyn has no reset pin - only s_axi_aresetn gates the AXI logic.
//
// PORTS:
//   s_axi_aclk    - AXI clock (same as clk_in1, your 100MHz)
//   s_axi_aresetn - Active-low reset, gates AXI transactions
//   clk_in        - Input clock to clk_wiz_dyn (your 100MHz)
//   clk_out       - Output clock at selected frequency
//   locked        - High when clk_wiz_dyn is locked and output is stable
//   reconfig_valid - Pulse high for one cycle to trigger reconfiguration
//   reconfig_ready - Pulses high for one cycle when reconfiguration is done
//   new_divide     - CLKOUT0 divide value
//   new_multiply   - CLKFBOUT multiply value
//   new_divclk     - Input divider (usually 1)
// =============================================================================

module clk_reconfig #(
    parameter integer DEFAULT_DIVIDE   = 5,
    parameter integer DEFAULT_MULTIPLY = 8,
    parameter integer DEFAULT_DIVCLK   = 1
) (
    input  wire       s_axi_aclk,
    input  wire       s_axi_aresetn,

    input  wire       clk_in,
    output wire       clk_out,
    output wire       locked,

    input  wire       reconfig_valid,
    output reg        reconfig_ready,

    input  wire [7:0] new_divide,
    input  wire [7:0] new_multiply,
    input  wire [7:0] new_divclk
);

// =============================================================================
// AXI4-Lite signals
// =============================================================================
reg  [10:0] m_axil_awaddr;
reg         m_axil_awvalid;
wire        m_axil_awready;

reg  [31:0] m_axil_wdata;
reg         m_axil_wvalid;
wire        m_axil_wready;
wire [1:0]  m_axil_bresp;
wire        m_axil_bvalid;
reg         m_axil_bready;

reg  [10:0] m_axil_araddr;
reg         m_axil_arvalid;
wire        m_axil_arready;
wire [31:0] m_axil_rdata;
wire [1:0]  m_axil_rresp;
wire        m_axil_rvalid;
reg         m_axil_rready;

// =============================================================================
// clk_wiz_dyn instantiation
// Note: no reset pin on this wizard when dynamic reconfig is enabled
// =============================================================================
clk_wiz_dyn u_clk_wiz (
    .clk_in1        (clk_in),
    .clk_out1       (clk_out),
    .locked         (locked),

    .s_axi_aclk     (s_axi_aclk),
    .s_axi_aresetn  (s_axi_aresetn),

    .s_axi_awaddr   (m_axil_awaddr),
    .s_axi_awvalid  (m_axil_awvalid),
    .s_axi_awready  (m_axil_awready),

    .s_axi_wdata    (m_axil_wdata),
    .s_axi_wstrb    (4'hF),
    .s_axi_wvalid   (m_axil_wvalid),
    .s_axi_wready   (m_axil_wready),

    .s_axi_bresp    (m_axil_bresp),
    .s_axi_bvalid   (m_axil_bvalid),
    .s_axi_bready   (m_axil_bready),

    .s_axi_araddr   (m_axil_araddr),
    .s_axi_arvalid  (m_axil_arvalid),
    .s_axi_arready  (m_axil_arready),

    .s_axi_rdata    (m_axil_rdata),
    .s_axi_rresp    (m_axil_rresp),
    .s_axi_rvalid   (m_axil_rvalid),
    .s_axi_rready   (m_axil_rready)
);

// =============================================================================
// AXI4-Lite single-write sub-FSM
// Set wr_addr/wr_data, pulse wr_start for one cycle.
// wr_done pulses one cycle when write response received.
// =============================================================================
reg  [10:0] wr_addr;
reg  [31:0] wr_data;
reg         wr_start;
reg         wr_done;

localparam WR_IDLE = 2'd0,
           WR_ADDR = 2'd1,
           WR_DATA = 2'd2,
           WR_RESP = 2'd3;

reg [1:0] wr_state;

always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        wr_state       <= WR_IDLE;
        m_axil_awvalid <= 0;
        m_axil_wvalid  <= 0;
        m_axil_bready  <= 0;
        wr_done        <= 0;
    end else begin
        wr_done <= 0; // default

        case (wr_state)
            WR_IDLE: begin
                if (wr_start) begin
                    m_axil_awaddr  <= wr_addr;
                    m_axil_wdata   <= wr_data;
                    m_axil_awvalid <= 1;
                    m_axil_wvalid  <= 1;
                    m_axil_bready  <= 1;
                    wr_state       <= WR_ADDR;
                end
            end

            WR_ADDR: begin
                if (m_axil_awready) begin
                    m_axil_awvalid <= 0;
                    wr_state       <= WR_DATA;
                end
            end

            WR_DATA: begin
                if (m_axil_wready) begin
                    m_axil_wvalid <= 0;
                    wr_state      <= WR_RESP;
                end
            end

            WR_RESP: begin
                if (m_axil_bvalid) begin
                    m_axil_bready <= 0;
                    wr_done       <= 1;
                    wr_state      <= WR_IDLE;
                end
            end
        endcase
    end
end

// =============================================================================
// Reconfig sequencer FSM
// Clocking Wizard AXI register offsets (PG065):
//   0x200 = CLKOUT0 divide
//   0x304 = CLKFBOUT multiply
//   0x300 = Input clock divide (DIVCLK)
//   0x380 = Load register  - write 0x3 to apply
//   0x384 = SEN register   - write 0x1 to start
//   0x000 = Status         - bit 0 = locked
// =============================================================================
localparam [10:0]
    ADDR_CLKOUT0_DIV  = 11'h200,
    ADDR_CLKFBOUT_MULT= 11'h304,
    ADDR_DIVCLK       = 11'h300,
    ADDR_LOAD         = 11'h380,
    ADDR_SEN          = 11'h384,
    ADDR_STATUS       = 11'h000;

localparam
    RC_IDLE        = 4'd0,
    RC_WR_DIV      = 4'd1,
    RC_WR_MULT     = 4'd2,
    RC_WR_DIVCLK   = 4'd3,
    RC_WR_LOAD     = 4'd4,
    RC_WR_SEN      = 4'd5,
    RC_WAIT_UNLOCK = 4'd6,
    RC_POLL_LOCK   = 4'd7,
    RC_RD_WAIT     = 4'd8,
    RC_CHECK_LOCK  = 4'd9,
    RC_DONE        = 4'd10;

reg [3:0]  rc_state;
reg [7:0]  lat_divide, lat_multiply, lat_divclk;
reg [10:0] unlock_timer;

always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        rc_state       <= RC_IDLE;
        reconfig_ready <= 0;
        wr_start       <= 0;
        m_axil_arvalid <= 0;
        m_axil_rready  <= 0;
        unlock_timer   <= 0;
        lat_divide     <= DEFAULT_DIVIDE;
        lat_multiply   <= DEFAULT_MULTIPLY;
        lat_divclk     <= DEFAULT_DIVCLK;
    end else begin
        wr_start       <= 0; // default
        reconfig_ready <= 0; // default

        case (rc_state)

            RC_IDLE: begin
                if (reconfig_valid) begin
                    lat_divide   <= new_divide;
                    lat_multiply <= new_multiply;
                    lat_divclk   <= new_divclk;
                    rc_state     <= RC_WR_DIV;
                end
            end

            RC_WR_DIV: begin
                wr_addr  <= ADDR_CLKOUT0_DIV;
                wr_data  <= {24'h0, lat_divide};
                wr_start <= 1;
                if (wr_done)
                    rc_state <= RC_WR_MULT;
            end

            RC_WR_MULT: begin
                wr_addr  <= ADDR_CLKFBOUT_MULT;
                wr_data  <= {24'h0, lat_multiply};
                wr_start <= 1;
                if (wr_done)
                    rc_state <= RC_WR_DIVCLK;
            end

            RC_WR_DIVCLK: begin
                wr_addr  <= ADDR_DIVCLK;
                wr_data  <= {24'h0, lat_divclk};
                wr_start <= 1;
                if (wr_done)
                    rc_state <= RC_WR_LOAD;
            end

            RC_WR_LOAD: begin
                wr_addr  <= ADDR_LOAD;
                wr_data  <= 32'h3;
                wr_start <= 1;
                if (wr_done)
                    rc_state <= RC_WR_SEN;
            end

            RC_WR_SEN: begin
                wr_addr  <= ADDR_SEN;
                wr_data  <= 32'h1;
                wr_start <= 1;
                if (wr_done) begin
                    unlock_timer <= 0;
                    rc_state     <= RC_WAIT_UNLOCK;
                end
            end

            // Wait for MMCM to drop locked before polling
            RC_WAIT_UNLOCK: begin
                unlock_timer <= unlock_timer + 1;
                if (unlock_timer == 11'd1023)
                    rc_state <= RC_POLL_LOCK;
            end

            // Issue AXI read of status register
            RC_POLL_LOCK: begin
                m_axil_araddr  <= ADDR_STATUS;
                m_axil_arvalid <= 1;
                m_axil_rready  <= 1;
                if (m_axil_arready) begin
                    m_axil_arvalid <= 0;
                    rc_state       <= RC_RD_WAIT;
                end
            end

            RC_RD_WAIT: begin
                if (m_axil_rvalid) begin
                    m_axil_rready <= 0;
                    rc_state      <= RC_CHECK_LOCK;
                end
            end

            RC_CHECK_LOCK: begin
                if (m_axil_rdata[0] == 1'b1)
                    rc_state <= RC_DONE;
                else
                    rc_state <= RC_POLL_LOCK; // not locked yet, keep polling
            end

            RC_DONE: begin
                reconfig_ready <= 1;
                rc_state       <= RC_IDLE;
            end

        endcase
    end
end

endmodule
