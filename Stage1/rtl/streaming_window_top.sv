// streaming_window_top.sv
// Stage 1: Streaming Window Generator (no math - just pixel delivery)
// Outputs the 3x3 window pixels for every valid input pixel

module streaming_window_top #(
    parameter IMAGE_WIDTH  = 64,
    parameter IMAGE_HEIGHT = 64
)(
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  pixel_in,
    input  logic        pixel_valid,
    output logic [7:0]  p00, p01, p02,
    output logic [7:0]  p10, p11, p12,
    output logic [7:0]  p20, p21, p22,
    output logic        window_valid
);

    logic [7:0] row0, row1;

    line_buffer #(.WIDTH(IMAGE_WIDTH)) u_line_buffer_0 (
        .clk(clk),
        .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .pixel_out(row0)
    );

    line_buffer #(.WIDTH(IMAGE_WIDTH)) u_line_buffer_1 (
        .clk(clk),
        .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_in(row0),
        .pixel_out(row1)
    );

    shift_registers u_shift_registers (
        .clk(clk),
        .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_row0(row0),
        .pixel_row1(row1),
        .pixel_row2(pixel_in),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22)
    );

    window_3x3 u_window_3x3 (
        .clk(clk),
        .rst(rst),
        .pixel_valid(pixel_valid),
        .p00_in(p00), .p01_in(p01), .p02_in(p02),
        .p10_in(p10), .p11_in(p11), .p12_in(p12),
        .p20_in(p20), .p21_in(p21), .p22_in(p22),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .window_valid(window_valid)
    );

endmodule
