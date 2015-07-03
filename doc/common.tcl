########################################################################
#
# sourced by gendoc and ../htmlgen/gendoc to have a consistent style
# for the documentation.
#
# (C) 2002 Harald Kirsch
# $Revision: 1.4 $, $Date: 2002/09/21 14:55:58 $
########################################################################

##
## Navigation structure for cgi-script 'index'
##
set navbar {
  overview Overview .
  xmlgen Xmlgen .
  htmlgen Htmlgen {
    tab {Notebook Tabs} .
    sidenav {Navigation Bar} .
  }
}

## Translate a path name into the associated text, return empty string
## if not found.
proc getNodeText {path tree} {
  if {[llength $tree]<3} { return "" }
  set top [lindex $path 0]
  foreach {n text subtree} $tree {
    if {$n==$top} {
      if {[llength $path]==1} { return $text }
      return [getNodeText [lrange $path 1 end] $subtree]
    }
  }
  return {}
}

## Some shortcuts
set Tcl [acronym Tcl]
set XML [acronym XML]
set HTML [acronym HTML]

interp alias {} dispcode {} p class=ttab 

proc makeTitle {text short} {
  return "$text &mdash; $short"
}
## The header mimics the page header of a typical unix manual page

proc putHeader {nodeText shorttitle} {
  table width=100% {style=border: 2px solid grey} ! {
    tr ! {
      td width=20% align=left - $nodeText
      td align=center - $shorttitle
      td width=20% align=right - xmlgen
    }
  }
}


proc putFooter {thisNode url} {
  ## Generate a flat list of links from the navigation bar
  ## rest will hold a multiple of 2 elements where the first is a path
  ## and the 2nd is the tree attached to this path.
  set rest [list {} $::navbar]
  for {set i 0} {$i<[llength $rest]} {} {
    set path [lindex $rest $i]; incr i
    set tree [lindex $rest $i]; incr i
    foreach {node text subtree} $tree {
      set p [concat $path [list $node]]
      if {[llength $subtree]>=3} {
	lappend rest $p
	lappend rest $subtree
      }
      if {"$p"=="$thisNode"} {
	set thisText $text
	continue
      }
      if {""=="$url"} {
	lappend l [a href=$node.html $text]
      } else {
	lappend l [a href=$url?[cgiset Path $p] $text]
      }
    }
  }

  h2 - See Also
  p + [join $l ", "]

  table width=100% {style=border: 2px solid grey} ! {
    tr ! {
      td width=30% align=left - $thisText
      td align=center - [package present xmlgen]
      td width=30% align=right - xmlgen
    }
  }
}


proc putStyle {} {
  style + {
    <!--
    p {margin-left:1cm; text-align:justify; margin-right:1cm;}
    *.n {margin-left: 0px; margin-right:0px;}
    *.tab {margin-left: 1cm; margin-right: 1cm;}
    *.ttab {
      margin-left:15mm;
      margin-right:15mm;
      padding: 1mm;
      font-family: monospace;
      background-color: \#eeeeee;
    }
    ul, ol {list-style-position: inside; text-align:justify;
      margin-left:5mm; margin-right:20mm;}
    acronym {font-style: oblique;}
    -->
  }
}

proc showpage {type node nodeText shorttitle page} {
  if {"$type"=="-all"} {
    html ! {
      head ! {
	title - [makeTitle $nodeText $shorttitle]
	putStyle
      }
      body ! {
	putHeader $nodeText $shorttitle
	put $page
	putFooter $node {}
      }
    }
  } else {
    body ! {
      putHeader $nodeText $shorttitle
      put $page
      putFooter $node $::url
    } 
  }
}
