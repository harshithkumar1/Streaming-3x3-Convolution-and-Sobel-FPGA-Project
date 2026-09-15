# Stage 1: Streaming Window Generator

## What This Does
**No math.** Just pixel delivery.

Takes a stream of pixels and outputs a 3×3 window of 9 pixels every clock cycle.

## How It Works

```
Input:  One pixel per clock (from camera)
        ↓
┌──────────────────────────────────┐
│  Line Buffer 0  ← stores row 1  │
│  Line Buffer 1  ← stores row 2  │
│  Shift Registers ← stores 3 cols│
│  Window 3×3     ← grabs 9 pixels│
└──────────────────────────────────┘
        ↓
Output: 9 pixels [p00-p22] every clock
```

## Files

| File | What It Does |
|------|-------------|
| `line_buffer.sv` | Stores one row of pixels |
| `shift_registers.sv` | Stores 3 columns per row |
| `window_3x3.sv` | Grabs 9 pixels into a grid |
| `streaming_window_top.sv` | Top-level (connects everything) |
| `tb_window_gen.sv` | Testbench |

## Test Results

| Test | Input | Window Output | Status |
|------|-------|---------------|--------|
| Constant | All pixels = 128 | All 9 pixels = 128 | PASS |
| Gradient | Brightness increases | 9 different values | PASS |
| Checkerboard | Black/white blocks | Mix of 0 and 255 | PASS |

## To Run in Vivado

```tcl
cd vivado
source create_project.tcl
source run_sim.tcl
```
