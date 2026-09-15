## Clock constraint - 50 MHz (20 ns period) - relaxed for small design
create_clock -period 20.000 -name clk -waveform {0.000 10.000} [get_ports clk]

## Input delay (relative to clock)
set_input_delay -clock clk -max 2.000 [get_ports {pixel_valid pixel_in[*]}]
set_input_delay -clock clk -min 0.000 [get_ports {pixel_valid pixel_in[*]}]

## Output delay (relative to clock)
set_output_delay -clock clk -max 2.000 [get_ports {pixel_out[*] pixel_valid_out}]
set_output_delay -clock clk -min 0.000 [get_ports {pixel_out[*] pixel_valid_out}]
