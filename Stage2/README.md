# Stage 2: Sobel Edge Detection

## What This Does
Takes the 3×3 pixel window from Stage 1 and detects edges using the Sobel operator.

```
Input:  One pixel per clock (from camera)
        ↓
┌──────────────────────────────────┐
│ Line Buffers (2)                 │ ← stores rows
│ Shift Registers (3)              │ ← stores columns
│ Window 3×3                       │ ← grabs 9 pixels
│ Sobel Edge Detect                │ ← Gx, Gy, threshold
│   Gx = left-right brightness     │
│   Gy = top-bottom brightness     │
│   magnitude = |Gx| + |Gy|        │
│   if magnitude ≥ threshold → 255 │
│   else → 0                       │
└──────────────────────────────────┘
        ↓
Output: White (255) = edge, Black (0) = no edge
```

## Files

| File | What It Does |
|------|-------------|
| `line_buffer.sv` | Stores one row of pixels |
| `shift_registers.sv` | Stores 3 columns per row |
| `window_3x3.sv` | Grabs 9 pixels into a grid |
| `sobel_edge_detect.sv` | Computes Gx, Gy, magnitude, threshold |
| `streaming_sobel_top.sv` | Top-level (connects everything) |
| `tb_sobel_edge.sv` | Testbench (5 tests) |

## Test Results

| Test | Input | Output | Status |
|------|-------|--------|--------|
| Vertical Edge | Left=0, Right=255 | White vertical line | PASS |
| Horizontal Edge | Top=0, Bottom=255 | White horizontal line | PASS |
| Square | White 20×20 on black | White square outline | PASS |
| Checkerboard | Black/white blocks | Grid pattern | PASS |
| Random | Random noise | Many edges | PASS |

## To Run in Vivado

```tcl
cd Stage2/vivado
source create_project.tcl
source run_sim.tcl
```
