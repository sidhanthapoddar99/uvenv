# demo/

VHS tape files for the GIFs in the project README. Tapes are checked in;
generated GIFs are **not** — regenerate them locally with [VHS](https://github.com/charmbracelet/vhs).

## Generate

Install VHS (Charm):

```bash
# macOS
brew install vhs

# Linux (binary release)
# https://github.com/charmbracelet/vhs/releases
```

You also need uvenv (and, for the conda comparison, conda) installed on the
host running VHS.

Then:

```bash
vhs demo/uvenv-tour.tape          # → demo/uvenv-tour.gif
vhs demo/uvenv-vs-conda.tape      # → demo/uvenv-vs-conda.gif
vhs demo/conda-side.tape          # → demo/conda-side.gif   (optional)
```

## Files

| Tape | What it shows |
| --- | --- |
| `uvenv-tour.tape` | 30-second hero clip: `create → activate → install → list → deactivate` |
| `uvenv-vs-conda.tape` | The uvenv half of a side-by-side timing comparison |
| `conda-side.tape` | The conda half — paired with `uvenv-vs-conda.tape` |

The README embeds the resulting `.gif`s side-by-side. Wall-clock timings come
from `time` calls inside each tape, so the comparison is honest — no edits.

## Notes

- VHS is a real virtual terminal, not a screen capture. Text stays crisp at
  any size, the recording is deterministic, and the `.tape` files are diff-able.
- Re-run after every major release to keep the demo current. Keep total length
  under ~30 seconds per GIF so they load fast in the README.
- Don't commit the generated GIFs unless you've actually run VHS — there's no
  point in checking in a stale binary.
