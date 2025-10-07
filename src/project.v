module tt_um_ms_pw (
    input  wire        clk,        // Clock
    input  wire        res_ni,       // Active-low reset
    input  wire [7:0]  set_thres_i,  // Asynchronous Set threshold (sampled/synced)
    input  wire [7:0]  clr_thres_i,  // Asynchronous Clear threshold (sampled/synced)
    input  wire [7:0]  reload_i,     // Asynchronous Reload value (sampled/synced)
    output reg         pwm_o         // PWM output
); 

    // Counter
    reg [7:0] cnt;

    // "Synchronized" copies (single register stage as in your VHDL)
    reg [7:0] set_thres_sync;
    reg [7:0] clr_thres_sync;
    reg [7:0] reload_sync;

    // ------------------------------------------------------------
    // Synchronize inputs to clk_i domain (single-stage, like VHDL)
    // ------------------------------------------------------------
    always @(posedge clk or negedge res_ni) begin
        if (!res_ni) begin
            set_thres_sync <= 8'd0;
            clr_thres_sync <= 8'd0;
            reload_sync    <= 8'd0;
        end else begin
            set_thres_sync <= set_thres_i;
            clr_thres_sync <= clr_thres_i;
            reload_sync    <= reload_i;
        end
    end

    // ------------------------------------------------------------
    // 8-bit counter with synchronous reload to 0
    // ------------------------------------------------------------
    always @(posedge clk or negedge res_ni) begin
        if (!res_ni) begin
            cnt <= 8'd0;
        end else begin
            if (cnt == reload_sync)
                cnt <= 8'd0;        // Reload to 0 when threshold met
            else
                cnt <= cnt + 8'd1;  // Increment
        end
    end

    // ------------------------------------------------------------
    // PWM set/clear with clear priority (matches VHDL ordering)
    // ------------------------------------------------------------
    always @(posedge clk or negedge res_ni) begin
        if (!res_ni) begin
            pwm_o <= 1'b0;
        end else begin
            if (cnt == clr_thres_sync)
                pwm_o <= 1'b0;      // Clear wins if both equal
            else if (cnt == set_thres_sync)
                pwm_o <= 1'b1;      // Set when counter hits set threshold
            // else: hold previous value
        end
    end

endmodule
