# Publication notes

The source MATLAB files, completed Simulink model and results were copied from the completed project folder. Numerical CSV values, MAT workspaces and the `.slx` model are preserved. The console log has its local Windows project path replaced with `<project>/results`.

The README was rewritten for the completed project. Additional report, motivation, data dictionary and reproducibility documents were added. The obsolete reference-only execution status was updated to acknowledge the subsequent MATLAB run. Selected MATLAB functions received explanatory comments. The trade-off figure layout was made persistent in `run_studies.m`. `select_configuration.m` packages the documented selection commands without changing the selection rule.

During packaging, the selection was independently recomputed from the saved sweep, all selected rows were matched to that sweep, and the 7/7 and 21/21 pass counts were verified from the original CSVs. Numerical solver routines were not modified. A fresh MATLAB execution was not performed during this publication step.

`FILE_SHA256.csv` records the publication file hashes, excluding itself. This is an integrity aid, not an experimental validation record.
