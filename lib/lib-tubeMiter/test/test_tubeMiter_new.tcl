##+##########################################################################
#
# test_canvas_CAD.tcl
# by Manfred ROSENBERGER
#
#   (c) Manfred ROSENBERGER 2010/02/06
#
#   canvas_CAD is licensed using the GNU General Public Licence,
#        see http://www.gnu.org/copyleft/gpl.html
# 
 


set WINDOW_Title      "tcl tubeMiter, based on canvasCAD@rattleCAD"


set APPL_ROOT_Dir [file normalize [file dirname [lindex $argv0]]]

puts "  -> \$APPL_ROOT_Dir $APPL_ROOT_Dir"
set APPL_Package_Dir [file dirname [file dirname $APPL_ROOT_Dir]]
puts "  -> \$APPL_Package_Dir $APPL_Package_Dir"

lappend auto_path [file dirname $APPL_ROOT_Dir]

lappend auto_path "$APPL_Package_Dir"
lappend auto_path [file join $APPL_Package_Dir __ext_Libraries]

package require   Tk
package require   tubeMiter
package require   cad4tcl
package require   bikeGeometry
package require   vectormath
package require   appUtil

set cad4tcl::canvasType 1

    ##+######################

namespace eval model {
        #
    variable dict_TubeMiter
        #
    dict create dict_TubeMiter {}
    dict append dict_TubeMiter settings \
            [list precision               48 \
                  viewOffset               0 \
            ]
    dict append dict_TubeMiter geometry \
            [list angleTool               90 \
                  angleTube              180 \
                  lengthOffset_z          60 \
            ]
    dict append dict_TubeMiter toolTube \
            [list Diameter_Base           56 \
                  Diameter_Top            28 \
                  Length                 160 \
                  Length_BaseCylinder     10 \
                  Length_Cone             70 \
            ]
    dict append dict_TubeMiter tube \
            [list Diameter_Miter          30 \
                  Length                 100 \
            ]
    dict append dict_TubeMiter result \
            [list Base_Position           {} \
                  Miter_Angle             {} \
                  Profile_Tool            {} \
                  Profile_Tube            {} \
                  Shape_Tool              {} \
                  Shape_Tube              {} \
                  ShapeCone_Tool          {} \
                  Miter_ToolPlane         {} \
                  Miter_BaseDiameter      {} \
                  Miter_TopDiameter       {} \
                  miter_Tool              {} \
                  MiterView_Plane         {} \
                  MiterView_BaseDiameter  {} \
                  MiterView_TopDiameter   {} \
                  MiterView_Tool          {} \
                  MiterView_Cone          {} \
                  Shape_ToolPlane         {} \
                  Shape_Debug             {} \
            ]  
}
namespace eval view {
    variable cvObject
    variable stageCanvas
    variable reportText         {}
}
namespace eval control {
        #
    variable angleTube               180
        #
    variable angleTool                90 
    variable lengthOffset_z           50 
    variable lengthOffset_x            0 
    variable diameterToolBase         56 
    variable diameterToolTop          28 
    variable lengthTool              100 
    variable lengthToolBase           30 
    variable lengthToolCone           50 
    variable diameterTube             38
    variable lengthTube               50
    variable rotationTube              0
    variable angleToolPlane            0    ;# clockwise
        #
    variable result/Base_Position     {}
    variable result/Miter_Angle       {}
    variable result/Profile_Tool      {}
    variable result/Profile_Tube      {}
    variable result/Shape_Tool        {}
    variable result/Shape_Tube        {}
        #
    variable viewMiter              right   ;# 
    variable typeTool            cylinder   ;#  ... plane / cone / cylinder
        #
    if 1 {
        variable diameterToolTop          28 
        variable lengthOffset_z           59 
        variable typeTool                cone   ;#  ... plane / cone / cylinder
    }
        #
    if 0 {
            # frustum
        variable diameterToolTop           8 
        variable lengthOffset_z           90 
        variable typeTool             frustum   ;#  ... plane / cone / cylinder
    }
    if 1 {
            # cone
        variable angleTool                70 
        variable diameterToolBase        100 
        variable lengthOffset_x            0 
        variable lengthOffset_z           30
        variable lengthToolCone          150
        variable rotationTube             45
    }
        #
    
    
    # trace add variable angleTool  write updateModel
    # trace add variable angleTube      write updateModel
    # trace add variable lengthOffset_z         write updateModel
    # trace add variable diameterToolBase       write updateModel
    # trace add variable diameterToolTop        write updateModel
    # trace add variable lengthTool              write updateModel
    # trace add variable lengthToolBase write updateModel
    # trace add variable lengthToolCone         write updateModel
    # trace add variable diameterTube          write updateModel
    # trace add variable lengthTube                  write updateModel
    
    # variable myCanvas
    
        # defaults
    variable start_angle        20
    variable start_length       80
    variable end_length         65
    variable dim_size            5
    variable dim_dist           30
    variable dim_offset          0
    variable dim_type_select    aligned
    variable dim_font_select    vector
    variable std_fnt_scl         1
    variable font_colour        black
    variable demo_type          dimension
    variable drw_scale           1.0
    variable cv_scale            1
    variable debugMode          off
        #
        #
    variable miterObjectOrigin  [tubeMiter::createMiter cylinder]
    variable miterObjectEnd     [tubeMiter::createMiter cylinder]
        #
    variable miterDebugCylinder [tubeMiter::createMiter cylinder]
    variable miterDebugPlane    [tubeMiter::createMiter plane]
        #

}    

    #
    # -- MODEL --
    #
proc model::xxx {value} {
        #
    # puts "\n\n--< model::setValue >--"
    # puts "      \$dictPath: $_dictPath"
    # puts "      \$value:    $value"
        #
    variable dict_TubeMiter
        #
    set dictPath [string map {"/" " "} $_dictPath]
    dict set dict_TubeMiter {*}$dictPath $value
        #
    # appUtil::pdict $dict_TubeMiter 
        #
    # puts "--< model::setValue >--\n\n"
}

    #
    # -- CONTROL --
    #
proc control::changeView {} {
        #
    variable viewMiter
        #
    if {$viewMiter eq "left"} {
        set viewMiter "right"
    } else {
        set viewMiter "left"
    }
        #
    control::update   
        #
}
proc control::moveto_StageCenter {item} {
    set cvObject $::view::cvObject
    set stage       [$cvObject getCanvas]
    set stageCenter [$cvObject getCenter]
    set bottomLeft  [$cvObject getBottomLeft]
    foreach {cx cy} $stageCenter break
    foreach {lx ly} $bottomLeft  break
    $cvObject move $item [expr $cx - $lx] [expr $cy -$ly]
}
proc control::recenter_board {} {
    variable  cv_scale 
    variable  drw_scale 
    set cvObject $::view::cvObject
    puts "\n  -> recenter_board:   $cvObject "
    puts "\n\n============================="
    puts "   -> cv_scale:           $cv_scale"
    puts "   -> drw_scale:          $drw_scale"
    puts "\n============================="
    puts "\n\n"
    moveto_StageCenter __cvElement__
    set cv_scale [$cvObject configure Canvas Scale]    
}
proc control::refit_board {} {
    variable  cv_scale 
    variable  drw_scale
    set cvObject $::view::cvObject
    puts "\n  -> recenter_board:   $::view::cvObject "
    puts "\n\n============================="
    puts "   -> cv_scale:           $cv_scale"
    puts "   -> drw_scale:          $drw_scale"
    puts "\n============================="
    puts "\n\n"
    set cv_scale [$cvObject fit]
}
proc control::scale_board {{value {1}}} {
    variable  cv_scale 
    variable  drw_scale 
    set cvObject $::view::cvObject
    puts "\n  -> scale_board:   $cvObject"
    puts "\n\n============================="
    puts "   -> cv_scale:           $cv_scale"
    puts "   -> drw_scale:          $drw_scale"
    puts "\n============================="
    puts "\n\n"        
    $cvObject center $cv_scale
}
proc control::cleanReport {} {
    # puts " -> control::cleanReport: $::view::reportText"
    catch {$::view::reportText   delete  1.0 end}
}
proc control::writeReport {text} {
    # puts " -> control::writeReport: $::view::reportText"
    catch {$::view::reportText   insert  end "$text\n"}
}
proc control::draw_centerLineEdge {} {
    
    set cvObject $::view::cvObject
    $::view::stageCanvas addtag {__CenterLine__} withtag  [$cvObject  create   circle {0 0}     -radius 2  -outline red        -fill white]
    set basePoints {}
    set p00 {0 0}
    set angle_00 0 
    set p01 [vectormath::addVector $p00 [vectormath::rotateLine {0 0} $control::S01_length $angle_00]]
    set angle_01 [expr $angle_00 + $control::S01_angle]
    set p02 [vectormath::addVector $p01 [vectormath::rotateLine {0 0} $control::S02_length $angle_01]]
    set angle_02 [expr $angle_01 + $control::S02_angle]
    set p03 [vectormath::addVector $p02 [vectormath::rotateLine {0 0} $control::S03_length $angle_02]]
    
    $::view::stageCanvas addtag {__CenterLine__} withtag  [$::view::stageCanvas  create   circle $p01       -radius 5  -outline green        -fill white]
    $::view::stageCanvas addtag {__CenterLine__} withtag  [$::view::stageCanvas  create   circle $p02       -radius 5  -outline green        -fill white]
    $::view::stageCanvas addtag {__CenterLine__} withtag  [$::view::stageCanvas  create   circle $p03       -radius 5  -outline green        -fill white]

    lappend basePoints $p00
    lappend basePoints $p01
    lappend basePoints $p02
    lappend basePoints $p03

    append polyLineDef [canvasCAD::flatten_nestedList $basePoints]
      # puts "  -> $polyLineDef"
    $::view::stageCanvas addtag {__CenterLine__} withtag  {*}[$cvObject  create   line $polyLineDef -tags dimension  -fill green ]
}
proc control::dimensionMessage { x y id} {
        tk_messageBox -message "giveMessage: $x $y $id"  
    }        
    #
proc control::getToolShape {{type {}}} {
        #
    variable diameterToolBase      
    variable diameterToolTop       
    variable lengthTool             
    variable lengthToolBase
    variable lengthToolCone        
    variable lengthOffset_z        
    variable typeTool
        #
    if {$type eq {}} {
        set type $typeTool
    }    
        #
    set toolShape {}
        #
    switch -exact $type {
        plane {
                puts "  <I> \$typeTool - cone"
                set lng_00      0
                set lng_01      $lengthToolBase
                set lng_02      [expr $lengthToolBase + $lengthToolCone]
                set lng_03      $lengthTool
                set radius_00   [expr 0.5 * $diameterToolBase]
                set radius_03   [expr 0.5 * $diameterToolTop]
                    #
                lappend toolShape [list $lng_00 0]
                lappend toolShape [list $lng_03 0]
            }
        frustum {
                puts "  <I> \$typeTool - frustum"
                set lng_00      0
                set lng_01      0
                set lng_02      $lengthToolBase
                set lng_03      [expr $lengthToolBase + $lengthToolCone]
                set lng_04      $lengthTool
                set lng_99      $lengthTool
                if {$lng_03 > $lng_04} {
                    set lng_03 $lng_04
                }
                set radius_00   0
                set radius_01   [expr 0.5 * $diameterToolBase]
                set radius_02   [expr 0.5 * $diameterToolBase]
                set radius_03   [expr 0.5 * $diameterToolTop]
                set radius_04   [expr 0.5 * $diameterToolTop]
                set radius_99   0
                    #
                lappend toolShape [list $lng_00 $radius_00]
                    #
                lappend toolShape [list $lng_01 [expr -1.0 * $radius_01]]
                lappend toolShape [list $lng_02 [expr -1.0 * $radius_02]]
                lappend toolShape [list $lng_03 [expr -1.0 * $radius_03]]
                lappend toolShape [list $lng_04 [expr -1.0 * $radius_04]]
                    #
                lappend toolShape [list $lng_99 $radius_99]
                    #
                lappend toolShape [list $lng_04 $radius_04]
                lappend toolShape [list $lng_03 $radius_03]
                lappend toolShape [list $lng_02 $radius_02]
                lappend toolShape [list $lng_01 $radius_01]
                    #
            }
        cone {
                puts "  <I> \$typeTool - cone"
                    #
                if {$diameterToolBase == $diameterToolTop} {
                    set toolShape   [getToolShape cylinder]
                    return $toolShape
                }
                set a           [expr 0.5 * ($diameterToolBase - $diameterToolTop) / $lengthToolCone] 
                set lengthCone  [expr 0.5 * $diameterToolBase / $a]
                    #
                if {$a >= 0} {
                        #
                    set lng_00      0
                    set lng_01      0
                    set lng_02      $lengthToolBase
                    set lng_03      [expr $lengthToolBase + $lengthToolCone]
                    set lng_04      $lengthTool
                    set lng_99      [expr $lengthToolBase + $lengthCone]
                    if {$lng_03 > $lng_04} {
                        set lng_03 $lng_04
                    }
                    set radius_00   0
                    set radius_01   [expr  0.5 * $diameterToolBase + ($lengthToolBase * $a)]
                    set radius_02   [expr  0.5 * $diameterToolBase]
                    set radius_03   [expr  0.5 * $diameterToolTop]
                    set radius_04   [expr  0.5 * $diameterToolTop - (($lengthTool - ($lengthToolBase + $lengthToolCone)) * $a)]
                    set radius_99   0
                        #
                } else {
                        #
                    set lng_00      [expr $lengthToolBase + $lengthCone]
                    set lng_01      0
                    set lng_02      $lengthToolBase
                    set lng_03      [expr $lengthToolBase + $lengthToolCone]
                    set lng_04      $lengthTool
                    set lng_99      $lengthTool
                        #
                    set radius_00   0
                    set radius_01   [expr  0.5 * $diameterToolBase + ($lengthToolBase * $a)]
                    set radius_02   [expr  0.5 * $diameterToolBase]
                    set radius_03   [expr  0.5 * $diameterToolTop]
                    set radius_04   [expr  0.5 * $diameterToolBase - (($lengthTool - $lengthToolBase) * $a)]
                    set radius_99   0
                        #
                }
                
                lappend toolShape [list $lng_00 $radius_00]
                    #
                lappend toolShape [list $lng_01 [expr -1.0 * $radius_01]]
                lappend toolShape [list $lng_02 [expr -1.0 * $radius_02]]
                lappend toolShape [list $lng_03 [expr -1.0 * $radius_03]]
                lappend toolShape [list $lng_04 [expr -1.0 * $radius_04]]
                    #
                lappend toolShape [list $lng_99 $radius_99]
                    #
                lappend toolShape [list $lng_04 $radius_04]
                lappend toolShape [list $lng_03 $radius_03]
                lappend toolShape [list $lng_02 $radius_02]
                lappend toolShape [list $lng_01 $radius_01]
                    #
                
                    #
                # exit
                    #
            }
        cylinder -
        default {
                puts "  <I> \$typeTool - cylinder"
                    #
                lappend toolShape [list 0           [expr -0.5 * $diameterToolBase]]
                lappend toolShape [list $lengthTool [expr -0.5 * $diameterToolBase]]
                    #
                lappend toolShape [list $lengthTool [expr  0.5 * $diameterToolBase]]
                lappend toolShape [list 0           [expr  0.5 * $diameterToolBase]]
            }
    }
        #
    foreach {xy} $toolShape {
        puts "       $typeTool -> $xy"
    }
        #
    set toolShape [vectormath::addVectorPointList [list [expr -1.0 * $lengthOffset_z] 0] $toolShape]
    set toolShape [vectormath::rotatePointList    {0 0} $toolShape 90]
    set toolShape [join $toolShape " "]    
        #
    return $toolShape
        #
}
    #
proc control::update {{key _any} {value {}}} {
        #
    puts "\n\n--< control::update >--"
    puts "      \$key:     $key"
    puts "      \$value:   $value"
        #
    variable angleTool 
    variable angleTube     
    variable diameterToolBase      
    variable diameterToolTop       
    variable diameterTube         
    variable lengthTool             
    variable lengthToolBase
    variable lengthToolCone        
    variable lengthOffset_x        
    variable lengthOffset_z        
    variable lengthTube 
    variable typeTool        
    variable angleToolPlane
        #
    variable viewMiter    
        #
    puts ""    
    puts "    --------------------------------------------------"    
    puts "          -> \$typeTool           $typeTool"
    puts ""
    puts "          -> \$angleTool          $angleTool"    
    puts "          -> \$diameterToolBase   $diameterToolBase"    
    puts "          -> \$diameterToolTop    $diameterToolTop"    
    puts "          -> \$lengthTool         $lengthTool"    
    puts "          -> \$lengthToolBase     $lengthToolBase"    
    puts "          -> \$lengthToolCone     $lengthToolCone"    
    puts "          -> \$lengthOffset_x     $lengthOffset_x"
    puts "          -> \$lengthOffset_z     $lengthOffset_z"
    puts ""    
    puts "          -> \$angleTube          $angleTube"    
    puts "          -> \$diameterTube       $diameterTube"    
    puts "          -> \$lengthTube         $lengthTube"        
    puts ""        
    puts "          -> \$angleToolPlane     $angleToolPlane"
    puts "          -> \$viewMiter          $viewMiter"
    puts "    --------------------------------------------------"    
    puts ""    
        #
        #
    variable miterObjectOrigin
    variable miterObjectEnd
        #
    variable miterDebugPlane  
    variable miterDebugCylinder  
        #
        #
    if [info exists $key] {
        puts "    -> set $key $value"
        set $key $value
    } else {
        puts "    -> can not set $key $value"
    }
        
        #
        # -- miterDebugCylinder
        #
    if {$typeTool eq {cone}} {
        $miterDebugCylinder setScalar   OffsetCenterLine    0
    } else {
        $miterDebugCylinder setScalar   OffsetCenterLine    $lengthOffset_x
    }
        #
    $miterDebugCylinder setScalar   AngleTool           $angleTool
    $miterDebugCylinder setScalar   DiameterTube        $diameterTube
    $miterDebugCylinder setScalar   OffsetCenterLine    $lengthOffset_x
        #
    $miterDebugCylinder updateMiter   
        #
        #
        # -- miterDebugPlane
        #
    $miterDebugPlane    setScalar   AngleTool           $angleTool
    $miterDebugPlane    setScalar   DiameterTool        $diameterToolBase   
    $miterDebugPlane    setScalar   DiameterTube        $diameterTube
    $miterDebugPlane    setScalar   OffsetToolBase      $lengthOffset_z   
        #
    $miterDebugPlane    updateMiter
        #
        #
        # -- miterObjectOrigin
        #
    switch -exact $typeTool {
        cone -
        cylinder -
        frustum -
        plane {
            set typeName $typeTool
        }
        default {
            tk_messageBox -message "\$typeTool: $typeTool not defined"
        }
    }    
        #
	set a           [expr 0.5 * ($diameterToolBase - $diameterToolTop) / $lengthToolCone] 
	set lengthCone  [expr 0.5 *  $diameterToolBase / $a]
        
        #
    $miterObjectOrigin  setToolType                     cone
        #
    $miterObjectOrigin  setScalar   AngleTool           $angleTool
    $miterObjectOrigin  setScalar   DiameterTool        $diameterToolBase   
    $miterObjectOrigin  setScalar   DiameterTop         $diameterToolTop    
    $miterObjectOrigin  setScalar   DiameterTube        $diameterTube
    $miterObjectOrigin  setScalar   HeightToolCone      $lengthToolCone    
    $miterObjectOrigin  setScalar   OffsetCenterLine    $lengthOffset_x   
    $miterObjectOrigin  setScalar   OffsetToolBase      [expr $lengthOffset_z - $lengthToolBase] 
    $miterObjectOrigin  setScalar   AngleToolPlane      $angleToolPlane
        #
        #
    puts "\n\n\n --- update Miter -------\n"    
        #
    # $miterObjectOrigin  updateMiter
        #
    puts "\n\n\n --- update Miter --done-\n"    
        #
    control::updateStage
        #
    return
        #
}
proc control::updateStage {{value {0}}} {
        #
    variable drw_scale
    variable dim_size
    variable dim_font_select
    variable dim_size
    variable dim_dist 
    variable dim_offset
    variable font_colour                        
        #
    variable typeTool
        #
        #
    set cvObject $::view::cvObject
        #
    $cvObject deleteContent
        #
    cleanReport
        #
        # $cvObject configure Stage    Scale        $drw_scale
    $cvObject configure Style    Fontstyle    $dim_font_select
    $cvObject configure Style    Fontsize     $dim_size
        #
        #
    createTool      {  10 0}
    createDev       {  10 0}
        #
    createTool_2    {-110 0}
    createTube      {-110 0}
    createProfile   {-110 0}
        #
        #
    control::moveto_StageCenter __CenterLine__ 
    control::moveto_StageCenter __ToolShape__
    control::moveto_StageCenter __TubeShape__
    control::moveto_StageCenter __DebugShape__
        #
        #
    return    
        #
}
    #
    #
proc control::createTool {position} {
        #
    variable drw_scale
    variable dim_size
    variable dim_font_select
    variable dim_size
    variable dim_dist 
    variable dim_offset
    variable font_colour
        #
    variable angleTool 
    variable angleTube     
    variable diameterToolBase      
    variable diameterToolTop       
    variable diameterTube         
    variable lengthTool             
    variable lengthToolBase
    variable lengthToolCone        
    variable lengthOffset_z
    variable lengthOffset_x    
    variable lengthTube                             
        #
    variable typeTool
    variable viewMiter
        #
        #
    variable miterObjectOrigin
    variable miterObjectEnd
        #
    variable miterDebugCylinder
    variable miterDebugPlane
        #
        #
    set cvObject $::view::cvObject
        #
        # diameterToolBase         50 
        # lengthOffset_x           10 
        # lengthToolCone           75
        #
    set radiusToolBase  [expr 0.5 * $diameterToolBase]    
        #
    set pos_XY          [vectormath::addVector $position {0 -75}]
    set pos_XZ          [vectormath::addVector $position {0   0}]
    set pos_YZ          [vectormath::addVector $position {125 0}]
        #
        #
    set myPositon       [vectormath::addVector              $pos_XZ {0 0}]
    $cvObject  create circle    $myPositon  [list -radius 1    -outline blue     -width 0.035    -tags __CenterLine__]
        #
    set pos_00  {0 0}    
    set pos_10  [list  [expr -1.0 * $radiusToolBase]   0]    
    set pos_20  [list  $radiusToolBase  0]
    set pos_99  [list  0  $lengthToolCone]    
        #
    set shape_Cone_XZ   [join "$pos_00 $pos_10 $pos_99 $pos_20" " "]        
    set shape_Cone_YZ   $shape_Cone_XZ      
        #
    set myPolygon       [vectormath::addVectorCoordList     $pos_XZ     $shape_Cone_XZ]
    $cvObject  create polygon   $myPolygon  [list               -outline red    -fill gray80    -width 0.1      -tags __ToolShape__]
        #
    set myPolygon       [vectormath::addVectorCoordList     $pos_YZ     $shape_Cone_YZ]
    $cvObject  create polygon   $myPolygon  [list               -outline red    -fill gray80    -width 0.1      -tags __ToolShape__]
        #
    set myPositon       [vectormath::addVector              $pos_XY     {0 0}]
    $cvObject  create circle    $myPositon  [list  -radius $radiusToolBase   -outline red    -fill gray80    -width 0.1      -tags __ToolShape__]
        #
    return    
        #
}
proc control::createDev {position} {
        #
    variable drw_scale
    variable dim_size
    variable dim_font_select
    variable dim_size
    variable dim_dist 
    variable dim_offset
    variable font_colour
        #
    variable angleTool 
    variable angleTube     
    variable diameterToolBase      
    variable diameterToolTop       
    variable diameterTube         
    variable lengthTool             
    variable lengthToolBase
    variable lengthToolCone        
    variable lengthOffset_z
    variable lengthOffset_x    
    variable lengthTube                             
        #
    variable typeTool
    variable viewMiter
        #
        #
    variable miterObjectOrigin
    variable miterObjectEnd
        #
    variable miterDebugCylinder
    variable miterDebugPlane
        #
        #
    set cvObject $::view::cvObject
        #
        # diameterToolBase         50 
        # lengthOffset_x           10 
        # lengthToolCone           75
        #
    set radiusToolBase  [expr 0.5 * $diameterToolBase]    
        #
    set pos_XY          [vectormath::addVector $position {0 -75}]
    set pos_XZ          [vectormath::addVector $position {0   0}]
    set pos_YZ          [vectormath::addVector $position {125 0}]
        #
        #
    set offsetPlane     $lengthOffset_x
        #
    set plane_XY        [list -35 [expr -1.0 * $offsetPlane]  35 [expr -1.0 * $offsetPlane]]
    set plane_YZ        [list $offsetPlane   -5 $offsetPlane  85]
        #
    set myLine          [vectormath::addVectorCoordList $pos_XY $plane_XY]
    $cvObject  create line      $myLine     [list               -fill blue                       -width 0.01     -tags __ToolShape__]
        #
    set myLine          [vectormath::addVectorCoordList $pos_YZ $plane_YZ]
    $cvObject  create line      $myLine     [list               -fill blue                       -width 0.01     -tags __ToolShape__]
        #
        #
        #
    set a               [expr abs($offsetPlane * ($lengthToolCone / $radiusToolBase))]
    set b               [expr abs($a / ($lengthToolCone / $radiusToolBase))]
        #
        # return
        #
        # -- view xy of cutting planes
        #
    set posTop_XZ       [list $b [expr $lengthToolCone - $a]]
    if {$offsetPlane <= $radiusToolBase} {
        set posBase_XY  [list [expr -1.0 * sqrt(pow($radiusToolBase,2) - pow($offsetPlane,2))] [expr -1.0 * $offsetPlane]]
            #
        set myPositon   [vectormath::addVector          $pos_XY $posBase_XY]
        $cvObject  create circle    $myPositon  [list -radius 2    -outline blue                -width 0.01     -tags __ToolShape__]
            #
            #
        set line_00     [list $posBase_XY  [vectormath::addVector $posBase_XY {0 100}]]
        set line_00     [join "$line_00" " "]
        puts $line_00
        set myLine      [vectormath::addVectorCoordList $pos_XY $line_00]
        $cvObject  create line      $myLine     [list               -fill red                   -width 0.01     -tags __ToolShape__]
    }
        #
        # return
        #
        # -- view yz of cutting Planes & pit of cutting plane
        #
    set z_Cut           [lindex $posTop_XZ 1]
    set line_01         [list -35 $z_Cut 35 $z_Cut]    
        #
    set myPositon       [vectormath::addVector          $pos_YZ $posTop_XZ]
    $cvObject  create circle    $myPositon  [list -radius 2    -outline blue                     -width 0.01     -tags __ToolShape__]
    set myLine          [vectormath::addVectorCoordList $pos_XZ $line_01]
    $cvObject  create line      $myLine     [list               -fill blue                       -width 0.01     -tags __ToolShape__]
    set myLine          [vectormath::addVectorCoordList $pos_YZ $line_01]
    $cvObject  create line      $myLine     [list               -fill blue                       -width 0.01     -tags __ToolShape__]
        #
        # return
        #
        # -- view yz of cutting Planes & pit of cutting plane
        #
    if 0 {
        set listControl     [getControl $a $b $lengthToolCone]
        set listControl     [vectormath::addVectorCoordList  [list 0 $lengthToolCone] $listControl]
            #
        foreach {x y} $listControl {
            set myPositon       [vectormath::addVector          $pos_XZ [list $x $y]]
            $cvObject  create circle    $myPositon  [list -radius 2 -outline orange                 -width 0.01     -tags __ToolShape__]
        }
    }
        #
        # return
        #
        # -- view xz, create hyperbel in cutting plane
        #
    set hypPolyline     [getHyperbel $a $b $lengthToolCone]
    set hypPolyline     [vectormath::addVectorCoordList [list 0 $lengthToolCone] $hypPolyline]
        #
    if {[llength $hypPolyline] >= 4} {
        set myLine      [vectormath::addVectorCoordList $pos_XZ $hypPolyline]
        $cvObject  create line          $myLine     [list           -fill darkblue                  -width 0.01     -tags __ToolShape__]
            #
        foreach {x y} $hypPolyline {
            set myPositon   [vectormath::addVector      $pos_XZ [list $x $y]]
            # $cvObject  create circle    $myPositon  [list -radius 1 -outline blue                   -width 0.01     -tags __ToolShape__]
        }
    }
        #
        # return
        #
        # -- view xz, create cutting line
        #
    set offsetTip       [expr $lengthOffset_z - $lengthToolCone]
    set k_x             [expr tan([vectormath::rad [expr $angleTool - 90]])]
        #
    set pos_21          [list -30 [expr (-30 * $k_x) + $offsetTip ]]
    set pos_22          [list  0  [expr    0         + $offsetTip ]] 
    set pos_23          [list  30 [expr ( 30 * $k_x) + $offsetTip ]] 
    set line_20         [join  "$pos_21 $pos_23" " "]
    set line_20         [vectormath::addVectorCoordList [list 0 $lengthToolCone] $line_20] 
    set myLine          [vectormath::addVectorCoordList $pos_XZ $line_20]
    $cvObject  create line      $myLine     [list               -fill red                       -width 0.01     -tags __ToolShape__]
        #
    set pos_22          [vectormath::addVector          [list 0 $lengthToolCone] $pos_22] 
    set myPositon       [vectormath::addVector          $pos_XZ $pos_22]
    $cvObject  create circle    $myPositon  [list -radius 1     -outline blue                   -width 0.01     -tags __ToolShape__]
        #
        # return
        #
        # -- view xz, create cutting position  -> I
        #
    foreach {xz_1 xz_2} [tubeMiter::IntersectHyperbelLine $a $b  $offsetTip  $k_x]   break  
    set posCut_XZ       [vectormath::addVector          [list 0 $lengthToolCone] $xz_1]
    set myPositon       [vectormath::addVector          $pos_XZ $posCut_XZ]
    $cvObject  create circle    $myPositon  [list -radius 1     -outline red                    -width 0.01     -tags __ToolShape__]
    set posCut_XZ       [vectormath::addVector          [list 0 $lengthToolCone] $xz_2]
    set myPositon       [vectormath::addVector          $pos_XZ $posCut_XZ]
    $cvObject  create circle    $myPositon  [list -radius 1     -outline red                    -width 0.01     -tags __ToolShape__]
        #
        # return
        #
        # -- view xz, create cutting position  -> II
        #
    set offsetPerp         [expr -1.0 * $lengthOffset_z * cos([vectormath::rad [expr $angleTool - 90]])]
        #
    puts "     -> \$lengthOffset_z  $lengthOffset_z "    
    puts "     -> \$offsetPerp  $offsetPerp "    
        #
    foreach {pos_01 pos_02}   [tubeMiter::CutCone $radiusToolBase $lengthToolCone $offsetPlane $offsetPerp $angleTool]   break
    foreach {x_1 y_1} $pos_01 break
    foreach {x_2 y_2} $pos_02 break
        #
    puts "   -----> \$lengthToolCone $lengthToolCone <----"
    puts "   -----> $x_1 $y_1 <----"
    puts "   -----> $x_2 $y_2 <----"
    set posCut_XZ       [vectormath::rotatePoint {0 0}  $pos_01 [expr $angleTool - 90]]
    set myPositon       [vectormath::addVector          $pos_XZ $posCut_XZ]
    $cvObject  create circle    $myPositon  [list -radius 2     -outline darkred                -width 0.01     -tags __ToolShape__]
        #
    set posCut_XZ       [vectormath::rotatePoint {0 0}  $pos_02 [expr $angleTool - 90]]
    set myPositon       [vectormath::addVector          $pos_XZ $posCut_XZ]
    $cvObject  create circle    $myPositon  [list -radius 2     -outline darkred                -width 0.01     -tags __ToolShape__]
        #
    if 0 {
        set pos_Cnt         [list  0 $lengthOffset_z] 
        set myPositon       [vectormath::addVector          $pos_XZ $pos_Cnt]
        $cvObject  create circle    $myPositon  [list -radius [expr abs($x_1)]  -outline yellow     -width 0.01     -tags __ToolShape__]
        $cvObject  create circle    $myPositon  [list -radius [expr abs($x_2)]  -outline yellow     -width 0.01     -tags __ToolShape__]
            #
        set pos_41          [list $x_1 [expr $lengthOffset_z -20]]
        set pos_42          [list $x_1 [expr $lengthOffset_z +20]]
        set line_40         [join  "$pos_41 $pos_42" " "]
        set myLine          [vectormath::addVectorCoordList $pos_XZ $line_40]
        $cvObject  create line      $myLine     [list               -fill red                       -width 0.01     -tags __ToolShape__]
        set pos_51          [list $x_2 [expr $lengthOffset_z -20]]
        set pos_52          [list $x_2 [expr $lengthOffset_z +20]]
        set line_50         [join  "$pos_51 $pos_52" " "]
        set myLine          [vectormath::addVectorCoordList $pos_XZ $line_50]
        $cvObject  create line      $myLine     [list               -fill red                       -width 0.01     -tags __ToolShape__]
    }
    return    
        #
}
    #
proc control::createTool_2 {position} {
        #
    variable drw_scale
    variable dim_size
    variable dim_font_select
    variable dim_size
    variable dim_dist 
    variable dim_offset
    variable font_colour
        #
    variable angleTool 
    variable angleTube     
    variable diameterToolBase      
    variable diameterToolTop       
    variable diameterTube         
    variable lengthTool             
    variable lengthToolBase
    variable lengthToolCone        
    variable lengthOffset_z
    variable lengthOffset_x    
    variable lengthTube                             
        #
    variable typeTool
    variable viewMiter
        #
        #
    variable miterObjectOrigin
    variable miterObjectEnd
        #
    variable miterDebugCylinder
    variable miterDebugPlane
        #
        #
    set cvObject $::view::cvObject
        #
        # diameterToolBase         50 
        # lengthOffset_x           10 
        # lengthToolCone           75
        #
    set radiusToolBase  [expr 0.5 * $diameterToolBase]    
        #
    set pos_XY          [vectormath::addVector $position {0 -75}]
    set pos_XZ          [vectormath::addVector $position {0   0}]
        #
        #
    set myPositon       [vectormath::addVector              $pos_XZ {0 0}]
    $cvObject  create circle    $myPositon  [list -radius 1    -outline blue     -width 0.035    -tags __CenterLine__]
        #
    set pos_00  {0 0}    
    set pos_10  [list  [expr -1.0 * $radiusToolBase]   0]    
    set pos_20  [list  $radiusToolBase  0]
    set pos_99  [list  0  $lengthToolCone]    
        #
    set shape_Cone_XZ   [join "$pos_00 $pos_10 $pos_99 $pos_20" " "]        
    set shape_Cone_YZ   $shape_Cone_XZ      
        #
    set myPolygon       [vectormath::addVectorCoordList     $pos_XZ     $shape_Cone_XZ]
    $cvObject  create polygon   $myPolygon  [list               -outline red    -fill gray80    -width 0.1      -tags __ToolShape__]
        #
    set myPositon       [vectormath::addVector              $pos_XY     {0 0}]
    $cvObject  create circle    $myPositon  [list  -radius $radiusToolBase   -outline red    -fill gray80    -width 0.1      -tags __ToolShape__]
        #
    return    
        #
}
proc control::createTube {position} {
        #
    variable drw_scale
    variable dim_size
    variable dim_font_select
    variable dim_size
    variable dim_dist 
    variable dim_offset
    variable font_colour
        #
    variable angleTool 
    variable angleTube     
    variable diameterToolBase      
    variable diameterToolTop       
    variable diameterTube         
    variable lengthTool             
    variable lengthToolBase
    variable lengthToolCone        
    variable lengthOffset_z
    variable lengthOffset_x    
    variable lengthTube
    variable rotationTube    
        #
    variable typeTool
    variable viewMiter
        #
        #
    variable miterObjectOrigin
    variable miterObjectEnd
        #
    variable miterDebugCylinder
    variable miterDebugPlane
        #
        #
    set cvObject $::view::cvObject
        #
        # diameterToolBase         50 
        # lengthOffset_x           10 
        # lengthToolCone           75
        #
    set radiusToolBase  [expr 0.5 * $diameterToolBase]    
    set radiusTube      [expr 0.5 * $diameterTube]    
        #
    set pos_XY          [vectormath::addVector $position {0 -75}]
    set pos_XZ          [vectormath::addVector $position {0   0}]
    set pos_YZ          [vectormath::addVector $position {125 0}]
        #
        #
    set myPositon       [vectormath::addVector              $pos_XZ {0 0}]
    $cvObject  create circle    $myPositon  [list -radius 5    -outline blue     -width 0.035    -tags __CenterLine__]
        #
    set k_x             [expr tan([vectormath::rad [expr $angleTool - 90]])]
        #
    set pos_00          [list  0 $lengthOffset_z] 
    set myPositon       [vectormath::addVector              $pos_XZ $pos_00]
    $cvObject  create circle    $myPositon  [list -radius 2    -outline red      -width 0.035    -tags __CenterLine__]
        #
    set pos_10          [vectormath::rotateLine             {0 0} $lengthTube  [expr $angleTool + 90]] ;# [expr $angleTool - 90]
    set pos_10          [vectormath::addVector              $pos_00 $pos_10]
    set myPositon       [vectormath::addVector              $pos_XZ $pos_10]
    $cvObject  create circle    $myPositon  [list -radius 2    -outline red      -width 0.035    -tags __CenterLine__]
        #
        # return
        #
        # -- create tube representation
        #
    set line_left       [vectormath::parallel $pos_00 $pos_10 $radiusTube left]
    set line_right      [vectormath::parallel $pos_10 $pos_00 $radiusTube left]
        #
    set shape_tube      [join "$line_left $line_right" " "]
        # puts "\n"    
        puts "    -> \$shape_tube $shape_tube"    
        # puts "\n"    
    set myLine          [vectormath::addVectorCoordList $position $shape_tube]
    $cvObject  create line      $myLine     [list               -fill red                   -width 0.01     -tags __ToolShape__]
        #
        #
    set rad_Angle   [vectormath::rad $rotationTube]
        #
    set x_Tube      [expr $radiusTube * sin($rad_Angle)]    ;# ... perpendicular to tube axis, in plane of tube- and cone axis
    set y           [expr $radiusTube * cos($rad_Angle)]    ;# ... perpendicular offset of surface line in plane of x and y axis
    set x_Tool      [expr $x_Tube - $lengthOffset_x]        ;# ... regarding offset of centerlines
        #
    set y_Tube      [expr -1.0 * $y]
        #
        # puts "    -> \$rotationTube $rotationTube"    
        # puts "    -> \$x_Tube $x_Tube"    
        # puts "    -> \$y_Tube $y_Tube"    
        #
    set lineSurface [vectormath::parallel $pos_10 $pos_00 $y_Tube right]    
    set lineSurface [join "$lineSurface" " "]    
    set myLine          [vectormath::addVectorCoordList $position $lineSurface]
    $cvObject  create line      $myLine     [list               -fill blue                  -width 0.01     -tags __ToolShape__]
        #
        # return
        #
        # -- create tool section plane -> hyperbel
        #
    set a               [expr abs($x_Tool * ($lengthToolCone / $radiusToolBase))]
    set b               [expr abs($a / ($lengthToolCone / $radiusToolBase))]
        #
    set hypPolyline     [getHyperbel $a $b $lengthToolCone]
    set hypPolyline     [vectormath::addVectorCoordList [list 0 $lengthToolCone] $hypPolyline]
    if {[llength $hypPolyline] >= 4} {
        set myLine      [vectormath::addVectorCoordList $pos_XZ $hypPolyline]
        $cvObject  create line          $myLine     [list           -fill darkblue                  -width 0.01     -tags __ToolShape__]
            #
        foreach {x y} $hypPolyline {
            set myPositon   [vectormath::addVector      $pos_XZ [list $x $y]]
            # $cvObject  create circle    $myPositon  [list -radius 1 -outline blue                   -width 0.01     -tags __ToolShape__]
        }
    }
        #
        # return
        #
        # -- create section: section line - hyperbel 
        #
    set k           [expr $radiusToolBase / $lengthToolCone]
    set lengthCone  [expr $lengthToolCone - $lengthOffset_z]
    set radiusCone  [expr 1.0 * $lengthCone * $k]
        #
        # puts "    -> \$rotationTube $rotationTube"    
        # puts "    -> \$x_Tube $x_Tube"    
        # puts "    -> \$y_Tube $y_Tube"    
    set z_y         [expr $y_Tube / cos([vectormath::rad [expr $angleTool - 90]])]
        # puts "    -> \$z_y $z_y"    
        #
        #
        #
    foreach {pos_01 pos_02}   [tubeMiter::CutCone $radiusCone  $lengthCone  $x_Tool  $y_Tube  $angleTool] break
    foreach {x_1 y_1} $pos_01 break
    foreach {x_2 y_2} $pos_02 break
        #
        # puts "   -----> \$lengthToolCone $lengthToolCone <----"
        # puts "   -----> $x_1 $y_1 <----"
        # puts "   -----> $x_2 $y_2 <----"
        #
    set posCut_XZ_left  [vectormath::rotatePoint {0 0}  $pos_01 [expr $angleTool - 90]]
    set posCut_XZ_left  [vectormath::addVector          [list 0 $lengthOffset_z] $posCut_XZ_left]
    set myPositon       [vectormath::addVector          $pos_XZ $posCut_XZ_left]
    $cvObject  create circle    $myPositon  [list -radius 2     -outline darkred                -width 0.01     -tags __ToolShape__]
        #
    set posCut_XZ_right [vectormath::rotatePoint {0 0}  $pos_02 [expr $angleTool - 90]]
    set posCut_XZ_right [vectormath::addVector          [list 0 $lengthOffset_z] $posCut_XZ_right]
    set myPositon       [vectormath::addVector          $pos_XZ $posCut_XZ_right]
    $cvObject  create circle    $myPositon  [list -radius 2     -outline darkred                -width 0.01     -tags __ToolShape__]
        #
        # return
        #
        # -- create section: section line - hyperbel in xy
        #
    set pos_20          {0 0}
    set pos_29          [vectormath::rotateLine  {0 0} $lengthTube  [expr $angleTool + 90]]
    set pos_30          [list [lindex $pos_29 0] 0]
        #
    set pos_20          [vectormath::addVector [list 0 $lengthOffset_x] $pos_20] 
    set pos_30          [vectormath::addVector [list 0 $lengthOffset_x] $pos_30] 
        #
    set line_left       [vectormath::parallel $pos_20 $pos_30 $radiusTube left]
    set line_right      [vectormath::parallel $pos_30 $pos_20 $radiusTube left]
        #
    set shape_tube      [join "$line_left $line_right" " "]
        # puts "\n"    
        # puts "    -> \$shape_tube $shape_tube"    
        # puts "\n"    
    set myLine          [vectormath::addVectorCoordList $pos_XY $shape_tube]
    $cvObject  create line      $myLine     [list               -fill red                   -width 0.01     -tags __ToolShape__]
        #
        # return
        #
        # -- create section: surface line in xy
        #
    set lineSurface     [vectormath::parallel $pos_30 $pos_20 $x_Tube right]    
    set lineSurface     [join "$lineSurface" " "]    
    set myLine          [vectormath::addVectorCoordList $pos_XY $lineSurface]
    $cvObject  create line      $myLine     [list               -fill blue                  -width 0.01     -tags __ToolShape__]
        #
        # return
        #
        # -- create section: section line - hyperbel in xy
        #
    set posCut_XY       [list [lindex $posCut_XZ_left 0] [expr [lindex $pos_XY 1] - $radiusTube]]
    set lineHelp_05     [join "$posCut_XZ_left $posCut_XY" " "]
        puts "    -> \$posCut_XZ_left   $posCut_XZ_left"    
        puts "    -> \$posCut_XY        $posCut_XY"    
        puts "    -> \$lineHelp_05      $lineHelp_05"    
    set myLine          [vectormath::addVectorCoordList $pos_XZ $lineHelp_05]
    $cvObject  create line      $myLine     [list               -fill blue                  -width 0.01     -tags __ToolShape__]
        
        
    # set pos_20          [vectormath::rotateLine             $pos_00 $lengthTube  [expr $angleTool + 90]] ;# [expr $angleTool - 90]
        
    return     
        #
}
proc control::createProfile {position} {
        #
    variable drw_scale
    variable dim_size
    variable dim_font_select
    variable dim_size
    variable dim_dist 
    variable dim_offset
    variable font_colour
        #
    variable angleTool 
    variable angleTube     
    variable angleToolPlane
	variable diameterToolBase      
    variable diameterToolTop       
    variable diameterTube         
    variable lengthTool             
    variable lengthToolBase
    variable lengthToolCone        
    variable lengthOffset_z
    variable lengthOffset_x    
    variable lengthTube
    variable rotationTube    
        #
    variable typeTool
    variable viewMiter
        #
        #
    variable miterObjectOrigin
    variable miterObjectEnd
        #
    variable miterDebugCylinder
    variable miterDebugPlane
        #
        #
    set cvObject $::view::cvObject
        #
    set radiusToolBase  [expr 0.5 * $diameterToolBase]    
    set radiusTube      [expr 0.5 * $diameterTube]    
        #
    set pos_XY          [vectormath::addVector $position {0 -75}]
    set pos_XZ          [vectormath::addVector $position {0   0}]
    set pos_YZ          [vectormath::addVector $position {125 0}]
        #
        #
    set myPositon       [vectormath::addVector              $pos_XZ {0 0}]
    $cvObject  create circle    $myPositon  [list -radius 5    -outline blue     -width 0.035    -tags __CenterLine__]
        #
    set pos_00          [list  0 $lengthOffset_z]
        #
        # puts "  -> \$radiusToolBase $radiusToolBase "
        # puts "  -> \$lengthToolCone $lengthToolCone "
        #
        # return
        #
        # -- create tube cutting profile 
        #
    set k           [expr  $radiusToolBase / $lengthToolCone]
    set radius_02   [expr  $radiusToolBase - $lengthOffset_z * $k]
    set length_02   [expr  $radius_02 / $k]
        #
        # puts "    -> \$k                - $k"
        # puts "    -> \$length_02        - $length_02"
        # puts "    -> \$radius_02        - $radius_02"
        #        
    $miterObjectOrigin  setScalar   HeightToolCone      $length_02 
    $miterObjectOrigin  setScalar   AngleTool           $angleTool
    $miterObjectOrigin  setScalar   DiameterTool        [expr 2.0 * $radius_02]  
    $miterObjectOrigin  setScalar   DiameterTube        $diameterTube
    $miterObjectOrigin  setScalar   OffsetCenterLine    $lengthOffset_x   
    $miterObjectOrigin  setScalar   AngleToolPlane      $angleToolPlane
        #
        # puts ""    
        puts "           HeightToolCone     [$miterObjectOrigin  getScalar   HeightToolCone  ]"    
        puts "           AngleTool          [$miterObjectOrigin  getScalar   AngleTool       ]"    
        puts "           DiameterTool       [$miterObjectOrigin  getScalar   DiameterTool    ]"    
        puts "           DiameterTube       [$miterObjectOrigin  getScalar   DiameterTube    ]"    
        puts "           OffsetCenterLine   [$miterObjectOrigin  getScalar   OffsetCenterLine]"    
        puts "           AngleToolPlane     [$miterObjectOrigin  getScalar   AngleToolPlane  ]"    
        # puts ""    
        #
        #
        # puts "\n\n\n --- update Miter -------\n"    
        #
    $miterObjectOrigin  updateMiter
        #
        # return
        #
        # -- create shape of tool 
        #
        # set toolShape   [$miterObjectOrigin getToolShape]
        # set myPolygon   [vectormath::addVectorCoordList [list 0 $lengthOffset_z] $toolShape]
        # set myPolygon   [vectormath::addVectorCoordList $pos_XZ $myPolygon]
        # $cvObject  create polygon   $myPolygon  [list               -outline red    -fill gray80    -width 0.1      -tags __ToolShape__]
        #
        # return
        #
        # -- create section profile of tube and cone 
        #
        # set profileOrigin   [$miterObjectOrigin getProfile  Origin  left   opposite]
    set profileOrigin   [$miterObjectOrigin getProfile  Origin  right]
        # puts "   -> \$profileOrigin $profileOrigin"    
    set profileOrigin   [vectormath::rotateCoordList    {0 0}   $profileOrigin  [expr $angleTool - 90]]
    set profileOrigin   [vectormath::addVectorCoordList $pos_00    $profileOrigin]
    set myLine          [vectormath::addVectorCoordList $pos_XZ $profileOrigin]
    $cvObject  create line          $myLine             [list                     -fill darkred -width 0.035     -tags __CenterLine__]
        #
        # puts "\n\n\n --- update Miter -------\n"    
        #
    return     
        #
}
    #
proc control::intersectHyperbel {a b k d} {
        #
    variable lengthOffset_x    
        #
    puts "\n -- control::intersectHyperbel -----"
    puts "         \$a $a"
    puts "         \$b $b"
    puts "        -------"
    puts "         \$k $k"
    puts "         \$d $d"
        #
    if {$a == 0}     {
        return {0 0}
    }
        #
        #
    set _A_ [expr 1.0 * (pow($k,2) - (pow($a,2) / pow($b,2)))]
    set _B_ [expr 2.0 * $k * $d]
    set _C_ [expr pow($d,2) - pow($a,2)]
        #
    puts "           --->  $b [expr pow($b,2)]"
    puts "           --->  $a [expr pow($a,2)]"
    puts "           --->  $k [expr pow($k,2)]"
    puts "           --->  \$_A_: $_A_  \$_B_: $_B_  \$_C_: $_C_"
        #
    set __D_    [expr pow($_B_,2) - 4 * $_A_ * $_C_]
    puts "           --->  \$__D_: $__D_"
        #
    if {$__D_ > 0} {
        set x1  [expr (-1.0 * $_B_ + sqrt(pow($_B_,2) - 4 * $_A_ * $_C_ )) / (2 * $_A_)]
        set x2  [expr (-1.0 * $_B_ - sqrt(pow($_B_,2) - 4 * $_A_ * $_C_ )) / (2 * $_A_)]
    } else {
        set x1 0
        set x2 0
    }
    set y1      [expr $k * $x1 + $d]
    set y2      [expr $k * $x2 + $d]
        #
        #puts "           ----> $x" 
        #set x 5
        #set y [expr -1.0 * $a]
        # set y [expr sqrt((pow($a,2) * (pow($x,2) + pow($b,2)) / pow($b,2)))]
    puts "           --->  $x1  ->  $y1"
    puts "           --->  $x2  ->  $y2"
    puts "         --------------------------"
        #
    # set polyline    [list $x_left [expr -1.0 * $h] 0 [expr -1.0 * $a] $x_right [expr -1.0 * $h]]
        #
    puts " -- control::intersectHyperbel -----\n"
        #
    return [list [list $x1 $y1] [list $x2 $y2]]
        #
}
    
proc control::intersectHyperbel2 {r h x y angle} {
        #
    variable lengthOffset_x    
        #
        
        # set offset_d  [expr $lengthOffset_z - $lengthToolCone]
        
        # set y         [expr $lengthOffset_z - $lengthToolCone]
        
    set k [expr tan([vectormath::rad [expr $angle - 90]])]
    
    puts "\n -- control::intersectHyperbel -----"
    puts "         \$r $r"
    puts "         \$h $h"
    puts "         \$x $x"
    puts "         \$y $y"
    puts "         \$angle $angle"
    puts "        -------"
    set distTip     [expr $y - $h]
    puts "         \$distTip $distTip"
    puts "        -------"
    puts "         \$k $k"
        #
    set a               [expr abs($x * ($h / $r))]
    set b               [expr abs($a / ($h / $r))]
    puts "        -------"
    puts "         \$a $a"
    puts "         \$b $b"
    if {$a == 0}     {
        return {0 0}
    }
        #
        #
    set _A_ [expr 1.0 * (pow($k,2) - (pow($a,2) / pow($b,2)))]
    set _B_ [expr 2.0 * $k * $distTip]
    set _C_ [expr pow($distTip,2) - pow($a,2)]
        #
    puts "           --->  $b [expr pow($b,2)]"
    puts "           --->  $a [expr pow($a,2)]"
    puts "           --->  $k [expr pow($k,2)]"
    puts "           --->  \$_A_: $_A_  \$_B_: $_B_  \$_C_: $_C_"
        #
    set __D_    [expr pow($_B_,2) - 4 * $_A_ * $_C_]
    puts "           --->  \$__D_: $__D_"
        #
    if {$__D_ > 0} {
        set x1  [expr (-1.0 * $_B_ + sqrt(pow($_B_,2) - 4 * $_A_ * $_C_ )) / (2 * $_A_)]
        set x2  [expr (-1.0 * $_B_ - sqrt(pow($_B_,2) - 4 * $_A_ * $_C_ )) / (2 * $_A_)]
    } else {
        set x1 0
        set x2 0
    }
    set y1      [expr $k * $x1]
    set y2      [expr $k * $x2]
        #
    # return [list [list $x1 $y1] [list $x2 $y2]]
        #
        #       
    set pos_1   [list $x1 $y1]    
    set pos_2   [list $x2 $y2]   
        #
    set pos_1   [vectormath::rotatePoint {0 0} $pos_1 [expr 90 - $angle]]
    set pos_2   [vectormath::rotatePoint {0 0} $pos_2 [expr 90 - $angle]]
        #
    return [list $pos_1 $pos_2]
        #


    return


    
        
        
    set e1_2    [expr pow($x1,2) + pow($y1,2)]         
    set e2_2    [expr pow($x2,2) + pow($y2,2)]         
        #
    puts "   -> $x1 + $y1 => \$e1_2 $e1_2"   
    puts "   -> $x2 + $y2 => \$e2_2 $e2_2"   
    puts "   -> \$y    $y"   
        #
    set z1      [expr sqrt($e1_2 - pow($y,2))]
    set z2      [expr sqrt($e2_2 - pow($y,2))]
        #
    return [list [list [expr -1.0 * $z1] $y] [list $z2 $y]]   
        #puts "           ----> $x" 
        #set x 5
        #set y [expr -1.0 * $a]
        # set y [expr sqrt((pow($a,2) * (pow($x,2) + pow($b,2)) / pow($b,2)))]
    puts "           --->  $x1  ->  $y1"
    puts "           --->  $x2  ->  $y2"
    puts "         --------------------------"
        #
    # set polyline    [list $x_left [expr -1.0 * $h] 0 [expr -1.0 * $a] $x_right [expr -1.0 * $h]]
        #
    puts " -- control::intersectHyperbel -----\n"
        #
    return [list [list $x1 $y1] [list $x2 $y2]]
        #
}
    
proc control::CutTool {r h x y angle} {
            #
        set k           [expr tan([vectormath::rad [expr $angle - 90]])]
        set distTip     [expr $y - $h]
            #
        set a           [expr abs($x * ($h / $r))]
        set b           [expr abs($a / ($h / $r))]
            #
        puts "\n -- control::intersectHyperbel -----"
        puts "         \$r $r"
        puts "         \$h $h"
        puts "         \$x $x"
        puts "         \$y $y"
        puts "         \$angle $angle"
        puts "        -------"
        puts "         \$distTip $distTip"
        puts "        -------"
        puts "         \$k $k"
            #
        puts "        -------"
        puts "         \$a $a"
        puts "         \$b $b"
        
    
        if {$x == 0} {
                #
            set z1  [expr 0 - ($r + $y * ($k + ($r / $h)))]
            set z2  [expr      $r + $y * ($k + ($r / $h))]
            return [list [list $z1 $y] [list $z2 $y]]
                #
        } else {
    
                #
            if {$a == 0}     {
                return {0 0}
            }
                #
                #
            set _A_ [expr 1.0 * (pow($k,2) - (pow($a,2) / pow($b,2)))]
            set _B_ [expr 2.0 * $k * $distTip]
            set _C_ [expr pow($distTip,2) - pow($a,2)]
                #
            puts "           --->  $b [expr pow($b,2)]"
            puts "           --->  $a [expr pow($a,2)]"
            puts "           --->  $k [expr pow($k,2)]"
            puts "           --->  \$_A_: $_A_  \$_B_: $_B_  \$_C_: $_C_"
                #
            set __D_    [expr pow($_B_,2) - 4 * $_A_ * $_C_]
            puts "           --->  \$__D_: $__D_"
                #
            if {$__D_ > 0} {
                set x1  [expr (-1.0 * $_B_ + sqrt(pow($_B_,2) - 4 * $_A_ * $_C_ )) / (2 * $_A_)]
                set x2  [expr (-1.0 * $_B_ - sqrt(pow($_B_,2) - 4 * $_A_ * $_C_ )) / (2 * $_A_)]
            } else {
                set x1 0
                set x2 0
            }
            set y1      [expr $k * $x1]
            set y2      [expr $k * $x2]
                #
                #       
            set pos_1   [list $x1 $y1]    
            set pos_2   [list $x2 $y2]   
                #
            set pos_1   [vectormath::rotatePoint {0 0} $pos_1 [expr 90 - $angle]]
            set pos_2   [vectormath::rotatePoint {0 0} $pos_2 [expr 90 - $angle]]
                #
            return [list $pos_1 $pos_2]
            
        }
        #
}
    
proc control::getHyperbel {a b h} {
        #
    variable lengthOffset_x    
        #
    puts "\n -- control::getHyperbel -----"
    puts "         \$a $a"
    puts "         \$b $b"
    puts "         \$h $h"
    puts "         -> $lengthOffset_x"
        #
    if {$a == 0}     {
        return {}
    }
        #
    set x_right [expr $h * ($b / $a)]    
    set x_left  [expr -1.0 * $x_right]    
        #
    puts "         -> $x_left <-> $x_right"
        #
    set polyline    {}    
        #
    set i           0
    set precision   20
    set incr_x      [expr 2.0 * $x_right / $precision]
    set x           $x_left
    puts "         --------------------------"
    while {$i <= $precision} {
        #set y [expr sqrt(abs(pow($a,2) * (pow($x,2) - pow($b,2)) / pow($b,2)))]
        #set y [expr (abs(pow($a,2) * (pow($x,2) - pow($b,2)) / pow($b,2)))]
        set y [expr sqrt((pow($a,2) * (pow($x,2) + pow($b,2)) / pow($b,2)))]
        puts "           --->  $x  ->  $y"
        lappend polyline $x [expr -1.0 * $y]
        set x [expr $x + $incr_x]
        incr i
    }
    puts "         --------------------------"
        #
    # set polyline    [list $x_left [expr -1.0 * $h] 0 [expr -1.0 * $a] $x_right [expr -1.0 * $h]]
        #
    puts " -- control::getHyperbel -----\n"
        #
    return $polyline
        #
}
    
proc control::getControl {a b h} {
        #
    variable lengthOffset_x    
        #
    puts "\n -- control::getControl -----"
    puts "         \$a $a"
    puts "         \$b $b"
    puts "         \$h $h"
    puts "         -> $lengthOffset_x"
        #
    set x_right [expr ($h - $a) * ($b / $a)]    
    set x_left  [expr -1.0 * $x_right]    
        #
    puts "         -> $x_left <-> $x_right"
        #
    set polyline    {}    
        #
    set i           0
    set precision   10
    set incr_x      [expr 2.0 * $x_right / $precision]
    set x           $x_left
        #
    set polyline    [list $x_left [expr -1.0 * $h] 0 [expr -1.0 * $a] $x_right [expr -1.0 * $h]]
        #
    puts " -- control::getControl -----\n"
        #
    return $polyline
        #
}

    
    #
    # -- VIEW --
    #
proc view::create_config_line {w lb_text entry_var start end  } {        
        frame   $w
        pack    $w
 
        global $entry_var

        label   $w.lb    -text $lb_text            -width 20  -bd 1  -anchor w 
        entry   $w.cfg    -textvariable $entry_var  -width 10  -bd 1  -justify right -bg white 
     
        scale   $w.scl  -width        12 \
                        -length       120 \
                        -bd           1  \
                        -sliderlength 15 \
                        -showvalue    0  \
                        -orient       horizontal \
                        -command      "control::update $entry_var" \
                        -variable     $entry_var \
                        -from         $start \
                        -to           $end 
                            # -resolution   $resolution
                            # -command      "control::updateStage" \

        pack      $w.lb  $w.cfg $w.scl    -side left  -fill x            
}
proc view::create_status_line {w lb_text entry_var} {         
        frame   $w
        pack    $w
 
        global $entry_var

        label     $w.lb     -text $lb_text            -width 20  -bd 1  -anchor w 
        entry     $w.cfg    -textvariable $entry_var  -width 10  -bd 1  -justify right -bg white 
        pack      $w.lb  $w.cfg    -side left  -fill x            
}
proc view::demo_canvasCAD {} {
          
      variable  stageCanvas
      
      $stageCanvas  create   line           {0 0 20 0 20 20 0 20 0 0}       -tags {Line_01}  -fill blue   -width 2 
      $stageCanvas  create   line           {30 30 90 30 90 90 30 90 30 30} -tags {Line_01}  -fill blue   -width 2 
      $stageCanvas  create   line           {0 0 30 30 }                    -tags {Line_01}  -fill blue   -width 2 
      
      $stageCanvas  create   rectangle      {180 120 280 180 }              -tags {Line_01}  -fill violet   -width 2 
      $stageCanvas  create   polygon        {40 60  80 50  120 90  180 130  90 150  50 90 35 95} -tags {Line_01}  -outline red  -fill yellow -width 2 

      $stageCanvas  create   oval           {30 160 155 230 }               -tags {Line_01}  -fill red   -width 2         
      $stageCanvas  create   circle         {160 60}            -radius 50  -tags {Line_01}  -fill blue   -width 2 
      $stageCanvas  create   arc            {270 160}           -radius 50  -start 30       -extent 170 -tags {Line_01}  -outline gray  -width 2  -style arc
      
      $stageCanvas  create   text           {140 90}  -text "text a"
      $stageCanvas  create   vectortext     {120 70}  -text "vectorText ab"
      $stageCanvas  create   vectortext     {100 50}  -text "vectorText abc"  -size 10
      $stageCanvas  create   text           {145 95}  -text "text abcd" -size 10
}
proc view::create {windowTitle} {
        #
    variable reportText
    variable stageCanvas
        #
    variable cvObject
    variable cv_scale
    variable drw_scale
        #
    frame .f0 
    set f_view      [labelframe .f0.f_view          -text "view"]
    set f_config    [labelframe .f0.f_config        -text "config"]

    pack  .f0      -expand yes -fill both
    pack  $f_view  $f_config    -side left -expand yes -fill both
    pack  configure  $f_config    -fill y
    
    
    set f_board     [labelframe $f_view.f_board     -text "board"]
    set f_report    [labelframe $f_view.f_report    -text "report"]
    pack  $f_board  $f_report    -side top -expand yes -fill both
   
  
        #
        ### -- G U I - canvas 
    set cvObject    [cad4tcl::new  $f_board  800 600  A3  1.0  25]
    set stageCanvas [$cvObject getCanvas]
    set cv_scale    [$cvObject configure Canvas Scale]
    set drw_scale   [$cvObject configure Stage Scale]
    
        #
        ### -- G U I - canvas report
        #
    set reportText  [text       $f_report.text  -width 50  -height 7]
    set reportScb_x [scrollbar  $f_report.sbx   -orient hori  -command "$reportText xview"]
    set reportScb_y [scrollbar  $f_report.sby   -orient vert  -command "$reportText yview"]
    $reportText     conf -xscrollcommand "$reportScb_x set"
    $reportText     conf -yscrollcommand "$reportScb_y set"
        grid $reportText $reportScb_y   -sticky news
        grid             $reportScb_x   -sticky news
        grid rowconfig    $f_report  0  -weight 1
        grid columnconfig $f_report  0  -weight 1

    if 0 {

            frame .f0 
        set f_canvas  [labelframe .f0.f_canvas   -text "board"  ]
        set f_config  [frame      .f0.f_config   ]

        pack  .f0      -expand yes -fill both
        pack  $f_canvas  $f_config    -side left -expand yes -fill both
        pack  configure  $f_config    -fill y
           
            #
            ### -- G U I - canvas 
        set cvObject    [cad4tcl::new  $f_canvas  800 600  A4  0.5  25]
        set stageCanvas [$cvObject getCanvas]
        set cv_scale    [$cvObject configure Canvas Scale]
        set drw_scale   [$cvObject configure Stage Scale]

            
            #set stageCanvas    [view::createStage    $f_canvas.cv   1000 800  250 250 m  0.5 -bd 2  -bg white  -relief sunken]
    }    

        #
        ### -- G U I - canvas demo
            
    set f_settings  [labelframe .f0.f_config.f_settings  -text "Test - Settings" ]
        
    labelframe  $f_config.tool            -text "Tool"
    labelframe  $f_config.tube            -text "Tube"
    labelframe  $f_config.geometry        -text "Geometry"
    labelframe  $f_config.font            -text font
    labelframe  $f_config.demo            -text demo
    labelframe  $f_config.tooltype        -text "ToolType:"
    labelframe  $f_config.miterView       -text "MiterView:"
    labelframe  $f_config.scale           -text scale

    pack    $f_config.tool        \
            $f_config.geometry    \
            $f_config.tube        \
            $f_config.font        \
            $f_config.demo        \
            $f_config.tooltype    \
            $f_config.miterView   \
            $f_config.scale       \
        -fill x -side top
        
    view::create_config_line $f_config.tool.l_cone        "Length Cone:         "     control::lengthToolCone      10   120   ;#   0
    #view::create_config_line $f_config.tool.l_base        "Length BaseCylinder: "     control::lengthToolBase       0    30   ;#   0
    #view::create_config_line $f_config.tool.d_top         "Diameter Top   :     "     control::diameterToolTop      5    60   ;#   0
    view::create_config_line $f_config.tool.d_bse         "Diameter Base  :     "     control::diameterToolBase    30    70   ;#   0
    #view::create_config_line $f_config.tool.l             "Length:              "     control::lengthTool          90   250   ;#   0
    
    view::create_config_line $f_config.geometry.d_tt      "Angle Tool:          "     control::angleTool           20   160   ;#   0
    view::create_config_line $f_config.geometry.o_t_z     "Offset Tool z:       "     control::lengthOffset_z     -20   120   ;#   0
    view::create_config_line $f_config.geometry.o_t_y     "Offset Tool x:       "     control::lengthOffset_x     -20    50   ;#  24
    view::create_config_line $f_config.geometry.t_a       "Angle Tool-Plane     "     control::angleToolPlane     -90    90   ;#   0
            
    view::create_config_line $f_config.tube.l             "Diameter:            "     control::diameterTube        20    60   ;#   0
    view::create_config_line $f_config.tube.d             "Length:              "     control::lengthTube          30    80   ;#   0
    view::create_config_line $f_config.tube.r             "rotation:            "     control::rotationTube         0   180   ;#   0
    
    radiobutton  $f_config.tooltype.typePlane       -text "Plane"           -variable control::typeTool   -command control::update    -value plane    
    radiobutton  $f_config.tooltype.typeCone        -text "Cone"            -variable control::typeTool   -command control::update    -value cone     
    radiobutton  $f_config.tooltype.typeCylinder    -text "Cylinder"        -variable control::typeTool   -command control::update    -value cylinder 
    radiobutton  $f_config.tooltype.typeCombined    -text "Frustum"         -variable control::typeTool   -command control::update    -value frustum 
        
    pack    $f_config.tooltype.typePlane    \
            $f_config.tooltype.typeCone     \
            $f_config.tooltype.typeCylinder \
            $f_config.tooltype.typeCombined \
        -side top  -fill x
        
    radiobutton  $f_config.miterView.viewRight      -text "right"           -variable control::viewMiter  -command control::update    -value right    
    radiobutton  $f_config.miterView.viewLeft       -text "left"            -variable control::viewMiter  -command control::update    -value left
    
    pack    $f_config.miterView.viewRight \
            $f_config.miterView.viewLeft \
        -side top  -fill x
    
    
        # view::create_config_line $f_config.scale.drw_scale    " Drawing scale "           control::drw_scale  0.2  2  
        #   $f_config.scale.drw_scale.scl      configure       -resolution 0.1
        # button             $f_config.scale.recenter   -text   "recenter"      -command {control::recenter_board}
    view::create_config_line $f_config.scale.cv_scale     " Canvas scale  "           control::cv_scale   0.2  5.0  
                       $f_config.scale.cv_scale.scl       configure       -resolution 0.1  -command "control::scale_board"
    button             $f_config.scale.refit      -text   "refit"         -command {control::refit_board}

    pack      \
            $f_config.scale.cv_scale \
            $f_config.scale.refit \
        -side top  -fill x                                                          
                     
    pack  $f_config  -side top -expand yes -fill both
         
            #
            ### -- G U I - canvas print
            #    
        #set f_print  [labelframe .f0.f_config.f_print  -text "Print" ]
        #    button  $f_print.bt_print   -text "print"  -command {$view::stageCanvas print "E:/manfred/_devlp/_svn_sourceforge.net/canvasCAD/trunk/_print"} 
        #pack  $f_print  -side top     -expand yes -fill x
        #    pack $f_print.bt_print     -expand yes -fill x
        
        
        #
        ### -- G U I - canvas demo
        #   
    set f_demo  [labelframe .f0.f_config.f_demo  -text "Demo" ]
        button  $f_demo.bt_clear   -text "clear"    -command {$::view::cvObject deleteContent} 
        button  $f_demo.bt_update  -text "update"   -command {control::updateStage}
     
    pack  $f_demo  -side top    -expand yes -fill x
        pack $f_demo.bt_clear   -expand yes -fill x
        pack $f_demo.bt_update  -expand yes -fill x
    
    
        #
        ### -- F I N A L I Z E
        #

    control::cleanReport
    control::writeReport "aha"
        # exit
        
        
        ####+### E N D
        
    update
    
    wm minsize . [winfo width  .]   [winfo height  .]
    wm title   . $windowTitle
    
    $cvObject fit

    return . $stageCanvas

}
    #
    # -- update view
    #
set returnValues [view::create $WINDOW_Title]
# set control::myCanvas [lindex $returnValues 1]
    #
    
control::refit_board
    #
# $::view::stageCanvas reportXMLRoot
        
    #
# appUtil::pdict $::model::dict_TubeMiter 
    #
control::update

