# The conda side of the comparison. Same task — create a Python ML env with
# numpy/pandas/scikit-learn — so the wall-clock difference is honest.
#
# Run:
#   vhs demo/conda-side.tape               # produces demo/conda-side.gif
#
# Requires: a conda/miniforge install (this tape does NOT install conda).

Output demo/conda-side.gif

Set Shell  "bash"
Set FontSize 16
Set Width  1100
Set Height 600
Set Theme  "Dracula"
Set TypingSpeed 55ms

Hide
Type "clear" Enter
Show

Type "# conda: spin up the same Python ML env"  Sleep 800ms  Enter
Sleep 500ms

Type "time conda create -n ml python=3.13 -y"   Sleep 400ms  Enter
Sleep 20s

Type "conda activate ml"                        Sleep 400ms  Enter
Sleep 1s

Type "time conda install -y numpy pandas scikit-learn"  Sleep 400ms  Enter
Sleep 30s

Type "python -c 'import sklearn; print(sklearn.__version__)'"  Sleep 400ms  Enter
Sleep 2s

Type "conda deactivate"  Sleep 400ms  Enter
Sleep 1500ms
