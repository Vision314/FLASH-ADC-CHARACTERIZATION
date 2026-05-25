


## =========================================================
## Cmod A7 Rev. B - Cleaned Constraint File
## =========================================================
## - Uses same pins and signal names
## - LVCMOS33 set globally
## - Organized by functional blocks
## =========================================================


## =========================================================
## Default I/O Standard
## =========================================================
set_property IOSTANDARD LVCMOS33 [get_ports *]


## =========================================================
## Clock (12 MHz)
## =========================================================
set_property PACKAGE_PIN L17 [get_ports sysclk]    ; # IO_L12P_T1_MRCC_14 Sch=gclk
create_clock -name sys_clk_pin -period 83.333 [get_ports sysclk]


## =========================================================
## LEDs
## =========================================================
set_property PACKAGE_PIN A17 [get_ports {led[0]}]  ; # IO_L12N_T1_MRCC_16
set_property PACKAGE_PIN C16 [get_ports {led[1]}]  ; # IO_L13P_T2_MRCC_16

set_property PACKAGE_PIN B17 [get_ports LEDB]      ; # IO_L14N_T2_SRCC_16
set_property PACKAGE_PIN B16 [get_ports LEDG]      ; # IO_L13N_T2_MRCC_16
set_property PACKAGE_PIN C17 [get_ports LEDR]      ; # IO_L14P_T2_SRCC_16


## =========================================================
## Buttons
## =========================================================
set_property PACKAGE_PIN A18 [get_ports btn0]      ; # IO_L19N_T3_VREF_16
 set_property PACKAGE_PIN B18 [get_ports {btn1}] ; # IO_L19P_T3_16


## =========================================================
## UART
## =========================================================
set_property PACKAGE_PIN J18 [get_ports Tx]        ; # IO_L7N_T1_D10_14
set_property PACKAGE_PIN J17 [get_ports Rx]        ; # IO_L7P_T1_D09_14


## =========================================================
## ADC Control
## =========================================================
set_property PACKAGE_PIN W5 [get_ports ADC_ENC]        ; # PIO36
set_property PACKAGE_PIN V3 [get_ports ADC_SH]         ; # PIO35
set_property PACKAGE_PIN W3 [get_ports ADC_PRE]        ; # PIO34
set_property PACKAGE_PIN V2 [get_ports ADC_CLK]        ; # PIO33
set_property PACKAGE_PIN W2 [get_ports ADC_TEST_EN]    ; # PIO32

set_property PACKAGE_PIN M3 [get_ports DOUT_TOP]       ; # PIO01
set_property PACKAGE_PIN K2 [get_ports DOUT_BOT]       ; # PIO12


## =========================================================
## ROW / COL Address Bus
## =========================================================
set_property PACKAGE_PIN L3  [get_ports {ROW_COL_ADDR[0]}] ; # PIO02
set_property PACKAGE_PIN A16 [get_ports {ROW_COL_ADDR[1]}] ; # PIO03
set_property PACKAGE_PIN K3  [get_ports {ROW_COL_ADDR[2]}] ; # PIO04
set_property PACKAGE_PIN C15 [get_ports {ROW_COL_ADDR[3]}] ; # PIO05
set_property PACKAGE_PIN H1  [get_ports {ROW_COL_ADDR[4]}] ; # PIO06
set_property PACKAGE_PIN A15 [get_ports {ROW_COL_ADDR[5]}] ; # PIO07
set_property PACKAGE_PIN B15 [get_ports {ROW_COL_ADDR[6]}] ; # PIO08
set_property PACKAGE_PIN A14 [get_ports {ROW_COL_ADDR[7]}] ; # PIO09

set_property PACKAGE_PIN J3 [get_ports COL_EN]          ; # PIO10
set_property PACKAGE_PIN J1 [get_ports VLN_EN]          ; # PIO11
set_property PACKAGE_PIN L1 [get_ports SHS_EN]          ; # PIO13
set_property PACKAGE_PIN L2 [get_ports SHR_EN]          ; # PIO14
# set_property PACKAGE_PIN ? [get_ports V_BYPASS_OUT_TOP]
# set_property PACKAGE_PIN ? [get_ports V_BYPASS_OUT_BOT]


## =========================================================
## Scan Chain
## =========================================================
set_property PACKAGE_PIN M1 [get_ports SCAN_IN]     ; # PIO17
set_property PACKAGE_PIN N3 [get_ports SCAN_CLK]    ; # PIO18
set_property PACKAGE_PIN P3 [get_ports SCAN_RSTB]   ; # PIO19
set_property PACKAGE_PIN M2 [get_ports SCAN_OUT]    ; # PIO20
set_property PACKAGE_PIN N1 [get_ports SCAN_SEL]    ; # PIO21

set_property PACKAGE_PIN N2 [get_ports CLAMP_EN]    ; # PIO22
set_property PACKAGE_PIN P1 [get_ports PWR_EN]      ; # PIO23

set_property PACKAGE_PIN T3 [get_ports ROLL_SEL]    ; # PIO27
set_property PACKAGE_PIN R3 [get_ports ROLL_CLK]    ; # PIO26


## =========================================================
## SERDES / SPI / External ADC
## =========================================================
set_property PACKAGE_PIN R2 [get_ports DATA_LOAD]       ; # PIO28
set_property PACKAGE_PIN T1 [get_ports DATA_SCLK]       ; # PIO29

set_property PACKAGE_PIN T2 [get_ports EXT_ADC_CONV_2]  ; # PIO30
set_property PACKAGE_PIN U1 [get_ports SPI_CLK_ADC_2]   ; # PIO31

set_property PACKAGE_PIN V4 [get_ports TEST_EN]         ; # PIO37

set_property PACKAGE_PIN U4 [get_ports ROW_RST_EN]      ; # PIO38
set_property PACKAGE_PIN V5 [get_ports ROW_SEL_EN]      ; # PIO39
set_property PACKAGE_PIN W4 [get_ports ADDR_LATCH]      ; # PIO40

set_property PACKAGE_PIN W6 [get_ports DAC_CS_2]        ; # PIO43
set_property PACKAGE_PIN U3 [get_ports DAC_IO_2]        ; # PIO44

set_property PACKAGE_PIN U8 [get_ports EXT_ADC_CONV]    ; # PIO47
set_property PACKAGE_PIN V8 [get_ports EXT_ADC_DATA]    ; # PIO48


## =========================================================
## Additional SPI / DAC
## =========================================================
set_property PACKAGE_PIN U7 [get_ports DAC_CS]      ; # PIO45
set_property PACKAGE_PIN W7 [get_ports DAC_SDO]     ; # PIO46

set_property PACKAGE_PIN W6 [get_ports DAC_CS_2]      ; # PIO43
#set_property PACKAGE_PIN U3 [get_ports DAC_SDO]     ; # PIO44

set_property PACKAGE_PIN U5 [get_ports SPI_SCLK]    ; # PIO41
set_property PACKAGE_PIN U2 [get_ports DAC_SDI]     ; # PIO42
















### This file is a general .xdc for the CmodA7 rev. B
### To use it in a project:
### - uncomment the lines corresponding to used pins
### - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal 12 MHz
#set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { sysclk }]; #IO_L12P_T1_MRCC_14 Sch=gclk
#create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {sysclk}];


### LEDs
#set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; #IO_L12N_T1_MRCC_16 Sch=led[1]
#set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; #IO_L13P_T2_MRCC_16 Sch=led[2]

#set_property -dict { PACKAGE_PIN B17   IOSTANDARD LVCMOS33 } [get_ports { LEDB }]; #IO_L14N_T2_SRCC_16 Sch=led0_b
#set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports { LEDG }]; #IO_L13N_T2_MRCC_16 Sch=led0_g
#set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { LEDR }]; #IO_L14P_T2_SRCC_16 Sch=led0_r


## Buttons
#set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { btn0 }]; #IO_L19N_T3_VREF_16 Sch=btn[0]
##set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; #IO_L19P_T3_16 Sch=btn[1]

## UART
#set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { Tx }]; #IO_L7N_T1_D10_14 Sch=uart_rxd_out
#set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { Rx  }]; #IO_L7P_T1_D09_14 Sch=uart_txd_in




#set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports { ADC_ENC  }];       # PIO36
#set_property -dict { PACKAGE_PIN V3   IOSTANDARD LVCMOS33 } [get_ports { ADC_SH  }];        # PIO35
#set_property -dict { PACKAGE_PIN W3   IOSTANDARD LVCMOS33 } [get_ports { ADC_PRE  }];       # PIO34
#set_property -dict { PACKAGE_PIN V2   IOSTANDARD LVCMOS33 } [get_ports { ADC_CLK }];        # PIO33
#set_property -dict { PACKAGE_PIN W2   IOSTANDARD LVCMOS33 } [get_ports { ADC_TEST_EN }];    # PIO32

#set_property -dict { PACKAGE_PIN M3    IOSTANDARD LVCMOS33 } [get_ports { DOUT_TOP }];      # PIO01
#set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { DOUT_BOT }];      # PIO12





## ROW/COL ADDR 0->7
#set_property -dict { PACKAGE_PIN L3     IOSTANDARD LVCMOS33 } [get_ports { ROW_COL_ADDR[0] }];    # PIO02
#set_property -dict { PACKAGE_PIN A16    IOSTANDARD LVCMOS33 } [get_ports { ROW_COL_ADDR[1]}];     # PIO03
#set_property -dict { PACKAGE_PIN K3     IOSTANDARD LVCMOS33 } [get_ports { ROW_COL_ADDR[2]}];     # PIO04
#set_property -dict { PACKAGE_PIN C15    IOSTANDARD LVCMOS33 } [get_ports { ROW_COL_ADDR[3]}];     # PIO05
#set_property -dict { PACKAGE_PIN H1     IOSTANDARD LVCMOS33 } [get_ports { ROW_COL_ADDR[4]}];     # PIO06
#set_property -dict { PACKAGE_PIN A15    IOSTANDARD LVCMOS33 } [get_ports { ROW_COL_ADDR[5]}];     # PIO07
#set_property -dict { PACKAGE_PIN B15    IOSTANDARD LVCMOS33 } [get_ports { ROW_COL_ADDR[6]}];     # PIO08
#set_property -dict { PACKAGE_PIN A14    IOSTANDARD LVCMOS33 } [get_ports { ROW_COL_ADDR[7]}];     # PIO09

#set_property -dict { PACKAGE_PIN J3    IOSTANDARD LVCMOS33 } [get_ports { COL_EN }];     # PIO10
#set_property -dict { PACKAGE_PIN J1    IOSTANDARD LVCMOS33 } [get_ports { VLN_EN }];     # PIO11
#set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports { SHS_EN }];     # PIO13
#set_property -dict { PACKAGE_PIN L2    IOSTANDARD LVCMOS33 } [get_ports { SHR_EN }];     # PIO14
##set_property -dict { PACKAGE_PIN     IOSTANDARD LVCMOS33 } [get_ports { V_BYPASS_OUT_TOP }];     # AIN15
##set_property -dict { PACKAGE_PIN     IOSTANDARD LVCMOS33 } [get_ports { V_BYPASS_OUT_BOT }];     # AIN16

## SCAN CHAIN
#set_property -dict { PACKAGE_PIN M1    IOSTANDARD LVCMOS33 } [get_ports { SCAN_IN }];     # PIO17
#set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33 } [get_ports { SCAN_CLK }];     # PIO18
#set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 } [get_ports { SCAN_RSTB }];     # PIO19
#set_property -dict { PACKAGE_PIN M2    IOSTANDARD LVCMOS33 } [get_ports { SCAN_OUT }];      # PIO20
#set_property -dict { PACKAGE_PIN N1    IOSTANDARD LVCMOS33 } [get_ports { SCAN_SEL }];      # PIO21

#set_property -dict { PACKAGE_PIN N2    IOSTANDARD LVCMOS33 } [get_ports { CLAMP_EN }];      # PIO22
#set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports { PWR_EN }];        # PIO23


#set_property -dict { PACKAGE_PIN T3    IOSTANDARD LVCMOS33 } [get_ports { ROLL_SEL }];      # PIO27
#set_property -dict { PACKAGE_PIN R3    IOSTANDARD LVCMOS33 } [get_ports { ROLL_CLK }];      # PIO26

## SERDES
#set_property -dict { PACKAGE_PIN R2    IOSTANDARD LVCMOS33 } [get_ports { DATA_LOAD }];         # PIO28
#set_property -dict { PACKAGE_PIN T1    IOSTANDARD LVCMOS33 } [get_ports { DATA_SCLK }];         # PIO29

#set_property -dict { PACKAGE_PIN T2    IOSTANDARD LVCMOS33 } [get_ports { EXT_ADC_CONV_2 }];      # PIO30
#set_property -dict { PACKAGE_PIN U1    IOSTANDARD LVCMOS33 } [get_ports { SPI_CLK_ADC_2 }];       # PIO31
##set_property -dict { PACKAGE_PIN     IOSTANDARD LVCMOS33 } [get_ports {  }];        # PIO32
##set_property -dict { PACKAGE_PIN     IOSTANDARD LVCMOS33 } [get_ports {  }];        # PIO33
##set_property -dict { PACKAGE_PIN     IOSTANDARD LVCMOS33 } [get_ports {  }];        # PIO34
##set_property -dict { PACKAGE_PIN     IOSTANDARD LVCMOS33 } [get_ports {  }];        # PIO35
##set_property -dict { PACKAGE_PIN     IOSTANDARD LVCMOS33 } [get_ports {  }];        # PIO36
#set_property -dict { PACKAGE_PIN V4    IOSTANDARD LVCMOS33 } [get_ports { TEST_EN }];             # PIO37

#set_property -dict { PACKAGE_PIN U4    IOSTANDARD LVCMOS33 } [get_ports { ROW_RST_EN }];          # PIO38
#set_property -dict { PACKAGE_PIN V5    IOSTANDARD LVCMOS33 } [get_ports { ROW_SEL_EN }];          # PIO39
#set_property -dict { PACKAGE_PIN W4    IOSTANDARD LVCMOS33 } [get_ports { ADDR_LATCH }];          # PIO40

##set_property -dict { PACKAGE_PIN U5    IOSTANDARD LVCMOS33 } [get_ports { SPI_CLK }];             # PIO41
##set_property -dict { PACKAGE_PIN U2    IOSTANDARD LVCMOS33 } [get_ports { DAC_SDI }];             # PIO42
#set_property -dict { PACKAGE_PIN W6    IOSTANDARD LVCMOS33 } [get_ports { DAC_CS_2 }];            # PIO43
#set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports { DAC_IO_2 }];            # PIO44
##set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33 } [get_ports { DAC_CS_1 }];            # PIO45
##set_property -dict { PACKAGE_PIN W7    IOSTANDARD LVCMOS33 } [get_ports { DAC_IO_1 }];            # PIO46
#set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS33 } [get_ports { EXT_ADC_CONV }];        # PIO47
#set_property -dict { PACKAGE_PIN V8    IOSTANDARD LVCMOS33 } [get_ports { EXT_ADC_DATA }];        # PIO48



#set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33 } [get_ports { DAC_CS }];            # PIO45
#set_property -dict { PACKAGE_PIN W7    IOSTANDARD LVCMOS33 } [get_ports { DAC_SDO }];            # PIO46

#set_property -dict { PACKAGE_PIN U5    IOSTANDARD LVCMOS33 } [get_ports { SPI_SCLK }];             # PIO41
#set_property -dict { PACKAGE_PIN U2    IOSTANDARD LVCMOS33 } [get_ports { DAC_SDI }];             # PIO42







