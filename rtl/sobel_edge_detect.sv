`timescale 1ns / 1ps
// Module: sobel_edge_detect
// Description: Sobel edge detection using 3x3 window. Computes Gx, Gy,
//   magnitude = |Gx| + |Gy|, and thresholds to produce binary edge map.

module sobel_edge_detect #(
    parameter PIXEL_W   = 8,
    parameter COEFF_W   = 12,
    parameter THRESHOLD = 128
)(
    input  logic                        clk,
    input  logic                        rst,
    input  logic                        window_valid,
    input  logic [PIXEL_W-1:0]         p00, p01, p02,
    input  logic [PIXEL_W-1:0]         p10, p11, p12,
    input  logic [PIXEL_W-1:0]         p20, p21, p22,
    output logic [PIXEL_W-1:0]         edge_out,
    output logic                        edge_valid
);

    localparam SUM_W = PIXEL_W + COEFF_W + 5;
    localparam MAG_W = SUM_W + 1;

    // Gx kernel: [-1 0 1; -2 0 2; -1 0 1]
    logic signed [COEFF_W-1:0] GX_K00 = -1, GX_K01 = 0, GX_K02 = 1;
    logic signed [COEFF_W-1:0] GX_K10 = -2, GX_K11 = 0, GX_K12 = 2;
    logic signed [COEFF_W-1:0] GX_K20 = -1, GX_K21 = 0, GX_K22 = 1;

    // Gy kernel: [-1 -2 -1; 0 0 0; 1 2 1]
    logic signed [COEFF_W-1:0] GY_K00 = -1, GY_K01 = -2, GY_K02 = -1;
    logic signed [COEFF_W-1:0] GY_K10 = 0,  GY_K11 = 0,  GY_K12 = 0;
    logic signed [COEFF_W-1:0] GY_K20 = 1,  GY_K21 = 2,  GY_K22 = 1;

    logic signed [SUM_W-1:0] gx_prod00, gx_prod01, gx_prod02;
    logic signed [SUM_W-1:0] gx_prod10, gx_prod11, gx_prod12;
    logic signed [SUM_W-1:0] gx_prod20, gx_prod21, gx_prod22;
    logic signed [SUM_W-1:0] gy_prod00, gy_prod01, gy_prod02;
    logic signed [SUM_W-1:0] gy_prod10, gy_prod11, gy_prod12;
    logic signed [SUM_W-1:0] gy_prod20, gy_prod21, gy_prod22;
    logic valid_pipe1;

    logic signed [SUM_W-1:0] gx_row0, gx_row1, gx_row2;
    logic signed [SUM_W-1:0] gy_row0, gy_row1, gy_row2;
    logic valid_pipe2;

    logic signed [SUM_W-1:0] gx_total, gy_total;
    logic valid_pipe3;

    logic [MAG_W-1:0] abs_gx, abs_gy, magnitude;
    logic valid_pipe4;

    logic [PIXEL_W-1:0] edge_result;
    logic valid_pipe5;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            gx_prod00 <= '0; gx_prod01 <= '0; gx_prod02 <= '0;
            gx_prod10 <= '0; gx_prod11 <= '0; gx_prod12 <= '0;
            gx_prod20 <= '0; gx_prod21 <= '0; gx_prod22 <= '0;
            gy_prod00 <= '0; gy_prod01 <= '0; gy_prod02 <= '0;
            gy_prod10 <= '0; gy_prod11 <= '0; gy_prod12 <= '0;
            gy_prod20 <= '0; gy_prod21 <= '0; gy_prod22 <= '0;
            valid_pipe1 <= 1'b0;
            gx_row0 <= '0; gx_row1 <= '0; gx_row2 <= '0;
            gy_row0 <= '0; gy_row1 <= '0; gy_row2 <= '0;
            valid_pipe2 <= 1'b0;
            gx_total <= '0; gy_total <= '0;
            valid_pipe3 <= 1'b0;
            abs_gx <= '0; abs_gy <= '0; magnitude <= '0;
            valid_pipe4 <= 1'b0;
            edge_result <= '0;
            valid_pipe5 <= 1'b0;
        end else begin
            gx_prod00 <= $signed({1'b0, p00}) * GX_K00;
            gx_prod01 <= $signed({1'b0, p01}) * GX_K01;
            gx_prod02 <= $signed({1'b0, p02}) * GX_K02;
            gx_prod10 <= $signed({1'b0, p10}) * GX_K10;
            gx_prod11 <= $signed({1'b0, p11}) * GX_K11;
            gx_prod12 <= $signed({1'b0, p12}) * GX_K12;
            gx_prod20 <= $signed({1'b0, p20}) * GX_K20;
            gx_prod21 <= $signed({1'b0, p21}) * GX_K21;
            gx_prod22 <= $signed({1'b0, p22}) * GX_K22;
            gy_prod00 <= $signed({1'b0, p00}) * GY_K00;
            gy_prod01 <= $signed({1'b0, p01}) * GY_K01;
            gy_prod02 <= $signed({1'b0, p02}) * GY_K02;
            gy_prod10 <= $signed({1'b0, p10}) * GY_K10;
            gy_prod11 <= $signed({1'b0, p11}) * GY_K11;
            gy_prod12 <= $signed({1'b0, p12}) * GY_K12;
            gy_prod20 <= $signed({1'b0, p20}) * GY_K20;
            gy_prod21 <= $signed({1'b0, p21}) * GY_K21;
            gy_prod22 <= $signed({1'b0, p22}) * GY_K22;
            valid_pipe1 <= window_valid;

            gx_row0 <= gx_prod00 + gx_prod01 + gx_prod02;
            gx_row1 <= gx_prod10 + gx_prod11 + gx_prod12;
            gx_row2 <= gx_prod20 + gx_prod21 + gx_prod22;
            gy_row0 <= gy_prod00 + gy_prod01 + gy_prod02;
            gy_row1 <= gy_prod10 + gy_prod11 + gy_prod12;
            gy_row2 <= gy_prod20 + gy_prod21 + gy_prod22;
            valid_pipe2 <= valid_pipe1;

            gx_total <= gx_row0 + gx_row1 + gx_row2;
            gy_total <= gy_row0 + gy_row1 + gy_row2;
            valid_pipe3 <= valid_pipe2;

            abs_gx <= (gx_total < 0) ? -gx_total : gx_total;
            abs_gy <= (gy_total < 0) ? -gy_total : gy_total;
            valid_pipe4 <= valid_pipe3;

            magnitude <= abs_gx + abs_gy;
            valid_pipe5 <= valid_pipe4;

            edge_result <= (magnitude >= THRESHOLD) ? 8'd255 : 8'd0;
            edge_valid <= valid_pipe5;
        end
    end

    assign edge_out = edge_result;

endmodule
