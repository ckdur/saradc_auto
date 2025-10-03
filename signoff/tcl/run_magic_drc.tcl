# run_magic_drc.tcl
crashbackups stop
drc euclidean on
drc style drc(full)
drc on
snap internal
gds flatglob *__example_*
gds flatten true
gds read $env(GDS)
select top cell
expand
drc catchup
set allerrors [drc listall why]
set oscale [cif scale out]
set ofile [open $env(SIGN_DIR)/reports/$env(TOP).magic.drc.txt w]
puts $ofile "DRC errors for cell $env(TOP)"
puts $ofile "--------------------------------------------"
foreach {whytext rectlist} $allerrors {
   puts $ofile ""
   puts $ofile $whytext
   foreach rect $rectlist {
       set llx [format "%.3f" [expr $oscale * [lindex $rect 0]]]
       set lly [format "%.3f" [expr $oscale * [lindex $rect 1]]]
       set urx [format "%.3f" [expr $oscale * [lindex $rect 2]]]
       set ury [format "%.3f" [expr $oscale * [lindex $rect 3]]]
       puts $ofile "$llx $lly $urx $ury"
   }
}
close $ofile
exit

