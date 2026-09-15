`timescale 1ns / 1ps
// Module: streaming_sobel_top
// Description: Top-level streaming Sobel edge detection processor.

module streaming_sobel_top #(
    parameter IMAGE_WIDTH  = 640,
    parameter IMAGE_HEIGHT = 480,
    parameter PIXEL_W      = 8,
    parameter COEFF_W      = 12,
    parameter THRESHOLD    = 128
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  pixel_valid,
    input  logic [PIXEL_W-1:0]   pixel_in,
    output logic [PIXEL_W-1:0]   pixel_out,
    output logic                  pixel_valid_out
);

    logic [PIXEL_W-1:0] lb0_out, lb1_out;
    logic [PIXEL_W-1:0] sr_p00, sr_p01, sr_p02;
    logic [PIXEL_W-1:0] sr_p10, sr_p11, sr_p12;
    logic [PIXEL_W-1:0] sr_p20, sr_p21, sr_p22;
    logic [PIXEL_W-1:0] win_p00, win_p01, win_p02;
    logic [PIXEL_W-1:0] win_p10, win_p11, win_p12;
    logic [PIXEL_W-1:0] win_p20, win_p21, win_p22;
    logic window_valid;
    logic [PIXEL_W-1:0] edge_result;
    logic edge_valid;
    logic edge_valid_raw;

    // Pipeline fill counter (same as streaming_conv_top)
    localparam PIPELINE_FILL = 2 * IMAGE_WIDTH + 3;
    localparam CNT_W = $clog2(PIPELINE_FILL + 1);
    logic [CNT_W-1:0] fill_cnt;
    logic             fill_done;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fill_cnt  <= '0;
            fill_done <= 1'b0;
        end else if (pixel_valid && !fill_done) begin
            fill_cnt <= fill_cnt + 1'b1;
            if (fill_cnt == PIPELINE_FILL - 1)
                fill_done <= 1'b1;
        end else if (!pixel_valid) begin
            fill_cnt  <= '0;
            fill_done <= 1'b0;
        end
    end

    // Output column counter (same as streaming_conv_top)
    localparam COL_CNT_W = $clog2(IMAGE_WIDTH);
    logic [COL_CNT_W-1:0] out_col_cnt;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            out_col_cnt <= '0;
        else if (!pixel_valid)
            out_col_cnt <= '0;
        else if (edge_valid_raw) begin
            if (out_col_cnt == IMAGE_WIDTH - 1)
                out_col_cnt <= '0;
            else
                out_col_cnt <= out_col_cnt + 1'b1;
        end
    end

    logic window_col_valid;
    assign window_col_valid = (out_col_cnt < IMAGE_WIDTH - 2);

    assign pixel_out = edge_result;
    assign pixel_valid_out = edge_valid_raw & window_col_valid;

    line_buffer #(.WIDTH(IMAGE_WIDTH), .PIXEL_W(PIXEL_W)) u_line_buffer_0 (
        .clk(clk), .rst(rst), .pixel_valid(pixel_valid),
        .pixel_in(pixel_in), .pixel_out(lb0_out)
    );

    line_buffer #(.WIDTH(IMAGE_WIDTH), .PIXEL_W(PIXEL_W)) u_line_buffer_1 (
        .clk(clk), .rst(rst), .pixel_valid(pixel_valid),
        .pixel_in(lb0_out), .pixel_out(lb1_out)
    );

    shift_registers #(.PIXEL_W(PIXEL_W)) u_shift_registers (
        .clk(clk), .rst(rst), .pixel_valid(pixel_valid),
        .pixel_row0(pixel_in), .pixel_row1(lb0_out), .pixel_row2(lb1_out),
        .p00(sr_p00), .p01(sr_p01), .p02(sr_p02),
        .p10(sr_p10), .p11(sr_p11), .p12(sr_p12),
        .p20(sr_p20), .p21(sr_p21), .p22(sr_p22)
    );

    window_3x3 #(.PIXEL_W(PIXEL_W)) u_window_3x3 (
        .clk(clk), .rst(rst), .pixel_valid(pixel_valid & fill_done),
        .p00_in(sr_p00), .p01_in(sr_p01), .p02_in(sr_p02),
        .p10_in(sr_p10), .p11_in(sr_p11), .p12_in(sr_p12),
        .p20_in(sr_p20), .p21_in(sr_p21), .p22_in(sr_p22),
        .p00(win_p00), .p01(win_p01), .p02(win_p02),
        .p10(win_p10), .p11(win_p11), .p12(win_p12),
        .p20(win_p20), .p21(win_p21), .p22(win_p22),
        .window_valid(window_valid)
    );

    sobel_edge_detect #(
        .PIXEL_W(PIXEL_W), .COEFF_W(COEFF_W), .THRESHOLD(THRESHOLD)
    ) u_sobel_edge_detect (
        .clk(clk), .rst(rst), .window_valid(window_valid),
        .p00(win_p00), .p01(win_p01), .p02(win_p02),
        .p10(win_p10), .p11(win_p11), .p12(win_p12),
        .p20(win_p20), .p21(win_p21), .p22(win_p22),
        .edge_out(edge_result), .edge_valid(edge_valid_raw)
    );

endmodule
