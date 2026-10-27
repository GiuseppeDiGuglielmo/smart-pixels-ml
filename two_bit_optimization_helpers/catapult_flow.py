"""Batch Catapult flow for codesign_catapult.ipynb (added 2026-10-27).

Lets the notebook run top to bottom, Catapult included, with the fully
parallel architecture that was first set up by hand in the GUI (QMlp_Slim,
2026-10-26, see PLAN.md, "QMlp_Slim Catapult results").

1. add_directives_to_build_script(output_dir, directives_tcl)

   Inserts "source <directives_tcl>" after "go assembly" in the synthesis
   block of the generated build_prj.tcl, so hls_model.build(Synth=True)
   applies the directives before "go architect". The default script,
   catapult_directives/fully_parallel.tcl, pipelines the main loop with
   II=1, unrolls every other loop and maps the arrays to registers, without
   naming any layer. The inserted lines carry MARKER, so calling it again
   does nothing. hls4ml rewrites build_prj.tcl on every write() (compile(),
   trace(), ...), so call it right before build().

2. read_rtl_summary(output_dir, project_name) / print_rtl_summary(summary)

   Reads the design totals from the solution's rtl.rpt: latency,
   throughput, II, area scores, registers, critical path and slack.
   hls4ml.report.parse_catapult_report() only reads nnet_layer_results.txt,
   whose per-layer tables are empty for io_parallel: build_prj.tcl inlines
   every nnet:: function into one block, so there are no layer blocks to
   report.
"""

import glob
import os
import re

MARKER = "HLS4ML_FULLY_PARALLEL_DIRECTIVES"

_DEFAULT_DIRECTIVES = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "catapult_directives",
    "fully_parallel.tcl",
)


def add_directives_to_build_script(output_dir, directives_tcl=_DEFAULT_DIRECTIVES, verbose=True):
    """Source directives_tcl after "go assembly" in output_dir/build_prj.tcl.

    Returns True if the script was changed, False if it already had them.
    """
    directives_tcl = os.path.abspath(directives_tcl)
    if not os.path.isfile(directives_tcl):
        raise FileNotFoundError(directives_tcl)

    script = os.path.join(output_dir, "build_prj.tcl")
    with open(script) as f:
        text = f.read()

    if MARKER in text:
        if verbose:
            print(f"{script}: directives already added ({MARKER})")
        return False

    # Synthesis block of the normal top-down flow:
    #   if {$BuildOptions(Synth)} {
    #     ...
    #     go assembly
    #     <- here
    #     go architect
    pattern = re.compile(r"(if \{\$BuildOptions\(Synth\)\} \{.*?\n([ \t]*)go assembly[ \t]*\n)", re.S)
    match = pattern.search(text)
    if match is None:
        raise RuntimeError(f'{script}: "go assembly" not found in the Synth block; build_prj.tcl template changed?')

    indent = match.group(2)
    insert = (
        f"{indent}# {MARKER}: added by two_bit_optimization_helpers/catapult_flow.py\n"
        f"{indent}# (codesign_catapult.ipynb), fully parallel architecture\n"
        f"{indent}source {directives_tcl}\n"
    )
    text = text[: match.end()] + insert + text[match.end() :]

    with open(script, "w") as f:
        f.write(text)
    if verbose:
        print(f"{script}: added 'source {directives_tcl}' after go assembly")
    return True


def find_rtl_report(output_dir, project_name):
    """Path of rtl.rpt of the latest solution, e.g. <prj>/<project>.v1/rtl.rpt."""
    reports = glob.glob(os.path.join(output_dir, f"{project_name}_prj*", f"{project_name}.v*", "rtl.rpt"))
    if not reports:
        raise FileNotFoundError(f"No rtl.rpt under {output_dir}/{project_name}_prj*/{project_name}.v*/ (synthesis not run?)")
    return max(reports, key=os.path.getmtime)


def _floats(line):
    return [float(x) for x in re.findall(r"-?\d+(?:\.\d+)?", line)]


def read_rtl_summary(output_dir, project_name, rtl_report=None):
    """Design totals from Catapult's rtl.rpt, as a dict."""
    if rtl_report is None:
        rtl_report = find_rtl_report(output_dir, project_name)
    with open(rtl_report) as f:
        lines = f.read().splitlines()

    summary = {"rtl_report": rtl_report}
    section = None
    for line in lines:
        if line.startswith("-- Version:") and "version" not in summary:
            summary["version"] = line.split(":", 1)[1].strip()
        if line.startswith("Solution Settings:") and "solution" not in summary:
            summary["solution"] = line.split(":", 1)[1].strip()
        if line and not line.startswith(" "):
            section = line.strip()
            continue
        s = line.strip()
        if section == "Processes/Blocks in Design" and s.startswith("Design Total:"):
            # Real Operation(s) count, Latency, Throughput, Reset Length, II
            ops, latency, throughput, reset_length, ii = _floats(s)[:5]
            summary.update(
                real_ops=int(ops),
                latency_cycles=int(latency),
                throughput_cycles=int(throughput),
                reset_length=int(reset_length),
                ii=int(ii),
            )
        elif section == "Area Scores" and s.startswith("Total Area Score:"):
            post_sched, post_dpfsm, post_assign = _floats(s)[:3]
            summary.update(
                area_post_scheduling=post_sched,
                area_post_dpfsm=post_dpfsm,
                area_post_assignment=post_assign,
            )
        elif section == "Area Scores" and s.startswith("Total Reg:"):
            # "3084.2 (1%) 3089.0 (1%) 3089.0 (1%)": take the last value
            summary["register_area_post_assignment"] = _floats(s)[-2]
        elif section == "Timing Report" and s.startswith("Max Delay:") and "max_delay_ns" not in summary:
            summary["max_delay_ns"] = _floats(s)[0]
        elif section == "Timing Report" and s.startswith("Slack:") and "slack_ns" not in summary:
            summary["slack_ns"] = _floats(s)[0]
        elif "Clock period or pin-to-reg delay constraint" in s and "clock_period_ns" not in summary:
            summary["clock_period_ns"] = _floats(s.split(":", 1)[1])[0]

    missing = [k for k in ("latency_cycles", "throughput_cycles", "area_post_assignment") if k not in summary]
    if missing:
        raise RuntimeError(f"{rtl_report}: could not read {missing}; report format changed?")

    if "clock_period_ns" in summary:
        summary["latency_ns"] = summary["latency_cycles"] * summary["clock_period_ns"]
        summary["throughput_ns"] = summary["throughput_cycles"] * summary["clock_period_ns"]
    return summary


def print_rtl_summary(summary):
    clk = summary.get("clock_period_ns")

    def ns(key):
        return f" ({summary[key]:g} ns)" if key in summary else ""

    def cycles(n):
        return f"{n} cycle" if n == 1 else f"{n} cycles"

    print(f"Catapult {summary.get('version', '?')}, solution {summary.get('solution', '?')}")
    print(f"  report:            {summary['rtl_report']}")
    if clk is not None:
        print(f"  clock period:      {clk:g} ns")
    print(f"  latency:           {cycles(summary['latency_cycles'])}{ns('latency_ns')}")
    print(f"  throughput:        {cycles(summary['throughput_cycles'])}{ns('throughput_ns')}")
    print(f"  II:                {summary.get('ii', '?')}")
    print(f"  total area score:  {summary['area_post_assignment']:,.1f} (post-assignment)")
    if "area_post_scheduling" in summary:
        print(f"                     {summary['area_post_scheduling']:,.1f} (post-scheduling)")
    if "register_area_post_assignment" in summary:
        print(f"  register area:     {summary['register_area_post_assignment']:,.1f}")
    if "max_delay_ns" in summary:
        print(f"  critical path:     {summary['max_delay_ns']:.2f} ns, slack {summary.get('slack_ns', float('nan')):.2f} ns")
    if "real_ops" in summary:
        print(f"  real operations:   {summary['real_ops']}")
