// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.2 (lin64) Build 6299465 Fri Nov 14 12:34:56 MST 2025
// Date        : Sun Mar  1 22:09:05 2026
// Host        : rocco running 64-bit Ubuntu 24.04.3 LTS
// Command     : write_verilog -force -mode funcsim {/home/frankie/WCIS/WCIS-CMODA7-Control-Board/sw/vivado
//               projects/adc_operation_v2/adc_operation_v2.gen/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0_sim_netlist.v}
// Design      : blk_mem_gen_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_0,blk_mem_gen_v8_4_12,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_12,Vivado 2025.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_0
   (clka,
    ena,
    wea,
    addra,
    dina,
    clkb,
    enb,
    addrb,
    doutb);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_mode = "slave BRAM_PORTA" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [11:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [7:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_mode = "slave BRAM_PORTB" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [11:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [7:0]doutb;

  wire [11:0]addra;
  wire [11:0]addrb;
  wire clka;
  wire clkb;
  wire [7:0]dina;
  wire [7:0]doutb;
  wire ena;
  wire enb;
  wire [0:0]wea;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [7:0]NLW_U0_douta_UNCONNECTED;
  wire [11:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [11:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [7:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "12" *) 
  (* C_ADDRB_WIDTH = "12" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "0" *) 
  (* C_COUNT_36K_BRAM = "1" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     5.045775 mW" *) 
  (* C_FAMILY = "artix7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "1" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "1" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "blk_mem_gen_0.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "1" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "4096" *) 
  (* C_READ_DEPTH_B = "4096" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "8" *) 
  (* C_READ_WIDTH_B = "8" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "4096" *) 
  (* C_WRITE_DEPTH_B = "4096" *) 
  (* C_WRITE_MODE_A = "READ_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "8" *) 
  (* C_WRITE_WIDTH_B = "8" *) 
  (* C_XDEVICEFAMILY = "artix7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_0_blk_mem_gen_v8_4_12 U0
       (.addra(addra),
        .addrb(addrb),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(NLW_U0_douta_UNCONNECTED[7:0]),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(enb),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[11:0]),
        .regcea(1'b1),
        .regceb(1'b1),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[11:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[7:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2025.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
YqH9kwIC39+qbZg4PSfFsXuB9k9wnuxNryS/CfnEri6Ci9fSC6fsrQ/T/hnt3u/yolbJ8DJa1Qu6
Qnm24A9jLbA+fu3Nsmm6/rM6a4vU6OfVl/gTFd/CiWDutv6Dhn6Lim4uUNPahoOR/A2Yc4Zo2tdI
kMLO9gn9WlH2l3O2oXs=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
XJYO2VHd/cnMxQd3i7/2qRhl57dl+doEKuhAunQyv3vpGRG/jlNxj8PqrgLoF0HMdqE3qJUVE/oq
kBSapqjVjLDMOrNGQ+Tc6VGsKMZH8FE/TXHQJ/IM5Iuiu2eozEwwVUomF+7cfqn+9OsVsqCONQ1M
g0oRlangiqasJDhhMfnlGGqwAwmgWRGQA6dmhTuua1s8zdvIv540zY6p5au8cAKVhqyyKK7wbxEE
SGuFqX+NYoyRV+rfWCcWM+hJEmnWS8LNAKkd13YE2+17sPYzUdZ23DmTxXK6KlAxKFW27CBySUfg
qdNXp2DSs2KAQYih27pBNMuHfGbM/ATFPWFvxg==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
lYoEi/e8HsDTz6N11EDe/B/iitERmeYndlCklmCluwgb0N4W80JUGVlkd7NlRZHRNhxaNBJPkcjC
n61nO0tb17NwsMwjbY5TF8JWRYTNw1JXCFacvQYrdKv4/7QNQEtwVGiCLxFhOA8aHlWMZIrc2fri
VRMVWaEBcPwCGorlVIM=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
QEw9fEsWFbdX0OQLvYs/gl+zyEOW3ak9TdQVaq+0AXXOT3LIqF7wDxJ6ZBnlf9mNbdsUVH5tAz1o
H8u7ihJl1L3THEvugW+TS8hkvVbEA9rKO2vV15KAj4Lla7UdFT/xDfe79RFarlLI7yGrubjgdoRi
QWy//UKsffG7IWNwmoSuppWiWB4ZHJtkunNyIkm70JPGyZF62VxJg1MTT+5LUbZG5vZjjuHZud9w
xJaKv1tFP/x8RVqLU5gPOqGqTW7/nKO2S+450Vo4D9vAmBVVcXpaL1EbSmCvQ+qJmcQKtf9qYFRV
Zko08hbpHjPxstqvTDro01jRzB8592m4xU2TWA==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
TC7q853CWBPPJgbRfgDV1lmjUwSAtliljShAyNFg8sfRfwDzchthzoSPH1UCHV++E2JXacEKq1lB
UWsNP92U4Xh0/Gu+6esOI0pJb8I+TRTxyBN1I4cRQEfQHcwfhbSdeH3yX9OV3opLEqYmT37hWU+J
zCawYnxVESI0FtRzEXve9gdEWlrKKckrT/hp4mvxxOjvOkOSQBvy0elgUOqh6mEOZl+JnUbsR+Wm
CoZLE1eefMZy3FnVmyDNPv3JPXi88aLXMyimal0MYFkTiS4XJiGT3eAIMIbksehXY+eYi/KFpZWQ
GHpX+lG3UmiWWLwyPakFwKEHbrBc70AlJ2eV9g==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2025.1-2029.x", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
j9nmCKgjPWNChPbpSW6EWLrMA6oCG2JGPoum8px09v0PEAh0DRXZi0J8HPzXUsZgOEMcKpA7X54u
YFcDDCLAQ+urha/eSPbQYHQh4yGCursxAQ1C6LEyNQ2wJ0eLlO2bJeAl/gof06zqsYVM2lLJVNv5
wao1k2bmgPdfpfY3c9vPD0fSMuZPS41EoRS0cQhO5GTZnKdjxm6tEUL3GnTjB8ynSCIbCJUsMtAX
4FRHNa52gudx5B5fagR+lXgFhE7e++rWTJELr7SYB+r5Es8qZLTpCH8TrQxEkV0rY/+e4sAjNE2D
gHw8GD7VcUtc15B8y1BbVmh29qc8Nd3V2i/miA==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
UkCD6I/Vye4qNoNoa3hIexBXG3xyKUJPAHAjIo7UcNVCDXpMQiYEtPDqExZMfiPlJn2nswCYIfIJ
FYWqMCloKSQyyI/7yZ2EtbyWEklb/P5IyZyvGi6hhFUo/JFTb12b4bK0gZPr+bCDdlVQKTx5GVHz
wptdUJO2omSj8axVMPbLRRtVzlJIZ29dTJ2ATXVXAcBxPnFfHRAMnYYKLeeLExX61vQvpqrkLQHm
XG7hpVzJi56gYKAzxa2BLq072OCVpVS70bfWlhlSTVcSlCrUf+EcarEk4FD8+Ih2NCvrqremG6yn
TtcBn8Xr8M/6zhOYvLi6AD6eArDMKA8n+Ccv8A==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
A5y5QVZU8yjPexRVPioSiAGohCHD5DX5FVobuMyhcgQRExLUhPvnnS8HOtxTj/2IapEcz68gFMGG
Hpi+m725u85/om/Vze9pGIW9Mn328Kz2FIg3W5EvGstfGwY+48LiAGAmTR269JS4lJGVYWYOz7Xk
S8cEsFd2m7j8iyKtARJzD90+UdXq/cIIh725jC9i8nbgxB364zddvm1Z/DF3JRw1qFp6GGcuRai1
KNcJ1j8c9wtIgktpsteU3e5+bxHEw8NT3gWXUFYjm00NDq97Jals8Jjktmum2nQxoF7ivPacfEey
gnSF6jRMkTsZObzc30hAhs0CEtc33hZLhPLHSn8pQ0WyvKJLHdd5s2yckgTZtqxC1Sbwe7WEgNXe
ZMX3pIkz+aoXsAL7GBLyVBMVQcyMoF0w8QGAaTe8sqatABwPqXidYRqNROTf62IYcMpV89XYgaTv
EwIn/oni9KOFd2BFVxRZbFGGC4IjvigsTBUijI+Dk6kVnDh240clGcc4

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Omtp+lCaqUx7Z4qdFj2zrN8LpCkit2eX4hlMtig+ielGm/x4FSZkpjoFmiqdKFPi2eg0pg09MSai
XyGH68UzAR7Xrj8f1jlIoUmMKp4GcxfdqfTeuu7kWGOJEP6cvgTjSJFj2gawDv7f4yZcltnK2x0L
e4GW/rBTmGvZtKWb2ahjINLxPuh3dDaSaWdb+zVgbtyrI5FrjxBkq+aOxSjyNsqnCx1L0uWbxnkl
88NbXN3dTaECXHNm/fsleayM5hKis7kTv9BFajJMGy+BhQlmIYpE+F5zchnTTFUFJZCz1sX9Fc8e
HcY7irB8mR3ajdzjUZLBQEMktp096Nheq3U75A==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
hpeBLwN9x2ZFDwroYLlUe5GjjDepHik2l0c2s3/6S7JPCRkzQSyt2V1Ad/JewAs/QNp5SXSbYYB4
rQl0My1LDMF3xw43r0g2IbcyHVpPhGp0W5msuQdF67afnsRv90iJYWLMI3QkYGCTWAzl4HrLxFSg
3z8XZRK670IcxznOrlvgHmIKsvubZrBkuc1EynrVb9Nw16QnIx2rc4WgcEXeFf+4i1RoYLDd3gXK
NFCNMdtaRYUThunFP6Z4ViZ5UnDmKq+IMhd31jTaqIlWOBDxPI1+v5RJYxIyTbn4rxlKR2fNbl5/
z4OUjBTd+1GH3I2OXlqmAOvIhpe2Z2HH7nZu/A==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Mt2RhTSUwEIEWeNARbyL+EdfS1UF6nPaL/fKl/7oO2gina93egwCWDLl1fbBtkfaPco0cu4MJ9K3
OraAsyHRlY+MNShmJ1LzAIA1LjZx4y55lu9dlQqSUXR7AW7wVbkg1864mK+hM/1XygU0jvebKNW9
B7xSER+asLO6pxi0mt7uC2PHxLPAYEszFhmnap82TtbDGdQ2qtyekY+ngs+N2fAdsblxVwJruiMl
e6XJ127M8N1mYwhWU2HtRpBOSnnKoHgD9fG51XK/rhk8DxT66QnX9uLPB+H25eDupBJGi1Y5o6x8
hOwZiSUVlBLh7brfzevh7+eRn+7es6wBas0+3w==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 27440)
`pragma protect data_block
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
N+PRCxuSxhFltZvcg/P4Rcn93eH4HWE=
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
