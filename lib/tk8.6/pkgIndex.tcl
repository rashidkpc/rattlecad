package ifneeded Tk 8.6.3 [format {if {[catch {load {} Tk}]} {load %s Tk}} [list [file join $dir tk86.dll]]]