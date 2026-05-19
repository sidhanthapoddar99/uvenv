# uvenv 30-second tour — generate with: vhs demo/uvenv-tour.tape
# Output: demo/uvenv-tour.gif

Output demo/uvenv-tour.gif

Set Shell  "bash"
Set FontSize 16
Set Width  1200
Set Height 720
Set Theme  "Dracula"
Set TypingSpeed 50ms
Set PlaybackSpeed 1.0

# Assume mise + uv + uvenv are already installed.
Hide
Type "clear" Enter
Show

Type "# uvenv: named global Python venvs over mise + uv"  Sleep 800ms  Enter

Type "uvenv create -n ml --python 3.13"                   Sleep 500ms  Enter
Sleep 4s

Type "uvenv activate ml"                                  Sleep 500ms  Enter
Sleep 1s

Type "uvenv install numpy pandas"                         Sleep 500ms  Enter
Sleep 6s

Type "python -c 'import numpy; print(numpy.__version__)'" Sleep 500ms  Enter
Sleep 2s

Type "uvenv list"                                         Sleep 500ms  Enter
Sleep 3s

Type "uvenv deactivate"                                   Sleep 500ms  Enter
Sleep 1500ms
