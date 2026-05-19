# uvenv

> Named global Python venvs, backed by [mise](https://mise.jdx.dev) + [uv](https://github.com/astral-sh/uv).

Conda-style `activate ml` ergonomics, without conda. uvenv is a small shell
wrapper around `mise` (Python versions) and `uv` (venvs + packages).

```bash
uvenv create --python=3.13 -n ml
uvenv activate ml
uvenv install numpy pandas
uvenv list                         # global envs + local venvs + mise pythons
uvenv deactivate
```

### Grammar

```text
uvenv tool --python=3.13 install dstack -U
        └─ uvenv's flags ─┘ └─ verbatim to uv ─┘
```

uvenv's own flags come **before** the action verb. Everything from the
action onward is passed straight to `uv` (or `mise`) without parsing —
so any flag uv accepts works as expected. Use `--` after uvenv's flags
when you need an explicit separator (e.g. `uvenv install -- numpy --pre`).

📖 **[USER_GUIDE.md](USER_GUIDE.md)** — full command reference & workflows
🛠 **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to extend it
🧠 **[DESIGN.md](DESIGN.md)** — why-it-works-this-way notes
🔒 **[SECURITY.md](SECURITY.md)** — reporting issues
🎬 **[demo/](demo/)** — VHS tape files for the README GIFs (not generated in CI)

---

## Why?

`mise` manages Python versions. `uv` creates venvs anywhere. Neither has a
"give me a named env I can activate from any directory" command — the conda
workflow many people miss after switching off conda. uvenv plugs that one gap.

It is **only a shell wrapper** — no new daemon, no new package format, no
new Python. Glue between mise, uv, and your shell, ~70 lines of dispatcher
plus a per-subcommand `lib/` file.

---

## Platform support

- ✅ Linux (and WSL2)
- ✅ macOS (bash 3.2+ and zsh)
- ❌ Windows native (no bash on PATH; use WSL)

Runs on bash and zsh. No bash-4-only constructs.

---

## Prerequisites

You need **mise** and **uv** before installing uvenv. One-time setup:

```bash
# 1. mise (Python version manager)
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc   # or .zshrc

# 2. uv (via mise)
mise use -g uv@latest

# 3. (optional) a default Python
mise use -g python@3.13
```

`uvenv doctor` verifies all of this after install.

---

## Install

```bash
curl -fsSL https://github.com/sidhanthapoddar99/uvenv/releases/latest/download/install.sh | bash
```

Open a new shell, then:

```bash
uvenv version
uvenv doctor
```

The installer downloads the release tarball, atomic-swaps it into
`~/.config/uvenv/`, and adds a `source` line to your `.bashrc` / `.zshrc`. Your
venvs in `~/.uvenv/` are never touched.

### Install options

| Env var | Default | Meaning |
| --- | --- | --- |
| `UVENV_VERSION` | `latest` | Pin a release tag (e.g. `v0.2.1`) |
| `UVENV_REF` | *(unset)* | Install from a branch/commit instead of a release |
| `UVENV_PREFIX` | `~/.config/uvenv` | Install dir |
| `UVENV_HOME` | `~/.uvenv` | Where your envs live |
| `UVENV_REPO` | `sidhanthapoddar99/uvenv` | Source repo |

```bash
# Install from main branch (bleeding edge)
UVENV_REF=main curl -fsSL \
  https://raw.githubusercontent.com/sidhanthapoddar99/uvenv/main/install.sh | bash
```

---

## Quick tour

```bash
uvenv create --python=3.13 -n ml            # ~/.uvenv/ml using mise's python 3.13
uvenv create --python=3.12 -l ./venv        # local venv at ./venv

uvenv activate ml                            # by name
uvenv activate ./venv                        # by path
uvenv install numpy pandas                   # uvenv-flags first, pkgs go to uv
uvenv install -y -- numpy --pre              # -- separates uvenv flags from uv args
uvenv update --all
uvenv deactivate

uvenv exec ml -- python train.py             # run in env without activating
uvenv freeze ml > requirements.txt

uvenv tool --python=3.13 install ruff -U     # remembers, switches, restores
uvenv tool upgrade --all

uvenv set --python=3.14                      # mise use -g python@3.14
uvenv status                                 # mise / uv / venv state
uvenv list                                   # all three sections; active marked with *

uvenv doctor                                 # PASS/FAIL on deps, paths, completions
uvenv self-update                            # re-run the bundled installer
```

Tab completion is enabled **automatically** when `uvenv.sh` is sourced from your
rc file — no extra setup needed. (If `uvenv doctor` reports it as missing under
zsh, ensure `autoload -Uz compinit && compinit` runs *before* the uvenv source line.)

---

## Uninstall

```bash
rm -rf ~/.config/uvenv ~/.config/uvenv.bak                # uvenv itself
sed -i.bak '/uvenv\/uvenv.sh/d' ~/.bashrc ~/.zshrc 2>/dev/null
rm -rf ~/.uvenv                                            # your envs (data!)
```

---

## Alternatives

| Tool | Strength | Weakness |
| --- | --- | --- |
| **uvenv** (this) | Tiny shell wrapper over the modern stack | Bash/zsh only, no lockfiles |
| `uv venv` directly | Already on your machine | No "named" abstraction, no central listing |
| [pixi](https://github.com/prefix-dev/pixi) | Full Conda alternative in Rust, conda-forge support, lockfiles | Heavier; doesn't reuse mise's Pythons |
| Conda / Mamba | Most complete, scientific stack | Heavy, slow, ships its own Python |

uvenv is intentionally narrow — *named global Python venvs on top of mise+uv*.
If you want full Conda compatibility, pixi is the better choice. See
[DESIGN.md](DESIGN.md) for what uvenv deliberately does NOT do.

---

## License

MIT — see [LICENSE](LICENSE).
