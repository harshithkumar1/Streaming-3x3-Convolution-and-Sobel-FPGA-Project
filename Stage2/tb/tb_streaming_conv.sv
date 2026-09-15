`timescale 1ns / 1ps
// =============================================================================
// Testbench: tb_streaming_conv
// Description: Self-checking testbench for streaming_conv_top.
//              Generates deterministic test images, feeds pixels one-per-clock,
//              computes golden convolution results, and compares against DUT.
//
// Pipeline timing:
//   - Line buffers: each delays WIDTH clocks effectively (DEPTH=WIDTH, combinational read)
//   - Shift registers: +2 clocks horizontal, window_3x3 register: +1 clock
//   - Total startup latency: 2*WIDTH + 3 clocks (PIPELINE_FILL)
//   - Convolution pipeline: +3 clocks (multiply, row-add, total-add)
//   - Total to first conv_valid: 2*WIDTH + 6 clocks
//   - First valid output at input position (0, 0)
//   - Valid output region: (WIDTH-2) x (HEIGHT-2) pixels
//
// Test images (all 64x64 to match DUT parameters):
//   1. 64x64 constant image (all pixels = 100)
//   2. 64x64 gradient image
//   3. 64x64 checkerboard image
//   4. 64x64 random-seeded image
// =============================================================================

module tb_streaming_conv;

    // =========================================================================
    // Parameters
    // =========================================================================
    parameter PIXEL_W      = 8;
    parameter COEFF_W      = 12;
    parameter CLK_PERIOD   = 10;  // 100 MHz clock

    // Test image dimensions (fixed for DUT elaboration parameters)
    parameter IMAGE_WIDTH = 64;
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
    integer test_num;
    integer pixel_count;       // Count of pixels fed to DUT
    integer output_count;      // Count of valid outputs received

    // Store full image for golden reference computation
    logic [PIXEL_W-1:0] test_image [0:2047][0:2047];  // Max 2048x2048

    // =========================================================================
    // Clock generation
    // =========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // DUT instantiation
    // =========================================================================
    streaming_conv_top #(
        .IMAGE_WIDTH  (IMAGE_WIDTH),
        .IMAGE_HEIGHT (IMAGE_HEIGHT),
        .PIXEL_W      (PIXEL_W),
        .COEFF_W      (COEFF_W)
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
    //   Applies synchronous reset for 5 clock cycles
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
    //   Sends all pixels of the test image one-per-clock
    //   Stores pixels in test_image array for golden reference
    // =========================================================================
    task feed_image;
        input integer width;
        input integer height;
        integer r, c;
        begin
            pixel_count = 0;
            for (r = 0; r < height; r = r + 1) begin
                for (c = 0; c < width; c = c + 1) begin
                    @(posedge clk);
                    pixel_valid = 1;
                    pixel_in = test_image[r][c];
                    pixel_count = pixel_count + 1;
                end
            end
            // Deassert pixel_valid after last pixel
            @(posedge clk);
            pixel_valid = 0;
            pixel_in = 0;
        end
    endtask

    // =========================================================================
    // Task: check_output
    //   Compares DUT output against golden convolution result
    //   Golden: box filter [1 1 1; 1 1 1; 1 1 1] with saturation to [0,255]
    //   Output (or, oc) corresponds to input window (or, oc) to (or+2, oc+2)
    // =========================================================================
    task check_output;
        input integer out_row;
        input integer out_col;
        input integer width;
        input integer height;
        integer wr, wc;
        integer golden_sum;
        integer golden_clipped;
        begin
            // Compute golden convolution result (box filter: sum of 9 pixels)
            golden_sum = 0;
            for (wr = 0; wr < 3; wr = wr + 1) begin
                for (wc = 0; wc < 3; wc = wc + 1) begin
                    golden_sum = golden_sum + test_image[out_row + wr][out_col + wc];
                end
            end
            // Clip to [0, 255] for box filter (all positive coefficients)
            if (golden_sum > 255)
                golden_clipped = 255;
            else if (golden_sum < 0)
                golden_clipped = 0;
            else
                golden_clipped = golden_sum;

            // Compare with DUT output
            if (pixel_valid_out) begin
                if (pixel_out !== golden_clipped[PIXEL_W-1:0]) begin
                    if (total_errors < 10) begin
                        $display("MISMATCH at output(%0d,%0d): expected=%0d, got=%0d",
                                 out_row, out_col, golden_clipped, pixel_out);
                        $display("  Window pixels: [%0d %0d %0d; %0d %0d %0d; %0d %0d %0d]",
                            test_image[out_row][out_col], test_image[out_row][out_col+1], test_image[out_row][out_col+2],
                            test_image[out_row+1][out_col], test_image[out_row+1][out_col+1], test_image[out_row+1][out_col+2],
                            test_image[out_row+2][out_col], test_image[out_row+2][out_col+1], test_image[out_row+2][out_col+2]);
                        $display("  Golden sum = %0d", golden_sum);
                    end
                    total_errors = total_errors + 1;
                end
                total_output_pixels = total_output_pixels + 1;
            end
        end
    endtask

    // =========================================================================
    // Task: run_conv_test
    //   Feeds image, waits for pipeline latency, checks all outputs
    // =========================================================================
    task run_conv_test;
        input integer width;
        input integer height;
        input [255:0] test_name;  // Fixed-width string for port compatibility
        integer out_row, out_col;
        integer out_width, out_height;
        integer latency_cycles;
        integer i;
        begin
            $display("\n========================================");
            $display("  TEST: %0s  (%0d x %0d)", test_name, width, height);
            $display("========================================");

            // Reset DUT
            reset_dut;

            // Reset counters
            total_errors = 0;
            total_output_pixels = 0;

            // Feed image
            feed_image(width, height);

            // Wait for pipeline to produce all outputs
            // Startup latency: 2*WIDTH + 6 clocks
            // Then (WIDTH-2)*(HEIGHT-2) output clocks
            out_width = width - 2;
            out_height = height - 2;
            latency_cycles = 2 * width + 4;
            // Total clocks after feed: latency + all outputs + some margin
            repeat (latency_cycles + out_width * out_height + 10) @(posedge clk);

            // Now verify: re-run with output checking
            // Reset and re-feed to check outputs precisely
            reset_dut;
            total_errors = 0;
            total_output_pixels = 0;

            // Fork: feed pixels in one process, check outputs in another
            fork
                // Process 1: Feed image
                begin
                    feed_image(width, height);
                end

                // Process 2: Wait for first output, then check each output
                begin
                    // Wait for first valid output (pixel_valid_out goes high)
                    while (!pixel_valid_out) @(posedge clk);

                    // Check all valid outputs
                    for (out_row = 0; out_row < out_height; out_row = out_row + 1) begin
                        for (out_col = 0; out_col < out_width; out_col = out_col + 1) begin
                            while (!pixel_valid_out) @(posedge clk);
                            check_output(out_row, out_col, width, height);
                            @(posedge clk);
                        end
                    end
                    // Extra clocks for pipeline drain
                    repeat (5) @(posedge clk);
                end
            join

            // Report results
            $display("  Output pixels checked: %0d", total_output_pixels);
            $display("  Expected output pixels: %0d", out_width * out_height);
            if (total_errors == 0 && total_output_pixels == out_width * out_height)
                $display("  >>> RESULT: PASS <<<");
            else if (total_errors == 0 && total_output_pixels != out_width * out_height)
                $display("  >>> RESULT: FAIL (output count mismatch: got %0d, expected %0d) <<<",
                         total_output_pixels, out_width * out_height);
            else
                $display("  >>> RESULT: FAIL (%0d mismatches) <<<", total_errors);
        end
    endtask

    // =========================================================================
    // Test image generation tasks
    // =========================================================================

    // TEST 1: 8x8 constant image (all pixels = 100)
    task gen_constant_image;
        input integer width;
        input integer height;
        integer r, c;
        begin
            for (r = 0; r < height; r = r + 1)
                for (c = 0; c < width; c = c + 1)
                    test_image[r][c] = 8'd100;
        end
    endtask

    // TEST 2: 8x8 gradient image (row*16 + col)
    task gen_gradient_image;
        input integer width;
        input integer height;
        integer r, c;
        begin
            for (r = 0; r < height; r = r + 1)
                for (c = 0; c < width; c = c + 1) begin
                    // Use modulo 256 to keep in 8-bit range
                    test_image[r][c] = ((r * 16 + c) % 256);
                end
        end
    endtask

    // TEST 3: 16x16 checkerboard (alternating 0 and 255)
    task gen_checkerboard_image;
        input integer width;
        input integer height;
        integer r, c;
        begin
            for (r = 0; r < height; r = r + 1)
                for (c = 0; c < width; c = c + 1)
                    test_image[r][c] = ((r + c) % 2 == 0) ? 8'd255 : 8'd0;
        end
    endtask

    // TEST 4: NxN pseudo-random image using LFSR
    task gen_random_image;
        input integer width;
        input integer height;
        integer r, c;
        logic [15:0] lfsr;
        begin
            lfsr = 16'hACE1;  // Fixed seed for reproducibility
            for (r = 0; r < height; r = r + 1) begin
                for (c = 0; c < width; c = c + 1) begin
                    test_image[r][c] = lfsr[7:0];
                    // LFSR feedback: x^16 + x^14 + x^13 + x^11 + 1
                    lfsr = {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
                end
            end
        end
    endtask

    // =========================================================================
    // Main test sequence
    // =========================================================================
    initial begin
        // Optional: dump waveforms
        $dumpfile("tb_streaming_conv.vcd");
        $dumpvars(0, tb_streaming_conv);

        total_errors = 0;
        total_output_pixels = 0;

        // =====================================================================
        // TEST 1: 64x64 constant image
        // Expected: all outputs = min(9*100, 255) = 255
        // =====================================================================
        gen_constant_image(64, 64);
        run_conv_test(64, 64, "64x64 Constant (all 100)");

        // =====================================================================
        // TEST 2: 64x64 gradient image
        // =====================================================================
        gen_gradient_image(64, 64);
        run_conv_test(64, 64, "64x64 Gradient");

        // =====================================================================
        // TEST 3: 64x64 checkerboard
        // =====================================================================
        gen_checkerboard_image(64, 64);
        run_conv_test(64, 64, "64x64 Checkerboard");

        // =====================================================================
        // TEST 4: 64x64 pseudo-random image
        // =====================================================================
        gen_random_image(64, 64);
        run_conv_test(64, 64, "64x64 Random (seed=0xACE1)");

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n========================================");
        $display("  ALL STAGE 1 TESTS COMPLETE");
        $display("========================================");

        #(CLK_PERIOD * 10);
        $finish;
    end

    // =========================================================================
    // Timeout watchdog
    // =========================================================================
    initial begin
        #(CLK_PERIOD * 5000000);  // 5M clock cycle timeout
        $display("ERROR: Simulation timed out!");
        $finish;
    end

endmodule
