#!/usr/bin/env bash
# run_container.sh — launch the Catapult Rocky Linux container
#
# Copy anywhere in your project tree. Set CONTAINER_DIR below to the
# root of the catapult-apptainer repo (where the Makefile lives).
#
# Usage: run_container.sh [TARGET [WORK_DIR]]
#
#   TARGET     container-shell (default) | catapult-shell
#   WORK_DIR   directory to start in; defaults to this script's directory
#              (can also be passed as an env var)
#
# Optional env vars:
#   CATAPULT_SCRIPT   /path/to/run.tcl   (-file <script>)
#   CATAPULT_CMD      "go_synthesis"     (-eval <command>)
#   CATAPULT_PROJECT  my_project.v2      (project file)

set -euo pipefail

# ----------
CONTAINER_DIR="/extras2/tools/Siemens/catapult/catapult_apptainer"
# ----------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-container-shell}"
WORK_DIR="${2:-${WORK_DIR:-$SCRIPT_DIR}}"

# Colors (terminal only)
if [[ -t 1 ]]; then
    RST=$'\033[0m' DIM=$'\033[2m' RED=$'\033[31m' CYAN=$'\033[36m' BCYAN=$'\033[1;36m'
else
    RST='' DIM='' RED='' CYAN='' BCYAN=''
fi

err() { printf '%sERROR:%s %s\n' "$RED" "$RST" "$*" >&2; exit 1; }

[[ -d "$CONTAINER_DIR"          ]] || err "Container directory not found: $CONTAINER_DIR"
[[ -f "$CONTAINER_DIR/Makefile" ]] || err "Makefile not found in $CONTAINER_DIR"
[[ -d "$WORK_DIR"               ]] || err "WORK_DIR does not exist: $WORK_DIR"

MAKE_ARGS=("$TARGET" "WORK_DIR=$WORK_DIR")
[[ -n "${CATAPULT_SCRIPT:-}"  ]] && MAKE_ARGS+=("CATAPULT_SCRIPT=$CATAPULT_SCRIPT")
[[ -n "${CATAPULT_CMD:-}"     ]] && MAKE_ARGS+=("CATAPULT_CMD=$CATAPULT_CMD")
[[ -n "${CATAPULT_PROJECT:-}" ]] && MAKE_ARGS+=("CATAPULT_PROJECT=$CATAPULT_PROJECT")

lbl() { printf '%s==>%s %-14s %s%s%s%s\n' "$BCYAN" "$RST" "$1" "$DIM" "$CYAN" "$2" "$RST"; }
lbl "Container dir" "$CONTAINER_DIR"
lbl "Target"        "$TARGET"
lbl "Work dir"      "$WORK_DIR"
[[ -n "${CATAPULT_SCRIPT:-}"  ]] && lbl "Script"  "$CATAPULT_SCRIPT"
[[ -n "${CATAPULT_CMD:-}"     ]] && lbl "Command" "$CATAPULT_CMD"
[[ -n "${CATAPULT_PROJECT:-}" ]] && lbl "Project" "$CATAPULT_PROJECT"
echo

cd "$CONTAINER_DIR"
exec make "${MAKE_ARGS[@]}"
