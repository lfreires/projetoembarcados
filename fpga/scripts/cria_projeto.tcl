# cria_projeto.tcl
# Cria o projeto do Vivado da central de alarme, monta o Block Design no
# IP Integrator e gera o wrapper. Placa: Basys 3 (xc7a35tcpg236-1).
#
# Como usar (testado no Vivado 2018.2):
#   1. Abrir o Vivado. Se ja houver um projeto aberto (ex.: projetoembarcados),
#      o script monta tudo DENTRO dele. Sem projeto aberto, cria
#      fpga/vivado/central_alarme.xpr.
#   2. Na janela "Tcl Console" (embaixo):
#        source C:/caminho/ate/fpga/scripts/cria_projeto.tcl
#   3. Generate Bitstream  (ou rodar:  source scripts/gera_bitstream.tcl)
#
# Blocos do diagrama:
#   IPs da Xilinx : Clocking Wizard, Binary Counter, Slice, Concat,
#                   Utility Vector Logic, Utility Reduced Logic, ILA
#   IPs proprios  : mef_zona (x4), mef_central, sensores, botoes, chaves,
#                   cmd_esp, gpio_esp, wdt_esp, display, reset_ger
#                   (entram como "module reference", direto do VHDL em src/)

set raiz [file normalize [file dirname [info script]]/..]
set nome central_alarme

if {[catch {current_project}]} {
    create_project $nome $raiz/vivado -part xc7a35tcpg236-1 -force
} else {
    puts "Usando o projeto aberto: [get_property NAME [current_project]]"
    set_property part xc7a35tcpg236-1 [current_project]
    # roda de novo sem duplicar: apaga o diagrama anterior, se existir
    if {[llength [get_files -quiet central_bd.bd]] > 0} {
        set bdf [lindex [get_files central_bd.bd] 0]
        catch { close_bd_design [get_bd_designs central_bd] }
        catch { export_ip_user_files -of_objects [get_files central_bd.bd] -no_script -reset -force -quiet }
        remove_files [get_files central_bd.bd]
        file delete -force [file dirname $bdf]
    }
    foreach f [get_files -quiet *central_bd_wrapper.vhd] { remove_files $f }
}
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

# (catch: na segunda execucao os arquivos ja estao no projeto)
catch { add_files -norecurse [glob $raiz/src/*.vhd] }
catch { add_files -fileset constrs_1 -norecurse $raiz/constr/basys3_central.xdc }
catch { add_files -fileset sim_1 -norecurse [glob $raiz/sim/*.vhd] }
update_compile_order -fileset sources_1

# ---------------------------------------------------------------- ajudantes
# cria um IP da Xilinx pegando a versao instalada neste Vivado
proc cria_ip {tipo inst cfg} {
    set vlnv [lindex [lsort [get_ipdefs -filter "NAME == $tipo"]] end]
    if {$vlnv eq ""} { error "IP $tipo nao encontrado neste Vivado" }
    set c [create_bd_cell -type ip -vlnv $vlnv $inst]
    if {[llength $cfg] > 0} { set_property -dict $cfg $c }
    return $c
}
# cria um bloco a partir de um VHDL nosso (module reference)
proc cria_mod {ref inst} {
    return [create_bd_cell -type module -reference $ref $inst]
}
# devolve o pino (inst/pino) ou a porta externa (sem barra)
proc obj {n} {
    if {[string first / $n] >= 0} {
        set o [get_bd_pins $n]
    } else {
        set o [get_bd_ports $n]
    }
    if {[llength $o] == 0} { error "nao achei $n no diagrama" }
    return $o
}
# liga uma origem a varios destinos
proc liga {origem args} {
    foreach d $args {
        connect_bd_net [obj $origem] [obj $d]
    }
}

# ---------------------------------------------------------------- diagrama
create_bd_design central_bd

# portas externas (mesmos nomes do XDC)
create_bd_port -dir I -type clk clk
set_property CONFIG.FREQ_HZ 100000000 [get_bd_ports clk]
create_bd_port -dir I btnC
create_bd_port -dir I btnU
create_bd_port -dir I btnD
create_bd_port -dir I btnL
create_bd_port -dir I btnR
create_bd_port -dir I -from 15 -to 0 sw
create_bd_port -dir O -from 15 -to 0 led
create_bd_port -dir O -from 6 -to 0 seg
create_bd_port -dir O dp
create_bd_port -dir O -from 3 -to 0 an
create_bd_port -dir I z1_pir
create_bd_port -dir O z1_trig
create_bd_port -dir I z1_echo
create_bd_port -dir I z2_reed
create_bd_port -dir O z2_trig
create_bd_port -dir I z2_echo
create_bd_port -dir I z3_pir
create_bd_port -dir O z3_trig
create_bd_port -dir I z3_echo
create_bd_port -dir I z4_ir
create_bd_port -dir O z4_trig
create_bd_port -dir I z4_echo
create_bd_port -dir O sirene
create_bd_port -dir O estrobo
create_bd_port -dir O nevoa
create_bd_port -dir O cerca
create_bd_port -dir O esp_rst
create_bd_port -dir I esp_hb
create_bd_port -dir O -from 3 -to 0 esp_d
create_bd_port -dir O esp_sof
create_bd_port -dir O esp_req
create_bd_port -dir I esp_ack
create_bd_port -dir O modo_deg
create_bd_port -dir I arm_req
create_bd_port -dir I disarm_req
create_bd_port -dir O cmd_ack
create_bd_port -dir O cmd_ok

# IPs da Xilinx
cria_ip clk_wiz clk_wiz_0 [list \
    CONFIG.PRIM_IN_FREQ {100.000} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {10.000} CONFIG.USE_RESET {false} \
    CONFIG.USE_LOCKED {true} \
]
cria_ip c_counter_binary contador_0 [list CONFIG.Output_Width {24}]
cria_ip xlslice fatia_sel [list CONFIG.DIN_WIDTH {24} CONFIG.DIN_FROM {16} CONFIG.DIN_TO {15} CONFIG.DOUT_WIDTH {2}]
cria_ip xlslice fatia_pisca [list CONFIG.DIN_WIDTH {24} CONFIG.DIN_FROM {22} CONFIG.DIN_TO {22} CONFIG.DOUT_WIDTH {1}]
cria_ip xlslice fatia_rapido [list CONFIG.DIN_WIDTH {24} CONFIG.DIN_FROM {21} CONFIG.DIN_TO {21} CONFIG.DOUT_WIDTH {1}]
cria_ip xlslice fatia_en [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {3} CONFIG.DIN_TO {0} CONFIG.DOUT_WIDTH {4}]
cria_ip xlslice fatia_en1 [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {0} CONFIG.DIN_TO {0} CONFIG.DOUT_WIDTH {1}]
cria_ip xlslice fatia_en2 [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {1} CONFIG.DIN_TO {1} CONFIG.DOUT_WIDTH {1}]
cria_ip xlslice fatia_en3 [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {2} CONFIG.DIN_TO {2} CONFIG.DOUT_WIDTH {1}]
cria_ip xlslice fatia_en4 [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {3} CONFIG.DIN_TO {3} CONFIG.DOUT_WIDTH {1}]
cria_ip xlslice fatia_teste [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {7} CONFIG.DIN_TO {4} CONFIG.DOUT_WIDTH {4}]
cria_ip xlslice fatia_fr [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {8} CONFIG.DIN_TO {8} CONFIG.DOUT_WIDTH {1}]
cria_ip xlslice fatia_fu [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {9} CONFIG.DIN_TO {9} CONFIG.DOUT_WIDTH {1}]
cria_ip xlslice fatia_fi [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {10} CONFIG.DIN_TO {10} CONFIG.DOUT_WIDTH {1}]
cria_ip xlslice fatia_atraso [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {13} CONFIG.DIN_TO {11} CONFIG.DOUT_WIDTH {3}]
cria_ip xlslice fatia_tcorr [list CONFIG.DIN_WIDTH {16} CONFIG.DIN_FROM {15} CONFIG.DIN_TO {14} CONFIG.DOUT_WIDTH {2}]
cria_ip xlconcat concat_al [list CONFIG.NUM_PORTS {4}]
cria_ip xlconcat concat_deg [list CONFIG.NUM_PORTS {4}]
cria_ip xlconcat concat_pronta [list CONFIG.NUM_PORTS {4}]
cria_ip xlconcat concat_est [list CONFIG.NUM_PORTS {4}]
cria_ip xlconcat concat_motivo [list CONFIG.NUM_PORTS {4}]
cria_ip xlconcat concat_viur [list CONFIG.NUM_PORTS {4}]
cria_ip xlconcat concat_viuu [list CONFIG.NUM_PORTS {4}]
cria_ip xlconcat concat_led [list CONFIG.NUM_PORTS {10}]
cria_ip util_reduced_logic or_deg [list CONFIG.C_SIZE {4} CONFIG.C_OPERATION {or}]
cria_ip util_reduced_logic or_teste [list CONFIG.C_SIZE {4} CONFIG.C_OPERATION {or}]
cria_ip util_vector_logic and_bip [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {and}]
cria_ip util_vector_logic and_disp [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {and}]
cria_ip util_vector_logic or_sirene [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {or}]
cria_ip ila ila_0 [list \
    CONFIG.C_MONITOR_TYPE {Native} CONFIG.C_NUM_OF_PROBES {9} CONFIG.C_DATA_DEPTH {4096} \
    CONFIG.C_ENABLE_ILA_AXI_MON {false} CONFIG.C_PROBE0_WIDTH {4} CONFIG.C_PROBE1_WIDTH {4} \
    CONFIG.C_PROBE2_WIDTH {2} CONFIG.C_PROBE3_WIDTH {3} CONFIG.C_PROBE4_WIDTH {1} \
    CONFIG.C_PROBE5_WIDTH {1} CONFIG.C_PROBE6_WIDTH {1} CONFIG.C_PROBE7_WIDTH {16} \
    CONFIG.C_PROBE8_WIDTH {1} \
]

# IPs proprios (VHDL em src/)
cria_mod reset_ger reset_ger_0
cria_mod chaves chaves_0
cria_mod botoes botoes_0
cria_mod sensores sensores_0
cria_mod mef_zona mef_zona_1
cria_mod mef_zona mef_zona_2
cria_mod mef_zona mef_zona_3
cria_mod mef_zona mef_zona_4
cria_mod mef_central mef_central_0
cria_mod cmd_esp cmd_esp_0
cria_mod wdt_esp wdt_esp_0
cria_mod gpio_esp gpio_esp_0
cria_mod display display_0

# ---------------------------------------------------------------- ligacoes

# clock de 100 MHz da placa -> Clocking Wizard
liga clk clk_wiz_0/clk_in1

# clock do sistema (10 MHz) para todo mundo
liga clk_wiz_0/clk_out1 reset_ger_0/clk chaves_0/clk botoes_0/clk sensores_0/clk mef_zona_1/clk \
    mef_zona_2/clk mef_zona_3/clk mef_zona_4/clk mef_central_0/clk cmd_esp_0/clk wdt_esp_0/clk \
    gpio_esp_0/clk contador_0/CLK ila_0/clk

# reset
liga clk_wiz_0/locked reset_ger_0/locked
liga btnC reset_ger_0/btn
liga reset_ger_0/rst botoes_0/rst sensores_0/rst mef_zona_1/rst mef_zona_2/rst mef_zona_3/rst \
    mef_zona_4/rst mef_central_0/rst cmd_esp_0/rst wdt_esp_0/rst gpio_esp_0/rst

# Binary Counter + Slices: varredura do display e pisca
liga contador_0/Q fatia_sel/Din fatia_pisca/Din fatia_rapido/Din
liga fatia_sel/Dout display_0/sel
liga fatia_pisca/Dout and_bip/Op2 concat_led/In9
liga fatia_rapido/Dout and_disp/Op2

# chaves sincronizadas e fatiadas por funcao
liga sw chaves_0/sw
liga chaves_0/sw_s fatia_en/Din fatia_en1/Din fatia_en2/Din fatia_en3/Din fatia_en4/Din \
    fatia_teste/Din fatia_fr/Din fatia_fu/Din fatia_fi/Din fatia_atraso/Din fatia_tcorr/Din
liga fatia_en/Dout mef_central_0/en_z
liga fatia_en1/Dout mef_zona_1/en
liga fatia_en2/Dout mef_zona_2/en
liga fatia_en3/Dout mef_zona_3/en
liga fatia_en4/Dout mef_zona_4/en
liga fatia_teste/Dout sensores_0/sel_teste or_teste/Op1
liga fatia_fr/Dout sensores_0/forca_r
liga fatia_fu/Dout sensores_0/forca_u
liga fatia_fi/Dout sensores_0/inj_f
liga fatia_atraso/Dout mef_central_0/atraso_sel
liga fatia_tcorr/Dout mef_zona_1/tcorr_sel mef_zona_2/tcorr_sel mef_zona_3/tcorr_sel \
    mef_zona_4/tcorr_sel

# botoes
liga btnU botoes_0/btn_armar
liga btnD botoes_0/btn_desarm
liga btnL botoes_0/btn_rec
liga btnR botoes_0/btn_calib
liga botoes_0/p_armar cmd_esp_0/btn_armar
liga botoes_0/p_desarm cmd_esp_0/btn_desarm
liga botoes_0/p_rec mef_zona_1/rec_deg mef_zona_2/rec_deg mef_zona_3/rec_deg mef_zona_4/rec_deg
liga botoes_0/p_calib sensores_0/calibra

# pinos dos sensores
liga z1_pir sensores_0/z1_pir
liga z1_echo sensores_0/z1_echo
liga sensores_0/z1_trig z1_trig
liga z2_reed sensores_0/z2_reed
liga z2_echo sensores_0/z2_echo
liga sensores_0/z2_trig z2_trig
liga z3_pir sensores_0/z3_pir
liga z3_echo sensores_0/z3_echo
liga sensores_0/z3_trig z3_trig
liga z4_ir sensores_0/z4_ir
liga z4_echo sensores_0/z4_echo
liga sensores_0/z4_trig z4_trig

# entradas qualificadas R, U, F de cada MEF de zona
liga sensores_0/r1 mef_zona_1/r ila_0/probe4
liga sensores_0/u1 mef_zona_1/u ila_0/probe5
liga sensores_0/f1 mef_zona_1/f ila_0/probe6
liga sensores_0/r2 mef_zona_2/r
liga sensores_0/u2 mef_zona_2/u
liga sensores_0/f2 mef_zona_2/f
liga sensores_0/r3 mef_zona_3/r
liga sensores_0/u3 mef_zona_3/u
liga sensores_0/f3 mef_zona_3/f
liga sensores_0/r4 mef_zona_4/r
liga sensores_0/u4 mef_zona_4/u
liga sensores_0/f4 mef_zona_4/f
liga sensores_0/f_vec gpio_esp_0/f_z
liga sensores_0/dist1_us ila_0/probe7

# saidas das 4 MEFs de zona -> Concats
liga mef_zona_1/al concat_al/In0
liga mef_zona_1/deg concat_deg/In0
liga mef_zona_1/pronta concat_pronta/In0
liga mef_zona_1/estado concat_est/In0 ila_0/probe3
liga mef_zona_1/motivo concat_motivo/In0
liga mef_zona_1/viu_r concat_viur/In0
liga mef_zona_1/viu_u concat_viuu/In0
liga mef_zona_2/al concat_al/In1
liga mef_zona_2/deg concat_deg/In1
liga mef_zona_2/pronta concat_pronta/In1
liga mef_zona_2/estado concat_est/In1
liga mef_zona_2/motivo concat_motivo/In1
liga mef_zona_2/viu_r concat_viur/In1
liga mef_zona_2/viu_u concat_viuu/In1
liga mef_zona_3/al concat_al/In2
liga mef_zona_3/deg concat_deg/In2
liga mef_zona_3/pronta concat_pronta/In2
liga mef_zona_3/estado concat_est/In2
liga mef_zona_3/motivo concat_motivo/In2
liga mef_zona_3/viu_r concat_viur/In2
liga mef_zona_3/viu_u concat_viuu/In2
liga mef_zona_4/al concat_al/In3
liga mef_zona_4/deg concat_deg/In3
liga mef_zona_4/pronta concat_pronta/In3
liga mef_zona_4/estado concat_est/In3
liga mef_zona_4/motivo concat_motivo/In3
liga mef_zona_4/viu_r concat_viur/In3
liga mef_zona_4/viu_u concat_viuu/In3

# vetores das zonas para a MEF central, GPIO, LEDs e ILA
liga concat_al/dout mef_central_0/al_z concat_led/In0 ila_0/probe0
liga concat_deg/dout or_deg/Op1 gpio_esp_0/deg_z concat_led/In1 ila_0/probe1
liga concat_pronta/dout mef_central_0/pronta_z
liga concat_est/dout gpio_esp_0/est_z
liga concat_motivo/dout gpio_esp_0/motivo_z
liga concat_viur/dout gpio_esp_0/viu_r_z
liga concat_viuu/dout gpio_esp_0/viu_u_z

# Utility Reduced Logic: MODO_DEGRADADO = OR(DEG_Z), TESTE = OR(sel_teste)
liga or_deg/Res modo_deg gpio_esp_0/modo_deg concat_led/In4
liga or_teste/Res display_0/teste gpio_esp_0/teste concat_led/In5

# comandos (ESP32 + botoes) e MEF central
liga arm_req cmd_esp_0/arm_esp
liga disarm_req cmd_esp_0/disarm_esp
liga cmd_esp_0/arm_req mef_central_0/arm_req
liga cmd_esp_0/disarm_req mef_central_0/disarm_req
liga mef_central_0/cmd_feito cmd_esp_0/cmd_feito
liga mef_central_0/cmd_ok cmd_esp_0/cmd_ok
liga cmd_esp_0/cmd_ack cmd_ack concat_led/In8
liga cmd_esp_0/cmd_res cmd_ok gpio_esp_0/cmd_res
liga mef_central_0/armada mef_zona_1/armada mef_zona_2/armada mef_zona_3/armada mef_zona_4/armada \
    concat_led/In2
liga mef_central_0/estado display_0/est_central gpio_esp_0/est_central ila_0/probe2
liga mef_central_0/rest_c display_0/rest_c
liga mef_central_0/rest_d display_0/rest_d
liga mef_central_0/rest_u display_0/rest_u

# LED de alarme (porta "sirene", canal 1 da placa de potencia):
# sirene = (disparo AND pisca_rapido) OR (pre_alarme AND pisca_lento)  (Utility Vector Logic)
# pisca_rapido = bit 21 do contador (~2,4 Hz), pisca_lento = bit 22 (~1,2 Hz)
liga mef_central_0/pre_alarme and_bip/Op1
liga mef_central_0/disparo and_disp/Op1 concat_led/In3
liga and_disp/Res or_sirene/Op1
liga and_bip/Res or_sirene/Op2
liga or_sirene/Res sirene ila_0/probe8

# contramedidas
liga mef_central_0/estrobo estrobo
liga mef_central_0/nevoa nevoa
liga mef_central_0/cerca cerca

# watchdog externo da ESP32
liga esp_hb wdt_esp_0/hb
liga wdt_esp_0/esp_ok cmd_esp_0/esp_ok concat_led/In6
liga wdt_esp_0/esp_rst esp_rst
liga wdt_esp_0/falha_esp gpio_esp_0/falha_esp concat_led/In7

# interface GPIO com a ESP32
liga esp_ack gpio_esp_0/ack
liga gpio_esp_0/dados esp_d
liga gpio_esp_0/sof esp_sof
liga gpio_esp_0/req esp_req

# display e LEDs
liga display_0/seg seg
liga display_0/dp dp
liga display_0/an an
liga concat_led/dout led

# ---------------------------------------------------------------- finaliza
regenerate_bd_layout
validate_bd_design
save_bd_design

set bd [get_files central_bd.bd]
# sintese global: um run so para o diagrama inteiro (muito mais rapido do que
# um run fora de contexto para cada um dos ~40 IPs)
set_property synth_checkpoint_mode None $bd
generate_target all $bd
# make_wrapper devolve o caminho do wrapper (.srcs no 2018.2, .gen nos novos)
set wrapper [make_wrapper -files $bd -top]
add_files -norecurse $wrapper
set_property top central_bd_wrapper [current_fileset]
set_property top tb_top [get_filesets sim_1]
update_compile_order -fileset sources_1

# exporta o diagrama em Tcl (para versionar no Git) e em PDF (para o relatorio)
write_bd_tcl -force $raiz/scripts/central_bd_exportado.tcl
catch { write_bd_layout -force -format pdf -orientation landscape $raiz/../docs/figuras/block_design.pdf }

puts "=============================================================="
puts " Block Design central_bd pronto no projeto [get_property DIRECTORY [current_project]]"
puts " Proximo passo: Generate Bitstream (ou source scripts/gera_bitstream.tcl)"
puts "=============================================================="
