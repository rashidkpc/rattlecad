########################################################################
# BigFloat for Tcl
# Copyright (C) 2003-2005  ARNOLD Stephane
#
# BIGFLOAT LICENSE TERMS
#
# This software is copyrighted by Stephane ARNOLD, (stephanearnold <at> yahoo.fr).
# The following terms apply to all files associated
# with the software unless explicitly disclaimed in individual files.
#
# The authors hereby grant permission to use, copy, modify, distribute,
# and license this software and its documentation for any purpose, provided
# that existing copyright notices are retained in all copies and that this
# notice is included verbatim in any distributions. No written agreement,
# license, or royalty fee is required for any of the authorized uses.
# Modifications to this software may be copyrighted by their authors
# and need not follow the licensing terms described here, provided that
# the new terms are clearly indicated on the first page of each file where
# they apply.
#
# IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
# FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
# ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
# DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
# IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
# NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
# MODIFICATIONS.
#
# GOVERNMENT USE: If you are acquiring this software on behalf of the
# U.S. government, the Government shall have only "Restricted Rights"
# in the software and related documentation as defined in the Federal
# Acquisition Regulations (FARs) in Clause 52.227.19 (c) (2).  If you
# are acquiring the software on behalf of the Department of Defense, the
# software shall be classified as "Commercial Computer Software" and the
# Government shall have only "Restricted Rights" as defined in Clause
# 252.227-7013 (c) (1) of DFARs.  Notwithstanding the foregoing, the
# authors grant the U.S. Government and others acting in its behalf
# permission to use and distribute the software in accordance with the
# terms specified in this license.
#
########################################################################

package require Tcl 8.4
package require math::bignum

# this line helps when I want to source this file again and again
catch {namespace delete ::math::bigfloat}

# private namespace
# this software works only with Tcl v8.4 and higher
# it is using the package math::bignum
namespace eval ::math::bigfloat {
    # cached constants
    # ln(2) with arbitrary precision
    variable Log2
    # Pi with arb. precision
    variable Pi
    variable _pi0
    # some constants (bignums) : {0 1 2 3 4 5 10}
    variable zero
    set zero [::math::bignum::fromstr 0]
    variable one
    set one [::math::bignum::fromstr 1]
    variable two
    set two [::math::bignum::fromstr 2]
    variable three
    set three [::math::bignum::fromstr 3]
    variable four
    set four [::math::bignum::fromstr 4]
    variable five
    set five [::math::bignum::fromstr 5]
    variable ten
    set ten [::math::bignum::fromstr 10]
}




################################################################################
# procedures that handle floating-point numbers
# these procedures are sorted by name (after eventually removing the underscores)
# 
# BigFloats are internally represented as a list :
# {"F" Mantissa Exponent Delta} where "F" is a character which determins
# the datatype, Mantissa and Delta are two Big integers and Exponent a raw integer.
#
# The BigFloat value equals to (Mantissa +/- Delta)*2^Exponent
# So the internal representation is binary, but trying to get as close as possible to
# the decimal one.
# When calling fromstr, the Delta parameter is set to the value of the last decimal digit.
# Example : 1.50 belongs to [1.49,1.51], but internally Delta is probably not equal to 1,
# because of the binary representation.
# 
# So Mantissa and Delta are not limited in size, but in practice Delta is kept under
# 2^32 by the 'normalize' procedure, to avoid a never-ended growth of memory used.
# Indeed, when you perform some computations, the Delta parameter (which represent
# the uncertainty on the value of the Mantissa) may increase.
# Exponent, as a classic integer, is limited to the interval [-2147483648,2147483647]

# Retrieving the parameters of a BigFloat is often done with that command :
# foreach {dummy int exp delta} $bigfloat {break}
# (dummy is not used, it is just used to get the "F" marker).
# The isInt, isFloat, checkNumber and checkFloat procedures are used
# to check data types
#
# Taylor development are often used to compute the analysis functions (like exp(),log()...)
# To learn how it is done in practice, take a look at ::math::bigfloat::_asin
# While doing computation on Mantissas, we do not care about the last digit,
# because if we compute wisely Deltas, the digits that remain will be exact.
################################################################################


################################################################################
# returns the absolute value
################################################################################
proc ::math::bigfloat::abs {number} {
    checkNumber number
    if {[isInt $number]} {
        # set sign to positive for a BigInt
        return [::math::bignum::abs $number]
    }
    # set sign to positive for a BigFloat into the Mantissa (index 1)
    lset number 1 [::math::bignum::abs [lindex $number 1]]
    return $number
}


################################################################################
# arccosinus of a BigFloat
################################################################################
proc ::math::bigfloat::acos {x} {
    # handy proc for checking datatype
    checkFloat x
    foreach {dummy entier exp delta} $x {break}
    set precision [expr {($exp<0)?(-$exp):1}]
    # acos(0.0)=Pi/2
    # 26/07/2005 : changed precision from decimal to binary
    # with the second parameter of pi command
    set piOverTwo [floatRShift [pi $precision 1]]
    if {[iszero $x]} {
        # $x is too close to zero -> acos(0)=PI/2
        return $piOverTwo
    }
    # acos(-x)= Pi/2 + asin(x)
    if {[::math::bignum::sign $entier]} {
        return [add $piOverTwo [asin [abs $x]]]
    }
    # we always use _asin to compute the result
    # but as it is a Taylor development, the value given to [_asin]
    # has to be a bit smaller than 1 ; by using that trick : acos(x)=asin(sqrt(1-x^2))
    # we can limit the entry of the Taylor development below 1/sqrt(2)
    if {[compare $x [fromstr 0.7071]]>0} {
        # x > sqrt(2)/2 : trying to make _asin converge quickly 
        # creating 0 and 1 with the same precision as the entry
        variable one
        variable zero
        set fzero [list F $zero -$precision $one]
        set fone [list F [::math::bignum::lshift 1 $precision] \
                -$precision $one]
        # when $x is close to 1 (acos(1.0)=0.0)
        if {[equal $fone $x]} {
            return $fzero
        }
        if {[compare $fone $x]<0} {
            # the behavior assumed because acos(x) is not defined
            # when |x|>1
            error "acos on a number greater than 1"
        }
        # acos(x) = asin(sqrt(1 - x^2))
        # since 1 - cos(x)^2 = sin(x)^2
        # x> sqrt(2)/2 so x^2 > 1/2 so 1-x^2<1/2
        set x [sqrt [sub $fone [mul $x $x]]]
        # the parameter named x is smaller than sqrt(2)/2
        return [_asin $x]
    }
    # acos(x) = Pi/2 - asin(x)
    # x<sqrt(2)/2 here too
    return [sub $piOverTwo [_asin $x]]
}


################################################################################
# returns A + B
################################################################################
proc ::math::bigfloat::add {a b} {
    checkNumber a b
    if {[isInt $a]} {
        if {[isInt $b]} {
            # intAdd adds two BigInts
            return [::math::bignum::add $a $b]
        }
        # adds the BigInt a to the BigFloat b
        return [addInt2Float $b $a]
    }
    if {[isInt $b]} {
        # ... and vice-versa
        return [addInt2Float $a $b]
    }
    # retrieving parameters from A and B
    foreach {dummy integerA expA deltaA} $a {break}
    foreach {dummy integerB expB deltaB} $b {break}
    # when we add two numbers which have different digit numbers (after the dot)
    # for example : 1.0 and 0.00001
    # We promote the one with the less number of digits (1.0) to the same level as
    # the other : so 1.00000. 
    # that is why we shift left the number which has the greater exponent
    # But we do not forget the Delta parameter, which is lshift'ed too.
    if {$expA>$expB} {
        set diff [expr {$expA-$expB}]
        set integerA [::math::bignum::lshift $integerA $diff]
        set deltaA [::math::bignum::lshift $deltaA $diff]
        set integerA [::math::bignum::add $integerA $integerB]
        set deltaA [::math::bignum::add $deltaA $deltaB]
        return [normalize [list F $integerA $expB $deltaA]]
    } elseif {$expA==$expB} {
        # nothing to shift left
        return [normalize [list F [::math::bignum::add $integerA $integerB] \
                $expA [::math::bignum::add $deltaA $deltaB]]]
    } else {
        set diff [expr {$expB-$expA}]
        set integerB [::math::bignum::lshift $integerB $diff]
        set deltaB [::math::bignum::lshift $deltaB $diff]
        set integerB [::math::bignum::add $integerA $integerB]
        set deltaB [::math::bignum::add $deltaB $deltaA]
        return [normalize [list F $integerB $expA $deltaB]]
    }
}

################################################################################
# returns the sum A(BigFloat) + B(BigInt)
# the greatest advantage of this method is that the uncertainty
# of the result remains unchanged, in respect to the entry's uncertainty (deltaA)
################################################################################
proc ::math::bigfloat::addInt2Float {a b} {
    # type checking
    checkFloat a
    if {![isInt $b]} {
        error "'$b' is not a BigInt"
    }
    # retrieving data from $a
    foreach {dummy integerA expA deltaA} $a {break}
    # to add an int to a BigFloat,...
    if {$expA>0} {
        # we have to put the integer integerA
        # to the level of zero exponent : 1e8 --> 100000000e0
        set shift $expA
        set integerA [::math::bignum::lshift $integerA $shift]
        set deltaA [::math::bignum::lshift $deltaA $shift]
        set integerA [::math::bignum::add $integerA $b]
        # we have to normalize, because we have shifted the mantissa
        # and the uncertainty left
        return [normalize [list F $integerA 0 $deltaA]]
    } elseif {$expA==0} {
        # integerA is already at integer level : float=(integerA)e0
        return [normalize [list F [::math::bignum::add $integerA $b] \
                0 $deltaA]]
    } else {
        # here we have something like 234e-2 + 3
        # we have to shift the integer left by the exponent |$expA|
        set b [::math::bignum::lshift $b [expr {-$expA}]]
        set integerA [::math::bignum::add $integerA $b]
        return [normalize [list F $integerA $expA $deltaA]]
    }
}


################################################################################
# arcsinus of a BigFloat
################################################################################
proc ::math::bigfloat::asin {x} {
    # type checking
    checkFloat x
    foreach {dummy entier exp delta} $x {break}
    if {$exp>-1} {
        error "not enough precision on input (asin)"
    }
    set precision [expr {-$exp}]
    # when x=0, return 0 at the same precision as the input was
    if {[iszero $x]} {
        variable one
        variable zero
        return [list F $zero -$precision $one]
    }
    # asin(-x)=-asin(x)
    if {[::math::bignum::sign $entier]} {
        return [opp [asin [abs $x]]]
    }
    # 26/07/2005 : changed precision from decimal to binary
    set piOverTwo [floatRShift [pi $precision 1]]
    # now a little trick : asin(x)=Pi/2-asin(sqrt(1-x^2))
    # so we can limit the entry of the Taylor development
    # to 1/sqrt(2)~0.7071
    # the comparison is : if x>0.7071 then ...
    if {[compare $x [fromstr 0.7071]]>0} {
        variable one
        set fone [list F [::math::bignum::lshift 1 $precision] \
                -$precision $one]
        # asin(1)=Pi/2 (with the same precision as the entry has)
        if {[equal $fone $x]} {
            return $piOverTwo
        }
        if {[compare $x $fone]>0} {
            error "asin on a number greater than 1"
        }
        # asin(x)=Pi/2-asin(sqrt(1-x^2))
        set x [sqrt [sub $fone [mul $x $x]]]
        return [sub $piOverTwo [_asin $x]]
    }
    return [normalize [_asin $x]]
}

################################################################################
# _asin : arcsinus of numbers between 0 and +1
################################################################################
proc ::math::bigfloat::_asin {x} {
    # Taylor development
    # asin(x)=x + 1/2 x^3/3 + 3/2.4 x^5/5 + 3.5/2.4.6 x^7/7 + ...
    # into this iterative form :
    # asin(x)=x * (1 + 1/2 * x^2 * (1/3 + 3/4 *x^2 * (...
    # ...* (1/(2n-1) + (2n-1)/2n * x^2 / (2n+1))...)))
    # we show how is really computed the development : 
    # we don't need to set a var with x^n or a product of integers
    # all we need is : x^2, 2n-1, 2n, 2n+1 and a few variables
    foreach {dummy mantissa exp delta} $x {break}
    set precision [expr {-$exp}]
    if {$precision+1<[::math::bignum::bits $mantissa]} {
        error "sinus greater than 1"
    }
    # precision is the number of after-dot digits
    set result $mantissa
    set delta_final $delta
    # resultat is the final result, and delta_final
    # will contain the uncertainty of the result
    # square is the square of the mantissa
    set square [intMulShift $mantissa $mantissa $precision]
    # dt is the uncertainty of Mantissa
    set dt [::math::bignum::add 1 [intMulShift $mantissa $delta [expr {$precision-1}]]]
    # these three are required to compute the fractions implicated into
    # the development (of Taylor, see former)
    variable one
    set num $one
    # two will be used into the loop
    variable two
    variable three
    set i $three
    set denom $two
    # the nth factor equals : $num/$denom* $mantissa/$i
    set delta [::math::bignum::add [::math::bignum::mul $delta $square] \
            [::math::bignum::mul $dt [::math::bignum::add $delta $mantissa]]]
    set delta [::math::bignum::add 1 [::math::bignum::rshift [::math::bignum::div \
            [::math::bignum::mul $delta $num] $denom] $precision]]
    # we do not multiply the Mantissa by $num right now because it is 1 !
    # but we have Mantissa=$x
    # and we want Mantissa*$x^2 * $num / $denom / $i
    set mantissa [intMulShift $mantissa $square $precision]
    set mantissa [::math::bignum::div $mantissa $denom]
    # do not forget the modified Taylor development :
    # asin(x)=x * (1 + 1/2*x^2*(1/3 + 3/4*x^2*(...*(1/(2n-1) + (2n-1)/2n*x^2/(2n+1))...)))
    # all we need is : x^2, 2n-1, 2n, 2n+1 and a few variables
    # $num=2n-1 $denom=2n $square=x^2 and $i=2n+1
    set mantissa_temp [::math::bignum::div $mantissa $i]
    set delta_temp [::math::bignum::add 1 [::math::bignum::div $delta $i]]
    # when the Mantissa increment is smaller than the Delta increment,
    # we would not get much precision by continuing the development
    while {![::math::bignum::iszero $mantissa_temp]} {
        # Mantissa = Mantissa * $num/$denom * $square
        # Add Mantissa/$i, which is stored in $mantissa_temp, to the result
        set result [::math::bignum::add $result $mantissa_temp]
        set delta_final [::math::bignum::add $delta_final $delta_temp]
        # here we have $two instead of [fromstr 2] (optimization)
        # num=num+2,i=i+2,denom=denom+2
        # because num=2n-1 denom=2n and i=2n+1
        set num [::math::bignum::add $num $two]
        set i [::math::bignum::add $i $two]
        set denom [::math::bignum::add $denom $two]
        # computes precisly the future Delta parameter
        set delta [::math::bignum::add [::math::bignum::mul $delta $square] \
                [::math::bignum::mul $dt [::math::bignum::add $delta $mantissa]]]
        set delta [::math::bignum::add 1 [::math::bignum::rshift [::math::bignum::div \
                [::math::bignum::mul $delta $num] $denom] $precision]]
        set mantissa [intMulShift $mantissa $square $precision]
        set mantissa [::math::bignum::div [::math::bignum::mul $mantissa $num] $denom]
        set mantissa_temp [::math::bignum::div $mantissa $i]
        set delta_temp [::math::bignum::add 1 [::math::bignum::div $delta $i]]
    }
    return [list F $result $exp $delta_final]
}

################################################################################
# arctangent : returns atan(x)
################################################################################
proc ::math::bigfloat::atan {x} {
    checkFloat x
    variable one
    variable two
    variable three
    variable four
    variable zero
    foreach {dummy mantissa exp delta} $x {break}
    if {$exp>=0} {
        error "not enough precision to compute atan"
    }
    set precision [expr {-$exp}]
    # atan(0)=0
    if {[iszero $x]} {
        return [list F $zero -$precision $one]
    }
    # atan(-x)=-atan(x)
    if {[::math::bignum::sign $mantissa]} {
        return [opp [atan [abs $x]]]
    }
    # now x is strictly positive
    # at this moment, we are trying to limit |x| to a fair acceptable number
    # to ensure that Taylor development will converge quickly
    set float1 [list F [::math::bignum::lshift 1 $precision] -$precision $one]
    if {[compare $float1 $x]<0} {
        # compare x to 2.4142
        if {[compare $x [fromstr 2.4142]]<0} {
            # atan(x)=Pi/4 + atan((x-1)/(x+1))
            # as 1<x<2.4142 : (x-1)/(x+1)=1-2/(x+1) belongs to
            # the range :  ]0,1-2/3.414[
            # that equals  ]0,0.414[
            set pi_sur_quatre [div [pi $precision 1] $four]
            return [add $pi_sur_quatre [atan \
                    [div [sub $x $float1] [add $x $float1]]]]
        }
        # atan(x)=Pi/2-atan(1/x)
        # 1/x < 1/2.414 so the argument is lower than 0.414
        set pi_over_two [div [pi $precision 1] $two]
        return [sub $pi_over_two [atan [div $float1 $x]]]
    }
    if {[compare $x [fromstr 0.4142]]>0} {
        # atan(x)=Pi/4 + atan((x-1)/(x+1))
        # x>0.420 so (x-1)/(x+1)=1 - 2/(x+1) > 1-2/1.414
        #                                    > -0.414
        # x<1 so (x-1)/(x+1)<0
        set pi_sur_quatre [div [pi $precision 1] $four]
        return [add $pi_sur_quatre [atan \
                [div [sub $x $float1] [add $x $float1]]]]
    }
    # precision increment : to have less uncertainty
    # we add a little more precision so that the result would be more accurate
    # Taylor development : x - x^3/3 + x^5/5 - ... + (-1)^(n+1)*x^(2n-1)/(2n-1)
    # when we have n steps in Taylor development : the nth term is :
    # x^(2n-1)/(2n-1)
    # and the loss of precision is of 2n (n sums and n divisions)
    # this command is called with x<sqrt(2)-1
    # if we add an increment to the precision, say n:
    # (sqrt(2)-1)^(2n-1)/(2n-1) has to be lower than 2^(-precision-n-1)
    # (2n-1)*log(sqrt(2)-1)-log(2n-1)<-(precision+n+1)*log(2)
    # 2n(log(sqrt(2)-1)-log(sqrt(2)))<-(precision-1)*log(2)+log(2n-1)+log(sqrt(2)-1)
    # 2n*log(1-1/sqrt(2))<-(precision-1)*log(2)+log(2n-1)+log(2)/2
    # 2n/sqrt(2)>(precision-3/2)*log(2)-log(2n-1)
    # hence log(2n-1)<2n-1
    # n*sqrt(2)>(precision-1.5)*log(2)+1-2n
    # n*(sqrt(2)+2)>(precision-1.5)*log(2)+1
    set n [expr {int((log(2)*($precision-1.5)+1)/(sqrt(2)+2)+1)}]
    incr precision $n
    set mantissa [::math::bignum::lshift $mantissa $n]
    set delta [::math::bignum::lshift $delta $n]
    # end of adding precision increment
    # now computing Taylor development :
    # atan(x)=x - x^3/3 + x^5/5 - x^7/7 ... + (-1)^n*x^(2n+1)/(2n+1)
    # atan(x)=x * (1 - x^2 * (1/3 - x^2 * (1/5 - x^2 * (...*(1/(2n-1) - x^2 / (2n+1))...))))
    # what do we need to compute this ?
    # x^2 ($square), 2n+1 ($divider), $result, the nth term of the development ($t)
    # and the nth term multiplied by 2n+1 ($temp)
    # then we do this (with care keeping as much precision as possible):
    # while ($t <>0) :
    #     $result=$result+$t
    #     $temp=$temp * $square
    #     $divider = $divider+2
    #     $t=$temp/$divider
    # end-while
    set result $mantissa
    set delta_end $delta
    # we store the square of the integer (mantissa)
    set delta_square [::math::bignum::lshift $delta 1]
    set square [intMulShift $mantissa $mantissa $precision]
    # the (2n+1) divider
    set divider $three
    # computing precisely the uncertainty
    set delta [::math::bignum::add 1 [::math::bignum::rshift [::math::bignum::add \
            [::math::bignum::mul $delta_square $mantissa] \
            [::math::bignum::mul $delta $square]] $precision]]
    # temp contains (-1)^n*x^(2n+1)
    set temp [opp [intMulShift $mantissa $square $precision]]
    set t [::math::bignum::div $temp $divider]
    set dt [::math::bignum::add 1 [::math::bignum::div $delta $divider]]
    while {![::math::bignum::iszero $t]} {
        set result [::math::bignum::add $result $t]
        set delta_end [::math::bignum::add $delta_end $dt]
        set divider [::math::bignum::add $divider $two]
        set delta [::math::bignum::add 1 [::math::bignum::rshift [::math::bignum::add \
                [::math::bignum::mul $delta_square [abs $temp]] [::math::bignum::mul $delta \
                [::math::bignum::add $delta_square $square]]] $precision]]
        set temp [opp [intMulShift $temp $square $precision]]
        set t [::math::bignum::div $temp $divider]
        set dt [::math::bignum::add [::math::bignum::div $delta $divider] $one]
    }
    # we have to normalize because the uncertainty might be greater than 99
    # moreover it is the most often case
    return [normalize [list F $result [expr {$exp-$n}] $delta_end]]
}


################################################################################
# compute atan(1/integer) at a given precision
# this proc is only used to compute Pi
# it is using the same Taylor development as [atan]
################################################################################
proc ::math::bigfloat::_atanfract {integer precision} {
    # Taylor development : x - x^3/3 + x^5/5 - ... + (-1)^(n+1)*x^(2n-1)/(2n-1)
    # when we have n steps in Taylor development : the nth term is :
    # 1/denom^(2n+1)/(2n+1)
    # and the loss of precision is of 2n (n sums and n divisions)
    # this command is called with integer>=5
    #
    # We do not want to compute the Delta parameter, so we just
    # can increment precision (with lshift) in order for the result to be precise.
    # Remember : we compute atan2(1,$integer) with $precision bits
    # $integer has no Delta parameter as it is a BigInt, of course, so
    # theorically we could compute *any* number of digits.
    #
    # if we add an increment to the precision, say n:
    # (1/5)^(2n-1)/(2n-1)     has to be lower than (1/2)^(precision+n-1)
    # Calculus :
    # log(left term) < log(right term)
    # log(1/left term) > log(1/right term)
    # (2n-1)*log(5)+log(2n-1)>(precision+n-1)*log(2)
    # n(2log(5)-log(2))>(precision-1)*log(2)-log(2n-1)+log(5)
    # -log(2n-1)>-(2n-1)
    # n(2log(5)-log(2)+2)>(precision-1)*log(2)+1+log(5)
    set n [expr {int((($precision-1)*log(2)+1+log(5))/(2*log(5)-log(2)+2)+1)}]
    incr precision $n
    # first term of the development : 1/integer
    set a [::math::bignum::div [::math::bignum::lshift 1 $precision] $integer]
    # 's' will contain the result
    set s $a
    # Taylor development : x - x^3/3 + x^5/5 - ... + (-1)^(n+1)*x^(2n-1)/(2n-1)
    # equals x (1 - x^2 * (1/3 + x^2 * (... * (1/(2n-3) + (-1)^(n+1) * x^2 / (2n-1))...)))
    # all we need to store is : 2n-1 ($denom), x^(2n+1) and x^2 ($square) and two results :
    # - the nth term => $u
    # - the nth term * (2n-1) => $t
    # + of course, the result $s
    set square [::math::bignum::mul $integer $integer]
    variable two
    variable three
    set denom $three
    # $t is (-1)^n*x^(2n+1)
    set t [opp [::math::bignum::div $a $square]]
    set u [::math::bignum::div $t $denom]
    # we break the loop when the current term of the development is null
    while {![::math::bignum::iszero $u]} {
        set s [::math::bignum::add $s $u]
        # denominator= (2n+1)
        set denom [::math::bignum::add $denom $two]
        # div $t by x^2
        set t [opp [::math::bignum::div $t $square]]
        set u [::math::bignum::div $t $denom]
    }
    # go back to the initial precision
    return [::math::bignum::rshift $s $n]
}

    
################################################################################
# returns the integer part of a BigFloat, as a BigInt
# the result is the same one you would have
# if you had called [expr {ceil($x)}]
################################################################################
proc ::math::bigfloat::ceil {number} {
    checkFloat number
    set number [normalize $number]
    if {[iszero $number]} {
        # returns the BigInt 0
        variable zero
        return $zero
    }
    foreach {dummy integer exp delta} $number {break}
    if {$exp>=0} {
        error "not enough precision to perform rounding (ceil)"
    }
    # saving the sign ...
    set sign [::math::bignum::sign $integer]
    set integer [abs $integer]
    # integer part
    set try [::math::bignum::rshift $integer [expr {-$exp}]]
    if {$sign} {
        return [opp $try]
    }
    # fractional part
    if {![equal [::math::bignum::lshift $try [expr {-$exp}]] $integer]} {
        return [::math::bignum::add 1 $try]
    }
    return $try
}


################################################################################
# checks each variable to be a BigFloat
# arguments : each argument is the name of a variable to be checked
################################################################################
proc ::math::bigfloat::checkFloat {args} {
    foreach x $args {
        upvar $x n
        if {![isFloat $n]} {
            error "BigFloat expected : received '$n'"
        }
    }
}

################################################################################
# checks if each number is either a BigFloat or a BigInt
# arguments : each argument is the name of a variable to be checked
################################################################################
proc ::math::bigfloat::checkNumber {args} {
    foreach i $args {
        upvar $i x
        if {![isInt $x] && ![isFloat $x]} {
            error "'$x' is not a number"
        }
    }
}


################################################################################
# returns 0 if A and B are equal, else returns 1 or -1
# accordingly to the sign of (A - B)
################################################################################
proc ::math::bigfloat::compare {a b} {
    if {[isInt $a] && [isInt $b]} {
        return [::math::bignum::cmp $a $b]
    }
    checkFloat a b
    if {[equal $a $b]} {return 0}
    return [expr {([::math::bignum::sign [lindex [sub $a $b] 1]])?-1:1}]
}




################################################################################
# gets cos(x)
# throws an error if there is not enough precision on the input
################################################################################
proc ::math::bigfloat::cos {x} {
    checkFloat x
    foreach {dummy integer exp delta} $x {break}
    if {$exp>-2} {
        error "not enough precision on floating-point number"
    }
    set precision [expr {-$exp}]
    # cos(2kPi+x)=cos(x)
    foreach {n integer} [divPiQuarter $integer $precision] {break}
    # now integer>=0 and <Pi/2
    set d [expr {[tostr $n]%4}]
    # add trigonometric circle turns number to delta
    set delta [::math::bignum::add [abs $n] $delta]
    set signe 0
    # cos(Pi-x)=-cos(x)
    # cos(-x)=cos(x)
    # cos(Pi/2-x)=sin(x)
    switch -- $d {
        1 {set signe 1;set l [_sin2 $integer $precision $delta]}
        2 {set signe 1;set l [_cos2 $integer $precision $delta]}
        0 {set l [_cos2 $integer $precision $delta]}
        3 {set l [_sin2 $integer $precision $delta]}
        default {error "internal error"}
    }
    # precision -> exp (multiplied by -1)
    lset l 1 [expr {-([lindex $l 1])}]
    # set the sign
    set integer [lindex $l 0]
    ::math::bignum::setsign integer $signe
    lset l 0 $integer
    return [normalize [linsert $l 0 F]]
}

################################################################################
# compute cos(x) where 0<=x<Pi/2
# returns : a list formed with :
# 1. the mantissa
# 2. the precision (opposite of the exponent)
# 3. the uncertainty (doubt range)
################################################################################
proc ::math::bigfloat::_cos2 {x precision delta} {
    # precision bits after the dot
    set pi [_pi $precision]
    set pis4 [::math::bignum::rshift $pi 2]
    set pis2 [::math::bignum::rshift $pi 1]
    if {[::math::bignum::cmp $x $pis4]>=0} {
        # cos(Pi/2-x)=sin(x)
        set x [::math::bignum::sub $pis2 $x]
        set delta [::math::bignum::add 1 $delta]
        return [_sin $x $precision $delta]
    }
    return [_cos $x $precision $delta]
}

################################################################################
# compute cos(x) where 0<=x<Pi/4
# returns : a list formed with :
# 1. the mantissa
# 2. the precision (opposite of the exponent)
# 3. the uncertainty (doubt range)
################################################################################
proc ::math::bigfloat::_cos {x precision delta} {
    variable zero
    variable one
    variable two
    set float1 [::math::bignum::lshift $one $precision]
    # Taylor development follows :
    # cos(x)=1-x^2/2 + x^4/4! ... + (-1)^(2n)*x^(2n)/2n!
    # cos(x)= 1 - x^2/1.2 * (1 - x^2/3.4 * (... * (1 - x^2/(2n.(2n-1))...))
    # variables : $s (the Mantissa of the result)
    # $denom1 & $denom2 (2n-1 & 2n)
    # $x as the square of what is named x in 'cos(x)'
    set s $float1
    # 'd' is the uncertainty on x^2
    set d [::math::bignum::mul $x [::math::bignum::lshift $delta 1]]
    set d [::math::bignum::add 1 [::math::bignum::rshift $d $precision]]
    # x=x^2 (because in this Taylor development, there are only even powers of x)
    set x [intMulShift $x $x $precision]
    set denom1 $one
    set denom2 $two
    set t [opp [::math::bignum::rshift $x 1]]
    set delta $zero
    set dt $d
    while {![::math::bignum::iszero $t]} {
        set s [::math::bignum::add $s $t]
        set delta [::math::bignum::add $delta $dt]
        set denom1 [::math::bignum::add $denom1 $two]
        set denom2 [::math::bignum::add $denom2 $two]
        set dt [::math::bignum::rshift [::math::bignum::add [::math::bignum::mul $x $dt]\
                [::math::bignum::mul [::math::bignum::add $t $dt] $d]] $precision]
        set dt [::math::bignum::add 1 $dt]
        set t [intMulShift $x $t $precision]
        set t [opp [::math::bignum::div $t [::math::bignum::mul $denom1 $denom2]]]
    }
    return [list $s $precision $delta]
}

################################################################################
# cotangent : the trivial algorithm is used
################################################################################
proc ::math::bigfloat::cotan {x} {
    return [::math::bigfloat::div [::math::bigfloat::cos $x] [::math::bigfloat::sin $x]]
}

################################################################################
# converts angles from degrees to radians
# deg/180=rad/Pi
################################################################################
proc ::math::bigfloat::deg2rad {x} {
    checkFloat x
    set xLen [expr {-[lindex $x 2]}]
    if {$xLen<3} {
        error "number too loose to convert to radians"
    }
    set pi [pi $xLen 1]
    return [div [mul $x $pi] [::math::bignum::fromstr 180]]
}



################################################################################
# private proc to get : x modulo Pi/2
# and the quotient (x divided by Pi/2)
# used by cos , sin & others
################################################################################
proc ::math::bigfloat::divPiQuarter {integer precision} {
    incr precision 2
    set integer [::math::bignum::lshift $integer 1]
    set dpi [_pi $precision]
    # modulo 2Pi
    foreach {n integer} [::math::bignum::divqr $integer $dpi] {break}
    # end modulo 2Pi
    set pi [::math::bignum::rshift $dpi 1]
    foreach {n integer} [::math::bignum::divqr $integer $pi] {break}
    # now divide by Pi/2
    # multiply n by 2
    set n [::math::bignum::lshift $n 1]
    # pis2=pi/2
    set pis2 [::math::bignum::rshift $pi 1]
    foreach {m integer} [::math::bignum::divqr $integer $pis2] {break}
    return [list [::math::bignum::add $n $m] [::math::bignum::rshift $integer 1]]
}


################################################################################
# divide A by B and returns the result
# throw error : divide by zero
################################################################################
proc ::math::bigfloat::div {a b} {
    variable one
    checkNumber a b
    # dispatch to an appropriate procedure 
    if {[isInt $a]} {
        if {[isInt $b]} {
            return [::math::bignum::div $a $b]
        }
        error "trying to divide a BigInt by a BigFloat"
    }
    if {[isInt $b]} {return [divFloatByInt $a $b]}
    foreach {dummy integerA expA deltaA} $a {break}
    foreach {dummy integerB expB deltaB} $b {break}
    # computes the limits of the doubt (or uncertainty) interval
    set BMin [::math::bignum::sub $integerB $deltaB]
    set BMax [::math::bignum::add $integerB $deltaB]
    if {[::math::bignum::cmp $BMin $BMax]>0} {
        # swap BMin and BMax
        set temp $BMin
        set BMin $BMax
        set BMax $temp
    }
    # multiply by zero gives zero
    if {[::math::bignum::iszero $integerA]} {
        # why not return any number or the integer 0 ?
        # because there is an exponent that might be different between two BigFloats
        # 0.00 --> exp = -2, 0.000000 -> exp = -6
        return $a 
    }
    # test of the division by zero
    if {[::math::bignum::sign $BMin]+[::math::bignum::sign $BMax]==1 || \
                [::math::bignum::iszero $BMin] || [::math::bignum::iszero $BMax]} {
        error "divide by zero"
    }
    # shift A because we need accuracy
    set l [math::bignum::bits $integerB]
    set integerA [::math::bignum::lshift $integerA $l]
    set deltaA [::math::bignum::lshift $deltaA $l]
    set exp [expr {$expA-$l-$expB}]
    # relative uncertainties (dX/X) are added
    # to give the relative uncertainty of the result
    # i.e. 3% on A + 2% on B --> 5% on the quotient
    # d(A/B)/(A/B)=dA/A + dB/B
    # Q=A/B
    # dQ=dA/B + dB*A/B*B
    # dQ is "delta"
    set delta [::math::bignum::div [::math::bignum::mul $deltaB \
            [abs $integerA]] [abs $integerB]]
    set delta [::math::bignum::div [::math::bignum::add\
            [::math::bignum::add 1 $delta]\
            $deltaA] [abs $integerB]]
    set quotient [::math::bignum::div $integerA $integerB]
    if {[::math::bignum::sign $integerB]+[::math::bignum::sign $integerA]==1} {
        set quotient [::math::bignum::sub $quotient 1]
    }
    return [normalize [list F $quotient $exp [::math::bignum::add $delta 1]]]
}




################################################################################
# divide a BigFloat A by a BigInt B
# throw error : divide by zero
################################################################################
proc ::math::bigfloat::divFloatByInt {a b} {
    variable one
    # type check
    checkFloat a
    if {![isInt $b]} {
        error "'$b' is not a BigInt"
    }
    foreach {dummy integer exp delta} $a {break}
    # zero divider test
    if {[::math::bignum::iszero $b]} {
        error "divide by zero"
    }
    # shift left for accuracy ; see other comments in [div] procedure
    set l [::math::bignum::bits $b]
    set integer [::math::bignum::lshift $integer $l]
    set delta [::math::bignum::lshift $delta $l]
    incr exp -$l
    set integer [::math::bignum::div $integer $b]
    # the uncertainty is always evaluated to the ceil value
    # and as an absolute value
    set delta [::math::bignum::add 1 [::math::bignum::div $delta [abs $b]]]
    return [normalize [list F $integer $exp $delta]]
}





################################################################################
# returns 1 if A and B are equal, 0 otherwise
# IN : a, b (BigFloats)
################################################################################
proc ::math::bigfloat::equal {a b} {
    if {[isInt $a] && [isInt $b]} {
        return [expr {[::math::bignum::cmp $a $b]==0}]
    }
    # now a & b should only be BigFloats
    checkFloat a b
    foreach {dummy aint aexp adelta} $a {break}
    foreach {dummy bint bexp bdelta} $b {break}
    # set all Mantissas and Deltas to the same level (exponent)
    # with lshift
    set diff [expr {$aexp-$bexp}]
    if {$diff<0} {
        set diff [expr {-$diff}]
        set bint [::math::bignum::lshift $bint $diff]
        set bdelta [::math::bignum::lshift $bdelta $diff]
    } elseif {$diff>0} {
        set aint [::math::bignum::lshift $aint $diff]
        set adelta [::math::bignum::lshift $adelta $diff]
    }
    # compute limits of the number's doubt range
    set asupInt [::math::bignum::add $aint $adelta]
    set ainfInt [::math::bignum::sub $aint $adelta]
    set bsupInt [::math::bignum::add $bint $bdelta]
    set binfInt [::math::bignum::sub $bint $bdelta]
    # A & B are equal
    # if their doubt ranges overlap themselves
    if {[::math::bignum::cmp $bint $aint]==0} {
        return 1
    }
    if {[::math::bignum::cmp $bint $aint]>0} {
        set r [expr {[::math::bignum::cmp $asupInt $binfInt]>=0}]
    } else {
        set r [expr {[::math::bignum::cmp $bsupInt $ainfInt]>=0}]
    }
    return $r
}

################################################################################
# returns exp(X) where X is a BigFloat
################################################################################
proc ::math::bigfloat::exp {x} {
    checkFloat x
    foreach {dummy integer exp delta} $x {break}
    if {$exp>=0} {
        # shift till exp<0 with respect to the internal representation
        # of the number
        incr exp
        set integer [::math::bignum::lshift $integer $exp]
        set delta [::math::bignum::lshift $delta $exp]
        set exp -1
    }
    set precision [expr {-$exp}]
    # add 8 bits of precision for safety
    incr precision 8
    set integer [::math::bignum::lshift $integer 8]
    set delta [::math::bignum::lshift $delta 8]
    set Log2 [_log2 $precision]
    foreach {new_exp integer} [::math::bignum::divqr $integer $Log2] {break}
    # new_exp = integer part of x/log(2)
    # integer = remainder
    # exp(K.log(2)+r)=2^K.exp(r)
    # so we just have to compute exp(r), r is small so
    # the Taylor development will converge quickly
    set delta [::math::bignum::add $delta $new_exp]
    foreach {integer delta} [_exp $integer $precision $delta] {break}
    set delta [::math::bignum::rshift $delta 8]
    incr precision -8
    # multiply by 2^K , and take care of the sign
    # example : X=-6.log(2)+0.01
    # exp(X)=exp(0.01)*2^-6
    if {![::math::bignum::iszero [::math::bignum::rshift [abs $new_exp] 30]]} {
        error "floating-point overflow due to exp"
    }
    set new_exp [tostr $new_exp]
    set exp [expr {$new_exp-$precision}]
    set delta [::math::bignum::add 1 $delta]
    return [normalize [list F [::math::bignum::rshift $integer 8] $exp $delta]]
}


################################################################################
# private procedure to compute exponentials
# using Taylor development of exp(x) :
# exp(x)=1+ x + x^2/2 + x^3/3! +...+x^n/n!
# input : integer (the mantissa)
#         precision (the number of decimals)
#         delta (the doubt limit, or uncertainty)
# returns a list : 1. the mantissa of the result
#                  2. the doubt limit, or uncertainty
################################################################################
proc ::math::bigfloat::_exp {integer precision delta} {
    set oneShifted [::math::bignum::lshift 1 $precision]
    if {[::math::bignum::iszero $integer]} {
        # exp(0)=1
        return [list $oneShifted $delta]
    }
    set s [::math::bignum::add $oneShifted $integer]
    variable two
    set d [::math::bignum::add 1 [::math::bignum::div $delta $two]]
    set delta [::math::bignum::add $delta $delta]
    # dt = uncertainty on x^2
    set dt [::math::bignum::add 1 [intMulShift $d $integer $precision]]
    # t= x^2/2
    set t [intMulShift $integer $integer $precision]
    set t [::math::bignum::div $t $two]
    set denom $two
    while {![::math::bignum::iszero $t]} {
        # the sum is called 's'
        set s [::math::bignum::add $s $t]
        set delta [::math::bignum::add $delta $dt]
        # we do not have to keep trace of the factorial, we just iterate divisions
        set denom [::math::bignum::add 1 $denom]
        # add delta
        set d [::math::bignum::add 1 [::math::bignum::div $d $denom]]
        set dt [::math::bignum::add $dt $d]
        # get x^n from x^(n-1)
        set t [intMulShift $integer $t $precision]
        # here we divide
        set t [::math::bignum::div $t $denom]
    }
    return [list $s $delta]
}
################################################################################
# divide a BigFloat by 2 power 'n'
################################################################################
proc ::math::bigfloat::floatRShift {float {n 1}} {
    return [lset float 2 [expr {[lindex $float 2]-$n}]]
}



################################################################################
# procedure floor : identical to [expr floor($x)] in functionality
# arguments : number IN (a BigFloat)
# returns : the floor value as a BigInt
################################################################################
proc ::math::bigfloat::floor {number} {
    variable zero
    checkFloat number
    set number [normalize $number]
    if {[::math::bignum::iszero $number]} {
        # returns the BigInt 0
        return $zero
    }
    foreach {dummy integer exp delta} $number {break}
    if {$exp>=0} {
        error "not enough precision to perform rounding (floor)"
    }
    # saving the sign ...
    set sign [::math::bignum::sign $integer]
    set integer [abs $integer]
    # integer part
    set try [::math::bignum::rshift $integer [expr {-$exp}]]
    # floor(n.xxxx)=n
    if {!$sign} {
        return $try
    }
    # floor(-n.xxxx)=-(n+1) when xxxx!=0
    if {![equal [::math::bignum::lshift $try [expr {-$exp}]] $integer]} {
        set try [::math::bignum::add 1 $try]
    }
    ::math::bignum::setsign try $sign
    return $try
}


################################################################################
# returns a list formed by an integer and an exponent
# x = (A +/- C) * 10 power B
# return [list "F" A B C] (where F is the BigFloat tag)
# A and C are BigInts, B is a raw integer
# return also a BigInt when there is neither a dot, nor a 'e' exponent
#
# arguments : -base base integer
#          or integer
#          or float
#          or float trailingZeros
################################################################################
proc ::math::bigfloat::fromstr {args} {
    if {[set string [lindex $args 0]]=="-base"} {
        if {[llength $args]!=3} {
            error "should be : fromstr -base base number"
        }
        # converts an integer i expressed in base b with : [fromstr b i]
        return [::math::bignum::fromstr [lindex $args 2] [lindex $args 1]]
    }
    # trailingZeros are zeros appended to the Mantissa (it is optional)
    set trailingZeros 0
    if {[llength $args]==2} {
        set trailingZeros [lindex $args 1]
    }
    if {$trailingZeros<0} {
        error "second argument has to be a positive integer"
    }
    # eliminate the sign problem
    # added on 05/08/2005
    # setting '$signe' to the sign of the number
    set string [string trimleft $string +]
    if {[string index $string 0]=="-"} {
        set signe 1
        set string2 [string range $string 1 end]
    } else  {
        set signe 0
        set string2 $string
    }
    # integer case (not a floating-point number)
    if {[string is digit $string2]} {
        if {$trailingZeros!=0} {
            error "second argument not allowed with an integer"
        }
        # we have completed converting an integer to a BigInt
        # please note that most math::bigfloat procs accept BigInts as arguments
        return [::math::bignum::fromstr $string]
    }
    set string $string2
    # floating-point number : check for an exponent
    # scientific notation
    set tab [split $string e]
    if {[llength $tab]>2} {
        # there are more than one 'e' letter in the number
        error "syntax error in number : $string"
    }
    if {[llength $tab]==2} {
        set exp [lindex $tab 1]
        # now exp can look like +099 so you need to handle octal numbers
        # too bad...
        # find the sign (if any?)
        regexp {^[\+\-]?} $exp expsign
        # trim the number with left-side 0's
        set found [string length $expsign]
        set exp $expsign[string trimleft [string range $exp $found end] 0]
        set number [lindex $tab 0]
    } else {
        set exp 0
        set number [lindex $tab 0]
    }
    # a floating-point number may have a dot
    set tab [split $number .]
    if {[llength $tab]>2} {error "syntax error in number : $string"}
    if {[llength $tab]==2} {
        set number [join $tab ""]
        # increment by the number of decimals (after the dot)
        incr exp -[string length [lindex $tab 1]]
    }
    # this is necessary to ensure we can call fromstr (recursively) with
    # the mantissa ($number)
    if {![string is digit $number]} {
        error "$number is not a number"
    }
    # take account of trailing zeros 
    incr exp -$trailingZeros
    # multiply $number by 10^$trailingZeros
    set number [::math::bignum::mul [::math::bignum::fromstr $number]\
            [tenPow $trailingZeros]]
    ::math::bignum::setsign number $signe
    # the F tags a BigFloat
    # a BigInt in internal representation begins by the sign
    # delta is 1 as a BigInt
    return [_fromstr $number $exp]
}

################################################################################
# private procedure to transform decimal floats into binary ones
# IN :
#     - number : a BigInt representing the Mantissa
#     - exp : the decimal exponent (a simple integer)
# OUT :
#     $number * 10^$exp, as the internal binary representation of a BigFloat
################################################################################
proc ::math::bigfloat::_fromstr {number exp} {
    variable one
    variable five
    if {$exp==0} {
        return [list F $number 0 $one]
    }
    if {$exp>0} {
        # mul by 10^exp, and by 2^4, then normalize
        set number [::math::bignum::lshift $number 4]
        set exponent [tenPow $exp]
        set number [::math::bignum::mul $number $exponent]
        # normalize number*2^-4 +/- 2^4*10^exponent
        return [normalize [list F $number -4 [::math::bignum::lshift $exponent 4]]]
    }
    # now exp is negative or null
    # the closest power of 2 to the 'exp'th power of ten, but greater than it
    set binaryExp [expr {int(ceil(-$exp*log(10)/log(2)))+4}]
    # then compute n * 2^binaryExp / 10^(-exp)
    # (exp is negative)
    # equals n * 2^(binaryExp+exp) / 5^(-exp)
    set diff [expr {$binaryExp+$exp}]
    if {$diff<0} {
        error "internal error"
    }
    set fivePow [::math::bignum::pow $five [::math::bignum::fromstr [expr {-$exp}]]]
    set number [::math::bignum::div [::math::bignum::lshift $number \
            $diff] $fivePow]
    set delta [::math::bignum::div [::math::bignum::lshift 1 \
            $diff] $fivePow]
    return [normalize [list F $number [expr {-$binaryExp}] [::math::bignum::add $delta 1]]]
}


################################################################################
# fromdouble :
# like fromstr, but for a double scalar value
# arguments :
# double - the number to convert to a BigFloat
# exp (optional) - the total number of digits
################################################################################
proc ::math::bigfloat::fromdouble {double {exp {}}} {
    set mantissa [lindex [split $double e] 0]
    # line added by SArnold on 05/08/2005
    set mantissa [string trimleft [string map {+ "" - ""} $mantissa] 0]
    set precision [string length [string map {. ""} $mantissa]]
    if { $exp != {} && [incr exp]>$precision } {
        return [fromstr $double [expr {$exp-$precision}]]
    } else {
        # tests have failed : not enough precision or no exp argument
        return [fromstr $double]
    }
}


################################################################################
# converts a BigInt into a BigFloat with a given decimal precision
################################################################################
proc ::math::bigfloat::int2float {int {decimals 1}} {
    # it seems like we need some kind of type handling
    # very odd in this Tcl world :-(
    if {![isInt $int]} {
        error "first argument is not an integer"
    }
    if {$decimals<1} {
        error "non-positive decimals number"
    }
    # the lowest number of decimals is 1, because
    # [tostr [fromstr 10.0]] returns 10.
    # (we lose 1 digit when converting back to string)
    set int [::math::bignum::mul $int [tenPow $decimals]]
    return [_fromstr $int [expr {-$decimals}]]
    
}



################################################################################
# multiplies 'leftop' by 'rightop' and rshift the result by 'shift'
################################################################################
proc ::math::bigfloat::intMulShift {leftop rightop shift} {
    return [::math::bignum::rshift [::math::bignum::mul $leftop $rightop] $shift]
}

################################################################################
# returns 1 if x is a BigFloat, 0 elsewhere
################################################################################
proc ::math::bigfloat::isFloat {x} {
    # a BigFloat is a list of : "F" mantissa exponent delta
    if {[llength $x]!=4} {
        return 0
    }
    # the marker is the letter "F"
    if {[string equal [lindex $x 0] F]} {
        return 1
    }
    return 0
}

################################################################################
# checks that n is a BigInt (a number create by math::bignum::fromstr)
################################################################################
proc ::math::bigfloat::isInt {n} {
    if {[llength $n]<3} {
        return 0
    }
    if {[string equal [lindex $n 0] bignum]} {
        return 1
    }
    return 0
}



################################################################################
# returns 1 if x is null, 0 otherwise
################################################################################
proc ::math::bigfloat::iszero {x} {
    if {[isInt $x]} {
        return [::math::bignum::iszero $x]
    }
    checkFloat x
    # now we do some interval rounding : if a number's interval englobs 0,
    # it is considered to be equal to zero
    foreach {dummy integer exp delta} $x {break}
    set integer [::math::bignum::abs $integer]
    if {[::math::bignum::cmp $delta $integer]>=0} {return 1}
    return 0
}


################################################################################
# compute log(X)
################################################################################
proc ::math::bigfloat::log {x} {
    checkFloat x
    foreach {dummy integer exp delta} $x {break}
    if {[::math::bignum::iszero $integer]||[::math::bignum::sign $integer]} {
        error "zero logarithm error"
    }
    if {[iszero $x]} {
        error "number is null"
    }
    set precision [::math::bignum::bits $integer]
    # uncertainty of the logarithm
    set delta [::math::bignum::add 1 [_logOnePlusEpsilon $delta $integer $precision]]
    # we got : x = 1xxxxxx (binary number with 'precision' bits) * 2^exp
    # we need : x = 0.1xxxxxx(binary) *2^(exp+precision)
    incr exp $precision
    foreach {integer deltaIncr} [_log $integer] {break}
    set delta [::math::bignum::add $delta $deltaIncr]
    # log(a * 2^exp)= log(a) + exp*log(2)
    # result = log(x) + exp*log(2)
    # as x<1 log(x)<0 but 'integer' (result of '_log') is the absolute value
    # that is why we substract $integer to log(2)*$exp
    set integer [::math::bignum::sub [::math::bignum::mul [_log2 $precision] \
            [set exp [::math::bignum::fromstr $exp]]] $integer]
    set delta [::math::bignum::add $delta [abs $exp]]
    return [normalize [list F $integer -$precision $delta]]
}


################################################################################
# compute log(1-epsNum/epsDenom)=log(1-'epsilon')
# Taylor development gives -x -x^2/2 -x^3/3 -x^4/4 ...
# used by 'log' command because log(x+/-epsilon)=log(x)+log(1+/-(epsilon/x))
# so the uncertainty equals abs(log(1-epsilon/x))
# ================================================
# arguments :
# epsNum IN (the numerator of epsilon)
# epsDenom IN (the denominator of epsilon)
# precision IN (the number of bits after the dot)
#
# 'epsilon' = epsNum*2^-precision/epsDenom
################################################################################
proc ::math::bigfloat::_logOnePlusEpsilon {epsNum epsDenom precision} {
    if {[::math::bignum::cmp $epsNum $epsDenom]>=0} {
        error "number is null"
    }
    set s [::math::bignum::lshift $epsNum $precision]
    set s [::math::bignum::div $s $epsDenom]
    variable two
    set divider $two
    set t [::math::bignum::div [::math::bignum::mul $s $epsNum] $epsDenom]
    set u [::math::bignum::div $t $divider]
    # when u (the current term of the development) is zero, we have reached our goal
    # it has converged
    while {![::math::bignum::iszero $u]} {
        set s [::math::bignum::add $s $u]
        # divider = order of the term = 'n'
        set divider [::math::bignum::add 1 $divider]
        # t = (epsilon)^n
        set t [::math::bignum::div [::math::bignum::mul $t $epsNum] $epsDenom]
        # u = t/n = (epsilon)^n/n and is the nth term of the Taylor development
        set u [::math::bignum::div $t $divider]
    }
    return $s
}


################################################################################
# compute log(0.xxxxxxxx) : log(1-epsilon)=-eps-eps^2/2-eps^3/3...-eps^n/n
################################################################################
proc ::math::bigfloat::_log {integer} {
    # the uncertainty is nbSteps with nbSteps<=nbBits
    # take nbSteps=nbBits (the worse case) and log(nbBits+increment)=increment
    set precision [::math::bignum::bits $integer]
    set n [expr {int(log($precision+2*log($precision)))}]
    set integer [::math::bignum::lshift $integer $n]
    incr precision $n
    variable three
    set delta $three
    # 1-epsilon=integer
    set integer [::math::bignum::sub [::math::bignum::lshift 1 $precision] $integer]
    set s $integer
    # t=x^2
    set t [intMulShift $integer $integer $precision]
    variable two
    set denom $two
    # u=x^2/2 (second term)
    set u [::math::bignum::div $t $denom]
    while {![::math::bignum::iszero $u]} {
        # while the current term is not zero, it has not converged
        set s [::math::bignum::add $s $u]
        set delta [::math::bignum::add 1 $delta]
        # t=x^n
        set t [intMulShift $t $integer $precision]
        # denom = n (the order of the current development term)
        set denom [::math::bignum::add 1 $denom]
        # u = x^n/n (the nth term of Taylor development)
        set u [::math::bignum::div $t $denom]
    }
    # shift right to restore the precision
    set delta [::math::bignum::add 1 [::math::bignum::rshift $delta $n]]
    return [list [::math::bignum::rshift $s $n] $delta]
}

################################################################################
# computes log(num/denom) with 'precision' bits
# used to compute some analysis constants with a given accuracy
# you might not call this procedure directly : it assumes 'num/denom'>4/5
# and 'num/denom'<1
################################################################################
proc ::math::bigfloat::__log {num denom precision} {
    # Please Note : we here need a precision increment, in order to
    # keep accuracy at $precision digits. If we just hold $precision digits,
    # each number being precise at the last digit +/- 1,
    # we would lose accuracy because small uncertainties add to themselves.
    # Example : 0.0001 + 0.0010 = 0.0011 +/- 0.0002
    # This is quite the same reason that made tcl_precision defaults to 12 :
    # internally, doubles are computed with 17 digits, but to keep precision
    # we need to limit our results to 12.
    # The solution : given a precision target, increment precision with a
    # computed value so that all digits of he result are exacts.
    # 
    # p is the precision
    # pk is the precision increment
    # 2 power pk is also the maximum number of iterations
    # for a number close to 1 but lower than 1,
    # (denom-num)/denum is (in our case) lower than 1/5
    # so the maximum nb of iterations is for:
    # 1/5*(1+1/5*(1/2+1/5*(1/3+1/5*(...))))
    # the last term is 1/n*(1/5)^n
    # for the last term to be lower than 2^(-p-pk)
    # the number of iterations has to be
    # 2^(-pk).(1/5)^(2^pk) < 2^(-p-pk)
    # log(1/5).2^pk < -p
    # 2^pk > p/log(5)
    # pk > log(2)*log(p/log(5))
    # now set the variable n to the precision increment i.e. pk
    set n [expr {int(log(2)*log($precision/log(5)))+1}]
    incr precision $n
    # log(num/denom)=log(1-(denom-num)/denom)
    # log(1+x) = x + x^2/2 + x^3/3 + ... + x^n/n
    #          = x(1 + x(1/2 + x(1/3 + x(...+ x(1/(n-1) + x/n)...))))
    set num [::math::bignum::fromstr [expr {$denom-$num}]]
    set denom [::math::bignum::fromstr $denom]
    # $s holds the result
    set s [::math::bignum::div [::math::bignum::lshift $num $precision] $denom]
    # $t holds x^n
    set t [::math::bignum::div [::math::bignum::mul $s $num] $denom]
    variable two
    set d $two
    # $u holds x^n/n
    set u [::math::bignum::div $t $d]
    while {![::math::bignum::iszero $u]} {
        set s [::math::bignum::add $s $u]
        # get x^n * x
        set t [::math::bignum::div [::math::bignum::mul $t $num] $denom]
        # get n+1
        set d [::math::bignum::add 1 $d]
        # then : $u = x^(n+1)/(n+1)
        set u [::math::bignum::div $t $d]
    }
    # see head of the proc : we return the value with its target precision
    return [::math::bignum::rshift $s $n]
}

################################################################################
# computes log(2) with 'precision' bits and caches it into a namespace variable
################################################################################
proc ::math::bigfloat::__logbis {precision} {
    set increment [expr {int(log($precision)/log(2)+1)}]
    incr precision $increment
    # ln(2)=3*ln(1-4/5)+ln(1-125/128)
    set a [__log 125 128 $precision]
    set b [__log 4 5 $precision]
    variable three
    set r [::math::bignum::add [::math::bignum::mul $b $three] $a]
    set ::math::bigfloat::Log2 [::math::bignum::rshift $r $increment]
    # formerly (when BigFloats were stored in ten radix) we had to compute log(10)
    # ln(10)=10.ln(1-4/5)+3*ln(1-125/128)
}


################################################################################
# retrieves log(2) with 'precision' bits ; the result is cached
################################################################################
proc ::math::bigfloat::_log2 {precision} {
    variable Log2
    if {![info exists Log2]} {
        __logbis $precision
    } else {
        # the constant is cached and computed again when more precision is needed
        set l [::math::bignum::bits $Log2]
        if {$precision>$l} {
            __logbis $precision
        }
    }
    # return log(2) with 'precision' bits even when the cached value has more bits
    return [_round $Log2 $precision]
}


################################################################################
# returns A modulo B (like with fmod() math function)
################################################################################
proc ::math::bigfloat::mod {a b} {
    checkNumber a b
    if {[isInt $a] && [isInt $b]} {return [::math::bignum::mod $a $b]}
    if {[isInt $a]} {error "trying to divide a BigInt by a BigFloat"}
    set quotient [div $a $b]
    # examples : fmod(3,2)=1 quotient=1.5
    # fmod(1,2)=1 quotient=0.5
    # quotient>0 and b>0 : get floor(quotient)
    # fmod(-3,-2)=-1 quotient=1.5
    # fmod(-1,-2)=-1 quotient=0.5
    # quotient>0 and b<0 : get floor(quotient)
    # fmod(-3,2)=-1 quotient=-1.5
    # fmod(-1,2)=-1 quotient=-0.5
    # quotient<0 and b>0 : get ceil(quotient)
    # fmod(3,-2)=1 quotient=-1.5
    # fmod(1,-2)=1 quotient=-0.5
    # quotient<0 and b<0 : get ceil(quotient)
    if {[sign $quotient]} {
        set quotient [ceil $quotient]
    } else  {
        set quotient [floor $quotient]
    }
    return [sub $a [mul $quotient $b]]
}

################################################################################
# returns A times B
################################################################################
proc ::math::bigfloat::mul {a b} {
    checkNumber a b
    # dispatch the command to appropriate commands regarding types (BigInt & BigFloat)
    if {[isInt $a]} {
        if {[isInt $b]} {
            return [::math::bignum::mul $a $b]
        }
        return [mulFloatByInt $b $a]
    }
    if {[isInt $b]} {return [mulFloatByInt $a $b]}
    # now we are sure that 'a' and 'b' are BigFloats
    foreach {dummy integerA expA deltaA} $a {break}
    foreach {dummy integerB expB deltaB} $b {break}
    # 2^expA * 2^expB = 2^(expA+expB)
    set exp [expr {$expA+$expB}]
    # mantissas are multiplied
    set integer [::math::bignum::mul $integerA $integerB]
    # compute precisely the uncertainty
    set deltaAB [::math::bignum::mul $deltaA $deltaB]
    set deltaA [::math::bignum::mul [abs $integerB] $deltaA]
    set deltaB [::math::bignum::mul [abs $integerA] $deltaB]
    set delta [::math::bignum::add [::math::bignum::add $deltaA $deltaB] \
            [::math::bignum::add 1 $deltaAB]]
    # we have to normalize because 'delta' may be too big
    return [normalize [list F $integer $exp $delta]]
}

################################################################################
# returns A times B, where B is a positive integer
################################################################################
proc ::math::bigfloat::mulFloatByInt {a b} {
    checkFloat a
    foreach {dummy integer exp delta} $a {break}
    if {![isInt $b]} {
        error "second argument expected to be a BigInt"
    }
    # Mantissa and Delta are simply multplied by $b
    set integer [::math::bignum::mul $integer $b]
    set delta [::math::bignum::mul $delta $b]
    # We normalize because Delta could have seriously increased
    return [normalize [list F $integer $exp $delta]]
}

################################################################################
# normalizes a number : Delta (accuracy of the BigFloat)
# has to be limited, because the memory use increase
# quickly when we do some computations, as the Mantissa and Delta
# increase together
# The solution : keep the size of Delta under 9 bits
################################################################################
proc ::math::bigfloat::normalize {number} {
    checkFloat number
    foreach {dummy integer exp delta} $number {break}
    set l [::math::bignum::bits $delta]
    if {$l>8} {
        # next line : $l holds the supplementary size (in bits)
        incr l -8
        # now we can shift right by $l bits
        # always round upper the Delta
        set delta [::math::bignum::add 1 [::math::bignum::rshift $delta $l]]
        set integer [::math::bignum::rshift $integer $l]
        incr exp $l
    }
    return [list F $integer $exp $delta]
}



################################################################################
# returns -A (the opposite)
################################################################################
proc ::math::bigfloat::opp {a} {
    checkNumber a
    if {[iszero $a]} {
        return $a
    }
    if {[isInt $a]} {
        ::math::bignum::setsign a [expr {![::math::bignum::sign $a]}]
        return $a
    }
    # recursive call
    lset a 1 [opp [lindex $a 1]] 
    return $a
}

################################################################################
# gets Pi with precision bits
# after the dot (after you call [tostr] on the result)
################################################################################
proc ::math::bigfloat::pi {precision {binary 0}} {
    if {[llength $precision]>1} {
        if {[isInt $precision]} {
            set precision [tostr $precision]
        } else {
            error "'$precision' expected to be an integer"
        }
    }
    if {!$binary} {
        # convert decimal digit length into bit length
        set precision [expr {int(ceil($precision*log(10)/log(2)))}]
    }
    variable one
    return [list F [_pi $precision] -$precision $one]
}


proc ::math::bigfloat::_pi {precision} {
    # the constant Pi begins with 3.xxx
    # so we need 2 digits to store the digit '3'
    # and then we will have precision+2 bits in the mantissa
    variable _pi0
    if {![info exists _pi0]} {
        set _pi0 [__pi $precision]
    }
    set lenPiGlobal [::math::bignum::bits $_pi0]
    if {$lenPiGlobal<$precision} {
        set _pi0 [__pi $precision]
    }
    return [::math::bignum::rshift $_pi0 [expr {[::math::bignum::bits $_pi0]-2-$precision}]]
}

################################################################################
# computes an integer representing Pi in binary radix, with precision bits
################################################################################
proc ::math::bigfloat::__pi {precision} {
    set safetyLimit 8
    # for safety and for the better precision, we do so ...
    incr precision $safetyLimit
    # formula found in the Math litterature
    # Pi/4 = 6.atan(1/18) + 8.atan(1/57) - 5.atan(1/239)
    set a [::math::bignum::mul [_atanfract [::math::bignum::fromstr 18] $precision] \
            [::math::bignum::fromstr 48]]
    set a [::math::bignum::add $a [::math::bignum::mul \
            [_atanfract [::math::bignum::fromstr 57] $precision] [::math::bignum::fromstr 32]]]
    set a [::math::bignum::sub $a [::math::bignum::mul \
            [_atanfract [::math::bignum::fromstr 239] $precision] [::math::bignum::fromstr 20]]]
    return [::math::bignum::rshift $a $safetyLimit]
}

################################################################################
# shift right an integer until it haves $precision bits
# round at the same time
################################################################################
proc ::math::bigfloat::_round {integer precision} {
    set shift [expr {[::math::bignum::bits $integer]-$precision}]
    # $result holds the shifted integer
    set result [::math::bignum::rshift $integer $shift]
    # $shift-1 is the bit just rights the last bit of the result
    # Example : integer=1000010 shift=2
    # => result=10000 and the tested bit is '1'
    if {[::math::bignum::testbit $integer [expr {$shift-1}]]} {
        # we round to the upper limit
        return [::math::bignum::add 1 $result]
    }
    return $result
}

################################################################################
# returns A power B, where B is a positive integer
################################################################################
proc ::math::bigfloat::pow {a b} {
    checkNumber a
    if {![isInt $b]} {
        error "pow : exponent is not a positive integer"
    }
    # case where it is obvious that we should use the appropriate command
    # from math::bignum (added 5th March 2005)
    if {[isInt $a]} {
        return [::math::bignum::pow $a $b]
    }
    # algorithm : exponent=$b = Sum(i=0..n) b(i)2^i
    # $a^$b = $a^( b(0) + 2b(1) + 4b(2) + ... + 2^n*b(n) )
    # we have $a^(x+y)=$a^x * $a^y
    # then $a^$b = Product(i=0...n) $a^(2^i*b(i))
    # b(i) is boolean so $a^(2^i*b(i))= 1 when b(i)=0 and = $a^(2^i) when b(i)=1
    # then $a^$b = Product(i=0...n and b(i)=1) $a^(2^i) and 1 when $b=0
    variable one
    if {[::math::bignum::iszero $b]} {return $one}
    # $res holds the result
    set res $one
    while {1} {
        # at the beginning i=0
        # $remainder is b(i)
        set remainder [::math::bignum::testbit $b 0]
        # $b 'rshift'ed by 1 bit : i=i+1
        # so next time we will test bit b(i+1)
        set b [::math::bignum::rshift $b 1]
        # if b(i)=1
        if {$remainder} {
            # mul the result by $a^(2^i)
            # if i=0 we multiply by $a^(2^0)=$a^1=$a
            set res [mul $res $a]
        }
        # no more bits at '1' in $b : $res is the result
        if {[::math::bignum::iszero $b]} {
            if {[isInt $res]} {
                # we cannot (and should not) normalize an integer
                return $res
            }
            return [normalize $res]
        }
        # i=i+1 : $a^(2^(i+1)) = square of $a^(2^i)
        set a [mul $a $a]
    }
}

################################################################################
# converts angles for radians to degrees
################################################################################
proc ::math::bigfloat::rad2deg {x} {
    checkFloat x
    set xLen [expr {-[lindex $x 2]}]
    if {$xLen<3} {
        error "number too loose to convert to degrees"
    }
    set pi [pi $xLen 1]
    # $rad/Pi=$deg/180
    # so result in deg = $radians*180/Pi
    return [div [mul $x [::math::bignum::fromstr 180]] $pi]
}

################################################################################
# retourne la partie entière (ou 0) du nombre "number"
################################################################################
proc ::math::bigfloat::round {number} {
    checkFloat number
    #set number [normalize $number]
    # fetching integers (or BigInts) from the internal representation
    foreach {dummy integer exp delta} $number {break}
    if {[::math::bignum::iszero $integer]} {
        # returns the BigInt 0
        variable zero
        return $zero
    }
    if {$exp>=0} {
        error "not enough precision to round (in round)"
    }
    set exp [expr {-$exp}]
    # saving the sign, ...
    set sign [::math::bignum::sign $integer]
    set integer [abs $integer]
    # integer part of the number
    set try [::math::bignum::rshift $integer $exp]
    # first bit after the dot
    set way [::math::bignum::testbit $integer [expr {$exp-1}]]
    # delta is shifted so it gives the integer part of 2*delta
    set delta [::math::bignum::rshift $delta [expr {$exp-1}]]
    # when delta is too big to compute rounded value (
    if {![::math::bignum::iszero $delta]} {
        error "not enough precision to round (in round)"
    }
    if {$way} {
        set try [::math::bignum::add 1 $try]
    }
    # ... restore the sign now
    ::math::bignum::setsign try $sign
    return $try
}

################################################################################
# round and divide by 10^n
################################################################################
proc ::math::bigfloat::roundshift {integer n} {
    # $exp= 10^$n
    set exp [tenPow $n]
    foreach {result remainder} [::math::bignum::divqr $integer $exp] {}
    # $remainder belongs to the interval [0, $exp-1]
    # $remainder >= $exp/2 is the rounding condition
    # that is better expressed in this form :
    # $remainder*2 >= $exp , as we are treating integers, not rationals
    # left shift $remainder by 1 equals to multiplying by 2 and is much faster
    if {[::math::bignum::cmp $exp [::math::bignum::lshift $remainder 1]]<=0} {
        return [::math::bignum::add 1 $result]
    }
    return $result
}

################################################################################
# gets the sign of either a bignum, or a BitFloat
# we keep the bignum convention : 0 for positive, 1 for negative
################################################################################
proc ::math::bigfloat::sign {n} {
    if {[isInt $n]} {
        return [::math::bignum::sign $n]
    }
    # sign of 0=0
    if {[iszero $n]} {return 0}
    # the sign of the Mantissa, which is a BigInt
    return [::math::bignum::sign [lindex $n 1]]
}


################################################################################
# gets sin(x)
################################################################################
proc ::math::bigfloat::sin {x} {
    checkFloat x
    foreach {dummy integer exp delta} $x {break}
    if {$exp>-2} {
        error "sin : not enough precision"
    }
    set precision [expr {-$exp}]
    # sin(2kPi+x)=sin(x)
    # $integer is now the modulo of the division of the mantissa by Pi/4
    # and $n is the quotient
    foreach {n integer} [divPiQuarter $integer $precision] {break}
    set delta [::math::bignum::add $delta $n]
    variable four
    set d [::math::bignum::mod $n $four]
    # now integer>=0
    # x = $n*Pi/4 + $integer and $n belongs to [0,3]
    # sin(2Pi-x)=-sin(x)
    # sin(Pi-x)=sin(x)
    # sin(Pi/2+x)=cos(x)
    set sign 0
    switch  -- [tostr $d] {
        0 {set l [_sin2 $integer $precision $delta]}
        1 {set l [_cos2 $integer $precision $delta]}
        2 {set sign 1;set l [_sin2 $integer $precision $delta]}
        3 {set sign 1;set l [_cos2 $integer $precision $delta]}
        default {error "internal error"}
    }
    # $l is a list : {Mantissa Precision Delta}
    # precision --> the opposite of the exponent
    # 1.000 = 1000*10^-3 so exponent=-3 and precision=3 digits
    lset l 1 [expr {-([lindex $l 1])}]
    set integer [lindex $l 0]
    # the sign depends on the switch statement below
    ::math::bignum::setsign integer $sign
    lset l 0 $integer
    # we insert the Bigfloat tag (F) and normalize the final result
    return [normalize [linsert $l 0 F]]
}

proc ::math::bigfloat::_sin2 {x precision delta} {
    set pi [_pi $precision]
    # shift right by 1 = divide by 2
    # shift right by 2 = divide by 4
    set pis2 [::math::bignum::rshift $pi 1]
    set pis4 [::math::bignum::rshift $pi 2]
    if {[::math::bignum::cmp $x $pis4]>=0} {
        # sin(Pi/2-x)=cos(x)
        set delta [::math::bignum::add 1 $delta]
        set x [::math::bignum::sub $pis2 $x]
        return [_cos $x $precision $delta]
    }
    return [_sin $x $precision $delta]
}

################################################################################
# sin(x) with 'x' lower than Pi/4 and positive
# 'x' is the Mantissa - 'delta' is Delta
# 'precision' is the opposite of the exponent
################################################################################
proc ::math::bigfloat::_sin {x precision delta} {
    # $s holds the result
    set s $x
    # sin(x) = x - x^3/3! + x^5/5! - ... + (-1)^n*x^(2n+1)/(2n+1)!
    #        = x * (1 - x^2/(2*3) * (1 - x^2/(4*5) * (...* (1 - x^2/(2n*(2n+1)) )...)))
    # The second expression allows us to compute the less we can
    
    # $double holds the uncertainty (Delta) of x^2 : 2*(Mantissa*Delta) + Delta^2
    # (Mantissa+Delta)^2=Mantissa^2 + 2*Mantissa*Delta + Delta^2
    set double [::math::bignum::rshift [::math::bignum::mul $x $delta] [expr {$precision-1}]]
    set double [::math::bignum::add [::math::bignum::add 1 $double] [::math::bignum::rshift \
            [::math::bignum::mul $delta $delta] $precision]]
    # $x holds the Mantissa of x^2
    set x [intMulShift $x $x $precision]
    set dt [::math::bignum::rshift [::math::bignum::add [::math::bignum::mul $x $delta] \
            [::math::bignum::mul [::math::bignum::add $s $delta] $double]] $precision]
    set dt [::math::bignum::add 1 $dt]
    # $t holds $s * -(x^2) / (2n*(2n+1))
    # mul by x^2
    set t [intMulShift $s $x $precision]
    variable two
    set denom2 $two
    variable three
    set denom3 $three
    # mul by -1 (opp) and divide by 2*3
    set t [opp [::math::bignum::div $t [::math::bignum::mul $denom2 $denom3]]]
    while {![::math::bignum::iszero $t]} {
        set s [::math::bignum::add $s $t]
        set delta [::math::bignum::add $delta $dt]
        # incr n => 2n --> 2n+2 and 2n+1 --> 2n+3
        set denom2 [::math::bignum::add $denom2 $two]
        set denom3 [::math::bignum::add $denom3 $two]
        # $dt is the Delta corresponding to $t
        # $double ""     ""    ""     ""    $x (x^2)
        # ($t+$dt) * ($x+$double) = $t*$x + ($dt*$x + $t*$double) + $dt*$double
        #                   Mantissa^        ^--------Delta-------------------^
        set dt [::math::bignum::rshift [::math::bignum::add [::math::bignum::mul $x $dt] \
                [::math::bignum::mul [::math::bignum::add $t $dt] $double]] $precision]
        set t [intMulShift $t $x $precision]
        # removed 2005/08/31 by sarnold75
        #set dt [::math::bignum::add $dt $double]
        set denom [::math::bignum::mul $denom2 $denom3]
        # now computing : div by -2n(2n+1)
        set dt [::math::bignum::add 1 [::math::bignum::div $dt $denom]]
        set t [opp [::math::bignum::div $t $denom]]
    }
    return [list $s $precision $delta]
}


################################################################################
# procedure for extracting the square root of a BigFloat
################################################################################
proc ::math::bigfloat::sqrt {x} {
    variable one
    checkFloat x
    foreach {dummy integer exp delta} $x {break}
    # if x=0, return 0
    if {[iszero $x]} {
        variable zero
        # return zero, taking care of its precision ($exp)
        return [list F $zero $exp $one]
    }
    # we cannot get sqrt(x) if x<0
    if {[lindex $integer 0]<0} {
        error "negative sqrt input"
    }
    # (1+epsilon)^p = 1 + epsilon*(p-1) + epsilon^2*(p-1)*(p-2)/2! + ...
    #                   + epsilon^n*(p-1)*...*(p-n)/n!
    # sqrt(1 + epsilon) = (1 + epsilon)^(1/2)
    #                   = 1 - epsilon/2 - epsilon^2*3/(4*2!) - ...
    #                       - epsilon^n*(3*5*..*(2n-1))/(2^n*n!)
    # sqrt(1 - epsilon) = 1 + Sum(i=1..infinity) epsilon^i*(3*5*...*(2i-1))/(i!*2^i)
    # sqrt(n +/- delta)=sqrt(n) * sqrt(1 +/- delta/n)
    # so the uncertainty on sqrt(n +/- delta) equals sqrt(n) * (sqrt(1 - delta/n) - 1)
    #         sqrt(1+eps) < sqrt(1-eps) because their logarithm compare as :
    #       -ln(2)(1+eps) < -ln(2)(1-eps)
    # finally :
    # Delta = sqrt(n) * Sum(i=1..infinity) (delta/n)^i*(3*5*...*(2i-1))/(i!*2^i)
    # here we compute the second term of the product by _sqrtOnePlusEpsilon
    set delta [_sqrtOnePlusEpsilon $delta $integer]
    set intLen [::math::bignum::bits $integer]
    # removed 2005/08/31 by sarnold75, readded 2005/08/31
    set precision $intLen
    # intLen + exp = number of bits before the dot
    #set precision [expr {-$exp}]
    # square root extraction
    set integer [::math::bignum::lshift $integer $intLen]
    incr exp -$intLen
    incr intLen $intLen
    # there is an exponent 2^$exp : when $exp is odd, we would need to compute sqrt(2)
    # so we decrement $exp, in order to get it even, and we do not need sqrt(2) anymore !
    if {$exp&1} {
        incr exp -1
        set integer [::math::bignum::lshift $integer 1]
        incr intLen
        incr precision
    }
    # using a low-level (in math::bignum) root extraction procedure
    set integer [::math::bignum::sqrt $integer]
    # delta has to be multiplied by the square root
    set delta [::math::bignum::rshift [::math::bignum::mul $delta $integer] $precision]
    # round to the ceiling the uncertainty (worst precision, the fastest to compute)
    set delta [::math::bignum::add 1 $delta]
    # we are sure that $exp is even, see above
    return [normalize [list F $integer [expr {$exp/2}] $delta]]
}



################################################################################
# compute abs(sqrt(1-delta/integer)-1)
# the returned value is a relative uncertainty
################################################################################
proc ::math::bigfloat::_sqrtOnePlusEpsilon {delta integer} {
    # sqrt(1-x) - 1 = x/2 + x^2*3/(2^2*2!) + x^3*3*5/(2^3*3!) + ...
    #               = x/2 * (1 + x*3/(2*2) * ( 1 + x*5/(2*3) *
    #                     (...* (1 + x*(2n-1)/(2n) ) )...)))
    variable one
    set l [::math::bignum::bits $integer]
    # to compute delta/integer we have to shift left to keep the same precision level
    # we have a better accuracy computing (delta << lg(integer))/integer
    # than computing (delta/integer) << lg(integer)
    set x [::math::bignum::div [::math::bignum::lshift $delta $l] $integer]
    variable four
    variable two
    # denom holds 2n
    set denom $four
    # x/2
    set result [::math::bignum::div $x $two]
    # x^2*3/(2!*2^2)
    variable three
    # numerator holds 2n-1
    set numerator $three
    set temp [::math::bignum::mul $result $delta]
    set temp [::math::bignum::div [::math::bignum::mul $temp $numerator] $integer]
    set temp [::math::bignum::add 1 [::math::bignum::div $temp $denom]]
    while {![::math::bignum::iszero $temp]} {
        set result [::math::bignum::add $result $temp]
        set numerator [::math::bignum::add $numerator $two]
        set denom [::math::bignum::add $two $denom]
        # n = n+1 ==> num=num+2 denom=denom+2
        # num=2n+1 denom=2n+2
        set temp [::math::bignum::mul [::math::bignum::mul $temp $delta] $numerator]
        set temp [::math::bignum::div [::math::bignum::div $temp $denom] $integer]
    }
    return $result
}

################################################################################
# substracts B to A
################################################################################
proc ::math::bigfloat::sub {a b} {
    checkNumber a b
    if {[isInt $a] && [isInt $b]} {
        # the math::bignum::sub proc is designed to work with BigInts
        return [::math::bignum::sub $a $b]
    }
    return [add $a [opp $b]]
}

################################################################################
# tangent (trivial algorithm)
################################################################################
proc ::math::bigfloat::tan {x} {
    return [::math::bigfloat::div [::math::bigfloat::sin $x] [::math::bigfloat::cos $x]]
}

################################################################################
# returns a power of ten
################################################################################
proc ::math::bigfloat::tenPow {n} {
    variable ten
    return [::math::bignum::pow $ten [::math::bignum::fromstr $n]]
}


################################################################################
# converts a BigInt to a double (basic floating-point type)
# with respect to the global variable 'tcl_precision'
################################################################################
proc ::math::bigfloat::todouble {x} {
    global tcl_precision
    checkFloat x
    # get the string repr of x without the '+' sign
    set result [string trimleft [tostr $x] +]
    set minus ""
    if {[string index $result 0]=="-"} {
        set minus -
        set result [string range $result 1 end]
    }
    set l [split $result e]
    set exp 0
    if {[llength $l]==2} {
        # exp : x=Mantissa*10^Exp
        set exp [lindex $l 1]
    }
    # Mantissa = integerPart.fractionalPart
    set l [split [lindex $l 0] .]
    set integerPart [lindex $l 0]
    set integerLen [string length $integerPart]
    set fractionalPart [lindex $l 1]
    # The number of digits in Mantissa, excluding the dot and the leading zeros, of course
    set len [string length [set integer $integerPart$fractionalPart]]
    # Now Mantissa is stored in $integer
    if {$len>$tcl_precision} {
        set lenDiff [expr {$len-$tcl_precision}]
        # true when the number begins with a zero
        set zeroHead 0
        if {[string index $integer 0]==0} {
            incr lenDiff -1
            set zeroHead 1
        }
        set integer [tostr [roundshift [::math::bignum::fromstr $integer] $lenDiff]]
        if {$zeroHead} {
            set integer 0$integer
        }
        set len [string length $integer]
        if {$len<$integerLen} {
            set exp [expr {$integerLen-$len}]
            # restore the true length
            set integerLen $len
        }
    }
    # number = 'sign'*'integer'*10^'exp'
    if {$exp==0} {
        # no scientific notation
        set exp ""
    } else {
        # scientific notation
        set exp e$exp
    }
    # place the dot just before the index $integerLen in the Mantissa
    set result [string range $integer 0 [expr {$integerLen-1}]]
    append result .[string range $integer $integerLen end]
    # join the Mantissa with the sign before and the exponent after
    return $minus$result$exp
}

################################################################################
# converts a number stored as a list to a string in which all digits are true
################################################################################
proc ::math::bigfloat::tostr {args} {
    variable five
	if {[llength $args]==2} {
		if {![string equal [lindex $args 0] -nosci]} {error "unknown option: should be -nosci"}
		set nosci yes
		set number [lindex $args 1]
	} else {
		if {[llength $args]!=1} {error "syntax error: should be tostr ?-nosci? number"}
		set nosci no
		set number [lindex $args 0]
	}
    if {[isInt $number]} {
        return [::math::bignum::tostr $number]
    }
    checkFloat number
    foreach {dummy integer exp delta} $number {break}
    if {[iszero $number]} {
        # we do not matter how much precision $number has :
        # it can be 0.0000000 or 0.0, the result is still the same : the "0" string
	# not anymore : 0.000 is not 0.0 !
    #    return 0
    }
    if {$exp>0} {
        # the power of ten the closest but greater than 2^$exp
        # if it was lower than the power of 2, we would have more precision
        # than existing in the number
        set newExp [expr {int(ceil($exp*log(2)/log(10)))}]
        # 'integer' <- 'integer' * 2^exp / 10^newExp
        # equals 'integer' * 2^(exp-newExp) / 5^newExp
        set binExp [expr {$exp-$newExp}]
        if {$binExp<0} {
            # it cannot happen
            error "internal error"
        }
        # 5^newExp
        set fivePower [::math::bignum::pow $five [::math::bignum::fromstr $newExp]]
        # 'lshift'ing $integer by $binExp bits is like multiplying it by 2^$binExp
        # but much, much faster
        set integer [::math::bignum::div [::math::bignum::lshift $integer $binExp] \
                $fivePower]
        # $integer is the Mantissa - Delta should follow the same operations
        set delta [::math::bignum::div [::math::bignum::lshift $delta $binExp] $fivePower]
        set exp $newExp
    } elseif {$exp<0} {
        # the power of ten the closest but lower than 2^$exp
        # same remark about the precision
        set newExp [expr {int(floor(-$exp*log(2)/log(10)))}]
        # 'integer' <- 'integer' * 10^newExp / 2^(-exp)
        # equals 'integer' * 5^(newExp) / 2^(-exp-newExp)
        set fivePower [::math::bignum::pow $five \
                [::math::bignum::fromstr $newExp]]
        set binShift [expr {-$exp-$newExp}]
        # rshifting is like dividing by 2^$binShift, but faster as we said above about lshift
        set integer [::math::bignum::rshift [::math::bignum::mul $integer $fivePower] \
                $binShift]
        set delta [::math::bignum::rshift [::math::bignum::mul $delta $fivePower] \
                $binShift]
        set exp -$newExp
    }
    # saving the sign, to restore it into the result
    set sign [::math::bignum::sign $integer]
    set result [::math::bignum::abs $integer]
    # rounded 'integer' +/- 'delta'
    set up [::math::bignum::add $result $delta]
    set down [::math::bignum::sub $result $delta]
    if {[sign $up]^[sign $down]} {
        # $up>0 and $down<0 and vice-versa : then the number is considered equal to zero
		# delta <= 2**n (n = bits(delta))
		# 2**n  <= 10**exp , then 
		# exp >= n.log(2)/log(10)
		# delta <= 10**(n.log(2)/log(10))
        incr exp [expr {int(ceil([::math::bignum::bits $delta]*log(2)/log(10)))}]
        set result 0
        set isZero yes
    } else {
		# iterate until the convergence of the rounding
		# we incr $shift until $up and $down are rounded to the same number
		# at each pass we lose one digit of precision, so necessarly it will success
		for {set shift 1} {
			[::math::bignum::cmp [roundshift $up $shift] [roundshift $down $shift]]
		} {
			incr shift
		} {}
		incr exp $shift
		set result [::math::bignum::tostr [roundshift $up $shift]]
		set isZero no
    }
    set l [string length $result]
    # now formatting the number the most nicely for having a clear reading
    # would'nt we allow a number being constantly displayed
    # as : 0.2947497845e+012 , would we ?
	if {$nosci} {
		if {$exp >= 0} {
			append result [string repeat 0 $exp].
		} elseif {$l + $exp > 0} {
			set result [string range $result 0 end-[expr {-$exp}]].[string range $result end-[expr {-1-$exp}] end]
		} else {
			set result 0.[string repeat 0 [expr {-$exp-$l}]]$result
		}
	} else {
		if {$exp>0} {
			# we display 423*10^6 as : 4.23e+8
			# Length of mantissa : $l
			# Increment exp by $l-1 because the first digit is placed before the dot,
			# the other ($l-1) digits following the dot.
			incr exp [incr l -1]
			set result [string index $result 0].[string range $result 1 end]
			append result "e+$exp"
		} elseif {$exp==0} {
			# it must have a dot to be a floating-point number (syntaxically speaking)
			append result .
		} else {
			set exp [expr {-$exp}]
			if {$exp < $l} {
				# we can display the number nicely as xxxx.yyyy*
				# the problem of the sign is solved finally at the bottom of the proc
				set n [string range $result 0 end-$exp]
				incr exp -1
				append n .[string range $result end-$exp end]
				set result $n
			} elseif {$l==$exp} {
				# we avoid to use the scientific notation
				# because it is harder to read
				set result "0.$result"
			} else  {
				# ... but here there is no choice, we should not represent a number
				# with more than one leading zero
				set result [string index $result 0].[string range $result 1 end]e-[expr {$exp-$l+1}]
			}
		}
	}
    # restore the sign : we only put a minus on numbers that are different from zero
    if {$sign==1 && !$isZero} {set result "-$result"}
    return $result
}

################################################################################
# PART IV
# HYPERBOLIC FUNCTIONS
################################################################################

################################################################################
# hyperbolic cosinus
################################################################################
proc ::math::bigfloat::cosh {x} {
    # cosh(x) = (exp(x)+exp(-x))/2
    # dividing by 2 is done faster by 'rshift'ing
    return [floatRShift [add [exp $x] [exp [opp $x]]] 1]
}

################################################################################
# hyperbolic sinus
################################################################################
proc ::math::bigfloat::sinh {x} {
    # sinh(x) = (exp(x)-exp(-x))/2
    # dividing by 2 is done faster by 'rshift'ing
    return [floatRShift [sub [exp $x] [exp [opp $x]]] 1]
}

################################################################################
# hyperbolic tangent
################################################################################
proc ::math::bigfloat::tanh {x} {
    set up [exp $x]
    set down [exp [opp $x]]
    # tanh(x)=sinh(x)/cosh(x)= (exp(x)-exp(-x))/2/ [(exp(x)+exp(-x))/2]
    #        =(exp(x)-exp(-x))/(exp(x)+exp(-x))
    #        =($up-$down)/($up+$down)
    return [div [sub $up $down] [add $up $down]]
}

# exporting public interface
namespace eval ::math::bigfloat {
    foreach function {
        add mul sub div mod pow
        iszero compare equal
        fromstr tostr fromdouble todouble
        int2float isInt isFloat
        exp log sqrt round ceil floor
        sin cos tan cotan asin acos atan
        cosh sinh tanh abs opp
        pi deg2rad rad2deg
    } {
        namespace export $function
    }
}

# (AM) No "namespace import" - this should be left to the user!
#namespace import ::math::bigfloat::*

package provide math::bigfloat 1.2.2
