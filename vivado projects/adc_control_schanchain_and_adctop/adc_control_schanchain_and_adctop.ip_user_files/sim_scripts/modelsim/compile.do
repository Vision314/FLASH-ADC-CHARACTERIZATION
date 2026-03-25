vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/fifo_generator_v13_2_14
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap fifo_generator_v13_2_14 modelsim_lib/msim/fifo_generator_v13_2_14
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm -64 -incr -mfcu  -sv "+incdir+../../../../../../../Xilinix/2025.2/data/rsb/busdef" "+incdir+../../ipstatic" \
"/home/frankie/Xilinix/2025.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/frankie/Xilinix/2025.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93  \
"/home/frankie/Xilinix/2025.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work fifo_generator_v13_2_14 -64 -incr -mfcu  "+incdir+../../../../../../../Xilinix/2025.2/data/rsb/busdef" "+incdir+../../ipstatic" \
"../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_14 -64 -93  \
"../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_14 -64 -incr -mfcu  "+incdir+../../../../../../../Xilinix/2025.2/data/rsb/busdef" "+incdir+../../ipstatic" \
"../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../../../../../Xilinix/2025.2/data/rsb/busdef" "+incdir+../../ipstatic" \
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

