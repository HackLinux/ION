# assumed to run from /<project directory>/sim/modelsim
# change the path to the libraries in the vmap commands to match your setup
# some unused modules' vcom calls have been commented out
vlib work

vcom -reportprogress 300 -work work ../../../src/rtl/common/ion_main_pkg.vhdl
vcom -reportprogress 300 -work work ../../../src/rtl/cpu/ion_shifter.vhdl
vcom -reportprogress 300 -work work ../../../src/rtl/cpu/ion_alu.vhdl
vcom -reportprogress 300 -work work ../../../src/rtl/cpu/ion_muldiv.vhdl
vcom -reportprogress 300 -work work ../../../src/rtl/cpu/ion_cop0.vhdl
vcom -reportprogress 300 -work work ../../../src/rtl/cpu/ion_cpu.vhdl

vcom -reportprogress 300 -work work ../../../src/testbench/txt_util.vhdl
vcom -reportprogress 300 -work work ../../../src/testbench/ion_tb_pkg.vhdl
#vlog -reportprogress 300 -work work ../../../src/testbench/models/mt48lc4m16a2.v
vcom -reportprogress 300 -work work ../../../src/testbench/sim_params_pkg.vhdl
vcom -reportprogress 300 -work work ../../../src/testbench/ion_cpu_tb.vhdl

vsim -t ps work.ion_cpu_tb(testbench)
do ./ion_cpu_tb_wave.do
set PrefMain(font) {Courier 9 roman normal}

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

run 150 us
