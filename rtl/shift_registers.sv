`timescale 1ns / 1ps
// Module: shift_registers
// Description: Three 3-tap horizontal shift registers for the 3x3 window.

module shift_registers #(
    parameter PIXEL_W = 8
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  pixel_valid,
    input  logic [PIXEL_W-1:0]   pixel_row0,
    input  logic [PIXEL_W-1:0]   pixel_row1,
    input  logic [PIXEL_W-1:0]   pixel_row2,
    output logic [PIXEL_W-1:0]   p00, p01, p02,
    output logic [PIXEL_W-1:0]   p10, p11, p12,
    output logic [PIXEL_W-1:0]   p20, p21, p22
);

    logic [PIXEL_W-1:0] row0_shift [0:2];
    logic [PIXEL_W-1:0] row1_shift [0:2];
    logic [PIXEL_W-1:0] row2_shift [0:2];
    integer i;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 3; i = i + 1) begin
                row0_shift[i] <= {PIXEL_W{1'b0}};
                row1_shift[i] <= {PIXEL_W{1'b0}};
                row2_shift[i] <= {PIXEL_W{1'b0}};
            end
        end else if (pixel_valid) begin
            row0_shift[0] <= row0_shift[1];
            row0_shift[1] <= row0_shift[2];
            row0_shift[2] <= pixel_row0;
            row1_shift[0] <= row1_shift[1];
            row1_shift[1] <= row1_shift[2];
            row1_shift[2] <= pixel_row1;
            row2_shift[0] <= row2_shift[1];
            row2_shift[1] <= row2_shift[2];
            row2_shift[2] <= pixel_row2;
        end
    end

    assign p00 = row0_shift[0]; assign p01 = row0_shift[1]; assign p02 = row0_shift[2];
    assign p10 = row1_shift[0]; assign p11 = row1_shift[1]; assign p12 = row1_shift[2];
    assign p20 = row2_shift[0]; assign p21 = row2_shift[1]; assign p22 = row2_shift[2];

endmodule
