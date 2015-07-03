########################################################################
#  webutils -- Toolbox of utility procs for easy web site generation
# $Revision: 1.4 $, $Date: 2002/07/11 05:32:03 $
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

# Load packages
foreach {i} {parse htmlgen} { package require $i }
# Load html commands into our namespace
namespace import -force ::htmlgen::*


#<<<<<<<<<<<< NAMESPACE ::webutils:: >>>>>>>>>>>>>>#
namespace eval ::webutils {

    namespace export -clear webgen tmlparse linksub tagsub keysub punctsub

}
#-----------------------------------------------


#<<<<<<<<<<<< ::webutils::webgen >>>>>>>>>>>>>>#
# webgen ?-file outPath? arrayName pageName
# outPath       = Path for .html page(s) to be written (created if not present)
# Returns HTML output for specified page, optionally also writes to outPath.html
proc ::webutils::webgen { args } {
    parse::args {file.arg} {arrayName pageName} $args

    # Setup
    set html {}         ;# HTML string that we build from null
    set sortList {
        ## TODO
    }

    # Start with any common elements, then go on to page-specific elements
    foreach {i} [list common $pageName] {

        foreach {j k} [array get $arrayName $i*] {

            # Process each element according to its type
            switch -glob $j {
                # Start with <HEAD>...</HEAD>
                ## TODO

            }
        }
    }

    return $html
}


#<<<<<<<<<<<< ::webutils::tmlparse >>>>>>>>>>>>>>#
# tmlparse arrayName specFile ?specFile2? ... ?specFileN?
# Returns list of page names defined by TML data
#
# TML File format:
# <<<???.styles>>>
# ...
# <<<???.domains>>>
# com gov edu de au etc. etc.
# ...
# <<<???.links>>>
# keyphrase linkexp
# ...
# <<<???.spans>>>
# keyphrase {attr value ...}
# ...
# <<<common.head>>>
# paramA {attr value pairs} {tag body} 
# ...
# paramB {attr value pairs} {tag body}
# ...
# <<<common.body>>>
# Plain text with [TCL procs] to generate any common HTML (at page top)
# ...
# <<<page1.tml>>>
# (or)
# <<<page1.head>>>
# paramC {attr value pairs} {tag body} 
# ...
# paramD {attr value pairs} {tag body}
# ...
# <<<page1.body>>>
# Plain text with [TCL procs] to generate any page1 HTML
# ...
proc ::webutils::tmlparse { args } {
    # Destination array name is first arg
    upvar [lindex $args 0] KEYS

    ### Read spec files into one big string
    set tmlString {}
    foreach {i} [lrange $args 1 end] {
        # Open settings file for reading
        set err [catch {set fh [open $i r]} errorMsg] 
        if { $err } {
            error "TML File Read Error: $errorMsg"

        } else {
            # Append each non-commented, non-blank line to string
            while { ![eof $fh] } {
                # Get first (or next) line of file
                gets $fh inLine
                # Append line if not blank or comment
                if { ![regexp {^#} $inLine] && ( [string length $inLine] > 1 ) } {
                    set tmlString "$tmlString\n$inLine"
                }
            }
            # Done reading file, so close it
            close $fh
        }
    }

    ### Iteratively substitute in all <<<xxx.tml>>> macros
    while {
        [regexp -nocase -indices {(<)<<[^>]+\.tml>>(>)} $tmlString null x y]
    } {
        set k1 [lindex $x 0]
        set k2 [lindex $y 0]
        set fname [string range "$tmlString" \
            [expr { $k1+3 }] [expr { $k2-3 }] ]
        if { ![catch { set fh [open $fname] }] } {
            set tmlString [string replace $tmlString $k1 $k2 [read $fh]]
            close $fh
        }
    }

    ### Get indices to all keywords
    set match 1; set k -1
    while {$match} {
        set match [regexp -start [expr $k+1] -indices \
            {(<)<<[^>]*>>(>)} $tmlString null x y]
        if {$match} {
             lappend keyList [lindex $x 0]
             set k [expr { [lindex $y 0]-1 }]
        }
    }

    ### Populate array with keyword sections, using keywords as indices
    # Create list of page names in the process
    set pageList {}
    set n [expr { [llength $keyList]-1 }]
    for {set i 0} {$i<$n} {incr i} {
        set k0 [lindex $keyList $i]
        set k1 [expr { [lindex $keyList [expr {$i+1}] ]-1 }]
        if { [regexp {<<<([^\.>]+)\.([^>]+)>>>(.*)} [string range $tmlString $k0 $k1] null x y z] } {
            array set KEYS [list $x.$y $z]
            # Add page name to list if not 'common' and not in list already
            if { ![string match $x common] && ( [lsearch $pageList $x] < 0 ) } {
                lappend pageList $x
            }
        }
    }

    return $pageList
}


#<<<<<<<<<<<< ::webutils::xmlsub (internal) >>>>>>>>>>>>>>#
proc ::webutils::xmlsub { tag attrList keyword string } {
    foreach {i j} $attrList {
        lappend attrs $i=$j
    }
    set x [eval ::xmlgen::doTag $tag $attrs $keyword]
    # Now do the full substitution
    regsub -all [subst {\x20$keyword\(\[^a-zA-Z<\])}] $string [subst {\x20$x\\1}] string

    return $string
}


#<<<<<<<<<<<< ::webutils::expsub (internal) >>>>>>>>>>>>>>#
proc ::webutils::expsub { exp string buffer subPlace } {
    # One loop iteration for each keyphrase match
    while {
        [regexp -indices "\[^a-zA-Z\<\>\]($exp)\[^a-zA-Z\<\>\]" $string null x]
    } {
        # Get match string
        set y [eval string range [subst -nocommands {{$string}}] $x]
        # In buffer, substitute match string for substitution
        # placeholder (e.g., "%1%")
        regsub -all $subPlace $buffer $y buffer
        # Replace match in main string with prepared buffer
        set string [eval string replace \
            [subst -nocommands {{$string}}] $x [subst {{$buffer}}] ]
    }
    return $string
}


#<<<<<<<<<<<< ::webutils::linksub >>>>>>>>>>>>>>#
# linksub ?-class <class>? ?-wwwclass <wwwclass>? ?-domains <list>? ?-autowww? subList string
# class         = CSS class name for normal links
# wwwclass      = CSS class name for links starting with "www."
# domains       = list of recognized domains, without leading "."
# subList       = keyword/link pairs. "http://" will be added if
#                 omitted and link is to a known domain from optional
#                 list -domains <list>
# Returns modified string
proc ::webutils::linksub { args } {
    parse::args {class.arg wwwclass.arg domains.arg autowww} {subList string} $args

    if { [info exists domains] } {
        set test "\{("
        foreach {i} $domains {
            set test "$test$i|"
        }
        set test "[string range $test 0 end-1])\}"
    } else {
        set test {impossible_regexp_match}
    }

    if { [info exists autowww] } {
        if { [info exists wwwclass] } {
            set moreAttr [list class $wwwclass]
        } else {
            set moreAttr {}
        }
        while { [regexp {[^>/]www\.[^\x20,]+} $string match] } {
            set string [xmlsub h [concat href $x $moreAttr] $match $string]
        }
    }

    foreach {i j} $subList {
        # Apply appropriate CSS class if specified
        if { [string match www.* $i] && [info exists wwwclass] } {
            set moreAttr [list class $wwwclass]
        } elseif { [info exists class] } {
            set moreAttr [list class $class]
        } else {
            set moreAttr {}
        }
        # Create the substitution string
        # No clue why the 'eval' is needed, but it is
        if { ![string match http://* $j] && [eval regexp $test $j] } {
        set x "http://$j"
        } else {
            set x $j
        }
        # Now do the full substitution for keyword in question
        set string [xmlsub h [concat href $x $moreAttr] $i $string]
    }

    return $string
}     


#<<<<<<<<<<<< ::webutils::keysub >>>>>>>>>>>>>>#
# keysub subList string
# subList       = { keyphrase {expanded result} ...}
# Returns modified string
proc ::webutils::keysub { args } {
    parse::args {} {subList string} $args
    
    foreach {i j} $subList {
        # Define what is substituted in, with %1% for enclosing target text
        buffer x $j
        # Now substitute each match to keyphrase with buffer contents,
        # except with any %1% in buffer replaced by match
        set string [expsub $i $string $x %1%]
    }

    return $string
}


#<<<<<<<<<<<< ::webutils::tagsub >>>>>>>>>>>>>>#
# tagsub subList stringName
# subList       = { keyTag1 keyTag2 {HTML %1%} ...}
# Modifies string in stringName
proc ::webutils::tagsub { args } {
    parse::args {} {subList stringName} $args

    foreach {i j k} $subList {
        # Define what is substituted in
        switch $j {
            ! {
                buffer x $k
                regsub %1% $x $i x
            } - {
                set x $k
            }
        }
        # Now do the full substitution
        # TODO
        regsub -all \
            [subst {(^|\\n)$i\\x20+(\[^\\n\]+)(\\n|$)}] \
            $string [subst {\\1$x\\2\\3}] string
    }

    return
}


#<<<<<<<<<<<< ::webutils::punctsub >>>>>>>>>>>>>>#
# punctsub ?-smart? stringName
# smart         = specify if proc should try using smart quotes
# Returns modified string
proc ::webutils::punctsub { args } {
    parse::args {smart} {string} $args

    set subList {
        {\ '(\[^\\x20\]|\[^s\]\[^\x20\])}       { \\&\#8216\;\\1}   { '\\1}
        {'}                                     {\\&\#8217\;}       {'}
        {(\[\\x20\(\])\"}                       {\\1\\&\#8220\;}    { \\&\#34\;\\1}
        {\"}                                    {\\&\#8221\;}       {\\&\#34\;}
        {&}                                     {\\&amp\;}          {\\&amp\;}
        {<}                                     {\\&lt\;}           {\\&lt\;}
        {>}                                     {\\&gt\;}           {\\&gt\;}
    }
    # Now do the substitutions for each punctuation mark found
    foreach {i j k} $subList {
        set x [expr { [info exists smart] ? $j : $k }]
        set keepLooping [regsub -all [subst $i] $string [subst $x] string]
    }

    return $string
}


#<<<<<<<<<<<< ::webutils::headset >>>>>>>>>>>>>>#
# headset ?-style <styleList>? headList stringName
# smart         = specify if proc should try using smart quotes
# Returns <style>...</style> block
proc ::webutils::headset { styleList } {

    # TODO
    # Proc body here

    return
}


#<<<<<<<<<<<< ::webutils::styleset (internal) >>>>>>>>>>>>>>#
# styleset styleList
# Returns <style>...</style> block
proc ::webutils::styleset { styleList } {

    # TODO
    # Proc body here

    return $result
}

