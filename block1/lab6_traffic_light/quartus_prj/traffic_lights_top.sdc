set_time_format -unit ns -decimal_places 3

create_clock -name {clk_2000} -period 500 -waveform { 0.000 1.000 } [get_ports {clk_2000hz}]

derive_clock_uncertainty