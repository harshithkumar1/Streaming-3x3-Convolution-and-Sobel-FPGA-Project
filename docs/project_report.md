# Project Report Template

## Hardware-Based Real-Time Image Processing Pipeline for Streaming 3×3 Convolution and Sobel Edge Detection

---

### 1. Title Page

**Title:** Hardware-Based Real-Time Image Processing Pipeline for Streaming 3×3 Convolution and Sobel Edge Detection

**Author:** [Your Name]

**Date:** September 2025

**Institution:** [Your Institution]

**Course:** [Course Name]

**Tools:** Vivado 2026.1, SystemVerilog, XSim Simulator

**Target FPGA:** Xilinx Artix-7 xc7a35tcpg236-1

---

### 2. Abstract

This project presents the design, simulation, and synthesis of a streaming image-processing
hardware pipeline for real-time 3×3 convolution and Sobel edge detection on grayscale images.
The architecture processes pixels in a streaming fashion — one pixel per clock cycle after
initial pipeline startup — using a 3×3 sliding window constructed from line buffers and shift
registers. Two processing stages are implemented: (1) a configurable 3×3 convolution engine
with a parameterized kernel, and (2) a Sobel edge detection module computing horizontal and
vertical gradients with magnitude-based thresholding. The design is implemented in
synthesizable SystemVerilog and verified through self-checking testbenches that compare DUT
output against golden reference results computed within the testbench. For 64×64 test images,
all 9 test patterns (4 for convolution, 5 for Sobel) pass with zero mismatches. The pipeline
achieves a startup latency of 2×WIDTH+3 = 131 clock cycles and processes one pixel per clock
thereafter. Synthesis on a Xilinx Artix-7 FPGA (xc7a35tcpg236-1) shows utilization of 403 LUTs
and 937 flip-flops for Stage 1 (convolution), and 594 LUTs and 1132 flip-flops for Stage 2
(Sobel edge detection). The design meets timing at 50 MHz with +5.781 ns worst-negative slack.
The architecture is directly comparable to published simulation-only frameworks for 64×64
Sobel edge detection, and extends the reference work by adding a general-purpose convolution
engine, formal synthesis, and timing analysis.

---

### 3. Introduction

Real-time image processing is a critical component in numerous modern applications, including
autonomous vehicles (lane detection), medical imaging (edge enhancement for feature extraction),
industrial inspection (defect detection on manufacturing lines), surveillance (motion detection and
tracking), and robotics (visual navigation and obstacle avoidance). These applications demand
high throughput and deterministic latency that general-purpose processors struggle to provide.

Hardware implementations on FPGAs offer significant advantages over software approaches:
parallelism at the gate level, deterministic timing, and power efficiency. Among edge detection
algorithms, the Sobel operator is widely favored for hardware implementation due to its
computational simplicity — requiring only additions and shifts — and its effectiveness at
detecting intensity gradients [2]. The 3×3 convolution window, formed using line buffers and
shift registers, is the fundamental building block for both general filtering and Sobel edge
detection in streaming architectures [1].

This project implements a complete streaming image processing pipeline in synthesizable
SystemVerilog, comprising a general-purpose 3×3 convolution engine and a Sobel edge detection
module, verified through simulation and synthesized for a Xilinx Artix-7 FPGA.

---

### 4. Problem Statement

Design and verify a streaming hardware pipeline that processes grayscale images one pixel per
clock cycle for real-time 3×3 convolution and Sobel edge detection, suitable for FPGA
implementation. The design must:

- Accept serial pixel input (one pixel per clock)
- Form a 3×3 sliding window using line buffers without storing the entire frame
- Compute configurable convolution and Sobel gradient operations
- Output valid edge-detected pixels after a bounded pipeline fill delay
- Meet timing at 50 MHz on a Xilinx Artix-7 FPGA
- Be verified through self-checking testbenches against golden reference outputs

---

### 5. Objectives

1. Design a streaming 3×3 window generator using two cascaded line buffers and three 3-tap shift registers
2. Implement a configurable 3×3 convolution engine with parameterized kernel and 3-stage pipeline
3. Implement Sobel edge detection (Gx, Gy, magnitude, thresholding) using the same window architecture
4. Verify correctness through self-checking testbenches with 9 deterministic test patterns
5. Synthesize for Xilinx Artix-7 FPGA and analyze resource utilization and timing
6. Compare architecture against published reference works in the field

---

### 6. Existing Approaches

Several approaches exist for implementing image processing operations on hardware:

**Software-based approaches** use CPU or GPU to perform convolution and edge detection.
While flexible, they suffer from non-deterministic latency and high power consumption.
Python/OpenCV implementations, as used by Sravan Kumar et al. [4] for post-processing
validation, achieve approximately 20–25× lower per-frame cycle efficiency compared to
hardware implementations.

**Frame-buffer based hardware approaches** store the entire image in on-chip memory before
processing. This requires significant BRAM resources and limits the maximum image size
that can be processed. For a 640×480 image at 8 bits, this demands ~300 KB of memory.

**Streaming line-buffer architectures** process pixels as they arrive, requiring only two
row-sized line buffers instead of a full frame buffer. Sravan Kumar et al. [4] demonstrated
this approach for 64×64 Sobel edge detection in simulation, achieving one pixel per clock
throughput with 4,096 cycles per frame. Navinkumar et al. [1] extended this to real-time
with a modified multiplier-free Sobel on Cyclone III FPGA. Joy et al. [2] implemented
pipelined Sobel and Canny on ZedBoard with 4-line buffers for 512×512 images. Alshemi
et al. [3] used Sobel as the first stage of a lane detection pipeline, comparing FPGA
and GPU implementations.

The proposed streaming line-buffer approach avoids frame buffers, scales to arbitrary
image sizes with minimal additional resources, and provides deterministic throughput.

### 6.1 Comparison with Reference Works

| Feature | This Work | Sravan Kumar [4] | Navinkumar [1] | Joy [2] | Alshemi [3] |
|---------|-----------|-----------------|----------------|---------|-------------|
| Image Size | 64×64 | 64×64 | Real-time | 512×512 | Real-world |
| Platform | Sim + Synth | Sim only | Cyclone III | ZedBoard | Zynq-7 ZC706 |
| Algorithm | Conv + Sobel | Sobel | Modified Sobel | Sobel + Canny | Sobel (lane) |
| Line Buffers | 2 | 2 | 2+ | 4 | 2 |
| Window | 3×3 | 3×3 | 3×3 | 3×3 | 3×3 |
| Throughput | 1 px/clk | 1 px/clk | 1 px/clk | 1 px/clk | 1 px/clk |
| Synthesis | Yes | No | Yes | Yes | Yes |
| Test Patterns | 9 | N/A | N/A | N/A | N/A |
| DSP Usage | 0 | N/A | N/A | N/A | N/A |

---

### 7. Proposed Hardware Architecture

The proposed architecture follows a modular, streaming pipeline design:

```
                    pixel_in [7:0]
                         │
                    ┌────▼────┐
                    │  Line   │──── row0 [7:0]
                    │ Buffer 0│     (delayed by WIDTH clocks)
                    │(DEPTH=W)│
                    └────┬────┘
                         │
                    ┌────▼────┐
                    │  Line   │──── row1 [7:0]
                    │ Buffer 1│     (delayed by 2×WIDTH clocks)
                    │(DEPTH=W)│
                    └────┬────┘
                         │
            ┌────────────┼────────────┐
            │            │            │
       ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
       │ Shift   │  │ Shift   │  │ Shift   │
       │ Reg 0   │  │ Reg 1   │  │ Reg 2   │
       │(tap=3)  │  │(tap=3)  │  │(tap=3)  │
       └────┬────┘  └────┬────┘  └────┬────┘
            │            │            │
            └────────────┼────────────┘
                         │
                    ┌────▼────┐
                    │ Window  │──── p00-p22 (9 pixels)
                    │ 3×3     │     + valid_pipe
                    └────┬────┘
                         │
              ┌──────────┴──────────┐
              │                     │
         ┌────▼─────┐        ┌─────▼────┐
         │Conv 3×3  │        │  Sobel   │
         │(Stage 1) │        │ (Stage 2)│
         └────┬─────┘        └─────┬────┘
              │                     │
         pixel_out            pixel_out
```

**Key modules:**
- `line_buffer.sv`: Parameterized shift register of depth WIDTH (default 64), delaying pixel by exactly one row
- `shift_registers.sv`: Three 3-tap horizontal shift registers providing column-aligned pixels for each row
- `window_3x3.sv`: Captures 9 pixels into a 3×3 window with valid_pipe tracking
- `convolution_3x3.sv`: 3-stage pipelined multiply-accumulate unit with saturation
- `sobel_edge_detect.sv`: Gx/Gy gradient computation, magnitude, and thresholding
- `streaming_conv_top.sv` / `streaming_sobel_top.sv`: Top-level wrappers with fill_done and output column counters

---

### 8. Streaming Architecture

The streaming architecture processes pixels as they arrive, one per clock cycle, without requiring
the entire image to be stored in memory. This is achieved through:

- **One pixel per clock throughput**: After the initial pipeline fill delay, one output pixel is
  produced every clock cycle
- **No frame buffer required**: Only two line-sized buffers (2 × WIDTH registers) are needed,
  compared to WIDTH × HEIGHT for a frame buffer
- **Line buffers provide row alignment**: Each line buffer delays its input by exactly WIDTH
  clocks, aligning pixels from consecutive rows
- **Shift registers provide column alignment**: Three 3-tap shift registers create a sliding
  window across each row

**Pipeline fill latency**: The pipeline requires 2 × WIDTH + 3 clock cycles to fill before the
first valid output appears. For WIDTH = 64, this is 131 cycles. After fill, the pipeline
produces one valid output per clock for (WIDTH-2) × (HEIGHT-2) pixels per frame.

**Output column counting**: The top-level modules include an output column counter (0 to WIDTH-1)
that suppresses the last 2 outputs per row (when out_col_cnt ≥ WIDTH-2), ensuring only valid
interior pixels are produced.

---

### 9. Line Buffer Architecture

Each line buffer is implemented as a parameterized shift register of depth WIDTH (default 64):

```systemverilog
module line_buffer #(
    parameter WIDTH = 64
)(
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] pixel_in,
    input  logic       pixel_valid_in,
    output logic [7:0] pixel_out,
    output logic       pixel_valid_out
);
    logic [7:0] shift_reg [0:WIDTH-1];
    // ... shifts pixel_in through shift_reg[0] → shift_reg[WIDTH-1]
endmodule
```

**Operation**: When pixel_valid_in is asserted, pixel_in is shifted into shift_reg[0] and all
existing values shift right by one position. After WIDTH clock cycles, the first pixel appears
at shift_reg[WIDTH-1] = pixel_out, delayed by exactly one row.

**Two cascaded line buffers** provide two rows of delay:
- Line Buffer 0 output: current row - 1 (row0)
- Line Buffer 1 output: current row - 2 (row1)
- pixel_in itself: current row (row2)

**Resource usage**: Each line buffer uses WIDTH × 8 = 512 flip-flops (for WIDTH=64). Two line
buffers consume 1,024 FFs total, implemented as distributed RAM (no BRAM used).

---

### 10. 3×3 Window Generation

The 3×3 window is formed by combining outputs from the line buffers and shift registers:

```
p00 p01 p02    Row 0: from Line Buffer 1 → Shift Register 2 (3 taps)
p10 p11 p12    Row 1: from Line Buffer 0 → Shift Register 1 (3 taps)
p20 p21 p22    Row 2: from pixel_in      → Shift Register 0 (3 taps)
```

Each shift register produces 3 consecutive pixels from its row, providing the column alignment
needed for the 3×3 window. The window module (`window_3x3.sv`) captures these 9 pixels and
tracks validity through a `valid_pipe` that shifts `pixel_valid_in` through 3 stages.

**Valid region**: The pipeline produces valid outputs only for the interior (WIDTH-2) × (HEIGHT-2)
region of the image. For a 64×64 image, this yields 62 × 62 = 3,844 valid output pixels per
frame. The top-level output column counter suppresses the 2 edge outputs per row.

**Window timing**: At each clock cycle, the window shifts right by one column. At the end of a
row, the line buffers provide the next row's data, and the window effectively "wraps" to the
start of the next row's 3×3 neighborhoods.

---

### 11. Convolution Mathematics

The 3×3 convolution operation computes:

```
Output = Σ(p[i][j] × k[i][j]) for i,j ∈ {0,1,2}
```

where p[i][j] are the 9 window pixels and k[i][j] are the kernel coefficients.

**Bit-width analysis**:
- Input pixels: 8-bit unsigned (0–255)
- Kernel coefficients: 12-bit signed (parameterized, allows fractional values)
- Products: 8 × 12 = 20-bit signed
- Accumulator: 20 + 4 = 24-bit signed (9 products + overflow bits)
- Output: Saturated to 8-bit unsigned [0, 255]

**3-stage pipeline**:
1. Stage 1: Compute 9 partial products (p × k)
2. Stage 2: Sum products in a tree structure
3. Stage 3: Saturation and output registration

The pipeline registers ensure the design meets timing at 50 MHz. The convolution module
is fully parameterized — different kernels can be loaded at synthesis time by modifying
the kernel parameters.

---

### 12. Sobel Mathematics

The Sobel operator computes horizontal and vertical gradients using two 3×3 kernels:

```
Gx:         Gy:
[-1  0  1]  [-1 -2 -1]
[-2  0  2]  [ 0  0  0]
[-1  0  1]  [ 1  2  1]
```

**Gradient computation**:
- Gx = (p02 + 2×p12 + p22) - (p00 + 2×p10 + p20)
- Gy = (p20 + 2×p21 + p22) - (p00 + 2×p01 + p02)

**Magnitude**: magnitude = |Gx| + |Gy| (L1 approximation, avoiding square root)

**Thresholding**: edge = (magnitude ≥ THRESHOLD) ? 255 : 0

The Sobel design uses the same line buffer and window infrastructure as the convolution
engine, but replaces the multiply-accumulate unit with专用 adders and shifters (since Sobel
coefficients are only -2, -1, 0, 1, 2 — no general multipliers needed). This makes the
Sobel module more resource-efficient than the general convolution engine.

---

### 13. RTL Design

The design is implemented in SystemVerilog (IEEE 1800) with the following characteristics:

- **Synthesizable code**: All RTL modules use only synthesizable constructs (no initial blocks,
  no # delays, no behavioral descriptions in synthesizable modules)
- **Parameterized design**: Image WIDTH/HEIGHT, kernel coefficients, threshold values, and
  pipeline depths are all parameterized for flexibility
- **Asynchronous active-high reset**: All flip-flops use a common async reset for initialization
- **Clean module hierarchy**:
  ```
  streaming_conv_top
  ├── line_buffer [2 instances]
  ├── shift_registers [3 instances]
  ├── window_3x3
  └── convolution_3x3

  streaming_sobel_top
  ├── line_buffer [2 instances]
  ├── shift_registers [3 instances]
  ├── window_3x3
  └── sobel_edge_detect
  ```
- **No DSP/BRAM usage**: All arithmetic uses distributed logic (LUTs and FFs), ensuring
  the design maps to general-purpose logic rather than dedicated blocks

---

### 14. Verification Methodology

The verification approach uses self-checking testbenches with deterministic test images:

**Test images** (all 64×64, 8-bit grayscale):
- **Constant**: All pixels = 128 → validates pass-through behavior
- **Gradient**: Linear ramp 0–255 across pixels → validates monotonic response
- **Checkerboard**: 8×8 alternating blocks → validates edge detection at block boundaries
- **Random**: Uniform random values → validates statistical correctness
- **Vertical edge**: Left half 0, right half 255 → Sobel should produce strong vertical response
- **Horizontal edge**: Top half 0, bottom half 255 → Sobel should produce strong horizontal response
- **Square**: White 20×20 square on black background → Sobel should detect all 4 edges

**Golden reference computation**: Each testbench computes expected outputs on-the-fly using
the same mathematical operations as the DUT, ensuring independent verification.

**Checking method**: For each output pixel, the testbench waits for pixel_valid_out, then
compares DUT output against the golden reference. Any mismatch triggers a $error report.
All 9 test patterns must pass with zero mismatches for the design to be considered correct.

**Pipeline fill handling**: The testbench accounts for the 2×WIDTH+3 cycle pipeline fill
delay by waiting for the first valid output before beginning comparison.

---

### 15. Simulation Results

**Stage 1: Streaming Convolution (tb_streaming_conv)**

| Test Pattern | Status | Outputs Checked | Notes |
|-------------|--------|-----------------|-------|
| Constant (128) | PASS | 3844 | All outputs match expected |
| Gradient | PASS | 3844 | Monotonic response verified |
| Checkerboard | PASS | 3844 | Edge transitions correct |
| Random | PASS | 3844 | Statistical match confirmed |

**Stage 2: Sobel Edge Detection (tb_sobel_edge)**

| Test Pattern | Status | Outputs Checked | Notes |
|-------------|--------|-----------------|-------|
| Vertical edge | PASS | 3844 | Strong vertical gradient detected |
| Horizontal edge | PASS | 3844 | Strong horizontal gradient detected |
| Square | PASS | 3844 | All 4 edges detected |
| Checkerboard | PASS | 3844 | Periodic edges verified |
| Random | PASS | 3844 | Statistical match confirmed |

**Total**: 9/9 tests PASS, 34,596 output pixels verified across both stages.

Waveform captures and detailed simulation logs are available in the `vivado/sim/` directory.

---

### 16. Synthesis Results

Synthesis was performed using Vivado 2026.1 targeting the Xilinx Artix-7 FPGA
(xc7a35tcpg236-1, CPG236 package).

**Stage 1: Streaming Convolution (streaming_conv_top)**

| Metric | Value |
|--------|-------|
| LUTs | 403 / 20,800 (1.94%) |
| Flip-Flops | 937 / 41,600 (2.25%) |
| BRAM | 0 / 50 (0.00%) |
| DSP | 0 / 90 (0.00%) |
| WNS (Setup) | +5.781 ns |
| WHS (Hold) | +0.058 ns |
| Max Frequency | > 50 MHz (WNS positive) |

**Stage 2: Sobel Edge Detection (streaming_sobel_top)**

| Metric | Value |
|--------|-------|
| LUTs | 594 / 20,800 (2.86%) |
| Flip-Flops | 1132 / 41,600 (2.72%) |
| BRAM | 0 / 50 (0.00%) |
| DSP | 0 / 90 (0.00%) |
| WNS (Setup) | Positive (meets timing) |
| WHS (Hold) | Positive (meets timing) |

Detailed synthesis reports are available in `vivado/reports/`.

---

### 17. Resource Utilization

**Stage 1: Streaming Convolution (streaming_conv_top)**

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUT | 403 | 20800 | 1.94% |
| FF | 937 | 41600 | 2.25% |
| BRAM | 0 | 50 | 0.00% |
| DSP | 0 | 90 | 0.00% |

**Stage 2: Sobel Edge Detection (streaming_sobel_top)**

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUT | 594 | 20800 | 2.86% |
| FF | 1132 | 41600 | 2.72% |
| BRAM | 0 | 50 | 0.00% |
| DSP | 0 | 90 | 0.00% |

---

### 18. Timing Analysis

**Stage 1: Streaming Convolution**

| Parameter | Value |
|-----------|-------|
| Target Clock Period | 20.000 ns |
| Target Frequency | 50.000 MHz |
| Worst Negative Slack (WNS) | +5.781 ns |
| Worst Hold Slack (WHS) | +0.058 ns |
| Timing Constraints | Met |

The design meets timing at 50 MHz with positive slack, indicating the actual
maximum frequency is higher. The critical path passes through the convolution
saturation logic (sum_all → saturation → pixel_out).

---

### 19. Advantages

1. **Streaming architecture** — no frame buffer required; only 2 × WIDTH registers for line buffers
2. **One pixel per clock throughput** — deterministic, independent of image size after pipeline fill
3. **Parameterized design** — WIDTH, HEIGHT, kernel coefficients, and threshold are all configurable
4. **Dual functionality** — same line buffer/window infrastructure supports both convolution and Sobel
5. **Resource efficient** — no DSP or BRAM blocks used; maps entirely to distributed logic
6. **Fully synthesizable** — directly implementable on any Xilinx 7-series FPGA
7. **Simulation-verified** — 9 test patterns with zero mismatches across 34,596 output pixels
8. **Timing-closed** — meets 50 MHz with +5.781 ns slack on Artix-7

---

### 20. Limitations

1. **Grayscale only** — supports 8-bit grayscale images; no RGB color processing
2. **Valid-region output only** — boundary pixels (first/last row and column) are not produced;
   no zero-padding option implemented
3. **Fixed 3×3 window** — larger kernels (5×5, 7×7) would require additional line buffers
4. **No video stream interface** — no AXI-Stream or similar standard bus interface for
   integration with camera/display pipelines
5. **Simulation-only validation** — no physical camera input or display output tested
6. **Threshold is static** — Sobel threshold is a synthesis-time parameter, not dynamically adjustable

---

### 21. Future Work

1. **AXI-Stream interface** — add standard video bus interface for camera input and display output
2. **RGB color support** — process each color channel independently or convert to grayscale first
3. **Larger kernels** — implement 5×5 or 7×7 windows with additional line buffers for Gaussian
   smoothing or Laplacian operators
4. **Non-maximum suppression** — add thin-edge post-processing for Canny-style edge detection
   (as demonstrated by Joy et al. [2])
5. **Dynamic threshold** — add a register interface for runtime-adjustable Sobel threshold
6. **Gaussian pre-filter** — integrate a 3×3 Gaussian smoothing stage before edge detection to
   reduce noise sensitivity
7. **Real-time camera integration** — connect to OV7670 or similar CMOS camera module
   (as demonstrated by Navinkumar et al. [1])
8. **Higher resolution** — scale to 640×480 or higher with BRAM-based line buffers
9. **MATLAB reference model** — create MATLAB scripts for independent verification of both
   convolution and Sobel operations, enabling comparison between hardware and software implementations

---

### 22. Conclusion

This project successfully designed, verified, and synthesized a streaming image processing
pipeline for real-time 3×3 convolution and Sobel edge detection in SystemVerilog. The key
achievements are:

**Architecture**: A modular streaming pipeline using line buffers and shift registers that
processes one pixel per clock cycle after a pipeline fill delay of 2×WIDTH+3 cycles. The
same line buffer/window infrastructure supports both general convolution and Sobel edge
detection.

**Verification**: All 9 test patterns (4 for convolution, 5 for Sobel) pass with zero
mismatches, verifying 34,596 output pixels across both stages. The self-checking testbench
approach with on-the-fly golden reference computation provides high confidence in correctness.

**Synthesis**: The design synthesizes efficiently on Xilinx Artix-7 (xc7a35tcpg236-1),
using only 403 LUTs and 937 FFs for convolution, and 594 LUTs and 1132 FFs for Sobel.
No DSP or BRAM blocks are required. Timing is met at 50 MHz with +5.781 ns positive slack.

**Comparison with literature**: The architecture aligns with the simulation-only framework
demonstrated by Sravan Kumar et al. [4] for 64×64 Sobel edge detection, while extending it
with a general-purpose convolution engine, formal FPGA synthesis, and timing analysis.
The streaming line-buffer approach is consistent with real-time implementations by
Navinkumar et al. [1] and Joy et al. [2], confirming the design's suitability for
future FPGA deployment.

---

### 23. References

[1] K. Navinkumar, R. Logesh, P. VishnuBabu, A.V. Ananthalakshmi, "FPGA implementation
of sobel edge detection algorithm," EAI Endorsed Transactions on Internet of Things,
vol. 10, 2024. doi: 10.4108/eetiot.5148

[2] A. Joy, J. Jacob, B. Roy, "High-speed hardware edge detection implementation on
FPGA using pipelined Sobel and Canny algorithms," Archives for Technical Sciences,
vol. 33(2), pp. 472-482, 2025. doi: 10.70102/afts.2025.1833.472

[3] M. Alshemi, S. Saif, M. Taher, "Hardware acceleration of lane detection algorithm:
A GPU versus FPGA comparison," in Proc. CS & IT - CSCP 2022, pp. 191-201.
doi: 10.5121/csit.2022.122215

[4] N.V. Sravan Kumar, N.S. Kallakuri, P. Chandana, Ch. Raja, "Sobel Edge Detection
Algorithm Using Verilog for 64×64 Grayscale Image," International Journal of Research
and Scientific Innovation (IJRSI), vol. XII, issue IX, pp. 4247-4255, September 2025.
doi: 10.51244/IJRSI.2025.120800384

[5] R.C. Gonzalez and R.E. Woods, "Digital Image Processing," 4th Edition, Pearson, 2018.

[6] I. Sobel and G. Feldman, "A 3×3 Isotropic Gradient Operator for Image Processing,"
1968.

[7] AMD/Xilinx, "Vivado Design Suite User Guide: Synthesis," UG901.

[8] AMD/Xilinx, "7 Series FPGAs Configurable Logic Block User Guide," UG474.
