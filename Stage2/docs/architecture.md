# Architecture Document

## Streaming 3x3 Convolution and Sobel Edge Detection Pipeline

### 1. System Overview

This document describes the hardware architecture of a streaming image-processing
pipeline designed for FPGA implementation. The system processes one grayscale pixel
per clock cycle after initial pipeline startup.

### 2. Design Hierarchy

```
streaming_conv_top          (Stage 1)
├── line_buffer [0]         (WIDTH-1 deep shift register)
├── line_buffer [1]         (WIDTH-1 deep shift register)
├── shift_registers         (3 × 3-tap horizontal shift)
├── window_3x3              (9-pixel register stage)
└── convolution_3x3         (3-stage pipelined MAC)

streaming_sobel_top         (Stage 2)
├── line_buffer [0]
├── line_buffer [1]
├── shift_registers
├── window_3x3
└── sobel_edge_detect       (6-stage pipelined Sobel)
```

### 3. Line Buffer Architecture

**Module:** `line_buffer.sv`

A line buffer stores exactly one row of pixels. It is implemented as a shift register
of depth `WIDTH - 1`.

```
pixel_in ──> [ SR[0] ] ──> [ SR[1] ] ──> ... ──> [ SR[WIDTH-2] ] ──> pixel_out
```

- When `pixel_valid` is high, `pixel_in` shifts into position `WIDTH-2`
- `pixel_out` always reads from position `0`
- After `WIDTH-1` clocks, the first pixel appears at the output
- Total delay: exactly one image row (WIDTH pixels)

**Two line buffers in cascade** provide two rows of delay:
- Line buffer 0: delays input by 1 row
- Line buffer 1: delays line buffer 0 output by 1 more row

### 4. Shift Register Architecture

**Module:** `shift_registers.sv`

Three independent 3-tap shift registers, one per row of the 3×3 window:

```
Row 0: [ SR0[0] ] ← [ SR0[1] ] ← [ SR0[2] ] ← pixel_row0
Row 1: [ SR1[0] ] ← [ SR1[1] ] ← [ SR1[2] ] ← pixel_row1
Row 2: [ SR2[0] ] ← [ SR2[1] ] ← [ SR2[2] ] ← pixel_row2
         ↓            ↓            ↓
        pX0          pX1          pX2
```

On each valid clock, all three shift registers shift left simultaneously.
After 3 clocks, each shift register contains 3 consecutive pixels from its row.

### 5. 3×3 Window

**Module:** `window_3x3.sv`

Captures the 9 outputs from the shift registers into a registered window:

```
p00 p01 p02
p10 p11 p12
p20 p21 p22
```

The window register adds 1 clock of pipeline delay. The `window_valid` signal
is `pixel_valid` delayed by 1 clock.

### 6. Valid Region

For an image of WIDTH × HEIGHT pixels:
- The 3×3 window first contains valid data after 2 rows + 2 columns have been received
- Valid output region: columns [2, WIDTH-1] × rows [2, HEIGHT-1]
- Output dimensions: (WIDTH-2) × (HEIGHT-2)

### 7. Convolution Arithmetic

**Module:** `convolution_3x3.sv`

3-stage pipelined multiply-accumulate:

| Stage | Operation | Latency |
|-------|-----------|---------|
| 1 | 9 parallel multiplications (pixel × kernel) | 1 clock |
| 2 | Row sums (3 groups of 3 adds) | 1 clock |
| 3 | Total sum + output register | 1 clock |

**Bit-width analysis:**
- Pixel: 8-bit unsigned
- Coefficient: 12-bit signed
- Product: 20-bit signed
- Accumulator: 24-bit signed (9 products summed)
- Output: clipped to [0, 255]

### 8. Sobel Edge Detection

**Module:** `sobel_edge_detect.sv`

6-stage pipelined Sobel operator:

| Stage | Operation |
|-------|-----------|
| 1 | 18 parallel multiplications (9 for Gx, 9 for Gy) |
| 2 | Row sums for Gx and Gy |
| 3 | Total Gx and Gy |
| 4 | Absolute values |
| 5 | Magnitude = |Gx| + |Gy| |
| 6 | Threshold comparison + output |

**Sobel kernels:**
```
Gx:                Gy:
-1  0  1           -1 -2 -1
-2  0  2            0  0  0
-1  0  1            1  2  1
```

### 9. Pipeline Timing

Total latency from first pixel to first valid output:

```
Latency = (2 × WIDTH) + 4 clock cycles
```

Breakdown:
- Line buffers fill: 2 × WIDTH clocks (2 rows)
- Shift registers fill: 3 clocks (3 pixels)
- Window register: 1 clock
- Convolution/Sobel pipeline: 3-6 clocks

### 10. Reset Behavior

- Asynchronous active-high reset
- All internal registers cleared to zero
- `pixel_valid_out` remains low during and after reset until valid data propagates
- Line buffers reset to all zeros
- Shift registers reset to all zeros

### 11. Resource Utilization (Estimated)

For 640×480 image with 8-bit pixels:

| Resource | Convolution | Sobel |
|----------|-------------|-------|
| LUTs | ~500 | ~800 |
| FFs | ~300 | ~400 |
| BRAM | 2 (line buffers) | 2 |
| DSPs | 9 (multipliers) | 18 |

Note: Line buffers may use distributed RAM (LUTs) for small widths or BRAM for
large widths. Vivado synthesis will determine the actual implementation.
