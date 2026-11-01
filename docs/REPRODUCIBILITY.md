# Reproducing the study

## Software and starting point

Use MATLAB R2024a and Simulink to reproduce the complete workflow. Base MATLAB is sufficient for the time-domain studies, metric calculation and frequency-response computation. Keep the MATLAB files at the repository root: the scripts locate `results/` relative to their own path.

The `.slx` file is the completed model from the verified MATLAB session. `build_simulink` preserves an existing open or saved model. To test generation from scratch, work in a separate copy without the `.slx` file, then run the builder. Do not assume that running the builder overwrites an existing edited model.

## Execution order

```matlab
START_HERE
verify_project
run_studies
[choice,selectedRuns] = select_configuration();
build_simulink
verify_simulink
```

`verify_project` writes seven checks. `run_studies` writes nine named-configuration rows and 60 sweep rows. `select_configuration` reads the sweep and writes the chosen multisine row, its three-road comparison and a MAT selection record. `verify_simulink` writes 21 comparisons and restores the model to the baseline bump input.

The selection helper packages the commands used during the original analysis. The committed selection CSVs were produced in that analysis and checked against the sweep during publication preparation. Packaging edits to comments and figure layout do not change the dynamics. A new end-to-end MATLAB run was not performed during repository preparation.

## Numerical settings

| Setting | Value |
|---|---|
| Duration | 8 s |
| Road/output sample interval | 0.002 s |
| MATLAB solver | `ode45` |
| Relative / absolute tolerance | 1e-8 / 1e-10 |
| Maximum MATLAB integration step | 0.002 s |
| Simulink solver | Fixed-step `ode4`, 0.001 s |
| Initial state | Zero dynamic displacements and velocities |
| Road interpolation | Linear in both implementations |

The optional `refine` argument to `qc_simulate` tightens tolerances and the maximum integration step. It keeps the same sampled road input, so the convergence check evaluates integration convergence rather than road-sampling convergence.

## Metric windows

RMS uses trapezoidal time integration over 1–8 s for the bump and 2–8 s for sine/multisine. Peaks and feasibility screens use the complete 0–8 s record. The post-ramp window is finite; it is not proof of exact steady state. Keep the same input and window when comparing designs.

## Regenerated outputs

The main outputs are listed in [DATA_DICTIONARY.md](DATA_DICTIONARY.md). Running the workflow replaces result files with the current calculation. Small solver/version differences are expected. Preserve the committed results separately if you intend to change input definitions or baseline assumptions.

The plot layout in `run_studies.m` uses a wide trade-off figure and individual colour-bar labels so future exports retain the readable presentation. The committed trade-off PNG was exported from the original MATLAB session with the same presentation changes.

## Optional independent reference

Python is not needed for the MATLAB study. To run the separate reference calculation, install NumPy, SciPy and Matplotlib in your own Python environment, then run:

```text
python independent_check.py
```

That script writes to `reference_results/`. These outputs are independent reference calculations, not replacements for the actual MATLAB data in `results/`.
