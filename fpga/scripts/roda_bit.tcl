# roda_bit.tcl - executa gera_bitstream.tcl e grava o resultado em fpga/log_bitstream.txt
set raiz_r [file normalize [file dirname [info script]]/..]
set fr [open $raiz_r/log_bitstream.txt w]
if {[catch {source $raiz_r/scripts/gera_bitstream.tcl} erro]} {
    puts $fr "ERRO: $erro"
    puts $fr $::errorInfo
} else {
    puts $fr "OK"
    puts $fr "synth: [get_property STATUS [get_runs synth_1]]"
    puts $fr "impl : [get_property STATUS [get_runs impl_1]]"
    puts $fr "WNS  : [get_property STATS.WNS [get_runs impl_1]]"
    puts $fr "WHS  : [get_property STATS.WHS [get_runs impl_1]]"
}
close $fr
