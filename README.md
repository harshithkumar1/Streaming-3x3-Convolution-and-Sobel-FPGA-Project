# Streaming 3x3 Convolution and Sobel Edge Detection

## Project Structure

```
├── Stage1/                    ← Window Generator (no math)
│   ├── rtl/
│   │   ├── line_buffer.sv
│   │   ├── shift_registers.sv
│   │   ├── window_3x3.sv
│   │   └── streaming_window_top.sv
│   ├── tb/
│   │   └── tb_window_gen.sv
│   └── vivado/
│       ├── create_project.tcl
│       └── run_sim.tcl
│
├── Stage2/                    ← Sobel Edge Detection (full project)
│   ├── rtl/
│   ├── tb/
│   ├── vivado/
│   ├── matlab/
│   └── docs/
│
└── README.md
```

## Stage 1: Window Generator
**What it does:** Creates a 3x3 pixel grid from streaming input. No math.

**To run:**
```tcl
cd Stage1/vivado
source create_project.tcl
source run_sim.tcl
```

## Stage 2: Sobel Edge Detection
**What it does:** Takes the 3x3 grid and finds edges using Sobel operator.

**To run:**
```tcl
cd Stage2/vivado
source create_project.tcl
source run_sim.tcl
```

## Results

| Stage | Tests | Status |
|-------|-------|--------|
| Stage 1 | 3/3 PASS | ✅ |
| Stage 2 | 9/9 PASS | ✅ |
