`timescale 1ns / 1ps
// Module: line_buffer
// Description: Single-line buffer using a shift register of depth WIDTH.
//              Delays pixel_in by exactly WIDTH clock cycles when pixel_valid
//              is asserted. This creates the one-row delay needed for the
//              streaming 3x3 window architecture, ensuring that when pixel
//              (r, c) arrives, the line buffer outputs pixel (r-1, c).

module line_buffer #(
    parameter WIDTH     = 640,
    parameter PIXEL_W   = 8
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  pixel_valid,
    input  logic [PIXEL_W-1:0]   pixel_in,
    output logic [PIXEL_W-1:0]   pixel_out
);

    localparam DEPTH = WIDTH;

    logic [PIXEL_W-1:0] shift_reg [0:DEPTH-1];
    integer i;

    assign pixel_out = shift_reg[0];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                shift_reg[i] <= {PIXEL_W{1'b0}};
        end else if (pixel_valid) begin
            for (i = 0; i < DEPTH - 1; i = i + 1)
                shift_reg[i] <= shift_reg[i + 1];
            shift_reg[DEPTH - 1] <= pixel_in;
        end
    end

endmodule
