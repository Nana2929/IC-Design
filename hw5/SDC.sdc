# create_clock -name {clk} -period 8 -waveform {0.000 4} { clk }
create_clock -name {clk} -period 32 -waveform {0.000 16} { clk }
set_input_delay -clock clk 1 [get_ports P*]
set_input_delay -clock clk 1 [get_ports K*]
set_input_delay -clock clk 1 [get_ports rst*]
set_output_delay -clock clk 1 [get_ports C*]
set_output_delay -clock clk 1 [get_ports valid*]