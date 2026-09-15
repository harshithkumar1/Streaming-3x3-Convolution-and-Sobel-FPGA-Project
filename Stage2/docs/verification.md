# Verification Document

## Verification Methodology

### 1. Overview

Verification is performed at multiple levels using self-checking SystemVerilog
testbenches. The testbenches generate deterministic test images, feed pixels to
the DUT one per clock, compute golden reference results, and compare against
DUT output.

### 2. Verification Levels

| Level | Description | Module |
|-------|-------------|--------|
| 1 | Individual module behavior | line_buffer, shift_registers |
| 2 | Window generation correctness | window_3x3 |
| 3 | Convolution arithmetic | convolution_3x3 |
| 4 | Complete streaming pipeline | streaming_conv_top |
| 5 | Sobel edge detection | streaming_sobel_top |
| 6 | Vivado synthesis | All modules |

### 3. Golden Reference Computation

The testbench computes expected results using the exact same arithmetic as the RTL:

**Convolution (box filter):**
```
golden = sum of 9 window pixels
clipped = clamp(golden, 0, 255)
```

**Sobel:**
```
Gx = sum of pixel[i][j] * Gx_kernel[i][j] for i,j in {0,1,2}
Gy = sum of pixel[i][j] * Gy_kernel[i][j] for i,j in {0,1,2}
magnitude = |Gx| + |Gy|
edge = (magnitude >= THRESHOLD) ? 255 : 0
```

### 4. Test Cases — Stage 1 (Convolution)

| Test | Image Size | Pattern | Expected Behavior |
|------|------------|---------|-------------------|
| 1 | 8×8 | Constant (all 100) | All outputs = 255 (9×100 > 255) |
| 2 | 8×8 | Diagonal gradient | Outputs vary with window position |
| 3 | 16×16 | Checkerboard | High contrast, outputs near 0 or 255 |
| 4 | 64×64 | Random (seed 0xACE1) | All outputs verified against reference |

### 5. Test Cases — Stage 2 (Sobel)

| Test | Image Size | Pattern | Expected Behavior |
|------|------------|---------|-------------------|
| 1 | 16×16 | Vertical edge | Strong Gx response at edge |
| 2 | 16×16 | Horizontal edge | Strong Gy response at edge |
| 3 | 32×32 | Center square | Edges detected at all 4 sides |
| 4 | 16×16 | Checkerboard | High edge density at transitions |
| 5 | 64×64 | Random (seed 0xBEEF) | All outputs verified against reference |

### 6. Checking Strategy

1. **Feed pixels sequentially** — one per clock, matching hardware input rate
2. **Store full image** — in testbench memory for golden reference lookup
3. **Track output position** — using output_valid pulse counter
4. **Compare on-the-fly** — each DUT output checked against computed golden value
5. **Report mismatches** — first mismatch details (position, expected, actual, window)
6. **Count outputs** — verify total matches expected (WIDTH-2) × (HEIGHT-2)

### 7. Pass/Fail Criteria

- **PASS:** All outputs match golden reference, output count matches expected
- **FAIL:** Any mismatch or incorrect output count

### 8. Simulation Commands

```bash
# Using Vivado
vivado -mode batch -source vivado/create_project.tcl
vivado -mode batch -source vivado/run_sim.tcl

# Using batch script
scripts\run_simulation.bat
```

### 9. Waveform Debug

VCD waveforms are dumped to:
- `tb_streaming_conv.vcd` (Stage 1)
- `tb_sobel_edge.vcd` (Stage 2)

Open in Vivado waveform viewer or GTKWave for signal-level debugging.

### 10. Known Limitations

- Testbench stores full image in registers (acceptable for verification, not synthesis)
- window_valid signal timing: goes high before shift registers have valid data
  (does not affect correctness — convolution output only checked after pipeline fills)
- Boundary behavior: valid-region-only (no padded output for edge pixels)
