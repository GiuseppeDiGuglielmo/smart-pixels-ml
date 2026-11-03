# Plan: QMlp, QConv1D and QConv2D Slim area with Catapult 2024.2_2

Goal: train the quantized Slim models (`QMlp_Slim`, `QConv1D_Slim`,
`QConv2D_Slim`) on the ROI dataset and get their HLS area from Catapult
2024.2_2, the release behind the May 2025 slides. Done for all three
(ASIC) on 2026-10-30, see "Where things stand". The whole flow runs in VS Code: notebooks, terminal
and Claude. (Catapult 2026.3_1 was tried first, see "Switch back to
2024.2_2" below.)

This is the current version of the "conv1d model" from the May 8, 2025
slides (0.39 mm^2 HLS area). Its numbers will not match the slide: the
inputs are now 2-bit ROI data instead of 4-bit 13x21 data, and the
precisions are different. See `../SUMMARY.md` for where the slide came
from.

## Status (updated 2026-11-03)

### Where things stand (2026-10-30), start here

Training is finished for the three quantized Slim models on the ROI
dataset (all 1000 + 2000 epochs, seed 42, CPU), each backed up with
checksums and write-protected (see "Things to watch"):

| Model | Fingerprint | Trained | Best val loss part 1 / 2 | Learned thresholds | QKeras test MSE total |
|---|---|---|---|---|---|
| QMlp_Slim | `392456de` | 2026-10-28 | 27.5634 / 26.4647 | `[276.16, 760.13, 1753.39]` | 0.004667 |
| QConv1D_Slim | `3eb13b90` | 2026-10-28 | 32.7620 / 31.4773 | `[255.33, 693.94, 1665.04]` | 0.005676 |
| QConv2D_Slim | `392456de` | 2026-10-30 | 44.2574 / 42.3299 | `[311.84, 890.80, 1832.28]` | 0.007418 |

QConv2D_Slim is clearly the least accurate (x 0.0083, y 0.0033, cotB
0.0106) and has the fewest parameters (1,682). Training speed per epoch:
QMlp 29 s / 10 s, QConv1D 28 s / 10 s, QConv2D 33 s / 17 s (part 1 /
part 2).

Catapult 2024.2_2 results (ASIC, TSMC 28 nm) now exist for all three
models, run from `codesign_catapult.ipynb` on 2026-10-30: see "Results
summary (2026-10-30)" under step 6. Virtex-7 is still the Oct 18 QMlp.
Genus synthesis of the same RTL (2026-11-03) is under "Genus logic
synthesis (2026-11-03)" in step 6. What to copy to another machine is
under "Moving to another machine" in the Reference section.

| Model | Latency / II | Area score | Slack | Test MSE QKeras / hls4ml |
|---|---|---|---|---|
| QMlp_Slim | 2 / 1 | 335,053.2 | 15.72 ns | 0.004668 / 0.004770 |
| QConv1D_Slim | 1 / 1 | 288,141.3 | 16.45 ns | 0.005676 / 0.005688 |
| QConv2D_Slim | 2 / 1 | 606,779.2 | 14.33 ns | 0.007419 / 0.008012 |

Everything from these runs (projects, executed notebooks, parquets,
directives) is in the write-protected backup
`smart-pixels/backups/Catapult_ASIC_QMlp_QConv1D_QConv2D-2026-10-30/`.
Uncommitted at the time of writing: `PLAN.md`, `fully_parallel.tcl`
(`nnet::linear` fix) and `codesign_catapult.ipynb` (`MODEL_TYPE` environment variable, `run_tag`,
`archive_existing`, nothing overwritten).

Next steps, in order (codesign phase):

- [x] `codesign_catapult.ipynb` (ASIC, TSMC 28 nm) rerun for the new
      QMlp_Slim (2026-10-30): same design and area as the Oct 18 model.
- [ ] `codesign_catapult_efpga.ipynb` (Virtex-7) for the new QMlp_Slim
      (`model_type = 'QMlp_Slim'`); its rows are still for the Oct 18
      model. Then delete
      `smart-pixels/backups/QMlp_Slim-392456de-2026-10-18/` (it holds
      the only copy of the old Catapult reports, so only after the
      Virtex-7 rows are updated).
- [x] `codesign_catapult.ipynb` for QConv2D_Slim (2026-10-30): latency
      2, II=1, area 606,779.2, slack 14.33 ns, see "Results summary
      (2026-10-30)". Needed a fix in `fully_parallel.tcl` (the
      `nnet::linear` loop, see below). The cell 53 layer names did not
      matter: the notebook ran top to bottom without changing them.
- [ ] QConv2D_Slim hls4ml vs QKeras: test MSE 0.008012 against 0.007419
      (+8 %; y +22 %, cotB +9 %), no sign flips checked yet. The
      per-layer MSE already starts at `q_dense` (1.7e-4) and ends at
      `q_dense_2` 6.8e-4 (`fixed<10,4>`); look at the dense precisions.
- [ ] Optional, not approved: pruning (post-training 50 percent sparsity
      keeps test MSE 0.005259 for QMlp, 60 percent gives 0.0165), as a
      `prune_sparsity` option in the FPGA notebook, then fine-tuning;
      the Virtex-7 design is about 5x too large for the target array.
- [ ] Optional: validation set equals the test set in the training code
      (test MSE slightly optimistic); input registers (inputs are not
      registered, outputs are).
- [x] Genus logic synthesis of the three Catapult RTLs, slow and
      typical corner (2026-11-03): see "Genus logic synthesis
      (2026-11-03)" under step 6. Slow-corner area is 3.5 to 8.2 %
      above the Catapult area, all meet 25 ns.
- [ ] Check the Genus netlists against the RTL (gate-level simulation
      with the cocotb testbenches in the VIAS repository, or Conformal
      equivalence) before quoting power.
- [ ] Optional: fixed-weight versions (weight and bias ports tied to the
      trained values) for a realistic area.

Facts for the codesign work: ROI finder input is 48x192x2x2 = 36,864
bits, its output is a 16x16x2x2 = 1,024-bit window plus 14-bit
coordinates; the NN takes 512 values x 2 bits = 1,024 bits. Weights
(bits): QMlp 2,096 x 8 = 16,768 plus 83 biases; QConv1D 2,604 weights
= 20,592 bits plus 45 biases. Catapult needs the VPN for the license
(`lmutil lmstat -c $LM_LICENSE_FILE -f CatapultUltra_c`). Headless
notebook run, one model at a time (2026-10-30): `source envsetup.sh`, then
from the repo root `MODEL_TYPE=<M> ~/catapult_venvs/2024.2_2/bin/python -m
jupyter nbconvert --to notebook --execute --ExecutePreprocessor.kernel_name=catapult-2024.2_2
--ExecutePreprocessor.timeout=-1 --output-dir codesign_runs --output
codesign_catapult_<M> codesign_catapult.ipynb`. `MODEL_TYPE` (cell 7)
overrides `model_type`, so there is one notebook and no copy; without
`--inplace` the executed notebook goes to `codesign_runs/` (gitignored)
and `codesign_catapult.ipynb` stays clean. Not tried yet: the 2026-10-30
runs used per-model copies (since deleted, they are in the backup).
Run it in the background and read
`<project>/catapult.log` (the notebook output only appears at the end).
Times: QMlp 6 min, QConv1D 12 min, QConv2D 1 h 46 min (about 12 min of
Python before Catapult starts); the notebook kernel uses about 35 GB of
RAM. Check the license first (VPN). Rerunning a model renames its old
project instead of deleting it (about 1.3 to 2 GB each).

### Switch back to 2024.2_2 (2026-10-19)

Training and codesign now use Catapult 2024.2_2 and its venv
`~/catapult_venvs/2024.2_2` (kernel "Catapult 2024.2_2", default of
`envsetup.sh`). Reasons:

- 2026.3_1 needed 10 workarounds (see "Changes made for Catapult
  2026.3_1") and still produced a different design. QMlp_Slim (scratch
  copy, 2026-10-18, all workarounds plus `[DirectInput]`): area score
  80,911, latency 2338 cycles (58.5 us), throughput 581 cycles. Every
  layer is sequential (pooling 576 cycles, dense 129 to 512 cycles),
  although `Strategy: Latency` and `ReuseFactor: 1`.
- The slide design was fully parallel: `SmtPxl.v1` latency 2 cycles,
  throughput 1 cycle, total area 398,576.93 (`../SUMMARY.md`).
- 2024.2_2 has none of the 2026.3_1 bugs (no `ac_sync` between
  io_parallel layers, `keras_to_hls()` exists, ReLU needs no
  `activ_param`).

The 2026.3_1 notebook changes are disabled (raw cells or comments) and
kept for reference. Checked 2026-10-19 with the 2024.2_2 venv: the
training helpers import, the 2026-10-18 QMlp_Slim loads (no retraining
needed: same TF 2.15.0.post1, Keras 2.15.0, QKeras 0.9.0, numpy, h5py;
only tfp 0.22.0 vs 0.23.0), and the notebook's conversion, `compile()`,
`predict()` and `trace()` run; hls4ml matches QKeras on 20,000 events
(correlation >= 0.999, mean difference about 0.009).

Done:

- [x] Catapult 2026.3_1 installed in `/extras2/tools/Siemens/catapult/2026.3_1`.
- [x] `Mgc_home/bin/create_catapult_py_venv.sh` patched (original kept
      as `.BKP`). The shipped script calls `pkgs/cds_python3/bin/python3`,
      which does not exist, and `Mgc_home/bin/python3` needs
      `libffi.so.6`, which Ubuntu does not have. The patch uses
      `pkgs/cds_undodb/private/gdb/install/x64/bin/python3` (3.10.18).
- [x] Venv rebuilt at `~/catapult_venvs/2026.3_1`, which `~/ccs_venv`
      links to, plus `tensorflow-probability==0.23.0 natsort pyarrow`.
      TF 2.15.0, hls4ml from Catapult, and the RTX A2000 GPU is visible
      (but the notebooks turn it off, see "Things to watch").
- [x] License: `1717@fasic-135413.fnal.gov` serves `CatapultUltra_c` and
      `CatAIhls4ml_c` (5 each). It needs the VPN: on 2026-10-18 it was
      unreachable until the VPN and the `1717@localhost` tunnel from
      `~/bin/siemens.sh` were turned on; both then worked.
- [x] Commits on `2bit_optimization-gdg` (not pushed):
  - `76767a5` Point codesign notebook at ROI models
  - `9e18bf3` Check npy files exist before loading
  - `bcb1a5d` Point notebooks at moved ROI dataset (VIAS moved to
    `VIAS/fermi_roi_finder/.../roi_finder/sim_out/`)

Remaining: steps 1 to 6 below.

Order (decided 2026-10-17): run steps 2 to 6 for `QMlp_Slim` first,
retrained from scratch, then repeat them for `QConv1D_Slim`. Retraining
reuses fingerprint `392456de` and overwrites the old QMlp_Slim model,
so it was backed up first (412 files, checksums verified) to
`smart-pixels/backups/QMlp_Slim-392456de-2026-08-03/` (gitignored). That
backup (200 + 200 epochs from 2026-08-03, test MSE total 0.005082,
thresholds `[278.33, 767.71, 1784.56]`) was deleted on 2026-10-30,
superseded by the full 1000 + 2000 runs.

QMlp_Slim progress:

- [x] Step 2, test run (2026-10-17): no errors, fingerprint `392456de`,
      val loss 81.4 after 2 epochs. Its `runs.csv` row was removed.
- [x] Step 3, full run (2026-10-18, 1000 + 2000 epochs, CPU, about
      13.5 h): best val loss 27.54 (part 1) and 26.49 at epoch 1882
      (part 2), against 30.40 and 28.98 for the old 200 + 200 run. Test
      MSE total 0.004649 (old 0.005082). Logged to `runs.csv`.
      Full comparison: `TRAINING_LENGTH_RESULT.md`.
      2026-10-19: an accidental Run All of `two_bit_optimization.ipynb`
      wiped the part 1 checkpoints (`...-soft_quantize_layer-392456de-
      checkpoints/`, 1000 epochs) and was stopped after 11 epochs; that
      partial folder was deleted. Part 2 (the model used for codesign,
      `...-2bit_optimized-392456de-checkpoints/`) and the `npy` files are
      intact. The learned thresholds are in `runs.csv`
      (`[277.35, 756.02, 1774.84]`). To get part 1 back: retrain it
      (1000 epochs, about 8 h). Do not run part 2 with `skip_part_1=True`
      until then.
- [x] Step 4 with 2024.2_2 (2026-10-19): all 46 code cells ran, no
      errors, no 2026.3_1 workarounds. hls4ml predicted all 255,409 test
      events. Per-layer MSE vs QKeras: pooling 0.0, then rising to
      1.2e-4 at `dense_3` (fixed-point rounding; the model's own test
      MSE is about 0.005). `build_prj.tcl` gets the TSMC library path
      through `asiclibspath`.
- [x] Steps 5 and 6 with 2024.2_2 (done, see below). Expect a parallel design like the
      slide (latency of a few cycles, throughput 1 cycle).
      First attempt (2026-10-19, `catapult -shell`, `Synth = True`, no
      loop directives): sequential design, `allocate` ran 8.6 h without
      finishing (estimate latency 1016, area 57,055). On 2026-10-26 the
      notebook was changed to `Synth = False` so the project is opened in
      the GUI and the loop directives are set by hand (step 5).
- [x] Step 5, QMlp_Slim with 2024.2_2 (2026-10-26, GUI, directives by
      hand): latency 2 cycles (50 ns), throughput 1 cycle (25 ns),
      total area score 335,053.2 post-assignment (about 0.34 mm^2),
      critical path 9.28 ns, slack 15.72 ns. allocate took 30 s. Same
      architecture as the slide's conv1d design (latency 2, throughput
      1, area 398,576.93), but a different model and dataset, so the
      area is not a like-for-like comparison. Results in "QMlp_Slim
      Catapult results" below.

## 1. Environment for VS Code

VS Code does not run `envsetup.sh`. A notebook kernel started from
`~/ccs_venv` directly has no `MGC_HOME`, no `PYTHONPATH` to Catapult's
hls4ml, and no license variables. The existing kernel
`~/.local/share/jupyter/kernels/ccs_venv/kernel.json` does exactly that.

- [x] Fix the typo in `envsetup.sh` (gitignored, local only):
      `SALT_LICENSE_SERVER=$LM_LICENS` should be
      `SALT_LICENSE_SERVER=$LM_LICENSE_FILE`. Done 2026-10-17.
- [x] Add a kernel that sets up the environment first, following the
      existing Vitis kernel. Created 2026-10-17 (outside the repo; the
      old `ccs_venv` kernel is unchanged) at
      `~/.local/share/jupyter/kernels/catapult-2026.3_1/kernel.json`.
      To remove it: `jupyter kernelspec remove catapult-2026.3_1`.
      Contents:

  ```json
  {
   "argv": [
    "/bin/bash",
    "-c",
    "source /extras2/home/gdg/research/projects/smartpixels/davidgjiang-smart-pixels-ml/envsetup.sh >/dev/null 2>&1 && exec python -m ipykernel_launcher -f \"$0\"",
    "{connection_file}"
   ],
   "display_name": "Catapult 2026.3_1 (ccs_venv)",
   "language": "python",
   "metadata": {"debugger": true}
  }
  ```

- [x] In VS Code, pick "Catapult 2026.3_1 (ccs_venv)" as the kernel for
      both notebooks ("Select Kernel" > "Jupyter Kernel..."). If it is
      not listed, run "Developer: Reload Window" first.
- [x] Check it from a notebook cell (passed 2026-10-17):

  ```python
  import os, hls4ml, tensorflow as tf
  print(os.environ.get("MGC_HOME"), hls4ml.__file__)
  print(os.environ.get("LM_LICENSE_FILE"), os.environ.get("SALT_LICENSE_SERVER"))
  print(tf.config.list_physical_devices("GPU"))
  ```

  Expect `MGC_HOME` under `.../catapult/2026.3_1/Mgc_home`, hls4ml under
  `.../ccs_hls4ml/hls4ml/`, the license set to `1717@fasic-135413.fnal.gov`,
  and one GPU.

- [ ] For the VS Code terminal (needed for Catapult in step 5), run
      `source envsetup.sh` in each new terminal.

### Catapult release selection (2026-10-19)

- `envsetup.sh` sets `CATAPULT_VER` (default `2024.2_2`) before
  `source ~/bin/siemens.sh`, which reads it, and puts
  `~/catapult_venvs/$CATAPULT_VER/bin` first in `PATH`. For another
  release: `CATAPULT_VER=2026.3_1 source envsetup.sh`.
- It sets `VIRTUAL_ENV` and `PATH` itself instead of sourcing
  `bin/activate`: the 2024.2_2 venv was created as `~/ccs_venv`, so its
  `activate` (and the shebangs of `pip`, `jupyter`, ...) still point at
  `~/ccs_venv`, which now links to 2026.3_1. Use `python -m pip` in that
  venv, not `pip`.
- Kernels: "Catapult 2024.2_2"
  (`~/.local/share/jupyter/kernels/catapult-2024.2_2/kernel.json`) and
  "Catapult 2026.3_1" (`catapult-2026.3_1`). Both run
  `export CATAPULT_VER=<release> && source envsetup.sh` before Python.
  `codesign_catapult.ipynb` is saved with the 2024.2_2 kernel.
- hls4ml comes from the install (`$MGC_HOME/shared/pkgs/ccs_hls4ml/hls4ml`,
  through `PYTHONPATH`). The 2024.2_2 venv also has an editable hls4ml
  (`0.9.0.dev105`, pointing at
  `~/research/projects/transformers/hls4ml-support/hls4ml-dgburnette-merging-features`);
  `PYTHONPATH` takes precedence, so it is not used. Check with
  `hls4ml.__file__`.
- `.vscode/settings.json` still points the editor's Python at
  `~/ccs_venv` (2026.3_1). That only affects code completion.

`.vscode/settings.json` (untracked) already points the Python
interpreter at `~/ccs_venv` and adds `two_bit_optimization_helpers` to
the analysis path.

## 2. Short test run of training

Done for all three models (2026-10-17 to 2026-10-30); kept for a new model.

`two_bit_optimization.ipynb`, Parameters cell (cell 8):

- [x] `model_type='QConv1D_Slim'`
- [x] Keep `use_roi=True`, `use_roi_labels=True`, `roi_dataset='2s'`,
      `tfrecords_exist_2s_roi=True`. The TFRecords are already in
      `.../sim_out/dataset_2s_48x192_50x12P5_parquets/TFR_files/2t/`.
- [x] Temporarily set `epochs1=2`, `epochs2=2`.
- [x] Restart the kernel and run all cells. The notebook only works when
      run top to bottom (see the README).

This catches path, package and shape errors in minutes. Afterwards,
delete the row the test run added to `runs.csv`.

## 3. Full training

Done for all three models (1000 + 2000 epochs, see the table at the top; the steps below say 200 + 200, the first plan). Training now needs `chmod` first, see "Things to watch".

- [x] Set `epochs1=200`, `epochs2=200`, then restart and run all.
- [x] Note `fingerprint2` from the output (it is also in the new
      `runs.csv` row).

Outputs:

- `smart-pixels/weights/dataset_2s_roi_weights/weights-2t-QConv1D_Slim-2bit_optimized-<fingerprint>-checkpoints/`
- `npy/2t-QConv1D_Slim-<fingerprint>-{X,y}_test.npy`
- a new row in `runs.csv`

The fingerprint comes from `random.randrange` after seeding
(`seed=42`), so it is the same on every run of a given model: all
seven Mlp runs in `runs.csv` got `392456de`. The test run from step 2
therefore writes to the same checkpoint directory and `npy` files as
the full run, and the full run replaces them.

## 4. Generate the HLS project

Done for all three models (2026-10-30), through `codesign_catapult.ipynb` run top to bottom.

`codesign_catapult.ipynb`:

- [x] `model_type = 'QConv1D_Slim'` (cell 7).
- [x] If `fingerprint2` is not `3eb13b90`, update `'QConv1D_Slim'` in
      `fingerprint_choices` (cell 18). The cell prints which models it
      finds and stops if the selected one is missing.
- [x] Run up to and including "Model synthesis". The precision overrides
      for `QConv1D_Slim` are already in the "Bit-precision" cell:
      input `ufixed<2,2>`, pooling `fixed<16,8>`, `dense_3` `fixed<10,2>`.
- [x] Check the QKeras vs hls4ml comparison (per-layer MSE, parity
      plots) before spending time on synthesis.

This writes `SmtPxl_QConv1D_Slim_io_parallel_Latency_pw_hls4ml_prj/`.
Clock: 25 ns. Library: TSMC 28 nm
(`/home/giuseppe/research/projects/smartpixels/tsmc28nm_lib`).

## 5. Run Catapult

Done by hand in the Catapult GUI, as for the May 2025 slide.
`codesign_catapult.ipynb` sets `Synth = False` in `create_config`
(2026-10-26, as in the slide commit d564843), so `build_prj.tcl` stops
after `go compile` plus the library and clock setup. The notebook does
not run Catapult itself (the `build()` cell is raw).

In a terminal (VPN on for the license):

```bash
cd SmtPxl_QConv1D_Slim_io_parallel_Latency_pw_hls4ml_prj
source ../envsetup.sh        # default 2024.2_2
catapult -f build_prj.tcl    # GUI, no -shell
```

- [x] In the GUI: pipeline the top/main loop with II=1, unroll all the
      other loops, then synthesize (QMlp_Slim, 2026-10-26).
- [x] Write down every directive set in the GUI (QMlp_Slim: listed in
      "QMlp_Slim Catapult results" below, saved in
      `catapult_directives/QMlp_Slim.tcl`).
- [x] Same for QConv1D_Slim (batch flow, below), and QConv2D_Slim.
      Smoke test 2026-10-27 with a 2 + 2 epoch model (fingerprint
      `3eb13b90`), batch flow, no GUI: `fully_parallel.tcl` mapped 19
      arrays, unrolled 49 loops; synthesis 9 min 7 s. Latency 1 cycle,
      throughput 1 cycle (II=1), total area score 288,073.2
      (post-assignment), register area 60.6, critical path 8.38 ns,
      slack 16.62 ns. Per-layer MSE vs QKeras 0 up to activation_tanh_2,
      1.1e-5 at dense_3. The slide's conv1d had latency 2 and area
      398,576.93, but different inputs (13x21x2, 14 outputs). Full
      training (1000 + 2000) started 2026-10-27; rerun codesign on it.
      Trained model (2026-10-28, batch flow, synthesis 18 min with the
      QMlp_Slim retraining on the CPU): same design as the smoke test
      (programmable weights, so the area does not depend on the weight
      values): latency 1, II=1, area 288,073.2, slack 16.62 ns. But
      `dense_3` (`fixed<10,2>`, range -2 to 2) overflows: QKeras gives
      y up to 2.224 and cotB down to -2.387, and ac_fixed wraps, so 36
      (y) and 9 (cotB) of 255,409 events change sign. hls4ml test MSE
      total 0.006616 against 0.005676 for QKeras (y +80 %); without those
      45 events hls4ml matches QKeras. Fixed the same day: `dense_3` to
      `fixed<11,3>` (same 8 fractional bits, range -4 to 4) in both
      codesign notebooks. Rerun (synthesis 18 min 25 s): latency 1,
      II=1, area 288,141.3 (+68.1, +0.02 %), register area 66.4, slack
      16.45 ns; no sign flips, per-layer MSE vs QKeras 9.7e-6 at
      `dense_3`, hls4ml test MSE total 0.005688 (QKeras 0.005676). See
      "Results summary" under step 6.

### Batch flow, no GUI (2026-10-27)

`codesign_catapult.ipynb` now runs top to bottom, synthesis included
(`run_catapult_synthesis = True` in the "Configure hls4ml model" cell):

1. `catapult_directives/fully_parallel.tcl`: the GUI directives without
   layer names. After `go assembly` it finds, with
   `directive get ... -match glob`, every `:rsc` array of the process
   (to `[Register]`), the main loop (II=1) and every loop below it, at
   any depth (`UNROLL yes`). For QMlp_Slim: 21 arrays, 39 loops (the 27
   set in the GUI plus the 12 `ResetAccum`/`Result` loops).
2. `two_bit_optimization_helpers/catapult_flow.py`:
   `add_directives_to_build_script()` adds `source .../fully_parallel.tcl`
   after `go assembly` in the generated `build_prj.tcl` (marker
   `HLS4ML_FULLY_PARALLEL_DIRECTIVES`), then the notebook calls
   `build(Synth=True)`. `create_config` keeps `Synth = False`, so the GUI
   flow still works.
3. `read_rtl_summary()` / `print_rtl_summary()` read the totals from
   `rtl.rpt`. `nnet_layer_results.txt` (`parse_catapult_report`, `qofr`)
   has empty tables for io_parallel: every `nnet::` function is inlined
   into one block, so there are no layer blocks, and with `_pw` no ROM
   constants.

Checked on a copy of the QMlp_Slim project, run the way `build()` runs
it (`catapult -product ultra -shell -f build_prj.tcl`): same result as
the GUI run (latency 2, throughput 1, area 335,053.2, slack 15.72 ns),
synthesis 3 min 55 s.

### QMlp_Slim Catapult results (2026-10-26)

Catapult 2024.2_2, solution `SmtPxl_QMlp_Slim.v1`, 25 ns clock, TSMC
28nm `tcbn28hpcplusbwp30p140ssg0p81v125c_ccs_dc`, model fingerprint
`392456de` (1000 + 2000 epochs), io_parallel, Latency, `_pw`.

| | QMlp_Slim (this run) | Slide `SmtPxl.v1` (conv1d, May 2025) |
|---|---|---|
| Latency | 2 cycles (50 ns) | 2 cycles (50 ns) |
| Throughput | 1 cycle (25 ns) | 1 cycle (25 ns) |
| Total area score | 335,053.2 (post-assignment) | 398,576.93 |
| Area, post-scheduling | 339,828.9 | |
| Registers | 3,089.0 (1 %) | |
| Critical path / slack | 9.28 ns / 15.72 ns | slack 13.28 |
| Real operations | 5,996 | |

Datapath is almost all multipliers (FUNC 99 %): 512 x mgc_mul(8,1,13,..)
and 560 x mgc_mul(8,1,8,..) after assignment.

Directives set in the GUI, after `go assembly` (from `catapult.log`):

- `-MAP_TO_MODULE {[Register]}` on every `layerN_out:rsc` (layers 2,
  3, 6, 8, 10-13, 15, 17, 19, 20, 22), the two `pooling2d_cl ... :pool:rsc`
  and the six `dense_latency ... :acc:rsc`.
- `/SmtPxl_QMlp_Slim/core/main -PIPELINE_INIT_INTERVAL 1`.
- `-UNROLL yes` on all other loops: pooling2d_cl and avg loops,
  `Compute`, `MultAndAccum` (#0-#5), relu, concatenate1d and hard_tanh
  loops.

Saved 2026-10-26 in `catapult_directives/` (the notebook's "Remove
existing project" cell deletes the project folder):
`QMlp_Slim.tcl` holds the 49 hand-set directives with a header on how
to reuse them; `QMlp_Slim_full_directives.tcl` is the solution's whole
`directives.tcl`, with only Catapult's banner removed.

The old notebook instructions said `built_prj.tcl` (typo, fixed
2026-10-26) and to edit `Synth False` by hand (no longer needed).

### Side study: QMlp_Slim on Virtex-7 (2026-10-27)

`codesign_catapult_efpga.ipynb`, a copy of `codesign_catapult.ipynb`:
`QMlp_Slim`, Catapult 2024.2_2, `tech = "fpga"`, part
`xc7vx485tffg1157-1` (Catapult maps it to `mgc_Xilinx-VIRTEX-7-1_beh`,
checked in `catapult -shell`), hardcoded weights
(`programmable_weights = False`), 25 ns clock, same batch flow and
`fully_parallel.tcl`. Project folder
`SmtPxl_QMlp_Slim_io_parallel_Latency_efpga_hls4ml_prj`;
the files it writes to the repo root carry a `run_tag` suffix. Its
"Remove existing project" cell uses no wildcard and deletes the folder
only if its `hls4ml_config.yml` says `Technology: fpga`, the same part
and not `BramFactor: 0` (programmable weights). A dry
run (conversion and `write()` only) gave `setup_xilinx_part
{xc7vx485tffg1157-1}` in `build_prj.tcl` and a top function with only
the input and output ports.

- [x] Run it top to bottom (VPN on) and record latency, throughput and
      area. The area is Catapult's estimate; LUT/FF/DSP counts need
      Vivado (`RTLSynth`).
      Baseline (2026-10-27, pooling `fixed<16,8>`, kept as
      `SmtPxl_QMlp_Slim_io_parallel_Latency_efpga_pool16_8_hls4ml_prj`):
      latency 5 cycles, II=1, area score 265,913.0, slack 3.43 ns.
      The design is about 5x too large for the target array.
- [x] Pooling output narrowed to `ufixed<6,2>` (2026-10-27; lossless,
      the outputs are k/16 with k in 0..48): per-layer MSE 0 at pooling,
      1.2e-4 at `dense_3`, as before. Area score 266,031.0, latency 5,
      II=1, slack 3.51 ns, so no gain: Catapult had already removed the
      constant bits of the `fixed<16,8>` pooling output. Its
      `concat_rtl.v` is `fasic-beast1:~/QMlp_Slim.v` (the baseline RTL
      that was there before is only in the folder above).
      The 5x has to come from retraining (fewer weight or ReLU bits,
      more pruning), a smaller architecture, or `ReuseFactor` > 1.

## 6. Keep the results

The Catapult number on the May 2025 slide was never saved, and a
license error was all that remained in the notebook. Do not repeat that.

- [x] In `codesign_catapult.ipynb`, change the two "Results" cells
      (`parse_catapult_report`, `qofr`) from raw to code and run them.
      Done 2026-10-27, plus a `read_rtl_summary` cell. QMlp_Slim: the
      notebook ran top to bottom with the batch flow (synthesis 3 min
      58 s), no errors, same result as the GUI run (latency 2,
      throughput 1, area 335,053.2, slack 15.72 ns) and the same
      per-layer MSE as on 2026-10-19 (1.2e-4 at `dense_3`).
- [x] Record area, latency and throughput, both in the notebook output
      and somewhere plain-text (for example a results section here or in
      `../SUMMARY.md`).
- [x] Commit the notebooks with outputs, and `runs.csv` (2026-10-30).

### Results summary (2026-10-28)

Catapult 2024.2_2, io_parallel, Latency strategy, 25 ns clock, batch
flow with `fully_parallel.tcl`. Area is the post-assignment total area
score from `rtl.rpt`: um^2 for the TSMC 28 nm library (288,141.3 is
about 0.29 mm^2), Catapult's own units for the FPGA (not comparable). Test
MSE is the mean over x, y, cotB of the MSE against the labels, on the
255,409 test events, as in `runs.csv`.

| Model (fingerprint, training) | Target, weights | Latency / II | Area score | Slack | Test MSE QKeras / hls4ml |
|---|---|---|---|---|---|
| QMlp_Slim (`392456de`, 1000 + 2000, 2026-10-18) | TSMC 28 nm, programmable | 2 / 1 | 335,053.2 | 15.72 ns | 0.004649 / 0.004770 |
| QMlp_Slim (same), pooling `fixed<16,8>` | Virtex-7 xc7vx485tffg1157-1, hardcoded | 5 / 1 | 265,913.0 | 3.43 ns | 0.004649 / 0.004770 |
| QMlp_Slim (same), pooling `ufixed<6,2>` | Virtex-7 xc7vx485tffg1157-1, hardcoded | 5 / 1 | 266,031.0 | 3.51 ns | 0.004649 / 0.004770 |
| QConv1D_Slim (`3eb13b90`, 1000 + 2000, 2026-10-28), `dense_3` `fixed<11,3>` | TSMC 28 nm, programmable | 1 / 1 | 288,141.3 | 16.45 ns | 0.005676 / 0.005688 |
| Slide `SmtPxl.v1` (conv1d, May 2025) | TSMC 28 nm | 2 / 1 | 398,576.93 | 13.28 ns | n/a (other model and data) |
| QMlp_Slim (`392456de`, retrain 2026-10-28) | TSMC 28 nm, programmable | 2 / 1 | 335,053.2 | 15.72 ns | 0.004668 / 0.004770 |
| QConv2D_Slim (`392456de`, 2026-10-30) | TSMC 28 nm, programmable | 2 / 1 | 606,779.2 | 14.33 ns | 0.007419 / 0.008012 |

### Results summary (2026-10-30)

All three models run from `codesign_catapult.ipynb` (one executed copy
per model, run on copies of the notebook; their executed notebooks are in the backup), Catapult
2024.2_2, 25 ns clock, TSMC 28 nm, programmable weights, batch flow with
`fully_parallel.tcl`. Area is the post-assignment total area score
(`rtl.rpt`). Test MSE is the mean over x, y, cotB on the 255,409 test
events, computed from the `-vars` (QKeras) and `-hls4ml-vars` parquets.

| Model | Latency / II | Area score | Register area | Slack | Real ops | Test MSE QKeras / hls4ml | Max per-layer MSE vs QKeras |
|---|---|---|---|---|---|---|---|
| QMlp_Slim | 2 / 1 | 335,053.2 | 3,089.0 | 15.72 ns | 5,996 | 0.004668 / 0.004770 | 1.2e-4 (`dense_3`) |
| QConv1D_Slim | 1 / 1 | 288,141.3 | 66.4 | 16.45 ns | 9,644 | 0.005676 / 0.005688 | 9.7e-6 (`dense_3`) |
| QConv2D_Slim | 2 / 1 | 606,779.2 | 1,351.0 | 14.33 ns | 37,052 | 0.007419 / 0.008012 | 6.8e-4 (`q_dense_2`) |

QMlp_Slim and QConv1D_Slim give exactly the earlier area and timing:
the weights are programmable, so the area does not depend on the
trained values (the Oct 18 and Oct 28 QMlp models have the same
numbers). QConv2D_Slim is about twice the area of QConv1D_Slim and the
least accurate. Its Catapult run took 1 h 46 min (`allocate` 49 min,
`instance` 34 min); QMlp 4 min, QConv1D 12 min with the notebook.

QConv2D_Slim, `nnet::linear` (`q_activation_2`): its loop has
`#pragma hls_pipeline_init_interval 1` in `nnet_activation.h`.
`fully_parallel.tcl` set `-UNROLL yes` on it, and `go architect` failed
with LOOP-21 "Cannot pipeline a fully unrolled loop" (first attempt,
8 min). Skipping that loop gave a rolled, pipelined loop of 80
iterations inside `main`: latency 81 (second attempt, stopped after
`allocate`). The directives set by hand in the GUI had
`-PIPELINE_INIT_INTERVAL 0` and then `-UNROLL yes` on it: latency 2,
II=1, and the script now does the same (rerun 2026-10-30: identical to
the GUI run, 606,779.2, slack 14.33 ns, 37,052 real operations). The
GUI run set no register mapping for the arrays; the script maps 22 to
registers, with the same area.

Nothing is overwritten any more (2026-10-30): `codesign_catapult.ipynb`
renames the previous project to `..._<mtime>_hls4ml_prj` and the old
`-hls4ml-vars.parquet` to `...-vars-<mtime>.parquet` instead of deleting
them, and tags the files in the repo root with the model (`run_tag`).
Archived projects: QMlp 20261027-083144, QConv1D 20261028-110630, and
for QConv2D 20261030-112151 (LOOP-21 failure) and 20261030-161837 (the
GUI run, `SmtPxl_QConv2D_Slim_prj_1`, and the latency 81 solution).
They are about 1.3 GB each and can be deleted when no longer needed.

Backup (2026-10-30, 9.8 GB, write-protected, checksums verified):
`smart-pixels/backups/Catapult_ASIC_QMlp_QConv1D_QConv2D-2026-10-30/`.
It holds the three full Catapult projects, the GUI run of QConv2D_Slim,
the executed per-model notebooks, `catapult_directives/`, the `-vars` and
`-hls4ml-vars` parquets and the tagged files of the repo root. The README
there has the contents and the restore steps. The run script overwrites
the executed notebooks and the tagged root files on a rerun;
the copies in the backup do not change.

The QMlp_Slim rows above for 2026-10-18 and the Virtex-7 rows are for
the model trained 2026-10-18 (backed up in
`smart-pixels/backups/QMlp_Slim-392456de-2026-10-18/`, with the
reports). QMlp_Slim was retrained 2026-10-28 (part 1 best val 27.5634,
part 2 best val 26.4647, QKeras test MSE 0.004667; backed up 2026-10-29);
the ASIC row was rerun on the new model (see the next summary), the
Virtex-7 rows were not. Results files:
`smart-pixels-ml/processed_parquets/dataset_2s_roi/test_dataset_2s_48x192_50x12P5_roi/2bit_optimized/`
(`-vars` QKeras, `-hls4ml-vars` ASIC, `-hls4ml-xc7vx485tffg1157-1-vars`
Virtex-7).

### Genus logic synthesis (2026-11-03)

The Catapult RTL of the three models (2026-10-30 runs) is synthesized
with Cadence Genus 23.1 in the VIAS repository, not here:
`fasic-beast1.fnal.gov:/fasic_home/gdg/research/projects/VIAS/VIAS_VC9_VIRTEX_2025`
(RTL in `hls/rtl/`, flow in `impl/syn/`, results also in
`impl/README.md`). Medium effort, 8 CPUs (one Genus_Synthesis license,
so one run at a time), 25 ns clock, 2 ns input and output delays,
`BUFFD1BWP30P140` driving cell, 0.02 pF load, weights as input ports.

Slow corner `ssg0p81v125c` (Catapult's corner, the one to report):

| Model | Slack HLS / Syn | HLS area | Syn cell area | Syn vs HLS | Run time |
|---|---|---|---|---|---|
| QMlp_Slim | 15.72 / 9.53 ns | 335,053.2 | 357,527.3 | +6.7 % | 7 h 37 min |
| QConv1D_Slim | 16.45 / 8.22 ns | 288,141.3 | 311,658.6 | +8.2 % | 7 h 17 min |
| QConv2D_Slim | 14.33 / 7.90 ns | 606,779.2 | 628,048.1 | +3.5 % | 13 h 15 min |

Typical corner `tt0p9v25c`, for power (Genus default activity, so
indicative only): QMlp_Slim 360,229 um^2, 11.18 ns, 23.0 mW (leakage
1.23); QConv1D_Slim 304,226, 10.52 ns, 19.6 mW (1.07); QConv2D_Slim
627,275, 11.72 ns, 36.7 mW (2.23). At the slow corner leakage is about
half the total (125 C), so slow-corner power is not quoted.

Synthesis slack is lower than Catapult's because Catapult does not model
the IO delays, driving cell and load. High effort was dropped: medium
already leaves 8 ns or more of slack. QConv2D_Slim needs
`AUTO_PARTITION=true` (now the Makefile default for it), otherwise its
core maps on a single worker. Run times are dominated by that one large
core chunk.

Working on the VIAS repository (state 2026-11-03):

- Git: `main` pushed to
  `git@github.com:Fermilab-Microelectronics/VIAS_VC9_VIRTEX_2025.git`
  (HEAD `41be6bd`). Use `scl enable rh-git218 "git ..."` on fasic-beast1
  (the default git is too old). Git LFS is disabled on that GitHub
  repository, so the RTL is stored as normal files; do not add LFS
  again. The pre-rewrite history (when the RTL was in LFS) is backed up
  read-only in
  `/fasic_home/gdg/research/projects/VIAS/backups/VIAS_VC9_VIRTEX_2025-pre-lfs-drop-20261103/`;
  delete it when no longer needed.
- Access: from this machine, `kinit gdg@FNAL.GOV` (the ticket lasts
  about a day) and the VPN ("No route to host" means the VPN is down).
- Run: `cd impl/syn; make syn-genus IMPLEMENTATION=<model>` (defaults:
  slow corner, medium effort, AUTO_PARTITION true only for QConv2D_Slim;
  `make syn-help`). Needs `LM_LICENSE_FILE=1717@fasic-admin1.fnal.gov:5280@fasic-admin1.fnal.gov:26745@fasic-admin1.fnal.gov:27001@fasic-admin1.fnal.gov:27000@fasic-admin1.fnal.gov`
  and `CDS_SKIP_OS_CHECK_ON_STARTUP=1`. Launch detached
  (`setsid nohup ... &`, then `ssh -n` with `timeout`), one run at a
  time: there is a single Genus_Synthesis license, and 8 CPUs is the
  most one license allows. Expect 7 to 13 h per model.
- Never edit `syn_genus.tcl`, the Makefile or a running queue script in
  place while a run is alive: Genus and bash read them incrementally,
  and an in-place edit killed a 13 h run. Write a new file and `mv` it
  over. Do not `pkill -f`; kill by PID only.
- Run folders (not in git, about 1.1 GB) in `impl/syn`:
  `genus_SmtPxl_<model>_v0_<corner>_medium_<timestamp>/` for the six
  runs above (three models, ssg and tt). The ssg ones are the reference.
- Another agent works in the same checkout on cocotb testbenches and
  ROI finder sources (untracked `src/roi_nn/`, `vrf/COCOTB/...`,
  `CLAUDE.md`, `cocotb_venv/`); leave its files alone, and gitignore
  `CLAUDE.md` and `cocotb_venv/` once it is done.

Next steps for the synthesized designs, in order: check the netlists
against the RTL (gate-level simulation with the cocotb testbenches and
the TSMC cell Verilog models, or Conformal equivalence if licensed);
fixed-weight versions (weight and bias ports tied to the trained values)
for a realistic area; typical-corner power on the ssg netlists (load
the netlist with the tt library, minutes per model, needs the Genus
license). Not needed now: high effort, fast corner or hold, place and
route.

## Things to watch

- QConv1D_Slim full training (1000 + 2000 epochs, fingerprint
  `3eb13b90`, ended 2026-10-28 02:02, test MSE total 0.005676) is
  protected: backup with checksums in
  `smart-pixels/backups/QConv1D_Slim-3eb13b90-2026-10-28/` (README.txt
  has the restore steps), and the two checkpoint folders and the two
  `npy/2t-QConv1D_Slim-3eb13b90-*` files are read-only. A rerun of
  `two_bit_optimization.ipynb` with QConv1D_Slim stops with
  PermissionError at `shutil.rmtree` in `train.py` before deleting
  anything. To retrain on purpose, `chmod -R u+w` them first.
  QMlp_Slim (`392456de`) retrain (1000 + 2000 epochs, 2026-10-28
  09:35 to 23:03, test MSE total 0.004667) is protected the same way:
  backup in `smart-pixels/backups/QMlp_Slim-392456de-2026-10-28/`, and
  its two checkpoint folders and `npy/2t-QMlp_Slim-392456de-*` files are
  read-only. The Oct 18 model (part 2 only, behind all QMlp_Slim
  Catapult results so far) and its Catapult reports stay in
  `smart-pixels/backups/QMlp_Slim-392456de-2026-10-18/`.
  QConv2D_Slim (`392456de`, 1000 + 2000 epochs, 2026-10-29 07:26 to
  2026-10-30 02:00, part 1 best val 44.2574, part 2 best val 42.3299,
  QKeras test MSE total 0.007418) is protected the same way: backup in
  `smart-pixels/backups/QConv2D_Slim-392456de-2026-10-30/`, checkpoint
  folders and `npy/2t-QConv2D_Slim-392456de-*` read-only. Run through
  Catapult on 2026-10-30.

- `codesign_catapult_efpga.ipynb` still deletes its previous project
  (`shutil.rmtree` in the "Remove the previous project" cell) and
  overwrites its `-xc7vx485tffg1157-1-vars` parquet; only
  `codesign_catapult.ipynb` archives (2026-10-30). The Oct 18 Virtex-7
  QMlp projects (`..._efpga_hls4ml_prj`, `..._efpga_pool16_8_hls4ml_prj`)
  are not in the 2026-10-30 backup: copy them before rerunning it, or
  port `archive_existing` first.
- Training runs on the CPU, not the GPU. The first code cell of both
  notebooks sets `CUDA_VISIBLE_DEVICES = "-1"` (added in `6cb1879`),
  so the GPU check in step 1 passes only because it runs before that
  cell. The likely reason, from memory: large training sets ran out of
  GPU memory or crashed. The 12 GB A2000 also drives the desktop (about
  2.4 GB in use), TF takes nearly all GPU memory by default, and
  `LD_LIBRARY_PATH` includes CUDA 11.8 while TF 2.15 is built for 12.2.
  To try the GPU later: remove the line, call `check_GPU()` from
  `utils.py` (enables memory growth) and time a few epochs. All
  `runs.csv` rows so far are CPU runs.
- `status.sh` and `clean.sh` still use the old VIAS path
  (`find_charge_cluster_centers/.../release/roi_finder`). `status.sh`
  will report the ROI TFRecords as missing even though they exist.
  `clean.sh` deletes TFRecords and trained weights. With the old path
  its ROI lines do nothing; if the path is updated, running it deletes
  the ROI TFRecords, which take a long time to rebuild.
- `run_container.sh` (untracked) starts a Rocky Linux Catapult container.
  It is not needed now that the venv works, but it is a fallback if
  Ubuntu library problems come back during synthesis.
- `CLAUDE.md` holds the commit message rules and is excluded from git.
- `codesign_catapult.ipynb` sets `Synth = False` in `create_config`
  since 2026-10-26 (it was `Synth = True`, while its "Run Catapult" note
  said to edit `build_prj.tcl` to `Synth False`). Check `build_prj.tcl`
  before running Catapult.

## Reference

### Slide (May 2025) vs this run

| | Slide, May 8 2025 | This run |
|---|---|---|
| Code | `xysum_model.py` at `d564843` | `two_bit_optimization_helpers/models/conv1d_model_quantized.py` |
| Input | 13x21x2, `fixed<4,1>` | 16x16x2 ROI window (from the 48x192 sensor), values 0 to 3, `ufixed<2,2>` |
| Pooling | `fixed<11,1>` | `fixed<16,8>` |
| Output (`dense_3`) | `fixed<8,2>` | `fixed<10,2>` |
| Dataset | `dataset_2s_50x12P5x100` | VIAS ROI `dataset_2s_48x192_50x12P5` |
| Catapult | 2024.2_2 | 2024.2_2 (2026.3_1 tried, see "Switch back to 2024.2_2") |
| HLS area | 0.81 mm^2 conv2d, 0.39 mm^2 conv1d | to be measured |

Both runs use a 25 ns clock, `io_parallel` and the Latency strategy.
The slide's trained weights and its Catapult report no longer exist.
`fasic-137645.fnal.gov` was searched as well and has no copy of this
work (it only has 2023 to early 2025 SmartPixels hls4ml repos).

### Models already trained here (ROI dataset)

In `smart-pixels/weights/dataset_2s_roi_weights/`: `Conv1D_Slim`
(`3eb13b90`), `Conv2D_Slim`, `Mlp_Slim`, `QMlp_Slim` and `QConv2D_Slim`
(`392456de`), and `QConv1D_Slim` (`3eb13b90`); the three quantized Slim
models are the full 1000 + 2000 epoch runs of 2026-10-28 to 30.
`Conv1D_Slim` is the non-quantized version of the target, so it cannot
go through hls4ml as is.

### Moving to another machine (2026-11-03)

Git carries the code, notebooks, `runs.csv` and this plan. Push branch
`2bit_optimization-gdg` to the `gdg` remote
(`git@github.com:GiuseppeDiGuglielmo/smart-pixels-ml.git`) before
cloning. Everything below is outside git. Paths are relative to the repo
root unless absolute.

Copy (needed to continue):

| What | Size | Why |
|---|---|---|
| `CLAUDE.md`, `ROI_LABEL_BUG_REPORT.md`, `ROI_LABEL_BUG_RETRAIN_RESULT.md` | small | agent instructions and notes, gitignored |
| `envsetup.sh`, `envsetup_vitis.sh`, `runme.sh`, `runme_vitis.sh` | small | local Catapult/Vitis setup, gitignored; fix the paths inside |
| `smart-pixels/weights/` | 534 MB | trained model checkpoints the notebooks load |
| `smart-pixels/backups/` | 13 GB | write-protected training and Catapult backups (keep read-only, `cp -a`) |
| `smart-pixels-ml/processed_parquets/` | 512 MB | QKeras and hls4ml prediction parquets (test MSE) |
| `npy/` | 3 GB | `X_test`/`y_test` arrays per model for the codesign notebooks |
| ROI dataset `/extras2/home/gdg/research/projects/smartpixels/VIAS/fermi_roi_finder/implementation/testbench/cocotb/roi_finder/sim_out/dataset_2s_48x192_50x12P5_parquets/` | 18 GB | training (`TFR_files/`, 2.5 GB, enough with `tfrecords_exist_2s_roi=True`) and test parquets (`test/`, 3.8 GB); `train/` (12 GB) only to rebuild the TFRecords |
| Claude memory `~/.claude/projects/-extras2-home-gdg-research-projects-smartpixels-davidgjiang-smart-pixels-ml/memory/` | 40 KB | put it under `~/.claude/projects/<new repo path with / as ->/memory/` |
| `.claude/settings.local.json` | small | local Claude Code permissions (optional) |

Optional (regenerated by the notebooks, or already in the backups):
the `SmtPxl_*_hls4ml_prj/` Catapult projects (about 14 GB; the
2026-10-30 ones are in `smart-pixels/backups/Catapult_ASIC_...`),
`tb_input_features*.dat` and `tb_output_predictions*.dat` (5.5 GB), the
`*.png`/`*.jpeg`/`*.gif` plots, `myproject_config*.yml`, `.vscode/`.

Not copied, set up on the new machine: the Catapult install and its
venvs (`~/catapult_venvs` is 138 GB; rebuild as in "Rebuilding the venv"
below), the Catapult license (`1717@fasic-135413.fnal.gov`, VPN), the
TSMC 28 nm library (licensed, site only; `build_prj.tcl` and the
notebooks point at `/home/giuseppe/research/projects/smartpixels/tsmc28nm_lib`),
and `run_container.sh`'s `CONTAINER_DIR`. Absolute paths to fix after
the move: the dataset path in `codesign_catapult.ipynb` and
`codesign_catapult_efpga.ipynb`, the TSMC path, `envsetup.sh`.

The Genus synthesis needs nothing from here: it lives in the VIAS
repository on fasic-beast1, which is on GitHub (see "Genus logic
synthesis (2026-11-03)"). Its run folders (`impl/syn/genus_*`, 1.1 GB)
are not in git; copy them only if the reports are needed elsewhere.

### Rebuilding the venv

For a new Catapult release, or if `~/catapult_venvs/2026.3_1` breaks:

```bash
mv ~/catapult_venvs/2026.3_1 ~/catapult_venvs/2026.3_1_OLD
# run with bash, not sh: the script uses BASH_SOURCE
/extras2/tools/Siemens/catapult/2026.3_1/Mgc_home/bin/create_catapult_py_venv.sh ~/catapult_venvs/2026.3_1
source ~/ccs_venv/bin/activate
pip install tensorflow-probability==0.23.0 natsort pyarrow
```

`tensorflow-probability` 0.23.0 is the release that matches TF 2.15.
The three extra packages are imported by `loss.py`, `train.py` and
pandas parquet I/O. `~/catapult_venvs/2026.3_1_BROKEN` is the first,
unusable attempt and can be deleted.

### Changes made for Catapult 2026.3_1

Everything changed to make the flow work with Catapult 2026.3_1 and its
hls4ml (`0.1.0.dev1981+g70cf498`), where it is, and its status since the
switch back to 2024.2_2 on 2026-10-19. Each change is also annotated in
place (look for `2026-10-18`, `2026-10-19`, `WORKAROUND` or `DISABLED`).
Cell numbers are as of 2026-10-19; the cell names do not change. To go
back to 2026.3_1: select the "Catapult 2026.3_1" kernel and undo the
"disabled" rows.

| # | Where | What and why | Status (2026-10-19) |
|---|---|---|---|
| 1 | `Mgc_home/bin/create_catapult_py_venv.sh` in the 2026.3_1 install (original kept as `.BKP`) | Uses `pkgs/cds_undodb/.../python3` (3.10.18): the shipped script calls a Python that is not shipped, and `Mgc_home/bin/python3.10` needs `libffi.so.6`. | kept (2026.3_1 install only) |
| 2 | `~/.local/share/jupyter/kernels/catapult-2026.3_1/kernel.json` | Kernel that sources `envsetup.sh` before Python. | kept, now "Catapult 2026.3_1" with `CATAPULT_VER=2026.3_1` |
| 3 | `envsetup.sh`, `SALT_LICENSE_SERVER` | Typo fix `$LM_LICENS` -> `$LM_LICENSE_FILE`. | active (any release) |
| 4 | `envsetup.sh`, `LIBRARY_PATH` | `/usr/lib/x86_64-linux-gnu`: the bundled GCC only searches `/usr/lib64`, so on Ubuntu linking fails with "cannot find crti.o". | active (harmless with 2024.2_2, whose customized `build_lib.sh` does the same for the testbench link) |
| 5 | notebook, "Bit-precision" cell (53) | Lone `;` under `case _:` replaced with `pass`. | active (bug fix) |
| 6 | notebook, `create_config` cell (48) | `startup = os.path.abspath("catapult_startup.tcl")`, because stock hls4ml ignores `asiclibspath`. | disabled (commented out) |
| 7 | `catapult_startup.tcl` | `solution options set ComponentLibs/SearchPath <tsmc28nm_lib> -append`. | kept, not used |
| 8 | notebook, ReLU workaround cell (57) | QKeras `quantized_relu` gets `activ_param = [None, 0.0, 0.0]`; the 2026.3_1 Catapult template requires it (`KeyError: 'activ_param'`). Kernel only. | disabled (raw cell) |
| 9 | notebook, "Convert QKeras model" cell (58) | `keras_v2_to_hls()`: `keras_to_hls()` was renamed, and the old name hits a leftover module ("'module' object is not callable"). | reverted: `keras_to_hls()` active, `keras_v2_to_hls()` commented |
| 10 | notebook, firmware fixes cell (59), `two_bit_optimization_helpers/catapult_firmware_fixes.py` | Hooks `write()` and rewrites `firmware/<project>.cpp`. (a) ac_sync fan-out: one `ac_sync` was given to several consumers ("ac_channel.h:296 Read from empty channel", kills the kernel); each now gets its own through `hls4ml_sync_fanout2`. Marker `HLS4ML_SYNC_FANOUT_FIX`. (b) `hard_tanh` block: its `#pragma hls_design block` is commented out in `nnet_activation.h`, so it was inlined into the top function (ASM-62 at `go assembly`); now called through `hls4ml_hard_tanh_block`. Marker `HLS4ML_HARD_TANH_BLOCK_FIX`. | disabled (raw cell), module kept |
| 11 | not implemented (tested by hand in a scratch copy) | `directive set /<top>/input_pxls:rsc -MAP_TO_MODULE {[DirectInput]}` before `go architect`: the input array read by two blocks failed with MEM-71. Would go into `config["GlobalDirectives"]["architect"]` or the firmware fixes hook. | not needed with 2024.2_2 |

Tests on QMlp_Slim (2026-10-18): conversion of all 18 layers (8, 9);
library and testbench build (4); C++ testbench on all 255,409 events
matches QKeras, `predict()` and `trace()` work, fixes re-applied after
`trace()` (10); library found (6, 7); full synthesis through `go extract`
in 53 minutes (all of the above plus 11), giving the sequential design
described under "Switch back to 2024.2_2".

### Catapult 2024.2_2 install customizations

Diff of `/extras2/tools/Siemens/catapult/2024.2_2` against
`2024.2_2_ORIG` (2026-10-19; `../check_local_changes.sh` in the
catapult folder does the same). Port these to a future release.

| File (under `Mgc_home/shared/`) | Change |
|---|---|
| `pkgs/ccs_hls4ml/hls4ml/hls4ml/backends/catapult/catapult_backend.py`, `pkgs/ccs_hls4ml/hls4ml/catapult_ai_nn.py` | `asiclibspath` option (stored as `ASICLibsPath`) |
| `.../writer/catapult_writer.py`, `.../templates/catapult/build_prj.tcl` | `setup_asic_libs {libs} {paths}`, which runs `solution options set ComponentLibs/SearchPath <path> -append` |
| `.../templates/catapult/build_lib.sh` | `LIBRARY_PATH=/usr/lib/x86_64-linux-gnu` for the testbench link |
| `.../model/profiling.py` | wraps a single traced output in a list |
| `.../report/catapult_report.py` | adds `format_and_print_report()` |
| `include/nnet_utils/nnet_conv2d_latency.h`, `nnet_sepconv2d.h`, `nnet_sepconv2d_latency.h` | `hls_unroll` pragmas and a sepconv output-size fix (conv2d only; QMlp and QConv1D do not use them) |

### Problems to report to Siemens (Catapult 2026.3_1)

1. `create_catapult_py_venv.sh` points at `pkgs/cds_python3/bin/python3`,
   which is not shipped (change 1).
2. `Mgc_home/bin/python3.10` links against `libffi.so.6`, which current
   Ubuntu does not provide (change 1).
3. The bundled GCC does not find `crti.o` on Ubuntu (change 4). Already
   worked around locally in 2024.2_2's `build_lib.sh`.
4. `keras_to_hls()` renamed, but the old `converters/keras_to_hls.py` is
   still shipped and imported by `converters/keras/transformer.py`, so
   the old name fails with a confusing error (change 9).
5. Catapult backend `ActivationConfigTemplate`
   (`backends/catapult/passes/core_templates.py`) requires `activ_param`,
   which `converters/keras/qkeras.py` `get_activation_quantizer` does not
   set for `quantized_relu` (change 8).
6. io_parallel `ac_sync` fan-out: one `ac_sync` given to several
   consumers; the Clone pass is off for io_parallel
   (`backends/fpga/passes/clone.py`) (change 10a). The input array read
   by several blocks also needs `[DirectInput]` (MEM-71, change 11).
   Minor: the generated testbench writes the "Quantized predictions" line
   to `csim_results.log` instead of stdout every 5000 events, so 52
   events appear twice in the log.
7. `nnet_activation.h`: `#pragma hls_design block` is commented out on
   the `ac_sync` overload of `hard_tanh` (since at least 2025.4_1), so
   `quantized_tanh` layers break `go assembly` with ASM-62 (change 10b).
8. With `Strategy: Latency` and `ReuseFactor: 1`, the io_parallel design
   is sequential (QMlp_Slim latency 2338 cycles, throughput 581), unlike
   2024.2_2. Not yet understood; possibly the programmable weights
   (`_pw`) mapped to memories.

Not a Siemens problem: stock hls4ml ignores `create_config(asiclibspath=...)`.
That option is our own 2024.2_2 customization (above), not ported to
2026.3_1 (changes 6 and 7 did its job there).

### License check

```bash
lmutil lmstat -c 1717@fasic-135413.fnal.gov -f | grep -E "CatapultUltra|CatAIhls4ml"
```

`fasic-admin1.fnal.gov:1717` (also in
`~/bin/eda_licenses_monitor/siemens/check_siemens_licenses.sh`) is
not reachable from this machine.

### Repository

- Branch `2bit_optimization-gdg`, local commits not pushed yet.
- Remotes: `origin` is `davidgjiang/smart-pixels-ml`, `gdg` is
  `GiuseppeDiGuglielmo/smart-pixels-ml`. The original xysum model came
  in through `smart-pix/smart-pixels-ml` PR #13.
- Other notebooks: `codesign_vitis.ipynb` runs the Vitis flow with the
  conda env in `environment_vitis.yml` (`envsetup_vitis.sh`, kernel
  "Vitis (smartpixels-regression-vitis-env)").
