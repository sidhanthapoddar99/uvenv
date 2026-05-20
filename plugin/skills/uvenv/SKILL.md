---
name: uvenv
description: Use whenever the user mentions uvenv, the shell wrapper that gives mise + uv conda-style named global Python venvs you can activate from anywhere. Covers the flags-first grammar (uvenv <subcommand> [uvenv-flags] <action> [verbatim args]), the four env kinds (base mise python, uv-managed tools, named global venvs, local in-tree venvs), the always-on confirm-on-create UX, conda→uvenv command translation, safety rails, and doctor-first diagnostics. Trigger on any mention of "uvenv", "named global Python venvs", "conda-style python without conda", "uvenv create / activate / tool install / doctor / status", or questions about coordinating mise + uv for venvs. Also trigger when the user is migrating from conda/miniconda/anaconda/mamba to a uv-based setup and wants conda-like ergonomics — they may not say "uvenv", so watch for "activate from anywhere", "conda replacement", "named venvs", "global python envs", "named venv I can use from any directory". SKIP when (a) the user is invoking uv / conda / poetry / pixi / pdm / pipenv / rye directly without involving uvenv, (b) they're on Windows native (cmd / PowerShell — uvenv is bash/zsh only; recommend WSL), or (c) the question is purely about mise's tool management with no Python venv angle.
---

# uvenv

uvenv is a ~70-line shell function that wraps mise + uv to give you what
neither offers on its own: **named global Python venvs you can `uvenv
activate <name>` from anywhere**, conda-style without conda.

## Installing uvenv

If the user doesn't have uvenv yet, the canonical one-liner is:

```bash
curl -fsSL https://github.com/sidhanthapoddar99/uvenv/releases/latest/download/install.sh | bash
```

This downloads the latest release tarball, installs to `~/.config/uvenv`
(override via `UVENV_PREFIX=...`), and appends `source $UVENV_PREFIX/uvenv.sh`
to the user's `.bashrc` / `.zshrc`. Open a new shell (or re-source the rc
file) and `uvenv version` should print the installed version. Requires
`mise` and `uv` already on PATH — `uvenv doctor` flags missing deps.

Source / issues: https://github.com/sidhanthapoddar99/uvenv

## Mental model — four kinds of env

| Kind | Created by | Lives at | Activated how |
|---|---|---|---|
| **Base** (mise python) | `uvenv set --python X.Y` | mise-managed install | always on PATH; no activate |
| **uv tool** (CLI in its own env) | `uvenv tool install <pkg>` | `~/.local/share/uv/tools/<pkg>/` | tool's bin on PATH; never activate |
| **Named global venv** | `uvenv create -n <name>` | `$UVENV_HOME/<name>/` (default `~/.venvs/<name>`) | `uvenv activate <name>` from anywhere |
| **Local venv** | `uvenv create -l ./path` | the path you give | `uvenv activate ./path` |

The unique value of uvenv is row 3 — name → activate-from-anywhere. The rest
are ergonomic shims over `mise` and `uv`.

## The grammar (flags-first, like git/docker/kubectl)

```
uvenv <subcommand> [uvenv-flags] <action> [verbatim args...]
                   ^^^^^^^^^^^^^         ^^^^^^^^^^^^^^^^^^^^
                   uvenv parses          forwarded to underlying tool
```

- uvenv flags (e.g. `--python=3.13`, `-y`) go **between** subcommand and action.
- Everything after the action is `"$@"`-forwarded verbatim. Pass `-U`,
  `--pre`, `--index-url`, etc. to the underlying `uv` exactly as you would
  to uv.
- Use `--` to mark end-of-uvenv-flags explicitly: `uvenv install -- numpy --pre`.

**Example:** `uvenv tool --python=3.13 install dstack -U`
→ runs `mise exec python@3.13 -- uv tool install --python 3.13 dstack -U`.

## Confirm-on-create UX

`uvenv create` and `uvenv tool install` **always** print which python they
will actually use (in yellow) and its install path, then confirm:

```
Will use: ~/.local/share/mise/installs/python/3.13.1/bin/python (3.13.1)
Continue? [y/N]
```

If `$VIRTUAL_ENV` is set and its X.Y differs from the python we'd use, a red
mismatch banner appears with a hint to pass `--python=<active>`. Default
flips to N on mismatch. `-y` / `--yes` skips the prompt — the info block
still prints for log visibility.

This exists because mise's "current" python changes silently when you
`mise use -g`; without the confirm, `uvenv tool install dstack` could land
on the wrong python and waste minutes.

## conda → uvenv translation

| conda | uvenv |
|---|---|
| `conda create -n myenv python=3.13` | `uvenv create --python=3.13 -n myenv` |
| `conda activate myenv` | `uvenv activate myenv` |
| `conda deactivate` | `uvenv deactivate` |
| `conda env list` | `uvenv list` |
| `conda remove -n myenv --all` | `uvenv remove myenv` |
| `conda install requests` | `uvenv install requests` (venv active) |
| `pip freeze` | `uvenv freeze` |
| `conda run -n myenv python ...` | `uvenv exec myenv -- python ...` |
| `pipx install ruff` | `uvenv tool install ruff` |
| `conda update --all` | `uvenv update --all` |

Differences worth flagging to a migrator:

- No "base" activation step — mise's python is always on PATH.
- `uvenv tool install` is the pipx equivalent, not `uvenv install` (which
  is pip-install-into-active-venv).
- No `environment.yml` lockfile; pin via `uv pip compile` if needed.

## Safety rails

- `uvenv install <pkg>` refuses to `--system` install (no venv active)
  without `-y`. Stops accidental clobbering of mise's python.
- `uvenv tool --python=X.Y install <pkg>` pins via `mise exec python@X.Y --
  uv tool install --python X.Y` — no global mise mutation, no
  PATH-staleness.
- `uvenv deactivate` unsets `$VIRTUAL_ENV` even when the venv's own
  `deactivate` function isn't defined (common in inherited-venv child
  shells).
- Sourcing `uvenv.sh` re-prepends `$VIRTUAL_ENV/bin` to PATH if mise's
  hook rebuilt PATH without it; unsets `$VIRTUAL_ENV` if the venv dir is
  gone.

## Doctor-first diagnostics

When something looks wrong, run `uvenv doctor` before anything else. It
checks `mise` + `uv` on PATH and min versions, `$UVENV_HOME` writable,
rc-file integration, completion registration, and `$VIRTUAL_ENV`/`$PATH`
consistency.

If doctor is green and the issue persists:
- `uvenv status` — what's active and which python it points at
- `uvenv list` — sectioned: global venvs, local venvs in cwd, available
  mise pythons (active marked with green `*`)
- `uvenv info` — translation map of every uvenv command to its underlying
  `mise` / `uv` call

## Common workflows

```bash
# Named global env
uvenv create --python=3.13 -y -n myproj
uvenv activate myproj
uvenv install requests pandas

# Local venv in-tree
uvenv create --python=3.13 -y -l ./.venv
uvenv activate ./.venv

# CLI tool pinned to a python
uvenv tool --python=3.13 install ruff

# Run without activating
uvenv exec myproj -- python -m pytest

# Self-update (atomic-swap from the latest release tarball)
uvenv update --self
```

## When NOT to use this skill

- The user is using **uv directly** (`uv venv`, `uv tool install`, `uv pip
  install`) without uvenv — answer in uv's terms.
- The user is on **conda / mamba / micromamba / pixi / poetry / pdm /
  pipenv / rye** and isn't migrating — answer in their tool's terms.
- The user is on **Windows native** (cmd, PowerShell) — uvenv requires
  bash/zsh. Recommend WSL or `uv` directly.
- The question is purely about **mise's tool management** with no Python
  venv angle — defer to mise docs.
