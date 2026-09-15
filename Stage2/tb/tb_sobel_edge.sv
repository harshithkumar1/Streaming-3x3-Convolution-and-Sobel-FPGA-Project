`timescale 1ns / 1ps
// =============================================================================
// Testbench: tb_sobel_edge
// Description: Self-checking testbench for streaming_sobel_top.
//              Tests vertical edges, horizontal edges, squares, checkerboards,
//              and random images against golden Sobel reference.
//
// Golden reference: magnitude = |Gx| + |Gy|, edge = (magnitude >= THRESHOLD) ? 255 : 0
// Sobel Gx: [-1 0 1; -2 0 2; -1 0 1]
// Sobel Gy: [-1 -2 -1; 0 0 0; 1 2 1]
// =============================================================================

module tb_sobel_edge;

    // =========================================================================
    // Parameters
    // =========================================================================
    parameter PIXEL_W      = 8;
    parameter COEFF_W      = 12;
    parameter THRESHOLD    = 128;
    parameter CLK_PERIOD   = 10;

    parameter IMAGE_WIDTH  = 64;
    parameter IMAGE_HEIGHT = 64;

    // =========================================================================
    // DUT signals
    // =========================================================================
    logic                  clk;
    logic                  rst;
    logic                  pixel_valid;
    logic [PIXEL_W-1:0]   pixel_in;
    logic [PIXEL_W-1:0]   pixel_out;
    logic                  pixel_valid_out;

    // =========================================================================
    // Testbench state
    // =========================================================================
    integer total_errors;
    integer total_output_pixels;
    integer total_input_pixels;
    integer first_error_row;
    integer first_error_col;
    logic   first_error_found;

    logic [PIXEL_W-1:0] test_image [0:2047][0:2047];

    // =========================================================================
    // File output for MATLAB visualization
    // =========================================================================
    integer output_file;

    // =========================================================================
    // Clock generation
    // =========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    streaming_sobel_top #(
        .IMAGE_WIDTH  (IMAGE_WIDTH),
        .IMAGE_HEIGHT (IMAGE_HEIGHT),
        .PIXEL_W      (PIXEL_W),
        .COEFF_W      (COEFF_W),
        .THRESHOLD    (THRESHOLD)
    ) dut (
        .clk            (clk),
        .rst            (rst),
        .pixel_valid    (pixel_valid),
        .pixel_in       (pixel_in),
        .pixel_out      (pixel_out),
        .pixel_valid_out(pixel_valid_out)
    );

    // =========================================================================
    // Task: reset_dut
    // =========================================================================
    task reset_dut;
        begin
            rst = 1;
            pixel_valid = 0;
            pixel_in = 0;
            repeat (5) @(posedge clk);
            rst = 0;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: feed_image
    // =========================================================================
    task feed_image;
        input integer width;
        input integer height;
        integer r, c;
        begin
            total_input_pixels = 0;
            for (r = 0; r < height; r = r + 1) begin
                for (c = 0; c < width; c = c + 1) begin
                    @(posedge clk);
                    pixel_valid = 1;
                    pixel_in = test_image[r][c];
                    total_input_pixels = total_input_pixels + 1;
                end
            end
            @(posedge clk);
            pixel_valid = 0;
            pixel_in = 0;
        end
    endtask

    // =========================================================================
    // Task: compute_sobel_gx
    //   Returns Gx for a 3x3 window (signed)
    // =========================================================================
    function integer compute_sobel_gx;
        input integer r, c;
        integer sum;
        begin
            sum = -1*test_image[r][c]   + 0*test_image[r][c+1]   + 1*test_image[r][c+2]
                + -2*test_image[r+1][c] + 0*test_image[r+1][c+1] + 2*test_image[r+1][c+2]
                + -1*test_image[r+2][c] + 0*test_image[r+2][c+1] + 1*test_image[r+2][c+2];
            compute_sobel_gx = sum;
        end
    endfunction

    // =========================================================================
    // Task: compute_sobel_gy
    //   Returns Gy for a 3x3 window (signed)
    // =========================================================================
    function integer compute_sobel_gy;
        input integer r, c;
        integer sum;
        begin
            sum = -1*test_image[r][c]   + -2*test_image[r][c+1]   + -1*test_image[r][c+2]
                +  0*test_image[r+1][c] +  0*test_image[r+1][c+1] +  0*test_image[r+1][c+2]
                +  1*test_image[r+2][c] +  2*test_image[r+2][c+1] +  1*test_image[r+2][c+2];
            compute_sobel_gy = sum;
        end
    endfunction

    // =========================================================================
    // Task: check_output
    // =========================================================================
    task check_output;
        input integer out_row;
        input integer out_col;
        input integer width;
        input integer height;
        integer gx, gy, mag, expected;
        begin
            gx = compute_sobel_gx(out_row, out_col);
            gy = compute_sobel_gy(out_row, out_col);
            mag = (gx < 0 ? -gx : gx) + (gy < 0 ? -gy : gy);
            expected = (mag >= THRESHOLD) ? 255 : 0;

            if (pixel_valid_out) begin
                // Write pixel to file for MATLAB visualization
                $fwrite(output_file, "%02x\n", pixel_out);

                if (pixel_out !== expected[PIXEL_W-1:0]) begin
                    total_errors = total_errors + 1;
                    if (!first_error_found) begin
                        first_error_row = out_row;
                        first_error_col = out_col;
                        first_error_found = 1;
                        $display("FIRST MISMATCH at output(%0d,%0d): expected=%0d, got=%0d",
                                 out_row, out_col, expected, pixel_out);
                        $display("  Gx=%0d, Gy=%0d, magnitude=%0d", gx, gy, mag);
                        $display("  Window: [%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
                            test_image[out_row][out_col], test_image[out_row][out_col+1], test_image[out_row][out_col+2],
                            test_image[out_row+1][out_col], test_image[out_row+1][out_col+1], test_image[out_row+1][out_col+2],
                            test_image[out_row+2][out_col], test_image[out_row+2][out_col+1], test_image[out_row+2][out_col+2]);
                    end
                end
                total_output_pixels = total_output_pixels + 1;
            end
        end
    endtask

    // =========================================================================
    // Task: run_sobel_test
    // =========================================================================
    task run_sobel_test;
        input integer width;
        input integer height;
        input [255:0] test_name;
        integer out_row, out_col;
        integer out_width, out_height;
        integer latency_cycles;
        begin
            $display("\n========================================");
            $display("  SOBEL TEST: %0s  (%0d x %0d)", test_name, width, height);
            $display("========================================");

            reset_dut;
            total_errors = 0;
            total_output_pixels = 0;
            first_error_found = 0;
            first_error_row = 0;
            first_error_col = 0;

            out_width = width - 2;
            out_height = height - 2;
            latency_cycles = 2 * width + 4;

            fork
                begin
                    feed_image(width, height);
                end
                begin
                    while (!pixel_valid_out) @(posedge clk);
                    for (out_row = 0; out_row < out_height; out_row = out_row + 1) begin
                        for (out_col = 0; out_col < out_width; out_col = out_col + 1) begin
                            while (!pixel_valid_out) @(posedge clk);
                            check_output(out_row, out_col, width, height);
                            @(posedge clk);
                        end
                    end
                    repeat (5) @(posedge clk);
                end
            join

            $display("  Input pixels: %0d", total_input_pixels);
            $display("  Output pixels checked: %0d", total_output_pixels);
            $display("  Expected output pixels: %0d", out_width * out_height);
            $display("  Mismatches: %0d", total_errors);
            if (first_error_found)
                $display("  First mismatch at: (%0d, %0d)", first_error_row, first_error_col);

            if (total_errors == 0 && total_output_pixels == out_width * out_height)
                $display("  >>> RESULT: PASS <<<");
            else
                $display("  >>> RESULT: FAIL <<<");
        end
    endtask

    // =========================================================================
    // Test image generation tasks
    // =========================================================================

    // TEST 1: Vertical edge (left half 0, right half 255)
    task gen_vertical_edge;
        input integer width;
        input integer height;
        integer r, c;
        begin
            for (r = 0; r < height; r = r + 1)
                for (c = 0; c < width; c = c + 1)
                    test_image[r][c] = (c < width/2) ? 8'd0 : 8'd255;
        end
    endtask

    // TEST 2: Horizontal edge (top half 0, bottom half 255)
    task gen_horizontal_edge;
        input integer width;
        input integer height;
        integer r, c;
        begin
            for (r = 0; r < height; r = r + 1)
                for (c = 0; c < width; c = c + 1)
                    test_image[r][c] = (r < height/2) ? 8'd0 : 8'd255;
        end
    endtask

    // TEST 3: Square (center square = 255, background = 0)
    task gen_square;
        input integer width;
        input integer height;
        integer r, c;
        integer sq_left, sq_right, sq_top, sq_bottom;
        begin
            sq_left   = width / 4;
            sq_right  = 3 * width / 4;
            sq_top    = height / 4;
            sq_bottom = 3 * height / 4;
            for (r = 0; r < height; r = r + 1)
                for (c = 0; c < width; c = c + 1) begin
                    if (r >= sq_top && r < sq_bottom && c >= sq_left && c < sq_right)
                        test_image[r][c] = 8'd255;
                    else
                        test_image[r][c] = 8'd0;
                end
        end
    endtask

    // TEST 4: Checkerboard
    task gen_checkerboard;
        input integer width;
        input integer height;
        integer r, c;
        begin
            for (r = 0; r < height; r = r + 1)
                for (c = 0; c < width; c = c + 1)
                    test_image[r][c] = ((r + c) % 2 == 0) ? 8'd255 : 8'd0;
        end
    endtask

    // TEST 5: Random image (deterministic LFSR)
    task gen_random_image;
        input integer width;
        input integer height;
        integer r, c;
        logic [15:0] lfsr;
        begin
            lfsr = 16'hBEEF;
            for (r = 0; r < height; r = r + 1) begin
                for (c = 0; c < width; c = c + 1) begin
                    test_image[r][c] = lfsr[7:0];
                    lfsr = {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
                end
            end
        end
    endtask

    // =========================================================================
    // Main test sequence
    // =========================================================================
    initial begin
        $dumpfile("tb_sobel_edge.vcd");
        $dumpvars(0, tb_sobel_edge);

        // Open file for MATLAB visualization
        output_file = $fopen("vivado_edge_output.hex", "w");
        if (output_file == 0) begin
            $display("ERROR: Could not open output file!");
            $finish;
        end

        // =====================================================================
        // TEST 1: 64x64 vertical edge
        // =====================================================================
        gen_vertical_edge(IMAGE_WIDTH, IMAGE_HEIGHT);
        run_sobel_test(IMAGE_WIDTH, IMAGE_HEIGHT, "64x64 Vertical Edge");

        // =====================================================================
        // TEST 2: 64x64 horizontal edge
        // =====================================================================
        gen_horizontal_edge(IMAGE_WIDTH, IMAGE_HEIGHT);
        run_sobel_test(IMAGE_WIDTH, IMAGE_HEIGHT, "64x64 Horizontal Edge");

        // =====================================================================
        // TEST 3: 64x64 square
        // =====================================================================
        gen_square(IMAGE_WIDTH, IMAGE_HEIGHT);
        run_sobel_test(IMAGE_WIDTH, IMAGE_HEIGHT, "64x64 Square");

        // =====================================================================
        // TEST 4: 64x64 checkerboard
        // =====================================================================
        gen_checkerboard(IMAGE_WIDTH, IMAGE_HEIGHT);
        run_sobel_test(IMAGE_WIDTH, IMAGE_HEIGHT, "64x64 Checkerboard");

        // =====================================================================
        // TEST 5: 64x64 random
        // =====================================================================
        gen_random_image(IMAGE_WIDTH, IMAGE_HEIGHT);
        run_sobel_test(IMAGE_WIDTH, IMAGE_HEIGHT, "64x64 Random (seed=0xBEEF)");

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n========================================");
        $display("  ALL STAGE 2 (SOBEL) TESTS COMPLETE");
        $display("========================================");

        // Close output file for MATLAB
        $fclose(output_file);
        $display("  Output saved to: vivado_edge_output.hex");

        #(CLK_PERIOD * 10);
        $finish;
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 10000000);
        $display("ERROR: Simulation timed out!");
        $finish;
    end

endmodule
