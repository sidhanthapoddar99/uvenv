# uvenv user guide

A friendly tour of every uvenv command, with the underlying `mise` / `uv`
commands shown alongside so you always know what's happening beneath the wrapper.

> Quick reference: `uvenv info` prints a one-screen cheat sheet of every mise +
> uv command uvenv composes.

## Contents

1. [Grammar](#grammar)
2. [Mental model](#mental-model)
3. [Install](#install)
4. [Layout on disk](#layout-on-disk)
5. [Concepts: base Python vs. venv](#concepts-base-python-vs-venv)
6. [Command reference](#command-reference)
7. [Common workflows](#common-workflows)
8. [Tab completion](#tab-completion)
9. [Updating uvenv](#updating-uvenv)
10. [Troubleshooting](#troubleshooting)

## Grammar

```text
uvenv tool --python=3.13 install dstack -U
        └─ uvenv's flags ─┘ └─ verbatim to uv ─┘
```

The grammar is consistent across every subcommand:

- **uvenv flags come first**, before the action verb. `--python=X.Y`, `-n`,
  `-l`, `-y` etc. are uvenv's; uvenv parses them.
- **The action verb** (`install`, `uninstall`, `upgrade`, `list` for `tool`;
  not applicable for one-shot commands like `set`) determines what uvenv
  dispatches to.
- **Everything after the action is forwarded verbatim** to `uv` (or `mise`).
  No re-parsing, no surprises — any uv flag works as expected.
- **Use `--` to be explicit** when there's ambiguity (e.g.
  `uvenv install -- numpy --pre` to be 100% sure `--pre` goes to uv).

---

## Mental model

```
┌──────────┐   manages Python versions       ┌──────────────────────────────┐
│   mise   │ ───────────────────────────────►│  ~/.local/share/mise/...     │
└──────────┘                                 │  python/3.12, python/3.13... │
     ▲                                       └──────────────────────────────┘
     │ "use this Python"
     │
┌──────────┐   creates a venv against         ┌──────────────────────────────┐
│   uvenv  │ ──────────────────────────────►  │  ~/.uvenv/<name>/            │
└──────────┘   mise's chosen Python           │  (regular Python venv)       │
                                              └──────────────────────────────┘
```

`uvenv` is glue between `mise` (the Python version manager) and `uv` (the venv
+ package installer). It adds one thing neither has on its own: **named global
Python venvs you can activate from anywhere**, conda-style.

## Install

```bash
curl -fsSL https://github.com/sidhanthapoddar99/uvenv/releases/latest/download/install.sh | bash
```

The installer:

1. Verifies `mise`, `uv`, `curl`, and `tar` are installed.
2. Downloads `uvenv-<tag>.tar.gz` from the latest GitHub release.
3. Extracts to `~/.config/uvenv/` (override with `UVENV_PREFIX`).
4. Backs up any previous install to `~/.config/uvenv.bak`.
5. Adds a `source ~/.config/uvenv/uvenv.sh` line to your `.bashrc` / `.zshrc`.

Open a new shell, then run:

```bash
uvenv version
uvenv help
```

### Install options

| Env var | Default | Meaning |
| --- | --- | --- |
| `UVENV_VERSION` | `latest` | Pin a release tag (e.g. `v0.2.0`) |
| `UVENV_REF` | *(unset)* | Install from a branch/commit instead of a release |
| `UVENV_PREFIX` | `~/.config/uvenv` | Install dir |
| `UVENV_REPO` | `sidhanthapoddar99/uvenv` | Source repo |

```bash
# Install from main branch (bleeding edge)
UVENV_REF=main curl -fsSL \
  https://raw.githubusercontent.com/sidhanthapoddar99/uvenv/main/install.sh | bash
```

## Layout on disk

```
~/.config/uvenv/             ← UVENV_PREFIX (the installation)
├── uvenv.sh                 ← thin dispatcher, sourced from rc
├── install.sh               ← bundled, called by `uvenv self-update`
├── VERSION
├── lib/                     ← per-subcommand shell modules, lazy-loaded
│   ├── common.sh
│   ├── create.sh
│   ├── activate.sh
│   ├── list.sh
│   └── ...
└── completions/
    ├── uvenv.bash
    └── uvenv.zsh

~/.uvenv/                    ← UVENV_HOME (your envs live here)
├── ml/
├── scratch/
└── ...
```

`UVENV_PREFIX` holds uvenv itself; `UVENV_HOME` holds your venvs. They are
independent, so reinstalling / updating uvenv never touches your envs.

## Concepts: base Python vs. venv

- **Base Python**: the Python that mise resolves on your `PATH` right now —
  shown by `mise current python`. Whatever `python` runs when no venv is active.
- **uvenv venv**: a regular Python venv created against a specific mise Python,
  living at `~/.uvenv/<name>/`. Activate it and `python` becomes that venv's.

`uvenv install <pkg>` always tries to do the safe thing:

- **Inside a venv** → installs into that venv (`uv pip install`).
- **No venv active** → warns you and asks for confirmation before doing a
  `uv pip install --system` into the base mise Python. Skip the prompt with
  `uvenv install -y <pkg>`.

## Command reference

### Environments

#### `uvenv create [--python=X.Y] -n <name>`

```bash
uvenv create --python=3.13 -n ml
```

Equivalent to:

```bash
mise install python@3.13
mise exec python@3.13 -- uv venv ~/.uvenv/ml
```

If `--python` is omitted, uvenv uses whatever Python mise currently resolves.

#### `uvenv create [--python=X.Y] -l <path>`

Create a venv at a local path (project-local, not global). Mise still picks
the Python:

```bash
uvenv create --python=3.13 -l ./venv
uvenv create -l /tmp/scratch
```

Equivalent to `mise install python@X.Y` + `mise exec python@X.Y -- uv venv <path>`.
`-n` and `-l` are mutually exclusive; the path must not already exist.

#### `uvenv activate <name|path>` / `uvenv deactivate`

Sources the venv's `bin/activate` (or runs `deactivate`). Works only because
uvenv is a sourced shell function — a binary couldn't mutate your shell.

```bash
uvenv activate ml          # named global env in $UVENV_HOME
uvenv activate ./venv      # local venv at a path
uvenv activate /abs/path   # absolute path also works
```

Resolution: name in `$UVENV_HOME` first, then path. Prefix with `./` to force
the path interpretation when a name might collide.

`uvenv remove <name|path>` follows the same resolution rules.

#### `uvenv list`

Three sections:

```
Global venvs (~/.uvenv)
    NAME                 PYTHON     BASE
  * ml                   3.13.13    ~/.local/share/mise/installs/python/3.13/bin
    scratch              3.12.7     ~/.local/share/mise/installs/python/3.12/bin

Local venvs (/current/dir)
  (none here)

Available mise pythons
  python  3.12.13
  python  3.13.13  ~/.config/mise/config.toml  3.13
  python  3.14.5
```

A leading `*` marks the active env.

#### `uvenv remove <name>`

Deletes `~/.uvenv/<name>`. Refuses if it's the active env (`uvenv deactivate`
first).

### Packages

#### `uvenv install [-y] <pkg>...`

Forwards args to `uv pip install`. Refuses to touch the base Python without
confirmation (or `-y`).

```bash
uvenv install numpy pandas
uvenv install -r requirements.txt
uvenv install -e .
```

#### `uvenv update <pkg>... | --all`

`uv pip install --upgrade <pkg>`. With `--all`, upgrades everything that
`uv pip list --outdated` flags.

```bash
uvenv update numpy
uvenv update --all
```

### Run / inspect without activating

#### `uvenv exec <name|path> -- <cmd> ...`

Run a command using a uvenv env's Python and bin/ — without activating in
this shell. The `--` is required:

```bash
uvenv exec ml -- python train.py
uvenv exec ./venv -- pytest -q
uvenv exec scratch -- which python
```

Useful for cron, CI, and one-shot scripts.

#### `uvenv freeze [<name|path>]`

`uv pip freeze` — for the active venv (no arg) or any named/path env:

```bash
uvenv freeze                # active venv
uvenv freeze ml             # global env, no activation
uvenv freeze ./venv         # local venv
uvenv freeze ml > reqs.txt  # export
```

### uv tools (`uvenv tool ...`)

Wraps `uv tool install` and (importantly) lets you pin a Python version per
install, by temporarily switching the global mise Python and **restoring it
afterwards** even on failure or Ctrl+C.

```bash
uvenv tool install ruff
uvenv tool --python=3.13 install yt-dlp   # uses 3.13, then restores prior
uvenv tool list
uvenv tool upgrade ruff
uvenv tool upgrade --all
uvenv tool uninstall yt-dlp
```

Under the hood (with `--python`):

```bash
prev=$(mise current python)
mise use -g python@3.13
uv tool install yt-dlp
mise use -g python@$prev      # always runs, even on failure (EXIT trap)
```

### Python version (`mise`) shortcuts

#### `uvenv set --python=X.Y`

```bash
uvenv set --python=3.14    # ≡ mise install python@3.14 + mise use -g python@3.14
```

### Status & info

#### `uvenv status`

```
uvenv 0.2.0

mise
  binary:  /home/you/.local/bin/mise
  version: 2026.4.27
  python:  3.13.13

uv
  binary:  /home/you/.local/share/mise/installs/uv/.../uv
  version: uv 0.11.15

Active venv
  name:    ml   (uvenv-managed)
  path:    /home/you/.uvenv/ml
  python:  3.13.13
  base:    /home/you/.local/share/mise/installs/python/3.13/bin
```

If no venv is active, the last section says so explicitly.

#### `uvenv doctor`

Sanity-check the install: mise + uv on PATH, mise has a Python, `UVENV_PREFIX`
contains `lib/`, `UVENV_HOME` writable, and an rc file actually sources uvenv.

```
uvenv doctor — uvenv 0.2.1

Dependencies
  [PASS] mise on PATH  (/usr/local/bin/mise)
  [PASS] uv on PATH    (/.../mise/installs/uv/.../uv)
  [PASS] mise has a Python  (3.13.13)

Paths
  [PASS] UVENV_PREFIX install OK  (/home/you/.config/uvenv)
  [PASS] lib/ present
  [PASS] UVENV_HOME writable  (/home/you/.uvenv)

Shell integration
  [PASS] /home/you/.bashrc sources uvenv

All checks passed.
```

Exits non-zero if any check fails — handy for scripting / install verification.

#### `uvenv info`

A cheat sheet of every `mise` / `uv` command uvenv composes. Read it once;
you'll mostly stop needing to look up flags.

### Maintenance

#### `uvenv update --self`  (alias: `uvenv self-update`)

Re-runs the bundled installer to pull the latest release. Your envs in
`~/.uvenv/` are untouched.

#### `uvenv which`

Prints `$UVENV_HOME` — where your envs live.

#### `uvenv completions {bash|zsh}`

Prints a completion script for the named shell. Pipe to `eval`:

```bash
# in ~/.bashrc
eval "$(uvenv completions bash)"

# in ~/.zshrc
eval "$(uvenv completions zsh)"
```

## Common workflows

### Try out a new Python release

```bash
uvenv set --python=3.14            # mise grabs 3.14, makes it global default
uvenv create --python=3.14 -n play314
uvenv activate play314
uvenv install ipython
```

### Multiple project envs, switch on demand

```bash
uvenv create --python=3.12 -n api
uvenv create --python=3.13 -n notebook
uvenv activate api
# work on api...
uvenv deactivate
uvenv activate notebook
```

### Install a CLI tool against a non-default Python

```bash
uvenv tool --python=3.12 install scrapy   # scrapy needs 3.12 today
# mise's global python stays whatever it was before
```

### Clean break: nuke everything and start over

```bash
uvenv deactivate
rm -rf ~/.uvenv               # all envs (your data)
rm -rf ~/.config/uvenv        # uvenv itself
# remove the source line from ~/.bashrc / ~/.zshrc
```

## Tab completion

Once enabled (see `uvenv completions`), uvenv completes:

- Subcommands (`uvenv <TAB>`)
- Env names (`uvenv activate <TAB>`, `uvenv remove <TAB>`)
- Installed Pythons (`uvenv create --python=<TAB> -n foo`)
- `uvenv tool` subcommands and `--python` values
- `uvenv update` flags
- `uvenv completions bash|zsh`

## Updating uvenv

```bash
uvenv self-update          # or: uvenv update --self
```

This runs the installer bundled inside your install directory. It downloads the
latest release tarball, swaps the install dir atomically, and keeps one
previous version at `~/.config/uvenv.bak` for rollback.

If for some reason the bundled installer is missing, uvenv falls back to
curling the latest `install.sh` from GitHub.

## Troubleshooting

### `uvenv: lib not found at ~/.config/uvenv/lib`

You have an old (pre-0.2) install (single `uvenv.sh` file). Re-install:

```bash
curl -fsSL https://github.com/sidhanthapoddar99/uvenv/releases/latest/download/install.sh | bash
```

### `uvenv activate` says "not found"

`uvenv list` to confirm the name. Envs live under `$UVENV_HOME` (default
`~/.uvenv`); make sure you didn't move that directory.

### `uvenv tool --python=X.Y install` left a tool on the wrong Python (pre-0.2.4 only)

Older uvenv versions used `mise use -g` + a restore trap, which had a stale-PATH
window. Fixed in 0.2.4 by switching to `mise exec` — the python is now pinned
both via mise's PATH and uv's `--python` flag for the duration of one command,
with no global mise mutation. Self-update to get the fix:

```bash
uvenv self-update
```

### `uvenv install` refuses without `-y`

That's by design when no venv is active — installing into the base mise Python
modifies the global site-packages. Either activate a venv first, or pass `-y`.

### Python from `uvenv create` doesn't match what mise has

uvenv always runs `mise exec python@X.Y -- uv venv ...`, so the exact patch
version mise picks (e.g. `3.13.13` for `--python=3.13`) is what ends up in the
venv. To pin further, pass the full version: `--python=3.13.13`.

### Prompt still shows a venv after `uvenv deactivate`

If `which python` and `python --version` look correct (point at mise's python,
report mise's version) but powerlevel10k / oh-my-zsh still shows the venv name,
the prompt is reading a stale `$VIRTUAL_ENV`. v0.2.4 guarantees `$VIRTUAL_ENV`
is unset after `uvenv deactivate` returns, so this should resolve itself —
make sure you're on the current version (`uvenv version`).

If you're on 0.2.4+ and still see it, your prompt may be caching state across
the precmd hook. For powerlevel10k specifically, check whether instant-prompt
mode is involved:

```bash
grep -n "instant_prompt\|POWERLEVEL9K_INSTANT_PROMPT" ~/.zshrc ~/.p10k.zsh
```
