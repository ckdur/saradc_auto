proc pos_sw_wtap {x y path capw tapcap nsw} {
  global track
  global row
  global metal1_py
  global saradc_fill_nopower
  global dbu
  set spc 2
  set spcend 8
  set tap_lib [[::ord::get_db] findLib $tapcap]
  set tap_master [$tap_lib findMaster $tapcap]
  set sizetap [expr 1.0*[$tap_master getWidth] / $dbu]
  set sw_lib [[::ord::get_db] findLib "SARADC_CELL_INVX0_ASSW"]
  set sw_master [$sw_lib findMaster "SARADC_CELL_INVX0_ASSW"]
  set swsizex [expr 1.0*[$sw_master getWidth] / $dbu]
  set totalsizex [expr 4*$nsw*$swsizex + (3*$spc*$nsw + $spcend*($nsw-1))*$track]
  set stpx [expr $x+($capw - $totalsizex)/2.0]
  set px $stpx
  set py $y
  set mir R0
  
  for {set i 0} {$i < $nsw} {incr i} {
    set ppath "${path}.impl\\\[${i}\\\].impl"
    # Spacings (always 2 in the middle, before only in 0, end always 2 except last
    set spcb 0
    set spca [expr {$i != ($nsw-1) ? $spcend : 0}]
    
    # puts "\[pos_cdac_unit\] pos_sw $px $py $ppath $spc $spcb $spca 1"
    set swxy [pos_sw $px $py $ppath $spc $spcb $spca 1]
    set px [lindex $swxy 0]
  }
  
  # set swxy [pos_sw $px $py $path 2 0 0 1]
  set swx [lindex $swxy 0]
  set swy [lindex $swxy 1]
  set tap2x [expr $x+$capw-$sizetap]
  
  # Put the taps and the fillers to the switches
  insert_fill $x $y $mir 1 1 $tapcap ${path}_SW_TAPB
  insert_fill_delta [expr $x+$sizetap] $y $stpx $swy $mir $saradc_fill_nopower ${path}_SW_TAPFILLB
  insert_fill_delta $swx $y $tap2x $swy $mir $saradc_fill_nopower ${path}_SW_TAPFILLA
  insert_fill $tap2x $y $mir 1 1 $tapcap ${path}_SW_TAPA
  
  insert_fill [expr $x-$sizetap] $y $mir 1 1 $tapcap ${path}_SW_TAPBB
  insert_fill [expr $tap2x+$sizetap] $y $mir 1 1 $tapcap ${path}_SW_TAPAA
  
  return "$capw $swy"
}

proc pos_cdac_circle {x y pathlsb pathmsb pathdummy nbits pw ph tapcap spctap inv} {
  global metal1_py
  global ntrack_capsw
  # The total number starts with the first two bits
  set lst {}
  lappend lst [list "${pathlsb}.cdac_bit\\\[0\\\].cdac_unit" 0]
  # puts $lst
  lappend lst [list "${pathlsb}.cdac_unit" 0]
  set last [expr $nbits-1]
  for {set k 1} {$k < $nbits} {incr k} {
    set n [expr 1<<$k]
    for {set i 0} {$i < $n} {incr i} {
      if {$k == $last} {
        lappend lst [list "${pathmsb}.cdac_unit" ${i}]
      } else {
        lappend lst [list "${pathlsb}.cdac_bit\\\[${k}\\\].cdac_unit" ${i}]
      }
    }
  }
  # Get all the positions from the circle algorithm
  set sum [llength $lst]
  set pos_ncircle [circle_gen $sum 1 1]
  set pos [lindex $pos_ncircle 0]
  set ncircle [lindex $pos_ncircle 1]
  set filt_pos [lrange $pos 0 [expr $sum-1]]
  
  # Check how many dummies are
  set ndummy 0
  set found 0
  while {!$found} {
    # Test if exists
    set ncap 0
    set path "${pathdummy}.dummy\\\[${ndummy}\\\].dummy.cdac_unit.cap\\\[${ncap}\\\].cap/impl"
    if {[inst_exist $path] == 0} {
      set found 1
    } else {
      incr ndummy
    }
  }
  
  # Assign the dummy to the non-filtered positions, and also the perimeter
  set nofilt_pos [lrange $pos $sum end]
  set per [per_gen [expr $ncircle*2] $ncircle]
  set dumpos [concat $nofilt_pos $per]
  set ndumpos [llength $dumpos]
  if {$ndummy < $ndumpos} {
    puts "There are less dummy than required. We require $ndumpos items but only $ndummy are present"
  }
  if {$ndummy > $ndumpos} { 
    puts "There are more dummy than required. We require $ndumpos items but only $ndummy are present"
  }
  
  # Position a single one, just to get the size
  set path_ind [lindex $lst 0]
  set path [lindex $path_ind 0]
  set ind [lindex $path_ind 1]
  # puts "\[pos_cdac_circle\] Doing $path ($path_ind)"
  set cdacuxy [pos_cdac_unit_wtap $x $y $path $ind $pw $ph $tapcap $spctap 0]
  set cdacw [expr [lindex $cdacuxy 0] - $x]
  set cdach [expr [lindex $cdacuxy 1] - $y + $metal1_py*$ntrack_capsw]
  
  # Position all of the content ones
  set realpos {}
  foreach path_ind $lst p $filt_pos { 
    set path [lindex $path_ind 0]
    set ind [lindex $path_ind 1]
    set i [lindex $p 0]
    set j [lindex $p 1]
    if {$inv} {
      # IF needed to be inverted, then just invert positions
      set j [expr $ncircle+1 - $j]
    }
    lappend realpos [list $i $j]
    set px [expr $x+$i*$cdacw]
    set py [lindex $y+$j*$cdach]
    set lrc 0
    if {$i == 0} {
      set lrc 1
    }
    if {$i == [expr 2*$ncircle+1]} {
      set lrc 2
    }
    # puts "\[pos_cdac_circle\]($i $j) $path $ind into ($px $py)"
    pos_cdac_unit_wtap $px $py $path $ind $pw $ph $tapcap $spctap $lrc
  }
  
  # Position the dummies
  set lstdmy {}
  set realposdmy {}
  for {set ind 0} {$ind < $ndummy} {incr ind} {
    if {$ind < $ndumpos} {
      set p [lindex $dumpos $ind]
      set i [lindex $p 0]
      set j [lindex $p 1]
    } else {
      # Exceeded the positions. We need to put it anywhere
      set i [expr $ind-$ndumpos]
      set j [expr $ncircle+2]
    }
    if {$inv} {
      # IF needed to be inverted, then just invert positions
      set j [expr $ncircle+1 - $j]
    }
    lappend realposdmy "$i $j"
    set path "${pathdummy}.dummy\\\[${ind}\\\].dummy.cdac_unit"
    set pind 0
    lappend lstdmy [list $path $pind]
    set px [expr $x+$i*$cdacw]
    set py [lindex $y+$j*$cdach]
    set lrc 0
    if {$i == 0} {
      set lrc 1
    }
    if {$i == [expr 2*$ncircle+1]} {
      set lrc 2
    }
    # puts "\[pos_cdac_circle\]($i $j) $path $pind into ($px $py)"
    pos_cdac_unit_wtap $px $py $path $pind $pw $ph $tapcap $spctap $lrc
  }
  
  # Return values for other utilities
  # 1. The width and height of a single cdac instantiation
  # 2. The width and height of the instantiation box, in indexes
  # 3. The positions for all CDAC units in indexes i,j
  # 4. The positions for all CDAC dummies in indexes i,j
  # 5. The list of the paths with indexes of all CDAC
  # 6. The same list, but with dummies
  set nx [expr $ncircle*2 + 2]
  set ny [expr $ncircle + 2]
  set ret {}
  lappend ret "$cdacw $cdach"
  lappend ret "$nx $ny"
  lappend ret $realpos
  lappend ret $realposdmy
  lappend ret $lst
  lappend ret $lstdmy
  return $ret
}

# Procedure to generate the perimeter ring
proc per_gen {pw ph} {
  set cx [expr $pw+1]
  set cy [expr $ph+1]
  set pos {}
  # Left
  for {set j 0} {$j < $ph} {incr j} {
    set x 0
    set y [expr $j+1]
    lappend pos "$x $y"
  }
  # Left-top corner
  lappend pos "0 $cy"
  # Top
  for {set i 0} {$i < $pw} {incr i} {
    set x [expr $i+1]
    set y $cy
    lappend pos "$x $y"
  }
  # Right-top corner
  lappend pos "$cx $cy"
  # Right
  for {set j 0} {$j < $ph} {incr j} {
    set x $cx
    set y [expr $ph-$j]
    lappend pos "$x $y"
  }
  # Right-bottom corner
  lappend pos "$cx 0"
  # Bottom
  for {set i 0} {$i < $pw} {incr i} {
    set x [expr $pw-$i]
    set y 0
    lappend pos "$x $y"
  }
  # Left-bottom corner
  lappend pos "0 0"
}

# Procedure to generate the following sequence in pairs of x, y
# 48 46 44 42 40 41 43 45 47 49 ### ncircle=5
# 38 30 28 26 24 25 27 29 31 39 ### ncircle=4
# 36 22 16 14 12 13 15 17 23 37 ### ncircle=3
# 34 20 10 06 04 05 07 11 21 35 ### ncircle=2
# 32 18 08 02 00 01 03 09 19 33 ### ncircle=1
# |_ |_ |_ |_ |_ |_ |_ |_ |_ |_ ### a
# 00 01 02 03 04 05 06 07 08 09 ### a
# We deduce the number of circles from nelem
proc circle_gen {nelem ox oy} {
  # Get the number of circles necessary for this many elements
  set ncircle 1 
  set ntotal 2
  while {$ntotal < $nelem} {
    incr ncircle
    set ntotal [expr $ncircle * $ncircle * 2]
  }
  
  # Generation logic
  set pw [expr $ncircle*2]
  set ph $ncircle
  set i 0
  set j 0
  set c 0
  set w [expr ($c+1)*2]
  set h [expr $c+1]
  
  set pos {}
  for {set k 0} {$k < $ntotal} {incr k} {
    # Generate this sequence
    #       k = 0 1 2 3 4 5 6 7 8 9 A B C D E F...
    #     dir = l r l r l r l r l r l r l r l r...
    #    sign = - + - + - + - + - + - + - + - +...
    #       w = 2 2 2 2 4 4 4 4 4 4 4 4 8 8 8 8...
    #       h = 1 1 1 1 2 2 2 2 2 2 2 2 4 4 4 4...
    #       i = 0 1 2 2 0 1 2 3 4 4 4 4 0 1 2 3...
    #       j = 0 0 0 1 0 0 0 0 0 1 2 3 0 0 0 0...
    # spacesx = 0 1-1 2 0 1-1 2-2 3-2 3 0 1-1 2...
    # spacesy = 0 0 0 0 1 1 1 1 0 0 1 1 0 0 0 0...
    
    # Left or right whenever k is odd or even
    set sign [expr {$k % 2 ? 1:-1}]
    
    set spacesx [expr $sign*int($i/2 + ($k % 2 ? 1:0))]
    set spacesy [expr {$i < $w ? ($h-1) : int($j/2) }]
    set x [expr $ncircle-1 + $spacesx + $ox]
    set y [expr $spacesy + $oy]
    
    # puts "($x $y) k=$k i=$i j=$j w=$w spacex=$spacesx spacesy=$spacesy sign=$sign"
    lappend pos "$x $y"
    
    if {$j == [expr $w-1]} {
      set i 0
      set j 0
      incr c
      set w [expr ($c+1)*2]
      set h [expr $c+1]
    } else {
      if {$i == $w} { 
        incr j 
      } else { 
        incr i 
      }
    }
  }
  set ret {}
  lappend ret $pos
  lappend ret $ncircle
  return $ret
}

# Position the CDAC unit, and also the TAP
proc pos_cdac_unit_wtap {x y path ind pw ph tapcap spctap lrc} {
  global track
  global row
  global saradc_fill_nopower
  global dbu
  set tap_lib [[::ord::get_db] findLib $tapcap]
  set tap_master [$tap_lib findMaster $tapcap]
  set sizetap [expr 1.0*[$tap_master getWidth] / $dbu]
  set sidespc [expr $sizetap+$track*$spctap]
  set px [expr $x+$sidespc]
  set cdacxy [pos_cdac_unit $px $y $path $ind $pw $ph]
  set swy [expr [lindex $cdacxy 1]-$row]
  set cdacx [lindex $cdacxy 0]
  set cdacy [lindex $cdacxy 1]
  set mir R0
  
  # Put the taps and the fillers to the caps
  insert_fill $x $y $mir 1 $ph $tapcap ${path}_${ind}_CAP_TAPB
  insert_fill [expr $x+$sizetap] $y $mir $spctap $ph $saradc_fill_nopower ${path}_${ind}_CAP_TAPFILLB
  insert_fill $cdacx $y $mir $spctap $ph $saradc_fill_nopower ${path}_${ind}_CAP_TAPFILLA
  insert_fill [expr $cdacx+$track*$spctap] $y $mir 1 $ph $tapcap ${path}_${ind}_CAP_TAPA
  
  # Put the taps and the fillers to the switches
  insert_fill $x $swy $mir 1 1 $tapcap ${path}_${ind}_SW_TAPB
  insert_fill [expr $x+$sizetap] $swy $mir $spctap 1 $saradc_fill_nopower ${path}_${ind}_SW_TAPFILLB
  insert_fill $cdacx $swy $mir $spctap 1 $saradc_fill_nopower ${path}_${ind}_SW_TAPFILLA
  insert_fill [expr $cdacx+$track*$spctap] $swy $mir 1 1 $tapcap ${path}_${ind}_SW_TAPA
  
  # Put the extra taps
  if {$lrc == 1} {
    insert_fill [expr $x-$sizetap] $y $mir 1 $ph $tapcap ${path}_${ind}_CAP_TAPBB
    insert_fill [expr $x-$sizetap] $swy $mir 1 1 $tapcap ${path}_${ind}_SW_TAPBB
  }
  if {$lrc == 2} {
#     puts "Putting aaaa in [expr $cdacx+$track*$spctap+$sizetap]"
    insert_fill [expr $cdacx+$track*$spctap+$sizetap] $y $mir 1 $ph $tapcap ${path}_${ind}_CAP_TAPAA
    insert_fill [expr $cdacx+$track*$spctap+$sizetap] $swy $mir 1 1 $tapcap ${path}_${ind}_SW_TAPAA
  }
  
  set px [expr $cdacx+$sidespc]
  return "$px $cdacy"
} 

# Position the whole CDAC unit
proc pos_cdac_unit {x y path ind pw ph} {
  global track
  global row
  global metal1_py
  global saradc_fill_nopower
  global ntrack_capsw
  global dbu
  
  set types "vi2cap cap2vouth cap2voutl"
  
  # Position the caps
  set capxy [pos_caps $x $y $path $ind $pw $ph]
  set capx [lindex $capxy 0]
  set capy [lindex $capxy 1]
  
  # Positioning of the switch
  # TODO: We are assuming 12 implementations
  set nsw 3
  set spc 2
  set spcend 8
  set sw_lib [[::ord::get_db] findLib "SARADC_CELL_INVX0_ASSW"]
  set sw_master [$sw_lib findMaster "SARADC_CELL_INVX0_ASSW"]
  set swsizex [expr 1.0*[$sw_master getWidth] / $dbu]
  set totalsizex [expr 4*$nsw*$swsizex + (3*$spc*$nsw + $spcend*($nsw-1))*$track]
  set stpx [expr $x+(($capx-$x) - $totalsizex)/2.0]
  set px $stpx
  set py [expr $capy + $metal1_py*$ntrack_capsw]
  
  set i 0
  set types_l [llength $types]
  foreach type $types {
    set ppath "${path}.${type}\\\[${ind}\\\].sw_${type}"
    # Spacings (always 2 in the middle, before only in 0, end always 2 except last
    set spcb 0
    set spca [expr {$i != ($types_l-1) ? $spcend : 0}]
    
    # puts "\[pos_cdac_unit\] pos_sw $px $py $ppath $spc $spcb $spca 1"
    set swxy [pos_sw $px $py $ppath $spc $spcb $spca 1]
    set px [lindex $swxy 0]
    incr i
  }
  set swx [lindex $swxy 0]
  set swy [lindex $swxy 1]
  
  # Put the fillers before and after
  # puts "\[pos_cdac_unit\] insert_fill_delta $x $py $stpx $swy R0 $saradc_fill_nopower ${path}_FILLB"
  insert_fill_delta $x $py $stpx $swy R0 $saradc_fill_nopower ${path}_${ind}_FILLB
  # puts "\[pos_cdac_unit\] insert_fill_delta $swx $py $capx $swy R0 $saradc_fill_nopower ${path}_FILLA"
  insert_fill_delta $swx $py $capx $swy R0 $saradc_fill_nopower ${path}_${ind}_FILLA
  
  # The last position is the greater of both x, and the y of the switch
  set px [expr {$capx > $swx ? $capx : $swx}]
  set py $swy
  return "$px $py"
}

proc inst_exist {inst} {
  global ::block
  # Specific for openroad
  
  set test [$::block findInst $inst]
  # puts "Searching for $inst is $test"
  if {$test != "NULL"} {
    return 1
  }
  return 0
}

# Insert fillers in an space from x1,y1 to x2,y2. Truncated to integers
proc insert_fill_delta {x1 y1 x2 y2 mir master name} {
  global track
  global row
  set px1 [expr {$x1 < $x2 ? $x1 : $x2}]
  set px2 [expr {$x1 > $x2 ? $x1 : $x2}]
  set py1 [expr {$y1 < $y2 ? $y1 : $y2}]
  set py2 [expr {$y1 > $y2 ? $y1 : $y2}]
  set repsx [expr round(($px2-$px1)/$track)]
  set repsy [expr round(($py2-$py1)/$row)]
  # puts "\[insert_fill_delta\] insert_fill $px1 $py1 $mir $repsx $repsy $master $name"
  insert_fill $px1 $py1 $mir $repsx $repsy $master $name
}

# Common procedure to insert fillers
proc insert_fill {x y mir repsx repsy master name} {
  global track
  global row
  set mirst $mir
  set mired [expr {$mir == "R0"? "MX" : "R0"}]
  for {set i 0} {$i < $repsx} {incr i} {
    for {set j 0} {$j < $repsy} {incr j} {
      set px [expr $x + $track*$i]
      set py [expr $y + $row*$j]
      set pmir [expr {$j % 2? $mired : $mirst}]
      if {[inst_exist ${name}_${i}_${j}] == 1} {
        [$::block findInst ${name}_${i}_${j}] setPlacementStatus UNPLACED
        place_inst -name [list ${name}_${i}_${j}] -location "$px $py" -orientation $pmir -status LOCKED
      } else {
        place_inst -name [list ${name}_${i}_${j}] -cell $master -location "$px $py" -orientation $pmir  -status LOCKED
      }
    }
  }
}

proc pos_sw {x y path spc spcb spca infill} {
  global track
  global row
  global saradc_fill_nopower
  global ::block
  global dbu
  
  # Query all the instances. Not all of them exist
  set all_sw "pgp_lz1 pgn_lz1 pgp_lz2 pgn_lz2"
  set all_inst {}
  foreach sw $all_sw {
    set inst ${path}/$sw
    if {[inst_exist $inst] == 1} {
      lappend all_inst $inst
    }
  }
  # puts "\[pos_sw\] $path inst:$all_inst"
  # Spacings before
  set mir R0
  if {$infill} { insert_fill $x $y $mir $spcb 1 $saradc_fill_nopower ${inst}_FILLB }
  set x [expr $x+$track*$spcb]
  
  # Cycle the instances
  set all_inst_l [llength $all_inst]
  for {set i 0} {$i < $all_inst_l} {incr i} {
    set inst [lindex $all_inst $i]
    set sizex [expr 1.0*[[[$::block findInst $inst] getMaster] getWidth] / $dbu]
    set sizey [expr 1.0*[[[$::block findInst $inst] getMaster] getHeight] / $dbu]
    set pitchx [expr $sizex+$track*$spc]
    set px [expr $x + $pitchx*$i]
    set py [expr $y]
      
    # puts "\[pos_sw\] place_inst -name $inst -location \"$px $py\" -orientation $mir -status LOCKED"
    if {[[$::block findInst $inst] isPlaced] == 1} {
      [$::block findInst $inst] setPlacementStatus UNPLACED
    }
    place_inst -name [list $inst] -location "$px $py" -orientation $mir -status LOCKED
    
    # Place the intermediate fillers
    if {$i != [expr $all_inst_l - 1]} {
      set px [expr $x + $pitchx*$i + $sizex]
      set py [expr $y]
      if {$infill} { insert_fill $px $py $mir $spc 1 $saradc_fill_nopower ${inst}_FILLM }
    }
  }
  # Spacing after
  set px [expr $x + $pitchx*$all_inst_l - $track*$spc]
  set py [expr $y]
  if {$infill} { insert_fill $px $py $mir $spca 1 $saradc_fill_nopower ${inst}_FILLA }
  
  # Return last positioning
  set px [expr $x + $pitchx*$all_inst_l + $track*($spca-$spc)]
  set py [expr $y + $sizey]
  return "$px $py"
}

proc pos_caps {x y path ind pw ph} {
  global track
  global row
  global ::block
  global dbu

  #Set all the cap positions, as a matrix (ph x pw)
  set cap_sizex 0
  set cap_sizey 0
  for {set j 0} {$j < $ph} {incr j} {
    for {set i 0} {$i < $pw} {incr i} {
      set index [expr $j*$pw + $i + $ind*$pw*$ph]
      set cap_inst "${path}.cap\\\[${index}\\\].cap/impl"
      
      if {[inst_exist $cap_inst] == 0} {
        continue
      }
      set cap_obj [$::block getInsts]
      
      set cap_sizex [expr 1.0*[[[$::block findInst $cap_inst] getMaster] getWidth] / $dbu]
      set cap_sizey [expr 1.0*[[[$::block findInst $cap_inst] getMaster] getHeight] / $dbu]
      set px [expr $x + $cap_sizex*$i]
      set py [expr $y + $cap_sizey*$j]
      set mir [expr { $j % 2 ? "MX" : "R0" }]
      
      # puts "\[pos_caps\] place_inst -name \"$cap_inst\" -location \"$px $py\" -orientation $mir -status LOCKED"

      if {[[$::block findInst $cap_inst] isPlaced] == 1} {
        [$::block findInst $cap_inst] setPlacementStatus UNPLACED
      }
      place_inst -name [list $cap_inst] -location "$px $py" -orientation $mir -status LOCKED
    }
  }
  
  # Return last positioning
  set px [expr $x + $cap_sizex*$pw]
  set py [expr $y + $cap_sizey*$ph]
  return "$px $py"
}

