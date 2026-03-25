// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2 (lin64) Build 6299465 Fri Nov 14 12:34:56 MST 2025
// Date        : Mon Mar 23 12:03:45 2026
// Host        : rocco running 64-bit Ubuntu 24.04.4 LTS
// Command     : write_verilog -force -mode synth_stub {/home/frankie/WCIS/FLASH-ADC-CHARACTERIZATION/vivado
//               projects/adc_control_schanchain_and_adctop/adc_control_schanchain_and_adctop.gen/sources_1/ip/clk_wiz_500k/clk_wiz_500k_stub.v}
// Design      : clk_wiz_500k
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CORE_GENERATION_INFO = "clk_wiz_500k,clk_wiz_v6_0_17_0_0,{component_name=clk_wiz_500k,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,enable_axi=0,feedback_source=FDBK_AUTO,PRIMITIVE=MMCM,num_out_clk=7,clkin1_period=10.000,clkin2_period=10.000,use_power_down=true,use_reset=true,use_locked=true,use_inclk_stopped=false,feedback_type=SINGLE,CLOCK_MGR_TYPE=NA,manual_override=false}" *) 
module clk_wiz_500k(clk_out500k, clk_out1M, clk_out2M, clk_out3M, 
  clk_out4M, clk_out5M, clk_out6M, reset, power_down, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="reset,power_down,locked,clk_in1" */
/* synthesis syn_force_seq_prim="clk_out500k" */
/* synthesis syn_force_seq_prim="clk_out1M" */
/* synthesis syn_force_seq_prim="clk_out2M" */
/* synthesis syn_force_seq_prim="clk_out3M" */
/* synthesis syn_force_seq_prim="clk_out4M" */
/* synthesis syn_force_seq_prim="clk_out5M" */
/* synthesis syn_force_seq_prim="clk_out6M" */;
  output clk_out500k /* synthesis syn_isclock = 1 */;
  output clk_out1M /* synthesis syn_isclock = 1 */;
  output clk_out2M /* synthesis syn_isclock = 1 */;
  output clk_out3M /* synthesis syn_isclock = 1 */;
  output clk_out4M /* synthesis syn_isclock = 1 */;
  output clk_out5M /* synthesis syn_isclock = 1 */;
  output clk_out6M /* synthesis syn_isclock = 1 */;
  input reset;
  input power_down;
  output locked;
  input clk_in1;
endmodule
