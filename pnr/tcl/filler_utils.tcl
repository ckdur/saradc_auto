proc is_inside {or area} {
    global dbu
    set x [expr 1.0*[lindex $or 0] / $dbu]
    set y [expr 1.0*[lindex $or 1] / $dbu]
    set x0 [lindex $area 0]
    set y0 [lindex $area 1]
    set x1 [lindex $area 2]
    set y1 [lindex $area 3]
    set inside [expr ($x0 <= $x) && ($x <= $x1) && ($y0 <= $y) && ($y <= $y1)]
    # puts "$dbu $x $y $area $inside"
    return $inside
}

proc reEscape {str} {
    regsub -all {\W} $str {\\&}
}

proc do_global_from_areas {} {
    global digcorearea
    global FILLERCells
    set all_inst [$::block getInsts]
    foreach inst $all_inst {
        set masterName [[$inst getMaster] getName]
        if {[$inst isPlaced] == 0 || !($masterName == "SARADC_FILLTIE2" || $masterName == "SARADC_FILL1" || $masterName == "sg13g2f_TAPCELL" || [lsearch -exact $FILLERCells $masterName] >= 0)} {
            continue
        }
        set name [$inst getName]
        # puts "Doing $name $masterName"

        set or [$inst getOrigin]
        if {[is_inside $or $digcorearea] == 0} {
            # Analog
            # puts "analog for $name in $or"
            add_global_connection -net AVDD -inst_pattern [reEscape "$name"] -pin_pattern {^vdd$} -power
            add_global_connection -net VSS -inst_pattern [reEscape "$name"] -pin_pattern {^vss$} -ground
        } else {
            # Digital
            # puts "digital for $name in $or"
            add_global_connection -net VDD -inst_pattern [reEscape "$name"] -pin_pattern {^vdd$} -power
            add_global_connection -net VSS -inst_pattern [reEscape "$name"] -pin_pattern {^vss$} -ground
        }
    }
}
