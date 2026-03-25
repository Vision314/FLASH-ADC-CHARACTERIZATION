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

vlog -work xpm  -incr "+incdir+../../../../../../../Xilinix/2025.2/data/rsb/busdef" "+incdir+../../ipstatic" -l xpm -l fifo_generator_v13_2_14 -l xil_defaultlib \
"/home/frankie/Xilinix/2025.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/frankie/Xilinix/2025.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"/home/frankie/Xilinix/2025.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work fifo_generator_v13_2_14  -incr -v2k5 "+incdir+../../../../../../../Xilinix/2025.2/data/rsb/busdef" "+incdir+../../ipstatic" -l xpm -l fifo_generator_v13_2_14 -l xil_defaultlib \
"../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_14 -93  -incr \
"../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_14  -incr -v2k5 "+incdir+../../../../../../../Xilinix/2025.2/data/rsb/busdef" "+incdir+../../ipstatic" -l xpm -l fifo_generator_v13_2_14 -l xil_defaultlib \
"../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../../../../Xilinix/2025.2/data/rsb/busdef" "+incdir+../../ipstatic" -l xpm -l fifo_generator_v13_2_14 -l xil_defaultlib \
"../../../adc_control_schanchain_and_adctop.gen/sources_1/ip/tx_fifo/sim/tx_fifo.v" \
"../../../adc_control_schanchain_and_adctop.gen/sources_1/ip/clk_wiz_base/clk_wiz_base_clk_wiz.v" \
"../../../adc_control_schanchain_and_adctop.gen/sources_1/ip/clk_wiz_base/clk_wiz_base.v" \
"../../../adc_control_schanchain_and_adctop.srcs/sources_1/imports/new/adc_control.v" \
"../../../adc_control_schanchain_and_adctop.srcs/sources_1/imports/new/baud_match.v" \
"../../../adc_control_schanchain_and_adctop.srcs/sources_1/new/debouncer.v" \
"../../../adc_control_schanchain_and_adctop.srcs/sources_1/imports/new/rx.v" \
"../../../adc_control_schanchain_and_adctop.srcs/sources_1/new/scan_chain_control.v" \
"../../../adc_control_schanchain_and_adctop.srcs/sources_1/imports/new/tx.v" \
"../../../adc_control_schanchain_and_adctop.srcs/sources_1/imports/new/top_v3.v" \

vlog -work xil_defaultlib \
"glbl.v"

