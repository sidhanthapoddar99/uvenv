# Side-by-side comparison: setting up the same ML env in conda vs uvenv.
# Generate two GIFs and place them side-by-side in the README.
#
# Run:
#   vhs demo/uvenv-vs-conda.tape           # produces demo/uvenv-vs-conda.gif
#   vhs demo/conda-side.tape               # produces demo/conda-side.gif
#
# This tape is the uvenv side. The conda side is in conda-side.tape so each
# can be re-recorded independently.

Output demo/uvenv-vs-conda.gif

Set Shell  "bash"
Set FontSize 16
Set Width  1100
Set Height 600
Set Theme  "Dracula"
Set TypingSpeed 55ms

Hide
Type "clear" Enter
Show

Type "# uvenv: spin up a Python ML env"  Sleep 800ms  Enter
Sleep 500ms

Type "time uvenv create -n ml --python 3.13"   Sleep 400ms  Enter
Sleep 5s

Type "uvenv activate ml"                       Sleep 400ms  Enter
Sleep 1s

Type "time uvenv install numpy pandas scikit-learn"  Sleep 400ms  Enter
Sleep 7s

Type "python -c 'import sklearn; print(sklearn.__version__)'"  Sleep 400ms  Enter
Sleep 2s

Type "uvenv deactivate"  Sleep 400ms  Enter
Sleep 1500ms
