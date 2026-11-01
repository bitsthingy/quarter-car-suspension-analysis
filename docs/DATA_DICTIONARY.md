# Results and data dictionary

## Files

| File in `results/` | Contents |
|---|---|
| `configuration_comparison.csv` | Soft, baseline and firm pairs on three roads: 9 rows |
| `parameter_sweep.csv` | 20 pairs × 3 roads: 60 rows, feasibility and Pareto flags |
| `selected_configuration.csv` | Selected design on the multisine selection input |
| `selected_configuration_all_roads.csv` | The same selected pair on all three inputs |
| `selection_record.mat` | Choice, baseline, criteria and selected runs |
| `baseline_bump_trace.csv` | 4,001 samples of the baseline bump response |
| `verification.csv` | Seven physics/numerical checks and thresholds |
| `simulink_verification.csv` | Relative L2 errors for 21 signal comparisons |
| `frequency_response.csv` | 500 frequencies, with three gains for each named pair |
| `study_workspace.mat` | Baseline parameters, comparison table and sweep table |
| `console_log.txt` | Study console output; local project path replaced for publication |
| `comparison_*.png` | Bump, sine and multisine comparison figures |
| `tradeoffs.png` | Acceleration, tyre load and travel trade-off plot |
| `frequency_response.png` | Continuous-model harmonic gains |

## Comparison and sweep columns

| Column | Definition |
|---|---|
| `Configuration` | Named parameter pair, or `Sweep` |
| `Scenario` | `bump`, `sine` or `multisine` |
| `ks_Npm` | Suspension spring stiffness [N/m] |
| `cs_Nspm` | Suspension damping coefficient [N s/m] |
| `RMS_window_start_s` | Start of RMS window [s]; end is 8 s |
| `Body_accel_RMS_mps2` | Unweighted body acceleration RMS [m/s²] |
| `Body_accel_peak_mps2` | Maximum absolute sampled body acceleration [m/s²] |
| `Travel_peak_mm` | Maximum absolute body-minus-wheel displacement [mm] |
| `Tyre_dynamic_load_RMS_N` | RMS of incremental tyre normal force [N] |
| `Dynamic_load_coefficient` | Dynamic load RMS / static normal load; dimensionless |
| `Minimum_total_tyre_load_N` | Minimum static-plus-dynamic normal load [N] |
| `Within_assumed_limits` | Travel ≤60 mm and minimum total load >0 N |
| `Pareto_within_limits` | Nondominated in acceleration, travel and load within that road's feasible grid |

## Signs, units and interpretation

The state order is body displacement, body velocity, wheel displacement, wheel velocity. SI units are used internally. Body and wheel displacement are relative to static loaded equilibrium, with upward positive. Travel is body minus wheel displacement: positive means extension relative to equilibrium.

Incremental tyre force is `kt*(road-wheel)`, positive for an increase in wheel normal load. Static normal load is `(ms+mu)*g = 3335.4 N`. A negative incremental load alone does not imply loss of contact; the total load is the relevant contact screen.

In `frequency_response.csv`, acceleration gain is [(m/s²)/m], travel gain is [m/m], and load gain is [N/m]. In the verification CSV, `Relative_L2_error` is dimensionless, with acceptance strictly below 0.001. Boolean CSV values may be represented as 1 and 0.
