transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/fifo_generator_v13_2_14
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap fifo_generator_v13_2_14 riviera/fifo_generator_v13_2_14
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../../../../../../../../Xilinix/2025.2/data/rsb/busdef" -l xpm -l fifo_generator_v13_2_14 -l xil_defaultlib \
"/home/frankie/Xilinix/2025.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/frankie/Xilinix/2025.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"/home/frankie/Xilinix/2025.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work fifo_generator_v13_2_14  -incr -v2k5 "+incdir+../../../../../../../../../../Xilinix/2025.2/data/rsb/busdef" -l xpm -l fifo_generator_v13_2_14 -l xil_defaultlib \
"../../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_14 -93  -incr \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_14  -incr -v2k5 "+incdir+../../../../../../../../../../Xilinix/2025.2/data/rsb/busdef" -l xpm -l fifo_generator_v13_2_14 -l xil_defaultlib \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../../../../../../../Xilinix/2025.2/data/rsb/busdef" -l xpm -l fifo_generator_v13_2_14 -l xil_defaultlib \
"../../../../updated_adc_operation_and_dac_works_frankie.gen/sources_1/ip/rx_fifo/sim/rx_fifo.v" \

vlog -work xil_defaultlib \
"glbl.v"

