# Catapult startup script for codesign_catapult.ipynb (added 2026-10-18).
#
# NOT USED since 2026-10-19: only needed for Catapult 2026.3_1. With the
# customized Catapult 2024.2_2 install, asiclibspath already sets the library
# path. Kept for reference; the startup= line in codesign_catapult.ipynb
# ("create_config" cell) is commented out. See PLAN.md.
#
# Passed to hls4ml as create_config(..., startup=<this file>). The generated
# build_prj.tcl sources it ("Source optional end-user startup script") after
# creating the project and before loading the technology libraries.
#
# Why: the hls4ml shipped with Catapult 2026.3_1 (0.1.0.dev1981+g70cf498)
# silently ignores create_config(asiclibspath=...). With Catapult 2024.2_2
# that path was written into build_prj.tcl as the line below; without it,
# Catapult stops with "Could not locate library file for library name
# tcbn28hpcplusbwp30p140ssg0p81v125c_ccs_dc". See PLAN.md, "Changes made
# for Catapult 2026.3_1".
#
# Keep the path in sync with asiclibspath in the notebook's
# "Configure hls4ml model" cell.
#
# Older Catapult (e.g. 2024.2_2) still uses asiclibspath, so this line only
# adds the same folder to the search path a second time, which is harmless.

solution options set ComponentLibs/SearchPath /home/giuseppe/research/projects/smartpixels/tsmc28nm_lib -append
