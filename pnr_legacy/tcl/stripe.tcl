set stripe_ortho 1

set intermediate_routing_layers_ {}

for {set i 0} {$i < [$tech getRoutingLayerCount]} {incr i} {
  lappend intermediate_routing_layers_ NULL
}

foreach layerobj [$tech getLayers] {
  set nrlayer [$layerobj getRoutingLevel]
  if {$nrlayer == 0} {
    continue
  }
  set intermediate_routing_layers_ [lreplace $intermediate_routing_layers_ [expr $nrlayer-1] [expr $nrlayer-1] $layerobj] 
}

set stacked_via_bottom_layer [[lindex $intermediate_routing_layers_ 0] getName]
set stacked_via_top_layer [[lindex $intermediate_routing_layers_ end] getName]

proc setAddStripeMode { args } {
  global stripe_ortho
  global stacked_via_bottom_layer
  global stacked_via_top_layer
  global intermediate_routing_layers_

  sta::parse_key_args "addStripe" args \
    keys {-orthogonal_only -ignore_nondefault_domains -stacked_via_top_layer -stacked_via_bottom_layer} \
    flags {-reset}
  
  if { [info exists flags(-reset)] } {

    set stripe_ortho 1
    set stacked_via_bottom_layer [[lindex $intermediate_routing_layers_ 0] getName]
    set stacked_via_top_layer [[lindex $intermediate_routing_layers_ end] getName]
  }

  if { [info exists keys(-orthogonal_only)] } {
    if {$keys(-orthogonal_only) == "true"} {
      set stripe_ortho 1
    } else {
      set stripe_ortho 0
    }
    # puts "orthogonal_only $stripe_ortho $keys(-orthogonal_only)"
  }

  if { [info exists keys(-stacked_via_top_layer)] } {
    set stacked_via_top_layer $keys(-stacked_via_top_layer)
  }

  if { [info exists keys(-stacked_via_bottom_layer)] } {
    set stacked_via_bottom_layer $keys(-stacked_via_bottom_layer)
  }
}

proc addStripe { args } {
  sta::parse_key_args "addStripe" args \
    keys {-nets -layer -direction -width -spacing -set_to_set_distance -start_from -start_offset -area} \
    flags {}

  if { ![info exists keys(-layer)] } {
    utl::error PDN 1007 "The -layer argument is required."
  }
  if { ![info exists keys(-nets)] } {
    utl::error PDN 1007 "The -nets argument is required."
  }
  
  set nets $keys(-nets)
  if {[llength $nets] == 1} {
    set nets [list $nets]
  }
  set layer $keys(-layer)

  set direction "horizontal"
  if { [info exists keys(-direction)] } {
    set direction $keys(-direction)
  }

  set width 0
  if { [info exists keys(-width)] } {
    set width $keys(-width)
  }

  set spacing 0
  if { [info exists keys(-spacing)] } {
    set spacing $keys(-spacing)
  }

  set ssdistance 0
  if { [info exists keys(-set_to_set_distance)] } {
    set ssdistance $keys(-set_to_set_distance)
  }

  set offset 0
  if { [info exists keys(-start_offset)] } {
    set offset $keys(-start_offset)
  }

  set area 0
  if { [info exists keys(-area)] } {
    set area $keys(-area)
  }

  # puts "add_stripe_over_area $nets $layer $direction $width $spacing $ssdistance $offset $area"
  add_stripe_over_area $nets $layer $direction $width $spacing $ssdistance $offset $area
}

proc get_via_name {layer1 layer2 dx dy rows cols pitchx pitchy} {
  return "via_${layer1}_${layer2}_${dx}_${dy}_${rows}_${cols}_${pitchx}_${pitchy}"
}

proc get_or_generate_via {blayer tlayer dx dy} {
  # puts "\[get_or_generate_via\] $blayer $tlayer $dx $dy"
  global intermediate_routing_layers_
  global tech
  global ::block
  global stacked_via_bottom_layer
  global stacked_via_top_layer
  set nblayer [[$tech findLayer $blayer] getRoutingLevel]
  set ntlayer [[$tech findLayer $tlayer] getRoutingLevel]
  set min_stack_level [[$tech findLayer $stacked_via_bottom_layer] getRoutingLevel]
  set max_stack_level [[$tech findLayer $stacked_via_top_layer] getRoutingLevel]
  if {$nblayer == 0 || $ntlayer == 0} {
    return NULL
  }
  if {$nblayer > $ntlayer} {
    # Invert the bottom and top if the routing level is wrong
    set tmp $nblayer
    set nblayer $ntlayer
    set ntlayer $tmp
  }
  # Also, only do the selected global stack
  set nblayer [expr max($nblayer, $min_stack_level)]
  set ntlayer [expr min($ntlayer, $max_stack_level)]
  # Explore all the stack
  set nblayer [expr $nblayer-1]
  set ntlayer [expr $ntlayer-1]
  set vias {}
  set ntblayer [expr $ntlayer-1]
  for {set i $nblayer} {$i <= $ntblayer} {incr i} {
    # Get this via generate
    set layerobj1 [lindex $intermediate_routing_layers_ $i]
    set layerobj2 [lindex $intermediate_routing_layers_ [expr $i+1]]
    set layer1 [$layerobj1 getName]
    set layer2 [$layerobj2 getName]

    # The exploration of this via rule is basic
    # Cannot check for the viarules or something
    # Lets hope for the best
    set vr_viarule "NULL"
    foreach viarule [$tech getViaGenerateRules] {
      set vr_layer1 "NULL"
      set vr_layer2 "NULL"
      set vr_layerv "NULL"
      for {set j 0} {$j < [$viarule getViaLayerRuleCount]} {incr j} {
        set vr_rule [$viarule getViaLayerRule $j]
        set vr_lname [[$vr_rule getLayer] getName]
        # Does have any of the layers?
        if {$vr_lname == $layer1 && [$vr_rule hasEnclosure]} {
          set vr_layer1 $vr_rule
        }
        if {$vr_lname == $layer2 && [$vr_rule hasEnclosure]} {
          set vr_layer2 $vr_rule
        }
        if {[$vr_rule hasRect]} {
          set vr_layerv $vr_rule
        }
      }
      if {$vr_layer1 != "NULL" && $vr_layer2 != "NULL" && $vr_layerv != "NULL"} {
        set vr_viarule $viarule
        break
      }
    }
    if {$vr_layer1 == "NULL" || $vr_layer2 == "NULL" || $vr_layerv == "NULL"} {
      # Cannot find it
      lappend vias "NULL"
      continue
    }
    lassign [$vr_layer1 getEnclosure] vr_enc1_x vr_enc1_y
    lassign [$vr_layer2 getEnclosure] vr_enc2_x vr_enc2_y
    set vr_via_x [[$vr_layerv getRect] dx]
    set vr_via_y [[$vr_layerv getRect] dy]
    lassign [$vr_layerv getSpacing] vr_via_sx vr_via_sy
    set vr_via_px [expr $vr_via_x+$vr_via_sx]
    set vr_via_py [expr $vr_via_y+$vr_via_sy]

    # Get the actual size in x and y for this generator
    set rows 1
    set cols 1
    set dx1 [expr $vr_via_x*$cols + $vr_via_sx*($cols-1) + 2*$vr_enc1_x]
    set dx2 [expr $vr_via_x*$cols + $vr_via_sx*($cols-1) + 2*$vr_enc2_x]
    set dy1 [expr $vr_via_y*$rows + $vr_via_sy*($rows-1) + 2*$vr_enc1_y]
    set dy2 [expr $vr_via_y*$rows + $vr_via_sy*($rows-1) + 2*$vr_enc2_y]

    while {[expr $dx1+$vr_via_px] < $dx && [expr $dx2+$vr_via_px] < $dx} {
      incr cols
      set dx1 [expr $vr_via_x*$cols + $vr_via_sx*($cols-1) + 2*$vr_enc1_x]
      set dx2 [expr $vr_via_x*$cols + $vr_via_sx*($cols-1) + 2*$vr_enc2_x]
    }

    while {[expr $dy1+$vr_via_py] < $dy && [expr $dy2+$vr_via_py] < $dy} {
      incr rows
      set dy1 [expr $vr_via_y*$rows + $vr_via_sy*($rows-1) + 2*$vr_enc1_y]
      set dy2 [expr $vr_via_y*$rows + $vr_via_sy*($rows-1) + 2*$vr_enc2_y]
    }
    set dxa [expr max($dx1, $dx2)]
    set dya [expr max($dy1, $dy2)]

    # Get the actual name of the via
    set name [get_via_name [expr $i+1] [expr $i+2] $dxa $dya $rows $cols $vr_via_px $vr_via_py]
    set viaobj [$::block findVia $name]
    if {$viaobj == "NULL"} {
      # If doesn't exist, we create it.
      # A TCL equivalent of pdn/src/via.cpp:650
      puts "Creating via: $name"

      set viaobj [odb::dbVia_create $::block $name]
      $viaobj setViaGenerateRule $vr_viarule

      set params [odb::dbViaParams]
      $params setBottomLayer $layerobj1
      $params setCutLayer [$vr_layerv getLayer]
      $params setTopLayer $layerobj2
      $params setXCutSize $vr_via_x
      $params setYCutSize $vr_via_y
      $params setXCutSpacing $vr_via_sx
      $params setYCutSpacing $vr_via_sy
      $params setXBottomEnclosure $vr_enc1_x
      $params setYBottomEnclosure $vr_enc1_y
      $params setXTopEnclosure $vr_enc2_x
      $params setYTopEnclosure $vr_enc2_y
      $params setNumCutRows $rows
      $params setNumCutCols $cols
      $viaobj setViaParams $params
    }
    lappend vias $viaobj
  }
  return $vias
}

proc add_vias_over_area {net layer direction xl0 yl0 xl1 yl1 geoms other_geoms new_swire} {
  global stripe_ortho
  global stacked_via_bottom_layer
  global stacked_via_top_layer
  global tech
  global ::block
  set netobj [$::block findNet $net]
  set commits {}
  #set new_swire [odb::dbSWire_create $netobj ROUTED]
  set layerobj [$tech findLayer $layer]
  set min_stack_level [[$tech findLayer $stacked_via_bottom_layer] getRoutingLevel]
  set max_stack_level [[$tech findLayer $stacked_via_top_layer] getRoutingLevel]

  # puts "Ortho, bottom, top: $stripe_ortho, $stacked_via_bottom_layer, $stacked_via_top_layer"

  foreach geom $geoms {
    lassign $geom dbTechLayer dbRect
    set ilayer [$dbTechLayer getName]
    if {$ilayer == $layer} {
      # We skip geometries on the same layer. 
      # If intersected, already connected.
      continue
    }
    set x0 [$dbRect xMin]
    set y0 [$dbRect yMin]
    set x1 [$dbRect xMax]
    set y1 [$dbRect yMax]

    # get the intersect, if exist
    if {$x0 > $xl1 || $xl0 > $x1 || $y0 > $yl1 || $yl0 > $y1} {
      continue
    }
    set xi0 [expr max($x0, $xl0)]
    set yi0 [expr max($y0, $yl0)]
    set xi1 [expr min($x1, $xl1)]
    set yi1 [expr min($y1, $yl1)]
    if {$xi0 > $xi1 || $yi0 > $yi1} {
      continue
    }
    #if {$yi0 == 0 && $yi1 == 150} {
    #  puts "I fucked up $xi0 $yi0 $xi1 $yi1"
    #  puts "The geom is $geom"
    #}

    # Check for orthogonals
    set isHorizontal 0
    if {($x1-$x0) >= ($y1-$y0)} {
      set isHorizontal 1
    }
    set isSHorizontal 0
    if {$direction == "horizontal"} {
      set isSHorizontal 1
    }
    if {$isHorizontal == $isSHorizontal && $stripe_ortho} {
      # Only orthogonals
      continue
    }

    # Check if the global stacking is ok?
    set level_layer_1 [$dbTechLayer getRoutingLevel]
    set level_layer_2 [$layerobj getRoutingLevel]
    set min_layer_level [expr min($level_layer_1, $level_layer_2)]
    set max_layer_level [expr max($level_layer_1, $level_layer_2)]
    # puts "$min_stack_level <= $min_layer_level && $min_layer_level <= $max_stack_level && $min_stack_level <= $max_layer_level && $max_layer_level <= $max_stack_level"
    if {!($min_stack_level <= $min_layer_level && $min_layer_level <= $max_stack_level && $min_stack_level <= $max_layer_level && $max_layer_level <= $max_stack_level)} {
      continue
    }

    # Explore the previous ones and see if there is an adjacent geom
    set dx [expr abs($xi1-$xi0)]
    set dy [expr abs($yi1-$yi0)]
    set larea [expr $dx*$dy]
    set luarea [expr [::ord::dbu_to_microns $dx]*[::ord::dbu_to_microns $dy]]

    # If the intersection is too small, we skip it also
    # Too small is just less than the minimal width of any layer
    set layer1_width [$dbTechLayer getWidth]
    set layer2_width [$layerobj getWidth]
    set layer1_area [$dbTechLayer getArea]
    set layer2_area [$layerobj getArea]
    if {($dx < $layer1_width || $dy < $layer1_width || $dx < $layer2_width || $dy < $layer2_width) && ($luarea < $layer1_area || $luarea < $layer2_area)} {
      #continue
      # Nah.. it doesnt work. Lets come up with something better
    }

    set icommit 0
    set adj_skip 0
    foreach commit $commits {
      lassign $commit dbaTechLayer aarea
      set alayer [$dbaTechLayer getName]
      set alevel [$dbaTechLayer getRoutingLevel]
      lassign $aarea xia0 yia0 xia1 yia1
      # Check if intersects in an attempted layer range
      if {!($xi0 > $xia1 || $xia0 > $xi1 || $yi0 > $yia1 || $yia0 > $yi1) && $alayer != $ilayer} {
        set min_alayer_level [expr min($alevel, $level_layer_2)]
        set max_alayer_level [expr max($alevel, $level_layer_2)]
        if {$min_layer_level <= $alevel && $alevel <= $max_layer_level} {
          # The current one is interferring with other commit. Skip
          set adj_skip 1
          break
        } elseif {$min_alayer_level <= $level_layer_1 && $level_layer_1 <= $max_alayer_level} {
          # The current one is interferring. Delete the explored one. Do not pass "go"
          set commits [lreplace $commits $icommit $icommit]
          continue
        } else {
          # NOTE: This is legal.
        }
      }
      # Check adjacent for the same layer
      if {($xi0 == $xia1 || $xi1 == $xia0 || $yi0 == $yia1 || $yi1 == $yia0) && $alayer == $ilayer} {
        set dax [expr abs($xia1-$xia0)]
        set day [expr abs($yia1-$yia0)]
        set laarea [expr $dax*$day]
        # Is adjacent to a previously commited one. Lets see which one is bigger
        if {$larea > $laarea} {
          # The current one is bigger. Delete the explored one. Do not pass "go"
          set commits [lreplace $commits $icommit $icommit]
          continue
        } else {
          # The explored one is bigger. We just skip this one
          set adj_skip 1
          break
        }
      }
      incr icommit
    }
    if {$adj_skip} {
      continue
    }

    # TODO: We need to merge with other existing shapes. That or, just remove some lef shinanigans
    lappend commits [list $dbTechLayer [list $xi0 $yi0 $xi1 $yi1]]
  }

  foreach commit $commits {
    lassign $commit dbTechLayer area
    lassign $area xi0 yi0 xi1 yi1
    set dx [expr abs($xi1-$xi0)]
    set dy [expr abs($yi1-$yi0)]
    set x [expr ($xi1+$xi0)/2]
    set y [expr ($yi1+$yi0)/2]
    # puts "get_or_generate_via [$dbTechLayer getName] $layer $dx $dy"
    set vias [get_or_generate_via [$dbTechLayer getName] $layer $dx $dy]
    foreach via $vias {
      if {$via == "NULL"} {
        continue
      }
      # puts "odb::dbSBox_create $new_swire $via $x $y STRIPE"

      odb::dbSBox_create $new_swire $via $x $y STRIPE
    }
  }
}

proc add_stripe_over_area {nets layer direction width spacing ssdistance offset area} {
  # Ahh yes. Is coming all together
  global ::block
  global tech
  global dbu
  set core_area [$::block getCoreArea]
  set metal_obj [$tech findLayer $layer]
  #set x0 [expr [lindex $area 0] + 1.0*[$core_area xMin] / $dbu]
  #set y0 [expr [lindex $area 1] + 1.0*[$core_area yMin] / $dbu]
  #set x1 [expr [lindex $area 2] + 1.0*[$core_area xMin] / $dbu]
  #set y1 [expr [lindex $area 3] + 1.0*[$core_area yMin] / $dbu]
  set x0 [lindex $area 0]
  set y0 [lindex $area 1]
  set x1 [lindex $area 2]
  set y1 [lindex $area 3]
  if {$direction == "horizontal"} {
    set send [expr abs($y1-$y0)]
  } else {
    set send [expr abs($x1-$x0)]
  }
  set soffset $offset
  set s $offset
  set nnets [llength $nets]
  set inet 0
  if {$direction == "horizontal"} {
    set isver 0
  } else {
    set isver 1
  }

  # Preload all the geoms and other geoms
  set list_geoms {}
  set list_other_geoms {}

  foreach net $nets { 
    set netobj [$::block findNet $net]
    set iterms [$netobj getITerms]
    # Get all geoms
    set geoms {}
    foreach iterm $iterms {
      # Skip non-placed iterm's instance
      if {![[$iterm getInst] isPlaced]} {
        continue
      }
      set geoms [list {*}$geoms {*}[$iterm getGeometries]]
    }
    foreach swire [$netobj getSWires] {
      foreach sbox [$swire getWires] {
        if {[$sbox isVia] != 0} {
          continue
        }
        lappend geoms [list [$sbox getTechLayer] $sbox]
      }
    }
    lappend list_geoms $geoms

    # Get all geoms that are not in the net
    set other_geoms {}
    #set other_net_objs [$::block getNets]  # TODO: Re-enable this
    set other_net_objs {}
    foreach other_netobj $other_net_objs {
      if {[$other_netobj getName] == $net} {
        continue
      }
      set other_iterms [$other_netobj getITerms]
      foreach iterm $other_iterms {
        set other_geoms [list {*}$other_geoms {*}[$iterm getGeometries]]
      }
      foreach swire [$other_netobj getSWires] {
        foreach sbox [$swire getWires] {
          if {[$sbox isVia] != 0} {
            continue
          }
          lappend other_geoms [list [$sbox getTechLayer] $sbox]
        }
      }
    }
    lappend list_other_geoms $other_geoms
  }

  while {1} {
    set s0 [expr $s]
    set s1 [expr $s+$width]

    # See if we need to break
    if {$s0 > $send || $s1 > $send} {
      break
    }

    # What is the actual box for drawing?
    if {$direction == "horizontal"} {
      set xl0 [expr int(round($x0*$dbu))]
      set xl1 [expr int(round($x1*$dbu))]
      set yl0 [expr int(round(($s0+$y0)*$dbu))]
      set yl1 [expr int(round(($s1+$y0)*$dbu))]
    } else {
      set xl0 [expr int(round(($s0+$x0)*$dbu))]
      set xl1 [expr int(round(($s1+$x0)*$dbu))]
      set yl0 [expr int(round($y0*$dbu))]
      set yl1 [expr int(round($y1*$dbu))]
    }

    # Just to be sure, we will use the fake connection of the net here
    set net [lindex $nets $inet]
    set geoms [lindex $list_geoms $inet]
    set other_geoms [lindex $list_other_geoms $inet]
    set netobj [$::block findNet $net]
    #puts "[lindex $nets $inet] $netobj"
    set sigTyp [$netobj getSigType]
    if {!($sigTyp == "GROUND" || $sigTyp == "POWER")} {
      $netobj setSigType "POWER"
    }
    # Put it special also
    if { [$netobj isSpecial] == 0 } {
      $netobj setSpecial
    }

    # draw the stripe like a box (extracted from PdnGen.i:368)
    set new_swire [odb::dbSWire_create $netobj ROUTED]
    #puts "odb::dbSBox_create $new_swire $metal_obj $xl0 $yl0 $xl1 $yl1 STRIPE $isver"
    odb::dbSBox_create $new_swire $metal_obj $xl0 $yl0 $xl1 $yl1 STRIPE $isver
    # puts "add_vias_over_area $net $layer $direction $xl0 $yl0 $xl1 $yl1"
    add_vias_over_area $net $layer $direction $xl0 $yl0 $xl1 $yl1 $geoms $other_geoms $new_swire

    # TODO: Search for the existing SRoutes, and other ITerms and see if they can
    # connect (Very difficult huh)

    # go for the next stripe
    set inet [expr ($inet+1) % $nnets]
    if {$inet == 0} {
      set s [expr $soffset + $ssdistance]
      set soffset [expr $soffset + $ssdistance] 
    } else {
      set s [expr $s1 + $spacing]
    }
  }
}
