## basys3_central.xdc - Central de alarme 4 zonas - Basys 3 (XC7A35T-1CPG236C)
## Os nomes das portas sao os mesmos no Block Design e no top_central.vhd.
## Todos os GPIOs sao 3,3 V. Sinais de 5 V (ECHO do HC-SR04) passam por divisor.

## ---------------- Clock 100 MHz ----------------
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## ---------------- Chaves ----------------
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]
set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS33 } [get_ports {sw[4]}]
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports {sw[5]}]
set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports {sw[6]}]
set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports {sw[7]}]
set_property -dict { PACKAGE_PIN V2  IOSTANDARD LVCMOS33 } [get_ports {sw[8]}]
set_property -dict { PACKAGE_PIN T3  IOSTANDARD LVCMOS33 } [get_ports {sw[9]}]
set_property -dict { PACKAGE_PIN T2  IOSTANDARD LVCMOS33 } [get_ports {sw[10]}]
set_property -dict { PACKAGE_PIN R3  IOSTANDARD LVCMOS33 } [get_ports {sw[11]}]
set_property -dict { PACKAGE_PIN W2  IOSTANDARD LVCMOS33 } [get_ports {sw[12]}]
set_property -dict { PACKAGE_PIN U1  IOSTANDARD LVCMOS33 } [get_ports {sw[13]}]
set_property -dict { PACKAGE_PIN T1  IOSTANDARD LVCMOS33 } [get_ports {sw[14]}]
set_property -dict { PACKAGE_PIN R2  IOSTANDARD LVCMOS33 } [get_ports {sw[15]}]

## ---------------- LEDs ----------------
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {led[7]}]
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {led[8]}]
set_property -dict { PACKAGE_PIN V3  IOSTANDARD LVCMOS33 } [get_ports {led[9]}]
set_property -dict { PACKAGE_PIN W3  IOSTANDARD LVCMOS33 } [get_ports {led[10]}]
set_property -dict { PACKAGE_PIN U3  IOSTANDARD LVCMOS33 } [get_ports {led[11]}]
set_property -dict { PACKAGE_PIN P3  IOSTANDARD LVCMOS33 } [get_ports {led[12]}]
set_property -dict { PACKAGE_PIN N3  IOSTANDARD LVCMOS33 } [get_ports {led[13]}]
set_property -dict { PACKAGE_PIN P1  IOSTANDARD LVCMOS33 } [get_ports {led[14]}]
set_property -dict { PACKAGE_PIN L1  IOSTANDARD LVCMOS33 } [get_ports {led[15]}]

## ---------------- Display de 7 segmentos ----------------
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]
set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]
set_property -dict { PACKAGE_PIN V7 IOSTANDARD LVCMOS33 } [get_ports dp]
set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports {an[3]}]

## ---------------- Botoes ----------------
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports btnC]
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports btnU]
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports btnL]
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports btnR]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports btnD]

## ---------------- Pmod JA : zonas 1, 2 e 3 ----------------
## Z1 ambiente 1: PIR + ultrassom | Z2 ambiente 2: reed porta + ultrassom
## Z3 ambiente 3: PIR + ultrassom | Z4 quintal: IR FC-51 + ultrassom
## Reed: contato para o GND, pull-up interno (porta aberta = 1)
## JA1  Z1 PIR            JA2  Z1 TRIG    JA3  Z1 ECHO (divisor 5V->3V3)
## JA4  Z2 reed (porta)   JA7  Z2 TRIG    JA8  Z2 ECHO (divisor 5V->3V3)
##                         JA9  Z3 TRIG    JA10 Z3 ECHO (divisor 5V->3V3)
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports z1_pir]
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 }               [get_ports z1_trig]
set_property -dict { PACKAGE_PIN J2 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports z1_echo]
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 PULLUP true }   [get_ports z2_reed]
set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 }               [get_ports z2_trig]
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports z2_echo]
set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 }               [get_ports z3_trig]
set_property -dict { PACKAGE_PIN G3 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports z3_echo]

## ---------------- Pmod JB : Z3 PIR, Z4 IR, LED de alarme e supervisao da ESP ----------------
## JB1 Z3 PIR           JB2 Z4 IR FC-51 (ativo em 0; alimentar em 3,3 V)
## JB3 sirene           JB4 estrobo
## JB7 nevoa (bomba)    JB8 cerca      JB9 reset ESP (NPN no EN)   JB10 heartbeat
## PULLDOWN no IR: fio solto parece deteccao -> dispara e degrada (falha segura)
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports z3_pir]
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports z4_ir]
set_property -dict { PACKAGE_PIN B15 IOSTANDARD LVCMOS33 }               [get_ports sirene]
set_property -dict { PACKAGE_PIN B16 IOSTANDARD LVCMOS33 }               [get_ports estrobo]
set_property -dict { PACKAGE_PIN A15 IOSTANDARD LVCMOS33 }               [get_ports nevoa]
set_property -dict { PACKAGE_PIN A17 IOSTANDARD LVCMOS33 }               [get_ports cerca]
set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS33 }               [get_ports esp_rst]
set_property -dict { PACKAGE_PIN C16 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports esp_hb]

## ---------------- Pmod JC : dados FPGA -> ESP32 ----------------
## JC1..JC4 DADOS[0..3]   JC7 SOF   JC8 REQ   JC9 ACK   JC10 MODO_DEGRADADO
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 }               [get_ports {esp_d[0]}]
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 }               [get_ports {esp_d[1]}]
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 }               [get_ports {esp_d[2]}]
set_property -dict { PACKAGE_PIN P18 IOSTANDARD LVCMOS33 }               [get_ports {esp_d[3]}]
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33 }               [get_ports esp_sof]
set_property -dict { PACKAGE_PIN M19 IOSTANDARD LVCMOS33 }               [get_ports esp_req]
set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports esp_ack]
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 }               [get_ports modo_deg]

## ---------------- Pmod JXADC : comandos ESP32 -> FPGA ----------------
## JXA1 ARM_REQ   JXA2 DISARM_REQ   JXA3 CMD_ACK   JXA4 CMD_OK
## PULLDOWN: com a ESP em reset as linhas ficam em 0 (nenhum comando indevido)
set_property -dict { PACKAGE_PIN J3 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports arm_req]
set_property -dict { PACKAGE_PIN L3 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports disarm_req]
set_property -dict { PACKAGE_PIN M2 IOSTANDARD LVCMOS33 }               [get_ports cmd_ack]
set_property -dict { PACKAGE_PIN N2 IOSTANDARD LVCMOS33 }               [get_ports cmd_ok]

## ---------------- Pmod JXADC (fileira de baixo) : ultrassom da zona 4 ----------------
## JXA7 Z4 TRIG   JXA8 Z4 ECHO (divisor 5V->3V3)
set_property -dict { PACKAGE_PIN K3 IOSTANDARD LVCMOS33 }               [get_ports z4_trig]
set_property -dict { PACKAGE_PIN M3 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports z4_echo]

## ---------------- Configuracao ----------------
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Entradas assincronas (sensores, botoes, chaves, ESP) passam por
## sincronizador de 2 FFs, entao nao entram na analise de timing.
set_false_path -from [get_ports {btn* sw[*] z*_reed z*_echo z*_ir z*_pir esp_hb esp_ack arm_req disarm_req}]
set_false_path -to   [get_ports {led[*] seg[*] dp an[*] z*_trig sirene estrobo nevoa cerca esp_rst esp_d[*] esp_sof esp_req modo_deg cmd_ack cmd_ok}]
