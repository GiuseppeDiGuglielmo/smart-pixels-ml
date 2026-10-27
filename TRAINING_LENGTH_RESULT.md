# QMlp_Slim: 1000 + 2000 epochs vs 200 + 200

**Date:** 2026-10-18
**Model:** `QMlp_Slim`, ROI dataset `2s` (`dataset_2s_48x192_50x12P5`),
`use_roi=True`, `use_roi_labels=True`, `seed=42`, fingerprint `392456de`

## Summary

Training longer improves every metric. In physical units the gain is
modest: x RMS 7.50 → 7.40 µm, y RMS 2.19 → 2.08 µm, cotB RMS
0.0434 → 0.0406. The 200 + 200 run had not converged: both parts
reached their best validation loss at or next to the last epoch.

Use 1000 + 2000 for results that will be reported. 200 + 200 is fine
for smoke tests and for HLS area, which does not depend on training
length.

## Results

Same test set (255,409 events) and the same test TFRecords for both
runs, so the numbers compare directly.

| | 200 + 200 (2026-08-03) | 1000 + 2000 (2026-10-18) | change |
|---|---|---|---|
| Part 1 best val loss | 30.40 (epoch 199) | **27.54** (epoch 969) | −9.4 % |
| Part 2 best val loss | 28.98 (epoch 200) | **26.49** (epoch 1882) | −8.6 % |
| Learned thresholds (e⁻) | 278, 768, 1785 | 277, 756, 1775 | |
| x RMS | 7.50 µm | **7.40 µm** | −1.3 % |
| y RMS | 2.19 µm | **2.08 µm** | −5.0 % |
| cotB RMS | 0.0434 | **0.0406** | −6.5 % |
| x bias | −0.14 µm | −0.08 µm | |
| y bias | +0.19 µm | +0.10 µm | |
| Normalized MSE total | 0.005082 | **0.004649** | −8.5 % |
| Training time (CPU) | about 2.1 h | about 13.3 h | 6× |

Physical values are the residuals in the performance parquet times
the test `labels_scale` `[102.366 µm, 40.698 µm, 0.5205]`. The MSE
change looks larger than the RMS change because MSE is squared.

Loss during the 200 + 200 run, part 2:

```
epoch   25   50   100   150   175   200
val   36.2 33.8  31.1  30.6  31.0  29.0   <- best at the last epoch
```

In the long run, part 2 kept improving well past epoch 200: best 28.10
by epoch 362, 26.55 by epoch 1577, 26.49 at epoch 1882.

## Caveat: one run each

Each configuration was trained once. Reruns are not identical even
with `seed=42`: in `runs.csv`, four Mlp_Slim runs with the same
200 + 200 configuration (after the label fix) gave part 2 val losses
of 28.38, 28.41, 28.50 and 31.20. This improvement (28.98 → 26.49) is about the size of that
spread, so treat the exact percentages as indicative. The steady
decrease of the loss over the long run supports a real effect.

## Where things are

- New model: `smart-pixels/weights/dataset_2s_roi_weights/weights-2t-QMlp_Slim-*-392456de-checkpoints/`
- Old model (backup, same paths inside): `smart-pixels/backups/QMlp_Slim-392456de-2026-08-03/`
- Both runs are rows in `runs.csv` (timestamps `2026-08-03T22:51:07`
  and `2026-10-18T13:27:35`).
- Training ran on the CPU: the notebooks set `CUDA_VISIBLE_DEVICES=-1`.
