"""Fixes for the C++ that the hls4ml shipped with Catapult 2026.3_1 generates.

NOT USED since 2026-10-19: only needed for Catapult 2026.3_1. Catapult 2024.2_2
has none of these bugs (no ac_sync between io_parallel layers). Kept for
reference; the notebook cell that installs it is a raw (disabled) cell.

Both fixes rewrite firmware/<project>.cpp after hls4ml writes the project.
install_firmware_fixes(hls_model) wraps hls_model.write, so they are
re-applied every time hls4ml regenerates the project (compile(), trace() and
build() all call write()). Each change is marked in the .cpp with its MARKER.
See PLAN.md, "Changes made for Catapult 2026.3_1".

1. ac_sync fan-out (fix_sync_fanout, marker HLS4ML_SYNC_FANOUT_FIX)

   In io_parallel the Catapult backend of hls4ml 0.1.0.dev1981+g70cf498
   passes an ac_sync handshake along with every layer output. Each layer
   block reads one token from its input sync (sync_in) and writes one to its
   output sync (sync_out). When one tensor feeds several layers (for example
   the model input feeding two AveragePooling2D layers in QMlp_Slim and
   QConv1D_Slim), the writer hands the same ac_sync to every consumer. Only
   one token is written, so the second consumer reads an empty channel:

       Assert in file .../ac_channel.h:296 Read from empty channel

   which aborts the process (and the Jupyter kernel). hls4ml's Clone pass,
   which handles fan-out, is disabled for io_parallel
   (backends/fpga/passes/clone.py: "Not needed for io_parallel").

   Fix: every ac_sync with more than one consumer goes through a small block
   (hls4ml_sync_fanout2) that reads the token once and writes one per
   consumer, so each consumer gets its own ac_sync. Only handshakes are
   duplicated; no data is copied.

2. hard_tanh block (fix_hard_tanh_block, marker HLS4ML_HARD_TANH_BLOCK_FIX)

   In Mgc_home/shared/include/nnet_utils/nnet_activation.h the ac_sync
   overload of nnet::hard_tanh has its "#pragma hls_design block" commented
   out (since at least Catapult 2025.4_1). Catapult then inlines it into the
   top function, which may only connect blocks, and synthesis stops at
   'go assembly' with

       Logic mixed with interconnect in hierarchical function '/<top>' (ASM-62)

   hard_tanh is what QKeras quantized_tanh becomes, so QMlp_Slim and
   QConv1D_Slim are both affected.

   Fix: add a template wrapper hls4ml_hard_tanh_block with
   "#pragma hls_design block" that only calls nnet::hard_tanh, and call it
   instead. The logic is unchanged; hard_tanh just becomes its own block
   like every other layer. Applied only when the installed header lacks the
   pragma (checked in $MGC_HOME), so it does nothing once Siemens fixes it.

Older or custom hls4ml without these bugs (e.g. Catapult 2024.2_2, which has
no ac_sync in io_parallel): the fixes find nothing to change and leave the
files alone. They can also be switched off in install_firmware_fixes.
"""

import os
import re

SYNC_FANOUT_MARKER = 'HLS4ML_SYNC_FANOUT_FIX'
HARD_TANH_MARKER = 'HLS4ML_HARD_TANH_BLOCK_FIX'

FANOUT_FUNCTION = f'''// {SYNC_FANOUT_MARKER}: added by two_bit_optimization_helpers/catapult_firmware_fixes.py.
// hls4ml gives one ac_sync to several consumers, so all but the first would
// read an empty channel. This block reads the token once and writes one per
// consumer.
#pragma hls_design block
void hls4ml_sync_fanout2(ac_sync &sync_in, ac_sync &sync_out0, ac_sync &sync_out1) {{
    sync_in.sync_in();
    sync_out0.sync_out();
    sync_out1.sync_out();
}}

'''

HARD_TANH_FUNCTION = f'''// {HARD_TANH_MARKER}: added by two_bit_optimization_helpers/catapult_firmware_fixes.py.
// The ac_sync overload of nnet::hard_tanh has its "#pragma hls_design block"
// commented out in nnet_activation.h, so Catapult inlined it into the top
// function (ASM-62). This wrapper makes it a block; the logic is unchanged.
#pragma hls_design block
template <class data_T, class res_T, typename CONFIG_T>
void hls4ml_hard_tanh_block(data_T data[CONFIG_T::n_in], ac_sync &sync_data,
                            res_T res[CONFIG_T::n_in], ac_sync &sync_res) {{
    nnet::hard_tanh<data_T, res_T, CONFIG_T>(data, sync_data, res, sync_res);
}}

'''

_ALIAS_RE = re.compile(r'static\s+ac_sync\s*&\s*(\w+)\s*=\s*(\w+)\s*;')
_TOP_PRAGMA = '#pragma hls_design top'


def _find_matching(text, start, open_ch, close_ch):
    """Index of the bracket closing the one at text[start]."""
    depth = 0
    for i in range(start, len(text)):
        if text[i] == open_ch:
            depth += 1
        elif text[i] == close_ch:
            depth -= 1
            if depth == 0:
                return i
    raise ValueError(f'unbalanced {open_ch}{close_ch} at {start}')


def _split_args(args):
    """Split a C++ argument list on top-level commas."""
    out, depth, cur = [], 0, ''
    for ch in args:
        if ch in '<([{':
            depth += 1
        elif ch in '>)]}':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(cur)
            cur = ''
        else:
            cur += ch
    out.append(cur)
    return out


def _layer_call(line):
    """(function name, args_start, args_end, args) of a nnet:: call, or None."""
    m = re.search(r'\bnnet::(\w+)\s*', line)
    if not m:
        return None
    i = m.end()
    if i < len(line) and line[i] == '<':
        i = _find_matching(line, i, '<', '>') + 1
    while i < len(line) and line[i].isspace():
        i += 1
    if i >= len(line) or line[i] != '(':
        return None
    j = _find_matching(line, i, '(', ')')
    return m.group(1), i + 1, j, _split_args(line[i + 1:j])


def _sync_arg_indices(args):
    return [k for k, a in enumerate(args) if a.strip().endswith('_sync')]


def _cpp_path(project_dir, project_name):
    return os.path.join(project_dir, 'firmware', f'{project_name}.cpp')


def _insert_before_top(lines, block, path):
    """Insert the lines of block just before '#pragma hls_design top'."""
    for li, line in enumerate(lines):
        if line.startswith(_TOP_PRAGMA):
            return lines[:li] + block.split('\n') + lines[li:]
    raise RuntimeError(f'"{_TOP_PRAGMA}" not found in {path}')


def fix_sync_fanout(project_dir, project_name, verbose=True):
    """Give every consumer of a shared ac_sync its own handshake.

    Returns a list of (sync, consumers) that were fixed. Safe to call more
    than once: an already fixed file is left alone.
    """
    path = _cpp_path(project_dir, project_name)
    with open(path) as f:
        lines = f.read().split('\n')
    if any(SYNC_FANOUT_MARKER in line for line in lines):
        if verbose:
            print(f'sync fan-out fix: already applied to {path}')
        return []

    alias = {}
    for line in lines:
        m = _ALIAS_RE.search(line)
        if m:
            alias[m.group(1)] = m.group(2)

    def root(name):
        while name in alias:
            name = alias[name]
        return name

    # Layer calls: every ac_sync argument except the last is an input,
    # the last is the layer's own output (hls4ml's argument order).
    # Calls with fewer than two syncs (e.g. trace helpers) are ignored.
    consumers = {}  # root sync -> [(line index, argument index)]
    calls = {}
    for li, line in enumerate(lines):
        call = _layer_call(line)
        if call is None:
            continue
        args = call[3]
        sync_idx = _sync_arg_indices(args)
        if len(sync_idx) < 2:
            continue
        calls[li] = call
        for k in sync_idx[:-1]:
            consumers.setdefault(root(args[k].strip()), []).append((li, k))

    fixed = [(s, uses) for s, uses in consumers.items() if len(uses) > 1]
    if not fixed:
        if verbose:
            print(f'sync fan-out fix: no shared ac_sync in {path}, nothing to do')
        return []

    new_args = {li: list(calls[li][3]) for li in calls}
    inserts = {}  # line index -> lines to insert before it
    for sync, uses in fixed:
        n = len(uses)
        outs = [f'{sync}_fo{i}' for i in range(n)]
        temps = [f'{sync}_fot{i}' for i in range(1, n - 1)]
        indent = re.match(r'\s*', lines[uses[0][0]]).group(0)
        block = [f'{indent}// {SYNC_FANOUT_MARKER}: {sync} has {n} consumers, one handshake each']
        block += [f'{indent}static ac_sync {name};' for name in outs + temps]
        src = sync
        for i in range(n - 1):
            nxt = outs[i + 1] if i == n - 2 else temps[i]
            block.append(f'{indent}hls4ml_sync_fanout2({src}, {outs[i]}, {nxt});')
            src = nxt
        inserts.setdefault(uses[0][0], []).extend(block)
        for (li, k), name in zip(uses, outs):
            lead = re.match(r'\s*', new_args[li][k]).group(0)
            new_args[li][k] = lead + name

    for li, (_, a, b, args) in calls.items():
        if new_args[li] != args:
            lines[li] = lines[li][:a] + ','.join(new_args[li]) + lines[li][b:]

    out = []
    for li, line in enumerate(lines):
        out.extend(inserts.get(li, []))
        out.append(line)
    out = _insert_before_top(out, FANOUT_FUNCTION, path)

    with open(path, 'w') as f:
        f.write('\n'.join(out))
    if verbose:
        for sync, uses in fixed:
            print(f'sync fan-out fix: {sync} had {len(uses)} consumers, gave each its own ac_sync')
    return fixed


def hard_tanh_needs_block_fix(mgc_home=None):
    """True if the installed ac_sync overload of nnet::hard_tanh has no
    active "#pragma hls_design block" (the Catapult 2026.3_1 bug).

    Returns None if nnet_activation.h cannot be found.
    """
    mgc_home = mgc_home or os.environ.get('MGC_HOME')
    if not mgc_home:
        return None
    header = os.path.join(mgc_home, 'shared', 'include', 'nnet_utils', 'nnet_activation.h')
    if not os.path.exists(header):
        return None
    lines = open(header).read().split('\n')
    for i, line in enumerate(lines):
        if re.match(r'\s*void\s+hard_tanh\s*\(', line) and 'ac_sync' in ' '.join(lines[i:i + 3]):
            for prev in reversed(lines[max(0, i - 4):i]):
                if 'hls_design' in prev:
                    return prev.strip().startswith('//')
            return True
    return None


def fix_hard_tanh_block(project_dir, project_name, verbose=True):
    """Call nnet::hard_tanh (ac_sync overload) through a block wrapper.

    Returns the number of calls changed. Safe to call more than once.
    """
    path = _cpp_path(project_dir, project_name)
    with open(path) as f:
        lines = f.read().split('\n')
    if any(HARD_TANH_MARKER in line for line in lines):
        if verbose:
            print(f'hard_tanh block fix: already applied to {path}')
        return 0

    needed = hard_tanh_needs_block_fix()
    if needed is False:
        if verbose:
            print('hard_tanh block fix: not needed, nnet::hard_tanh is already a block in this Catapult')
        return 0
    if needed is None and verbose:
        print('hard_tanh block fix: nnet_activation.h not found under $MGC_HOME, applying anyway')

    n = 0
    for li, line in enumerate(lines):
        call = _layer_call(line)
        if call is None or call[0] != 'hard_tanh' or len(_sync_arg_indices(call[3])) != 2:
            continue
        lines[li] = line.replace('nnet::hard_tanh', 'hls4ml_hard_tanh_block', 1)
        lines[li] += f' // {HARD_TANH_MARKER}: was nnet::hard_tanh'
        n += 1
    if n == 0:
        if verbose:
            print(f'hard_tanh block fix: no hard_tanh layer in {path}, nothing to do')
        return 0

    lines = _insert_before_top(lines, HARD_TANH_FUNCTION, path)
    with open(path, 'w') as f:
        f.write('\n'.join(lines))
    if verbose:
        print(f'hard_tanh block fix: {n} hard_tanh call(s) now go through hls4ml_hard_tanh_block')
    return n


def apply_firmware_fixes(project_dir, project_name, sync_fanout=True, hard_tanh_block=True, verbose=True):
    """Apply the selected fixes to an already written project."""
    if sync_fanout:
        fix_sync_fanout(project_dir, project_name, verbose=verbose)
    if hard_tanh_block:
        fix_hard_tanh_block(project_dir, project_name, verbose=verbose)


def install_firmware_fixes(hls_model, sync_fanout=True, hard_tanh_block=True, verbose=True):
    """Apply the selected fixes after every hls_model.write().

    compile(), trace() and build() call write(), which regenerates the
    project from scratch, so the fixes must follow each write. Calling this
    more than once on the same model is harmless (the first call wins).
    """
    if getattr(hls_model.write, '_firmware_fixes', False):
        if verbose:
            print('firmware fixes: already installed')
        return
    original_write = hls_model.write
    project_dir = hls_model.config.get_output_dir()
    project_name = hls_model.config.get_project_name()

    def write_and_fix(*args, **kwargs):
        result = original_write(*args, **kwargs)
        apply_firmware_fixes(project_dir, project_name, sync_fanout, hard_tanh_block, verbose)
        return result

    write_and_fix._firmware_fixes = True
    hls_model.write = write_and_fix
    if verbose:
        print(f'firmware fixes: installed for {project_name} '
              f'(sync_fanout={sync_fanout}, hard_tanh_block={hard_tanh_block})')
