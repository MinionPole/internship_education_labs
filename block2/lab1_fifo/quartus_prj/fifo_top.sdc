set_time_format -unit ns -decimal_places 3

create_clock -name {clk_150} -period 6.670 -waveform { 0.000 3.335 } [get_ports {clk_150mhz}]

derive_clock_uncertainty