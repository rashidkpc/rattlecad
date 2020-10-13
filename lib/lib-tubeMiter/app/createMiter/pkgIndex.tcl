# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded tubeMiter_createMiter  0.00 "\
        [list source [file join $dir createMiter.tcl]]; \
        [list source [file join $dir classScalarEntry.tcl]]; \
            \
        [list source [file join $dir lib_model.tcl]]; \
            \
        [list source [file join $dir lib_view.tcl]]; \
        [list source [file join $dir lib_viewConfig.tcl]]; \
        [list source [file join $dir lib_viewConfigTube.tcl]]; \
        [list source [file join $dir lib_viewConfigTool.tcl]]; \
        [list source [file join $dir lib_viewConfigMiter.tcl]]; \
        [list source [file join $dir lib_viewShape.tcl]]; \
        [list source [file join $dir lib_viewCanvas.tcl]]; \
        [list source [file join $dir lib_viewCanvasConfig.tcl]]; \
        [list source [file join $dir lib_viewCanvasMiter.tcl]]; \
            \
        [list source [file join $dir lib_control.tcl]]; \
            \
"
