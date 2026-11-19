# roda.tcl - executa cria_projeto.tcl e grava o resultado em fpga/log_execucao.txt
set raiz_r [file normalize [file dirname [info script]]/..]
set fr [open $raiz_r/log_execucao.txt w]
if {[catch {source $raiz_r/scripts/cria_projeto.tcl} erro]} {
    puts $fr "ERRO: $erro"
    puts $fr $::errorInfo
} else {
    puts $fr "OK"
}
close $fr
