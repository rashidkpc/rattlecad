 ##+##########################################################################
 #
 # package: bikeFrame    ->    classAbstractComponent.tcl
 #
 #   bikeFrame is software of Manfred ROSENBERGER
 #       based on tclTk, BWidgets and tdom on their
 #       own Licenses.
 #
 # Copyright (c) Manfred ROSENBERGER, 2016/05/19
 #
 # The author  hereby grant permission to use,  copy, modify, distribute,
 # and  license this  software  and its  documentation  for any  purpose,
 # provided that  existing copyright notices  are retained in  all copies
 # and that  this notice  is included verbatim  in any  distributions. No
 # written agreement, license, or royalty  fee is required for any of the
 # authorized uses.  Modifications to this software may be copyrighted by
 # their authors and need not  follow the licensing terms described here,
 # provided that the new terms are clearly indicated on the first page of
 # each file where they apply.
 #
 # IN NO  EVENT SHALL THE AUTHOR  OR DISTRIBUTORS BE LIABLE  TO ANY PARTY
 # FOR  DIRECT, INDIRECT, SPECIAL,  INCIDENTAL, OR  CONSEQUENTIAL DAMAGES
 # ARISING OUT  OF THE  USE OF THIS  SOFTWARE, ITS DOCUMENTATION,  OR ANY
 # DERIVATIVES  THEREOF, EVEN  IF THE  AUTHOR  HAVE BEEN  ADVISED OF  THE
 # POSSIBILITY OF SUCH DAMAGE.
 #
 # THE  AUTHOR  AND DISTRIBUTORS  SPECIFICALLY  DISCLAIM ANY  WARRANTIES,
 # INCLUDING,   BUT   NOT  LIMITED   TO,   THE   IMPLIED  WARRANTIES   OF
 # MERCHANTABILITY,    FITNESS   FOR    A    PARTICULAR   PURPOSE,    AND
 # NON-INFRINGEMENT.  THIS  SOFTWARE IS PROVIDED  ON AN "AS  IS" BASIS,
 # AND  THE  AUTHOR  AND  DISTRIBUTORS  HAVE  NO  OBLIGATION  TO  PROVIDE
 # MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 #
 # ---------------------------------------------------------------------------
 #    namespace:  bikeFrame
 # ---------------------------------------------------------------------------
 #
 # http://www.magicsplat.com/articles/oo.html
 #
 #
 # 0.00 - 20160417
 #      ... new: rattleCAD - 3.4.03
 #
 #
 #


oo::class create bikeFrame::AbstractComponent {
        #
    variable Config    ;# config Parameter set by
    variable Direction    ;# {x y}
    variable Position     ;# {x y}
    variable Scalar       ;# {x}
    
    #variable Config    ;# config Parameter set by
    #variable Direction    ;# {x y}
    #variable Position     ;# {x y}
    #variable Scalar       ;# {x}
    variable CenterLine   ;# list: {x y x y x y ...}        
    variable Profile      ;# list: {x y x y x y ...}        
    variable Shape        ;# list: {{x y} {x y} {x y} {x y} ...}
    
    
        #
    # variable _File
    # variable _Polygon
        #
    constructor {} {
        if {![lindex [self call] 1]} {
            return -code error "class '[info object class [self]]' is abstract"
        }
        puts "              -> superclass AbstractComponent"
            #
        variable Position;    array set Position    {
                                            Origin {0 0}
                                            End    {1 1}
                                }
        variable Direction;   array set Direction   {Config {1 0}}
            #
    }
        #
    destructor { 
        puts "            [self] destroy"
    }
        #
    method unknown {target_method args} {
        puts "            <E> ... [info object class [self]]  $target_method $args  ... unknown"
        return -code error " '[info object class [self]]' $target_method $args  ... unknown"
    }
        #
    method initValues {compDict} {
        my prototype_initValues $compDict
    }
        #
    method update {} {}    
        #
    method setConfig {keyName value} {
        return [my prototype_setConfig $keyName $value]
    }
        #
    method setDirection {keyName listXY} {
        return [my prototype_setDirection $keyName $listXY]
    }
        #
    method setPosition {keyName listXY} {
        return [my prototype_setPosition $keyName $value]
    }
        #
    method setScalar {keyName value} {
        return [my prototype_setScalar $keyName $value]
    }
        #
    method getDictionary {} {
        return [my prototype_getDictionary]
    }
        #     
    method getConfig {keyName} {
        return [my prototype_getConfig $keyName]
    }
        #
    method getDirection {{type cartesian}} {
        return [my prototype_getDirection $type]
    }
        #
    method getFile {} {
        variable Config
        return  $Config(File)
    }
        #
    method getPosition {{positionName {}}} {
        return [my prototype_getPosition $positionName]
    }
        #
    method getShape {{shapeName {}}} {
        return [my prototype_getShape $shapeName]
    }
        #
    method getScalar {keyName} {
        return [my prototype_getScalar $keyName]
    }
        #
    method reportValues {} {
        my prototype_reportValues
    }
        #
}
    #
oo::define bikeFrame::AbstractComponent {mixin bikeFrame::MixinMethodProtoypes}
    #
