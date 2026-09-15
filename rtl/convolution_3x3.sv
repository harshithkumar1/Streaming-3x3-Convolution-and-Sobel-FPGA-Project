`timescale 1ns / 1ps
// Module: convolution_3x3
// Description: 3x3 convolution engine. Multiplies each of the 9 window pixels
//              by the corresponding kernel coefficient and sums the results.
//              Uses signed arithmetic to handle negative kernel coefficients.
//
// Bit-width analysis (for PIXEL_W=8, COEFF_W=12, signed):
//   Product: 8-bit unsigned pixel * 12-bit signed coeff = 20-bit signed
//   Sum of 9 products: 20 + ceil(log2(9)) = 20 + 4 = 24-bit signed
//   OUTPUT_W = PIXEL_W + COEFF_W + 4 = 24 bits
//
// Saturation policy:
//   If the result exceeds the OUTPUT_W range, it is saturated to the
//   maximum or minimum representable value.

module convolution_3x3 #(
    parameter PIXEL_W  = 8,          // Input pixel width (unsigned)
    parameter COEFF_W  = 12,         // Kernel coefficient width (signed)
    parameter OUTPUT_W = PIXEL_W + COEFF_W + 4  // Accumulator width (signed)
)(
    input  logic                        clk,
    input  logic                        rst,
    input  logic                        window_valid,
    // 3x3 window pixels
    input  logic [PIXEL_W-1:0]         p00, p01, p02,
    input  logic [PIXEL_W-1:0]         p10, p11, p12,
    input  logic [PIXEL_W-1:0]         p20, p21, p22,
    // Convolution result
    output logic signed [OUTPUT_W-1:0]  conv_out,
    output logic                        conv_valid
);

    // Kernel coefficients (signed, parameterized)
    // Default: box filter [1 1 1; 1 1 1; 1 1 1]
    parameter logic signed [COEFF_W-1:0] K00 = 1;
    parameter logic signed [COEFF_W-1:0] K01 = 1;
    parameter logic signed [COEFF_W-1:0] K02 = 1;
    parameter logic signed [COEFF_W-1:0] K10 = 1;
    parameter logic signed [COEFF_W-1:0] K11 = 1;
    parameter logic signed [COEFF_W-1:0] K12 = 1;
    parameter logic signed [COEFF_W-1:0] K20 = 1;
    parameter logic signed [COEFF_W-1:0] K21 = 1;
    parameter logic signed [COEFF_W-1:0] K22 = 1;

    // Pipeline stage 1: multiply
    logic signed [OUTPUT_W-1:0] prod00, prod01, prod02;
    logic signed [OUTPUT_W-1:0] prod10, prod11, prod12;
    logic signed [OUTPUT_W-1:0] prod20, prod21, prod22;
    logic valid_pipe1;

    // Pipeline stage 2: adder tree
    logic signed [OUTPUT_W-1:0] sum_row0, sum_row1, sum_row2;
    logic valid_pipe2;

    // Pipeline stage 3: final sum (output stage)
    logic signed [OUTPUT_W-1:0] sum_all;
    logic valid_pipe3;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            prod00 <= '0; prod01 <= '0; prod02 <= '0;
            prod10 <= '0; prod11 <= '0; prod12 <= '0;
            prod20 <= '0; prod21 <= '0; prod22 <= '0;
            valid_pipe1 <= 1'b0;
            sum_row0 <= '0; sum_row1 <= '0; sum_row2 <= '0;
            valid_pipe2 <= 1'b0;
            sum_all <= '0;
            valid_pipe3 <= 1'b0;
        end else begin
            // Stage 1: Multiply pixels by kernel coefficients
            prod00 <= $signed({1'b0, p00}) * K00;
            prod01 <= $signed({1'b0, p01}) * K01;
            prod02 <= $signed({1'b0, p02}) * K02;
            prod10 <= $signed({1'b0, p10}) * K10;
            prod11 <= $signed({1'b0, p11}) * K11;
            prod12 <= $signed({1'b0, p12}) * K12;
            prod20 <= $signed({1'b0, p20}) * K20;
            prod21 <= $signed({1'b0, p21}) * K21;
            prod22 <= $signed({1'b0, p22}) * K22;
            valid_pipe1 <= window_valid;

            // Stage 2: Adder tree (row sums)
            sum_row0 <= prod00 + prod01 + prod02;
            sum_row1 <= prod10 + prod11 + prod12;
            sum_row2 <= prod20 + prod21 + prod22;
            valid_pipe2 <= valid_pipe1;

            // Stage 3: Final sum and output
            sum_all <= sum_row0 + sum_row1 + sum_row2;
            valid_pipe3 <= valid_pipe2;
        end
    end

    assign conv_out = sum_all;
    assign conv_valid = valid_pipe3;

endmodule
