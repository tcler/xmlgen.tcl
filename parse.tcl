########################################################################
#
#  parse -- extension for parsing procedure arguments
# 
# $Revision: 1.1 $, $Date: 2002/06/10 03:22:08 $
########################################################################
set license {
Copyright (c) 2002, Edwin A. Suominen
Registered Patent Agent * http://eepatents.com
Author, PRIVARIA Secure Networking Suite
Freely available at http://www.privaria.org

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of the author nor any contributor may be used to
endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}

package require cmdline

namespace eval ::parse {

namespace export args

#<<<<<<<<<<<< PARSE::ARGS >>>>>>>>>>>>>>#
proc args { optsList varsList args } {

### List Pre-processing
# Determine whether args is only a single variable (list?)
set singleVarFlag 1
if {    [llength $args] == 0    ||
        [regexp {^\{*(\-|\}$)} $args]  } {
    # Not possible to be a single-variable arg list
    # if there's any option present
    set singleVarFlag 0

} else {
    foreach {i} $args {
        if { [llength $i] > 1 } {
            set singleVarFlag 0
            break
        }
    }
}
# Now work on each list in turn
foreach {i} {optsList varsList args} {
    # Massage selected list if multiply escaped
    while { [llength [set $i]] == 1 &&
            [regexp {\x20} [set $i]] } {
        set $i [lindex [set $i] 0]
    }

    # Extract any default values from opts, vars lists (to be overwritten
    # for defined options)
    if { [regexp List $i] } {
        set count 0
        set x [set $i]  ;# For loop, create temp list w/ selected list contents
        foreach {j} $x {
            if { [llength $j] > 1 } {
                regexp -nocase {^([a-z0-9]+)} [lindex $j 0] null varName
                set $i [lreplace [set $i] $count $count [lindex $j 0] ]
                set xxx [lindex $j end]
                uplevel [list set $varName $xxx]
            }
            incr count
        }
    }
}
# Assign variables based on lists
if {$singleVarFlag} {
    if { [llength $varsList] > 0 } {
        uplevel [subst { set [lindex $varsList 0] {$args} } ]
    }

} else {
    uplevel [subst {
        set parseargsList [list $args]
        while { \[ ::cmdline::getopt parseargsList {$optsList} x y \] == 1 } {
            set \$x \$y }
        foreach {i} {$varsList} {j} \$parseargsList {
            # The IF corrects a bug that was very hard to spot. Can you?
            if { \[llength \$j \] > 0 } { 
                set \$i \$j
            } elseif { !\[info exists \$i \] } {
                set \$i \[list \]   ;# List w/ no args returns empty list
            }
        }
        unset parseargsList
    }]
}

### END PARSEARGS
return
}

### END PARSE.TCL
}