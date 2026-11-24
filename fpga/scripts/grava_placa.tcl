# grava_placa.tcl - grava a Basys 3 pelo JTAG e, se pedido, na flash QSPI
# uso no Tcl Console:  set flash 0; source .../grava_placa.tcl   (so JTAG)
#                      set flash 1; source .../grava_placa.tcl   (JTAG + flash)
set raiz C:/Users/Win10/projetoembarcados
set bit  $raiz/projetoembarcados.runs/impl_1/central_bd_wrapper.bit
set bin  $raiz/fpga/central_alarme.bin
if {![info exists flash]} { set flash 0 }
set fr [open $raiz/fpga/log_grava.txt w]
if {[catch {
    file copy -force $bit $raiz/fpga/central_alarme.bit
    catch { file copy -force $raiz/projetoembarcados.runs/impl_1/central_bd_wrapper.ltx $raiz/fpga/central_alarme.ltx }
    open_hw
    catch { disconnect_hw_server }
    connect_hw_server
    open_hw_target
    set dev [lindex [get_hw_devices xc7a35t*] 0]
    current_hw_device $dev
    refresh_hw_device -update_hw_probes false $dev
    set_property PROBES.FILE {} $dev
    set_property FULL_PROBES.FILE {} $dev
    set_property PROGRAM.FILE $bit $dev
    program_hw_devices $dev
    puts $fr "JTAG OK: [get_property REGISTER.IR.BIT5_DONE $dev]"
    if {$flash} {
        write_cfgmem -format bin -interface SPIx1 -size 4 -loadbit "up 0x0 $bit" -force $bin
        # Basys 3 rev. C antiga: Spansion s25fl032p; as mais novas: Macronix mx25l3233f
        set parte [lindex [get_cfgmem_parts {mx25l3233f-spi-x1_x2_x4}] 0]
        if {$parte eq ""} { set parte [lindex [get_cfgmem_parts {s25fl032p-spi-x1_x2_x4}] 0] }
        catch { delete_hw_cfgmem [get_property PROGRAM.HW_CFGMEM $dev] }
        create_hw_cfgmem -hw_device $dev $parte
        set m [get_property PROGRAM.HW_CFGMEM $dev]
        set_property PROGRAM.ADDRESS_RANGE {use_file} $m
        set_property PROGRAM.FILES [list $bin] $m
        set_property PROGRAM.PRM_FILE {} $m
        set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} $m
        set_property PROGRAM.BLANK_CHECK 0 $m
        set_property PROGRAM.ERASE 1 $m
        set_property PROGRAM.CFG_PROGRAM 1 $m
        set_property PROGRAM.VERIFY 1 $m
        set_property PROGRAM.CHECKSUM 0 $m
        create_hw_bitstream -hw_device $dev [get_property PROGRAM.HW_CFGMEM_BITFILE $dev]
        program_hw_devices $dev
        refresh_hw_device $dev
        program_hw_cfgmem -hw_cfgmem $m
        puts $fr "FLASH OK"
        # volta a carregar o design normal na FPGA (a gravacao da flash usa um design auxiliar)
        set_property PROGRAM.FILE $bit $dev
        program_hw_devices $dev
        puts $fr "JTAG de novo OK"
    }
} erro]} {
    puts $fr "ERRO: $erro"
    puts $fr $::errorInfo
}
close $fr
