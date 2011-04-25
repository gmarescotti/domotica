#!/bin/sh
# the next line restarts using wish\
exec wish "$0" "$@" 

if {![info exists vTcl(sourcing)]} {

    # Provoke name search
    catch {package require bogus-package-name}
    set packageNames [package names]

    package require Tk
    switch $tcl_platform(platform) {
	windows {
            option add *Button.padY 0
	}
	default {
            option add *Scrollbar.width 10
            option add *Scrollbar.highlightThickness 0
            option add *Scrollbar.elementBorderWidth 2
            option add *Scrollbar.borderWidth 2
	}
    }
    
    # Tix is required
    package require Tix
    
}

#############################################################################
# Visual Tcl v1.60 Project
#


#################################
# VTCL LIBRARY PROCEDURES
#

if {![info exists vTcl(sourcing)]} {
#############################################################################
## Library Procedure:  Window

proc ::Window {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global vTcl
    foreach {cmd name newname} [lrange $args 0 2] {}
    set rest    [lrange $args 3 end]
    if {$name == "" || $cmd == ""} { return }
    if {$newname == ""} { set newname $name }
    if {$name == "."} { wm withdraw $name; return }
    set exists [winfo exists $newname]
    switch $cmd {
        show {
            if {$exists} {
                wm deiconify $newname
            } elseif {[info procs vTclWindow$name] != ""} {
                eval "vTclWindow$name $newname $rest"
            }
            if {[winfo exists $newname] && [wm state $newname] == "normal"} {
                vTcl:FireEvent $newname <<Show>>
            }
        }
        hide    {
            if {$exists} {
                wm withdraw $newname
                vTcl:FireEvent $newname <<Hide>>
                return}
        }
        iconify { if $exists {wm iconify $newname; return} }
        destroy { if $exists {destroy $newname; return} }
    }
}
#############################################################################
## Library Procedure:  vTcl:DefineAlias

proc ::vTcl:DefineAlias {target alias widgetProc top_or_alias cmdalias} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global widget
    set widget($alias) $target
    set widget(rev,$target) $alias
    if {$cmdalias} {
        interp alias {} $alias {} $widgetProc $target
    }
    if {$top_or_alias != ""} {
        set widget($top_or_alias,$alias) $target
        if {$cmdalias} {
            interp alias {} $top_or_alias.$alias {} $widgetProc $target
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:DoCmdOption

proc ::vTcl:DoCmdOption {target cmd} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## menus are considered toplevel windows
    set parent $target
    while {[winfo class $parent] == "Menu"} {
        set parent [winfo parent $parent]
    }

    regsub -all {\%widget} $cmd $target cmd
    regsub -all {\%top} $cmd [winfo toplevel $parent] cmd

    uplevel #0 [list eval $cmd]
}
#############################################################################
## Library Procedure:  vTcl:FireEvent

proc ::vTcl:FireEvent {target event {params {}}} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## The window may have disappeared
    if {![winfo exists $target]} return
    ## Process each binding tag, looking for the event
    foreach bindtag [bindtags $target] {
        set tag_events [bind $bindtag]
        set stop_processing 0
        foreach tag_event $tag_events {
            if {$tag_event == $event} {
                set bind_code [bind $bindtag $tag_event]
                foreach rep "\{%W $target\} $params" {
                    regsub -all [lindex $rep 0] $bind_code [lindex $rep 1] bind_code
                }
                set result [catch {uplevel #0 $bind_code} errortext]
                if {$result == 3} {
                    ## break exception, stop processing
                    set stop_processing 1
                } elseif {$result != 0} {
                    bgerror $errortext
                }
                break
            }
        }
        if {$stop_processing} {break}
    }
}
#############################################################################
## Library Procedure:  vTcl:Toplevel:WidgetProc

proc ::vTcl:Toplevel:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }
    set command [lindex $args 0]
    set args [lrange $args 1 end]
    switch -- [string tolower $command] {
        "setvar" {
            foreach {varname value} $args {}
            if {$value == ""} {
                return [set ::${w}::${varname}]
            } else {
                return [set ::${w}::${varname} $value]
            }
        }
        "hide" - "show" {
            Window [string tolower $command] $w
        }
        "showmodal" {
            ## modal dialog ends when window is destroyed
            Window show $w; raise $w
            grab $w; tkwait window $w; grab release $w
        }
        "startmodal" {
            ## ends when endmodal called
            Window show $w; raise $w
            set ::${w}::_modal 1
            grab $w; tkwait variable ::${w}::_modal; grab release $w
        }
        "endmodal" {
            ## ends modal dialog started with startmodal, argument is var name
            set ::${w}::_modal 0
            Window hide $w
        }
        default {
            uplevel $w $command $args
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:WidgetProc

proc ::vTcl:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }

    set command [lindex $args 0]
    set args [lrange $args 1 end]
    uplevel $w $command $args
}
#############################################################################
## Library Procedure:  vTcl:toplevel

proc ::vTcl:toplevel {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    uplevel #0 eval toplevel $args
    set target [lindex $args 0]
    namespace eval ::$target {set _modal 0}
}
}


if {[info exists vTcl(sourcing)]} {

proc vTcl:project:info {} {
    set base .top60
    namespace eval ::widgets::$base {
        set set,origin 1
        set set,size 1
        set runvisible 1
    }
    namespace eval ::widgets::$base.tix64 {
        array set save {-highlightbackground 1}
        namespace eval subOptions {
            array set save {-anchor 1 -label 1}
        }
    }
    set site_5_page1 [$base.tix64 subwidget [lindex [$base.tix64 pages] 0]]
    namespace eval ::widgets::$site_5_page1 {
        array set save {-height 1 -highlightcolor 1 -width 1}
    }
    set site_5_0 $site_5_page1
    namespace eval ::widgets::$site_5_0.fra76 {
        array set save {-height 1 -width 1}
    }
    set site_6_0 $site_5_0.fra76
    namespace eval ::widgets::$site_6_0.cpd77 {
        array set save {-arrowbitmap 1 -crossbitmap 1 -disabledforeground 1 -dropdown 1 -editable 1 -fancy 1 -highlightbackground 1 -history 1 -label 1 -prunehistory 1 -relief 1 -tickbitmap 1}
    }
    namespace eval ::widgets::$site_6_0.cpd78 {
        array set save {-borderwidth 1 -relief 1 -text 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.fra66 {
        array set save {-height 1 -width 1}
    }
    set site_6_0 $site_5_0.fra66
    namespace eval ::widgets::$site_6_0.tix61 {
        array set save {-highlightbackground 1 -scrollbar 1}
    }
    set site_5_page2 [$base.tix64 subwidget [lindex [$base.tix64 pages] 1]]
    namespace eval ::widgets::$site_5_page2 {
        array set save {-height 1 -highlightcolor 1 -width 1}
    }
    set site_5_page3 [$base.tix64 subwidget [lindex [$base.tix64 pages] 2]]
    namespace eval ::widgets::$site_5_page3 {
        array set save {-height 1 -highlightcolor 1 -width 1}
    }
    namespace eval ::widgets::$base.cpd69 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_3_0 $base.cpd69
    namespace eval ::widgets::$site_3_0.but70 {
        array set save {-text 1 -width 1}
    }
    namespace eval ::widgets::$site_3_0.but71 {
        array set save {-command 1 -text 1 -width 1}
    }
    namespace eval ::widgets::$site_3_0.but72 {
        array set save {-text 1 -width 1}
    }
    namespace eval ::widgets_bindings {
        set tagslist _TopLevel
    }
    namespace eval ::vTcl::modules::main {
        set procs {
            init
            main
        }
        set compounds {
        }
        set projectType single
    }
}
}

#################################
# USER DEFINED PROCEDURES
#
#############################################################################
## Procedure:  main

proc ::main {argc argv} {
   global widget

$widget(MyAddrs) subwidget listbox configure -listvariable ::list_addrs
}

#############################################################################
## Initialization Procedure:  init

proc ::init {argc argv} {

}

init $argc $argv

#################################
# VTCL GENERATED GUI PROCEDURES
#

proc vTclWindow. {base} {
    if {$base == ""} {
        set base .
    }
    ###################
    # CREATING WIDGETS
    ###################
    wm focusmodel $top passive
    wm geometry $top 1x1+0+0; update
    wm maxsize $top 1425 870
    wm minsize $top 1 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm withdraw $top
    wm title $top "vtcl.tcl"
    bindtags $top "$top Vtcl.tcl all"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    ###################
    # SETTING GEOMETRY
    ###################

    vTcl:FireEvent $base <<Ready>>
}

proc vTclWindow.top60 {base} {
    if {$base == ""} {
        set base .top60
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel \
        -highlightcolor black 
    wm focusmodel $top passive
    wm geometry $top 609x422+296+433; update
    wm maxsize $top 1425 870
    wm minsize $top 1 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm deiconify $top
    wm title $top "SCAN25100 Tester"
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    tixNoteBook $top.tix64 \
        -highlightbackground #d9d9d9 
    vTcl:DefineAlias "$top.tix64" "TixNoteBook1" vTcl:WidgetProc "$top" 1
    $top.tix64 add page1 \
        -anchor center -label bitmap 
    $top.tix64 add page2 \
        -anchor center -label {Special command} 
    $top.tix64 add page3 \
        -anchor center -label Info 
    set site_5_page1 [$top.tix64 subwidget [lindex [$top.tix64 pages] 0]]
    frame $site_5_page1.fra76 \
        -height 75 -width 125 
    vTcl:DefineAlias "$site_5_page1.fra76" "Frame3" vTcl:WidgetProc "$top" 1
    set site_6_0 $site_5_page1.fra76
    tixComboBox $site_6_0.cpd77 \
        -dropdown 1 -editable 0 -fancy 0 -history 0 -prunehistory 1 \
        -label Address -relief ridge 
    vTcl:DefineAlias "$site_6_0.cpd77" "MyAddrs" vTcl:WidgetProc "$top" 1
    button $site_6_0.cpd78 \
        -borderwidth 1 -relief ridge -text reload -width 8 
    vTcl:DefineAlias "$site_6_0.cpd78" "Button5" vTcl:WidgetProc "$top" 1
    pack $site_6_0.cpd77 \
        -in $site_6_0 -anchor center -expand 0 -fill none -side left 
    pack $site_6_0.cpd78 \
        -in $site_6_0 -anchor e -expand 0 -fill none -side left 
    pack $site_5_page1.fra76 \
        -in $site_5_page1 -anchor center -expand 0 -fill x -side top 
    frame $site_5_page1.fra66 \
        -height 75 -width 125 
    vTcl:DefineAlias "$site_5_page1.fra66" "bitmap" vTcl:WidgetProc "$top" 1
    set site_6_0 $site_5_page1.fra66
    tixScrolledListBox $site_6_0.tix61 \
        -scrollbar auto -borderwidth 1 
    bind $site_6_0.tix61 <FocusIn> {
        focus %W.listbox
    }
    pack $site_6_0.tix61 \
        -in $site_6_0 -anchor center -expand 1 -fill both -side top 
    pack $site_5_page1.fra66 \
        -in $site_5_page1 -anchor center -expand 1 -fill both -side top 
    set site_5_page2 [$top.tix64 subwidget [lindex [$top.tix64 pages] 1]]
    set site_5_page3 [$top.tix64 subwidget [lindex [$top.tix64 pages] 2]]
    frame $top.cpd69 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$top.cpd69" "Frame2" vTcl:WidgetProc "$top" 1
    set site_3_0 $top.cpd69
    button $site_3_0.but70 \
        -text {reload all} -width 8 
    vTcl:DefineAlias "$site_3_0.but70" "Button1" vTcl:WidgetProc "$top" 1
    button $site_3_0.but71 \
        -command exit -text quit -width 8 
    vTcl:DefineAlias "$site_3_0.but71" "Button2" vTcl:WidgetProc "$top" 1
    button $site_3_0.but72 \
        -text info -width 8 
    vTcl:DefineAlias "$site_3_0.but72" "Button3" vTcl:WidgetProc "$top" 1
    pack $site_3_0.but70 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.but71 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side right 
    pack $site_3_0.but72 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    ###################
    # SETTING GEOMETRY
    ###################
    pack $top.tix64 \
        -in $top -anchor center -expand 1 -fill both -side top 
    pack $top.cpd69 \
        -in $top -anchor center -expand 0 -fill x -side top 

    vTcl:FireEvent $base <<Ready>>
}

#############################################################################
## Binding tag:  _TopLevel

bind "_TopLevel" <<Create>> {
    if {![info exists _topcount]} {set _topcount 0}; incr _topcount
}
bind "_TopLevel" <<DeleteWindow>> {
    if {[set ::%W::_modal]} {
                vTcl:Toplevel:WidgetProc %W endmodal
            } else {
                destroy %W; if {$_topcount == 0} {exit}
            }
}
bind "_TopLevel" <Destroy> {
    if {[winfo toplevel %W] == "%W"} {incr _topcount -1}
}

Window show .
Window show .top60

main $argc $argv
