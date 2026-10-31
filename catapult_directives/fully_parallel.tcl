# Fully parallel architecture for hls4ml io_parallel designs (2026-10-27).
#
# Model-independent version of the directives first set by hand in the
# Catapult GUI for QMlp_Slim (catapult_directives/QMlp_Slim.tcl):
# - every array resource of the process (layer outputs, pooling buffers,
#   dense accumulators: paths ending in ":rsc") mapped to registers
# - the main loop pipelined with II=1 (one result per clock)
# - every loop below the main loop fully unrolled
#
# The loops and arrays are found with "directive get ... -match glob", so
# no layer numbers or template arguments are written here.
#
# Must be sourced after "go assembly" and before "go architect". In the
# notebook flow, codesign_catapult.ipynb inserts
#   source <this file>
# after "go assembly" in the generated build_prj.tcl (see the cell
# "Add the fully parallel directives to build_prj.tcl"). In the GUI: run
# "go assembly", then "source <this file>", then "go extract".
#
# Uses $design_top (set by build_prj.tcl); falls back to the only design
# top found when it is not set.

proc hls4ml_fully_parallel { {top ""} {max_depth 12} } {
  if { $top eq "" } {
    if { [info exists ::design_top] } {
      set top $::design_top
    } else {
      error "hls4ml_fully_parallel: design top not given and \$design_top not set"
    }
  }

  # Processes with a main loop, e.g. /SmtPxl_QMlp_Slim/core
  set procs {}
  foreach p [directive get /$top/*/main/PIPELINE_INIT_INTERVAL -match glob -ret path -checkpath 0] {
    lappend procs [file dirname [file dirname $p]]
  }
  if { [llength $procs] == 0 } {
    error "hls4ml_fully_parallel: no main loop found under /$top (run after go assembly)"
  }

  set n_rsc 0
  set n_unroll 0
  set n_pipe_off 0
  foreach proc_path $procs {
    # Arrays of the process to registers
    foreach p [directive get $proc_path/*:rsc/MAP_TO_MODULE -match glob -ret path -checkpath 0] {
      directive set [file dirname $p] -MAP_TO_MODULE {[Register]}
      incr n_rsc
    }

    # Main loop: one new input every clock
    directive set $proc_path/main -PIPELINE_INIT_INTERVAL 1

    # Every loop nested below main (any depth) fully unrolled
    set pat $proc_path/main
    for {set d 1} {$d <= $max_depth} {incr d} {
      set pat $pat/*
      foreach p [directive get $pat/UNROLL -match glob -ret path -checkpath 0] {
        # 2026-10-30: nnet::linear (QKeras quantized_bits output activation)
        # is pipelined in the source (hls_pipeline_init_interval 1). Unrolling
        # it without removing that pipeline fails at go architect with LOOP-21
        # "Cannot pipeline a fully unrolled loop" (QConv2D_Slim). Skipping the
        # unroll instead leaves a rolled, pipelined loop of 80 iterations
        # inside main (latency 81). Set by hand in the GUI, latency 2: drop the
        # pipeline (II 0), then unroll.
        if { [string match {*nnet::linear<*} $p] } {
          directive set [file dirname $p] -PIPELINE_INIT_INTERVAL 0
          incr n_pipe_off
        }
        directive set [file dirname $p] -UNROLL yes
        incr n_unroll
      }
    }
  }

  logfile message "hls4ml_fully_parallel: [llength $procs] process(es), $n_rsc array(s) to registers, main loop II=1, $n_unroll loop(s) unrolled, $n_pipe_off source pipeline(s) removed\n" info
  puts "hls4ml_fully_parallel: [llength $procs] process(es), $n_rsc array(s) to registers, main loop II=1, $n_unroll loop(s) unrolled, $n_pipe_off source pipeline(s) removed"
}

hls4ml_fully_parallel
