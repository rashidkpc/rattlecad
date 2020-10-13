 ##+##########################################################################
 #
 # package: bikeFrame    ->    classProvideBottomBracket.tcl
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
 

oo::class create bikeFrame::ProvideBottomBracket {
        #
    superclass bikeFrame::AbstractProvidePart
        #
    constructor {} {
            #
        puts "              -> class ProvideBottomBracket"
            #
        variable providedObject [bikeFrame::BottomBracket new]
            #
        next
            #
    }
        #
    destructor { 
        puts "            [self] destroy"
    }
        #
    method unknown {target_method args} {
        next $target_method $args
    }
        #
    method update {} {
            # method is called by ... my initValues -> next
            #
        variable providedObject
        variable Position
        variable Scalar
            #
        #set Position(SaddleMount) [vectormath::subVector  $Position(Origin)      [$providedObject getPosition_Top]]
        #set Position(SaddleNose)  [vectormath::addVector  $Position(SaddleMount) [$providedObject getPosition_Nose]]
        #set Position(SaddleTop)   $Position(Origin)
            #
        #set Scalar(Height)        [$providedObject getHeight]
            #
    }
        #
    method setPosition {keyName listXY} {
        return [my prototype_setPosition $keyName $value]
    }
        #
    method getPosition_Mount {} {
        variable Position
        return  $Position(Mount)
    }
        #
    method getPosition_Nose {} {
        variable Position
        return  $Position(Nose)
    }
    method getPosition_Top {} {
        variable Position
        return  $Position(Top)
    }            
        #
    method getHeight {} {
        variable Scalar
        return  $Scalar(Height)
    }            
        #
}

    