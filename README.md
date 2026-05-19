# uvenv

> Named global Python venvs, backed by [mise](https://mise.jdx.dev) + [uv](https://github.com/astral-sh/uv).

A modular shell wrapper that gives `mise + uv` the one ergonomic thing they're missing: named global Python environments you can activate from anywhere, conda-style — without conda.

```bash
uvenv create -n ml --python 3.14
uvenv activate ml
uvenv install numpy pandas
uvenv tool install ruff --python 3.13   # restores mise's python afterwards
uvenv status
uvenv list                              # global venvs + local venvs + mise pythons
uvenv self-update
```

Everything lives under `~/.uvenv/<name>/`. Each env is just a `uv venv` under the hood, so it's lightweight, disposable, and works with any tool that understands a regular Python venv.

> 📖 Full tour: **[USER_GUIDE.md](USER_GUIDE.md)** · Contributing: **[CONTRIBUTING.md](CONTRIBUTING.md)**

---

## Why?

`mise` manages Python versions. `uv` creates venvs anywhere. But neither has a "give me a named env I can activate from any directory" command — the conda-style `conda activate ml` workflow many people miss after moving off conda.

This plugs that gap:

```text
   mise        ────►  installs Python 3.14 at ~/.local/share/mise/installs/...
     │
     ▼
   uvenv       ────►  uv venv ~/.uvenv/ml --python 3.14   (uses mise's Python)
     │
     ▼
   activate    ────►  source ~/.uvenv/ml/bin/activate
```

It's a shell function. No new tools. Just glue between `mise`, `uv`, and your shell.

---

## Prerequisites

- **mise** on PATH — https://mise.run
- **uv** installed via mise — `mise use -g uv@latest`
- bash or zsh

The installer checks for both up front; the runtime function trusts they're there. If you don't have them yet, set them up in three steps:

### 1. Install mise

```bash
curl https://mise.run | sh
```

Then add mise to your shell so the `mise` command and its shims are on `PATH`:

```bash
# bash
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

# zsh
echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc
```

Open a new shell and verify:

```bash
mise --version
```

### 2. Add uv to mise's global config

```bash
mise use -g uv@latest
```

This pins `uv` as a global tool in `~/.config/mise/config.toml`. You can confirm with:

```bash
mise ls          # shows uv and any other globally-managed tools
uv --version     # uv is now on PATH via mise's shims
```

### 3. (Optional) Pre-install a Python via mise

`uvenv create --python X.Y` runs `mise install python@X.Y` for you, so this is optional — but if you want a default Python globally:

```bash
mise use -g python@3.14
mise install        # installs anything declared in config but not yet present
```

You're now ready to install uvenv (next section).

---

## Install

```bash
curl -fsSL https://github.com/sidhanthapoddar99/uvenv/releases/latest/download/install.sh | bash
```

After it finishes, open a new shell (or `source ~/.config/uvenv/uvenv.sh`) and run:

```bash
uvenv help
```

### Install options

The installer respects a few environment variables:

| Var | Default | Meaning |
| --- | --- | --- |
| `UVENV_VERSION` | `latest` | Pin a specific release tag (e.g. `v0.1.0`) |
| `UVENV_REF` | *(unset)* | Install from a branch/commit instead of a release |
| `UVENV_PREFIX` | `~/.config/uvenv` | Where to store `uvenv.sh` |
| `UVENV_REPO` | `sidhanthapoddar99/uvenv` | Source repo |

Examples:

```bash
# Pin a version
UVENV_VERSION=v0.1.0 curl -fsSL https://github.com/sidhanthapoddar99/uvenv/releases/latest/download/install.sh | bash

# Install from main branch (bleeding edge)
UVENV_REF=main curl -fsSL https://raw.githubusercontent.com/sidhanthapoddar99/uvenv/main/install.sh | bash
```

---

## Usage

### Create

```bash
uvenv create -n scratch                       # uses default Python (whatever mise points to)
uvenv create -n ml --python 3.14              # ensures mise has 3.14, builds env against it
uvenv create -n py312 python=3.12             # alt syntax
uvenv create -l ./venv --python 3.13          # local venv at ./venv (project-local)
```

When `--python X.Y` is provided, `uvenv` runs `mise install python@X.Y` first (idempotent), then `mise exec python@X.Y -- uv venv <target>`. That way **mise is the single source of truth for Python versions** — uv never falls back to downloading its own.

### Activate / deactivate

```bash
uvenv activate ml           # named global env in $UVENV_HOME
uvenv activate ./venv       # local venv (anything with bin/activate)
# ... do work ...
uvenv deactivate
```

### Install packages into the active env

```bash
uvenv install numpy pandas
uvenv install -r requirements.txt
uvenv install -e .
uvenv install "torch>=2.0,<3"
```

All arguments after `install` are forwarded directly to `uv pip install`. The only thing `uvenv install` adds is a guard: it refuses to run unless a `uvenv` env is active.

### List

```bash
uvenv list
#   ml                       python 3.14.1
# * scratch                  python 3.14.1        ← active env
#   py312                    python 3.12.7
```

### Remove

```bash
uvenv remove py312
```

Refuses to remove the currently-active env (deactivate first).

### Other

```bash
uvenv which       # prints $UVENV_HOME
uvenv version     # prints the uvenv version
uvenv help        # help text
```

---

## Storage

```text
~/.config/uvenv/                  ← UVENV_PREFIX (the install)
├── uvenv.sh                       # dispatcher, sourced from .bashrc/.zshrc
├── install.sh                     # bundled — used by `uvenv self-update`
├── VERSION
├── lib/                           # one file per subcommand, lazy-sourced
└── completions/{uvenv.bash,uvenv.zsh}

~/.uvenv/                         ← UVENV_HOME (your envs)
├── scratch/
│   ├── bin/python → ~/.local/share/mise/installs/python/3.14.x/bin/python
│   ├── lib/python3.14/site-packages/
│   └── pyvenv.cfg
├── ml/
└── notebooks/
```

`UVENV_PREFIX` and `UVENV_HOME` are independent — reinstalling uvenv never touches your envs. Override either with the matching env var.

---

## Command Reference

| Command | What it does |
| --- | --- |
| `uvenv create -n <name> [--python X.Y]` | `mise install python@X.Y` → `mise exec python@X.Y -- uv venv ~/.uvenv/<name>` |
| `uvenv create -l <path> [--python X.Y]` | Same, but the venv goes to `<path>` (e.g. `./venv`) instead of `$UVENV_HOME` |
| `uvenv activate <name\|path>` / `uvenv deactivate` | Activate by name (in `$UVENV_HOME`) or by path (e.g. `./venv`) |
| `uvenv list` | Three sections: global venvs, local venvs in cwd, available mise pythons |
| `uvenv remove <name\|path>` | Delete a global env (by name) or a local venv (by path); refuses if active |
| `uvenv install [-y] <pkg>...` | `uv pip install` into active env; warns + confirms when no venv is active |
| `uvenv update <pkg>... \| --all` | `uv pip install --upgrade` in the active env |
| `uvenv update --self` / `uvenv self-update` | Re-run the bundled installer |
| `uvenv tool install <pkg> [--python X.Y]` | `uv tool install` with optional temporary mise-python switch + auto-restore |
| `uvenv tool uninstall <pkg>` / `uvenv tool list` | Thin wrappers over `uv tool` |
| `uvenv set --python X.Y` | `mise use -g python@X.Y` |
| `uvenv status` | Show current mise, uv, and active-venv state |
| `uvenv info` | Cheat sheet of every mise + uv command uvenv composes |
| `uvenv completions {bash\|zsh}` | Print a tab-completion script |
| `uvenv which` / `uvenv version` / `uvenv help` | Storage dir / version / help text |

For details on each command and common workflows, see **[USER_GUIDE.md](USER_GUIDE.md)**.

---

## Design Notes

### Why a shell function, not a binary?

`uvenv activate` must mutate the **current** shell's `PATH` and `$VIRTUAL_ENV`. A regular script (or compiled binary) runs in a subprocess and can't do that — the moment the process exits, env changes are lost.

This is the same reason `nvm`, `pyenv`, `rbenv`, `conda activate`, and similar tools are all shell functions, not binaries. uvenv lives at `~/.config/uvenv/uvenv.sh`, sourced into your shell from `.bashrc` / `.zshrc`.

### Why mise picks the Python, not uv?

uv has its own Python discovery — it can download Python distributions under `~/.local/share/uv/python/` independently of mise. That's two managers fighting over the same job.

uvenv resolves the question by routing through mise explicitly:

```text
uvenv create -n ml --python 3.14
   │
   ├── mise install python@3.14      (idempotent — installs if missing)
   └── mise exec python@3.14 -- uv venv ~/.uvenv/ml
                                    └── uv uses mise's Python, not its own
```

Without `--python`, uvenv just runs `uv venv ~/.uvenv/<name>` against whatever Python is on PATH — which mise controls via `mise use -g python@X.Y`. Either way, mise is the authority.

### Why `uv venv` under the hood?

Speed. `uv venv ~/.uvenv/<name>` is ~10× faster than `python -m venv` and integrates cleanly with `uv pip install`. The resulting env is a regular Python venv on disk — anything you can do to a normal venv works here.

### Relationship to `uv tool install`

`uv tool install` is for **standalone CLIs you run as commands** (`ruff`, `dstack`, `yt-dlp`). Each gets its own isolated venv with a shim on PATH.

`uvenv` is for **interactive envs you enter and work in** — Jupyter notebooks, REPLs, scripts where you want `python` to mean "the Python in this env."

Both are isolated global venvs, just with different ergonomics.

### What `uvenv` does NOT do

- **No lockfile.** These are scratch / global envs, not reproducible projects. For reproducibility, use `uv add` in a real project folder (see [uv's docs](https://docs.astral.sh/uv/)).
- **No auto-deactivate on `cd`.** Activation is explicit, like a regular venv. Use [direnv](https://direnv.net) or shell hooks if you want auto-switching.
- **No multi-shell coordination.** Each shell tracks its own active env via `$VIRTUAL_ENV`.
- **No conda channel support.** This is pure pip/uv. For conda-forge packages and full Conda compatibility, look at [pixi](https://github.com/prefix-dev/pixi).

---

## Uninstall

```bash
# Remove uvenv itself (and any .bak from a previous self-update)
rm -rf ~/.config/uvenv ~/.config/uvenv.bak

# Remove the source line from your rc files
sed -i.bak '/uvenv\/uvenv.sh/d' ~/.bashrc ~/.zshrc 2>/dev/null

# Remove all your envs (optional — your data lives here)
rm -rf ~/.uvenv
```

---

## Alternatives

| Tool | Strength | Weakness |
| --- | --- | --- |
| **uvenv** (this) | Tiny shell wrapper over the modern stack | Bash/zsh only, no lockfiles |
| `uv venv` directly | Already on your machine | No "named" abstraction, no central listing |
| [pixi](https://github.com/prefix-dev/pixi) | Full Conda alternative in Rust, conda-forge support, lockfiles | Heavier; doesn't reuse mise's Pythons |
| [Conda / Mamba](https://github.com/conda-forge/miniforge) | Most complete, scientific stack | Heavy, slow, ships its own Python |

uvenv is a small fix for a small gap — *named global Python venvs on top of mise+uv*. If you want a full Conda alternative, pixi is the better choice.

---

## Contributing

Issues and PRs welcome. See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the
modular layout, how to add a subcommand, and the release process.

---

## License

MIT — see [LICENSE](LICENSE).
