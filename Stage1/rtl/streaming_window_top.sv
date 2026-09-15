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
    input  logic        pixel_valid_in,
    output logic [7:0]  p00, p01, p02,
    output logic [7:0]  p10, p11, p12,
    output logic [7:0]  p20, p21, p22,
    output logic        pixel_valid_out
);

    localparam PIPELINE_FILL = 2 * IMAGE_WIDTH + 3;

    logic [7:0] row0, row1;
    logic       row0_valid, row1_valid;

    line_buffer #(.WIDTH(IMAGE_WIDTH)) u_line_buffer_0 (
        .clk(clk), .rst(rst),
        .pixel_in(pixel_in), .pixel_valid_in(pixel_valid_in),
        .pixel_out(row0), .pixel_valid_out(row0_valid)
    );

    line_buffer #(.WIDTH(IMAGE_WIDTH)) u_line_buffer_1 (
        .clk(clk), .rst(rst),
        .pixel_in(row0), .pixel_valid_in(row0_valid),
        .pixel_out(row1), .pixel_valid_out(row1_valid)
    );

    shift_registers u_shift_registers (
        .clk(clk), .rst(rst),
        .pixel_in(pixel_in), .pixel_valid_in(pixel_valid_in),
        .row0(row0), .row0_valid(row0_valid),
        .row1(row1), .row1_valid(row1_valid),
        .sr0_out0(p00), .sr0_out1(p01), .sr0_out2(p02),
        .sr1_out0(p10), .sr1_out1(p11), .sr1_out2(p12),
        .sr2_out0(p20), .sr2_out1(p21), .sr2_out2(p22)
    );

    window_3x3 u_window_3x3 (
        .clk(clk), .rst(rst),
        .p00_in(p00), .p01_in(p01), .p02_in(p02),
        .p10_in(p10), .p11_in(p11), .p12_in(p12),
        .p20_in(p20), .p21_in(p21), .p22_in(p22),
        .pixel_valid_in(pixel_valid_in),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10), .p11(p11), .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .pixel_valid_out(pixel_valid_out)
    );

endmodule
