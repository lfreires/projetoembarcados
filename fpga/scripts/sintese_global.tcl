# sintese_global.tcl - sintetiza o Block Design de uma vez (sem um run por IP)
# e dispara sintese + implementacao + bitstream sem travar a interface.
set raiz_r C:/Users/Win10/projetoembarcados/fpga
set fr [open $raiz_r/log_global.txt w]
if {[catch {
    # para e limpa os runs fora de contexto (OOC) dos IPs
    foreach r [get_runs -filter {IS_SYNTHESIS && NAME != synth_1}] {
        catch { reset_run $r }
        catch { delete_runs $r }
    }
    catch { reset_run impl_1 }
    catch { reset_run synth_1 }
    set bd [get_files central_bd.bd]
    set_property synth_checkpoint_mode None $bd
    generate_target all $bd
    launch_runs impl_1 -to_step write_bitstream -jobs 2
} erro]} {
    puts $fr "ERRO: $erro"
    puts $fr $::errorInfo
} else {
    puts $fr "LANCADO"
}
close $fr
