`timescale 1ns / 1ps
// Module: window_3x3
// Description: Captures 9 pixels from shift registers into a registered 3x3 window.

module window_3x3 #(
    parameter PIXEL_W = 8
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  pixel_valid,
    input  logic [PIXEL_W-1:0]   p00_in, p01_in, p02_in,
    input  logic [PIXEL_W-1:0]   p10_in, p11_in, p12_in,
    input  logic [PIXEL_W-1:0]   p20_in, p21_in, p22_in,
    output logic [PIXEL_W-1:0]   p00, p01, p02,
    output logic [PIXEL_W-1:0]   p10, p11, p12,
    output logic [PIXEL_W-1:0]   p20, p21, p22,
    output logic                  window_valid
);

    logic [PIXEL_W-1:0] win [0:8];
    logic valid_pipe;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 9; i = i + 1)
                win[i] <= {PIXEL_W{1'b0}};
            valid_pipe <= 1'b0;
        end else begin
            valid_pipe <= pixel_valid;
            if (pixel_valid) begin
                win[0] <= p00_in; win[1] <= p01_in; win[2] <= p02_in;
                win[3] <= p10_in; win[4] <= p11_in; win[5] <= p12_in;
                win[6] <= p20_in; win[7] <= p21_in; win[8] <= p22_in;
            end
        end
    end

    assign p00 = win[0]; assign p01 = win[1]; assign p02 = win[2];
    assign p10 = win[3]; assign p11 = win[4]; assign p12 = win[5];
    assign p20 = win[6]; assign p21 = win[7]; assign p22 = win[8];
    assign window_valid = valid_pipe;

endmodule
