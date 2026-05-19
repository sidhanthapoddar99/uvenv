# Design notes

Why uvenv is the shape it is. If you're just using uvenv, the [user guide](USER_GUIDE.md)
is what you want.

## Why a shell function, not a binary?

`uvenv activate` must mutate the **current** shell's `PATH` and `$VIRTUAL_ENV`.
A regular script (or compiled binary) runs in a subprocess and can't do that —
the moment the process exits, env changes are lost.

This is the same reason `nvm`, `pyenv`, `rbenv`, `conda activate`, and similar
tools are all shell functions. uvenv lives at `~/.config/uvenv/uvenv.sh`,
sourced into your shell from `.bashrc` / `.zshrc`.

A hybrid approach (small Rust/Go binary + a thin shell shim that `eval`s its
output, the way `mise activate` and `direnv hook` work) is technically possible
but not justified at this scale — `uv` and `mise` themselves are the heavy
lifting, and a wrapper measured in tens of subprocess calls per command will
never be performance-bound by its own dispatch.

## Modular shell, not a monolith

The dispatcher (`uvenv.sh`) is ~70 lines and only routes. Every subcommand is
its own `lib/<cmd>.sh` file, sourced lazily on first use and cached for the rest
of the shell session. Adding a new subcommand means writing one file and adding
one line to the case statement — see [CONTRIBUTING.md](CONTRIBUTING.md).

Lazy sourcing keeps shell startup cost flat as the command surface grows.

## Why mise picks the Python, not uv

`uv` has its own Python discovery — it can download Python distributions under
`~/.local/share/uv/python/` independently of mise. That's two managers fighting
over the same job.

uvenv resolves this by routing through mise explicitly:

```text
uvenv create -n ml --python 3.13
   │
   ├── mise install python@3.13      (idempotent — installs if missing)
   └── mise exec python@3.13 -- uv venv ~/.uvenv/ml
                                    └── uv uses mise's Python, not its own
```

Without `--python`, uvenv just runs `uv venv ~/.uvenv/<name>` against whatever
Python is on PATH — which mise controls. Either way, mise is the single source
of truth for Python versions.

## Why `uv venv` under the hood

Speed. `uv venv` is ~10× faster than `python -m venv` and integrates cleanly
with `uv pip install`. The resulting env is a regular Python venv on disk —
anything you'd do to a normal venv works here.

## Why `uvenv tool` restores the mise Python

`uv tool install <pkg> --python X.Y` would install with whatever Python uv
discovers — which means uv might fetch its own Python rather than reusing
mise's. To keep mise authoritative we instead:

1. Remember the current global mise Python
2. `mise use -g python@X.Y`
3. `uv tool install <pkg>`  ← uses mise's X.Y
4. Restore the previous Python

Step 4 must run on success, on failure, **and on Ctrl+C**. So the whole thing
lives in a subshell with `trap _restore EXIT` — bash fires EXIT traps on signals
as well as normal exit, but only inside subshells where it can't accidentally
clobber a user-defined trap in the interactive shell.

## Relationship to `uv tool install`

`uv tool install` is for **standalone CLIs you run as commands** (`ruff`,
`yt-dlp`, `dstack`). Each gets its own isolated venv with a shim on PATH.

`uvenv` is for **interactive envs you enter and work in** — Jupyter notebooks,
REPLs, scripts where you want `python` to mean "the Python in this env."

Both are isolated global venvs, just with different ergonomics. uvenv wraps
both: `uvenv install` for the former case, `uvenv tool install` for the latter.

## Tarball install (and self-update)

Releases ship a `uvenv-<tag>.tar.gz` containing the whole modular tree
(`uvenv.sh`, `install.sh`, `lib/`, `completions/`, `VERSION`). The installer:

1. Downloads to a temp dir
2. Extracts + verifies (`uvenv.sh` contains `uvenv() {`, `lib/` exists)
3. Moves any existing install to `~/.config/uvenv.bak`
4. Moves the new tree into place
5. Restores from `.bak` if anything failed mid-flight

`install.sh` is bundled inside the tarball so `uvenv self-update` re-runs
exactly that script without needing the network for the script itself, only
for the next release tarball.

## What uvenv deliberately does NOT do

- **No lockfile.** These are scratch / global envs, not reproducible projects.
  For reproducibility, use `uv add` in a real project folder (see
  [uv's docs](https://docs.astral.sh/uv/)).
- **No auto-deactivate on `cd`.** Activation is explicit. Use
  [direnv](https://direnv.net) if you want auto-switching.
- **No multi-shell coordination.** Each shell tracks its own active env via
  `$VIRTUAL_ENV`.
- **No conda channel support.** Pure pip/uv. For conda-forge packages, use
  [pixi](https://github.com/prefix-dev/pixi).
- **No rename / clone of envs.** Venvs aren't path-portable (shebangs and
  `.pth` files bake in absolute paths). Create fresh and `uvenv freeze | uvenv install -r -` is the supported workflow.

These aren't TODOs — they're scope decisions. The point of uvenv is to be the
*tiny* layer that gives mise+uv the one ergonomic affordance they lack. Bigger
needs are better served by bigger tools.
