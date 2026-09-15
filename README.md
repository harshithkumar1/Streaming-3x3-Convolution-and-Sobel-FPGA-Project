# Hardware-Based Real-Time Image Processing Pipeline

## Streaming 3x3 Convolution and Sobel Edge Detection

An academic FPGA/VLSI project implementing a streaming pixel-processing architecture
for real-time image convolution and Sobel edge detection.

---

## Project Structure

```
VLSI_Project/
├── rtl/                          # Synthesizable RTL (SystemVerilog)
│   ├── line_buffer.sv            # Single-row delay line buffer
│   ├── shift_registers.sv        # 3-tap horizontal shift registers
│   ├── window_3x3.sv             # 3x3 sliding window capture
│   ├── convolution_3x3.sv        # 3x3 convolution arithmetic engine
│   ├── streaming_conv_top.sv     # Stage 1 top-level processor
│   ├── sobel_edge_detect.sv      # Sobel edge detection engine
│   └── streaming_sobel_top.sv    # Stage 2 top-level processor
│
├── tb/                           # Testbenches (self-checking)
│   ├── tb_streaming_conv.sv      # Stage 1 testbench
│   ├── tb_sobel_edge.sv          # Stage 2 testbench
│   └── test_images/              # (reserved for image files)
│
├── matlab/                       # MATLAB reference model
│   └── reference_model.m         # Reference implementation
│
├── vivado/                       # Vivado project scripts
│   ├── create_project.tcl        # Create Vivado project
│   ├── run_sim.tcl               # Run behavioral simulation
│   ├── run_synth.tcl             # Run synthesis + reports
│   └── run_sobel_synth.tcl       # Sobel synthesis
│
├── scripts/                      # Windows batch scripts
│   ├── run_simulation.bat        # One-click simulation
│   └── run_synthesis.bat         # One-click synthesis
│
├── docs/                         # Documentation
│   ├── architecture.md           # Architecture description
│   ├── verification.md           # Verification methodology
│   ├── project_report.md         # Academic report material
│   └── references/               # Extracted reference papers (text)
│       ├── eetiot.5148.txt       # Navinkumar et al. (2024)
│       ├── 1833.472.txt          # Joy et al. (2025)
│       ├── 2212.09460v1.txt      # Alshemi et al. (2022)
│       └── vol12-iss9-...txt     # Sravan Kumar et al. (2025)
│
└── README.md                     # This file
```

---

## Quick Start

### Prerequisites

- AMD/Xilinx Vivado (2020.1 or later)
- Windows 10/11

### Running Simulation

```batch
scripts\run_simulation.bat
```

Or manually in Vivado Tcl Console:

```tcl
cd vivado
source create_project.tcl
source run_sim.tcl
```

### Running Synthesis

```batch
scripts\run_synthesis.bat
```

Reports are generated in `vivado/reports/`.

---

## Architecture Overview

The design processes grayscale pixels in a streaming fashion, one pixel per clock
after initial pipeline startup.

```
                    ┌─────────────┐
 pixel_in ────────>│ Line Buffer 0│──────> Line 1 delayed
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ Line Buffer 1│──────> Line 2 delayed
                    └──────┬──────┘
                           │
              ┌────────────▼────────────┐
              │     Shift Registers      │
              │  (3 rows × 3 columns)    │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │       Window 3x3         │
              │  (9-pixel register)      │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │  Convolution / Sobel     │
              │  (multiply-accumulate)   │
              └────────────┬────────────┘
                           │
                      pixel_out
```

---

## Stage 1: Streaming 3x3 Convolution

**Default kernel:** Box filter [1 1 1; 1 1 1; 1 1 1]

- Parameterized image dimensions (default 640×480)
- 8-bit grayscale pixels
- Signed 12-bit kernel coefficients
- 24-bit signed accumulator (prevents overflow)
- Output saturated to [0, 255]

**Pipeline latency:** 2×WIDTH + 6 clocks to first valid output

**Valid output region:** (WIDTH−2) × (HEIGHT−2) pixels

---

## Stage 2: Sobel Edge Detection

Reuses the streaming window architecture. Computes:

- **Gx** = [-1 0 1; -2 0 2; -1 0 1] (horizontal gradient)
- **Gy** = [-1 -2 -1; 0 0 0; 1 2 1] (vertical gradient)
- **magnitude** = |Gx| + |Gy|
- **edge** = (magnitude ≥ THRESHOLD) ? 255 : 0

**Default threshold:** 128

---

## Test Images

| Test | Size | Description | Stage |
|------|------|-------------|-------|
| 1 | 64×64 | Constant image (all pixels = 128) | Conv |
| 2 | 64×64 | Gradient image (linear ramp 0-255) | Conv |
| 3 | 64×64 | Checkerboard pattern (8×8 blocks) | Conv |
| 4 | 64×64 | Pseudo-random (seed: 0xACE1) | Conv |
| 5 | 64×64 | Vertical edge (left=0, right=255) | Sobel |
| 6 | 64×64 | Horizontal edge (top=0, bottom=255) | Sobel |
| 7 | 64×64 | Square (20×20 white on black) | Sobel |
| 8 | 64×64 | Checkerboard pattern | Sobel |
| 9 | 64×64 | Pseudo-random | Sobel |

---

## Key Design Decisions

1. **Streaming architecture** — Uses line buffers instead of storing the full image
2. **Synchronous reset** — Active-high, fully synchronous
3. **Valid-region-only** — No output for incomplete neighborhoods at boundaries
4. **Signed arithmetic** — Handles negative kernel coefficients correctly
5. **Saturation** — Output clipped to [0, 255] to prevent wrapping

---

## Results

**Stage 1: Streaming Convolution**
- Simulation: All 4 tests PASS (64×64 images)
- Synthesis: 403 LUTs (1.94%), 937 FFs (2.25%), 0 DSPs
- Timing: Meets 50 MHz (WNS = +5.781 ns)

**Stage 2: Sobel Edge Detection**
- Simulation: All 5 tests PASS (64×64 images)
- Synthesis: 594 LUTs (2.86%), 1132 FFs (2.72%), 0 DSPs

Reports are generated in `vivado/reports/`.
See `docs/project_report.md` for the academic report template.

---

## References

1. K. Navinkumar et al., "FPGA implementation of sobel edge detection algorithm,"
   EAI Endorsed Transactions on Internet of Things, 2024. doi: 10.4108/eetiot.5148

2. A. Joy et al., "High-speed hardware edge detection on FPGA using pipelined
   Sobel and Canny algorithms," Archives for Technical Sciences, 2025.
   doi: 10.70102/afts.2025.1833.472

3. M. Alshemi et al., "Hardware acceleration of lane detection algorithm:
   A GPU versus FPGA comparison," CS & IT - CSCP 2022. doi: 10.5121/csit.2022.122215

4. N.V. Sravan Kumar et al., "Sobel Edge Detection Algorithm Using Verilog for
   64×64 Grayscale Image," IJRSI, vol. XII, Sept 2025. doi: 10.51244/IJRSI.2025.120800384

5. R.C. Gonzalez and R.E. Woods, "Digital Image Processing," 4th Edition, Pearson, 2018.

6. I. Sobel and G. Feldman, "A 3×3 Isotropic Gradient Operator for Image Processing," 1968.

7. AMD/Xilinx, "Vivado Design Suite User Guide: Synthesis," UG901.

8. AMD/Xilinx, "7 Series FPGAs Configurable Logic Block User Guide," UG474.
