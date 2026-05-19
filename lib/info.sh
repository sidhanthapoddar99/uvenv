# uvenv info — detailed translation map: what each uvenv command runs
# underneath, what guarantees / safety rails it adds, and how the three env
# types (tool / global / local) relate.

_uvenv_info() {
    cat <<'EOF'
uvenv info — what every command actually does

═══════════════════════════════════════════════════════════════════════════
 Four kinds of Python environment uvenv touches
═══════════════════════════════════════════════════════════════════════════

  1. BASE  — the Python mise resolves on your PATH right now.
             Nothing is "activated"; `python` is whatever mise points at.
             Touching this is global: it affects every shell and every
             tool that uses mise's Python.
                                                              uvenv set,
                                                              uvenv install -y

  2. uv TOOL env — an isolated venv per CLI tool (ruff, yt-dlp, ...).
             Created by `uv tool install`. The CLI lands on PATH; the
             Python it uses is invisible to you.
                                                              uvenv tool ...

  3. GLOBAL venv  — a named venv under $UVENV_HOME (~/.uvenv/<name>).
             You activate it explicitly; lives forever until you remove it.
             This is the "conda activate ml" use case.
                                                              uvenv create -n
                                                              uvenv activate <name>

  4. LOCAL venv   — a venv at an arbitrary path (e.g. ./venv).
             Project-local; lives with the project, not under $UVENV_HOME.
                                                              uvenv create -l
                                                              uvenv activate <path>

═══════════════════════════════════════════════════════════════════════════
 Command → underlying calls (the "translation table")
═══════════════════════════════════════════════════════════════════════════

  uvenv set --python X.Y
    →  mise install python@X.Y               (idempotent)
    →  mise use -g python@X.Y                (updates ~/.config/mise/config.toml)

  uvenv create -n <name> --python X.Y
    →  mise install python@X.Y
    →  mise exec python@X.Y -- uv venv $UVENV_HOME/<name>
        Result: a venv whose Python IS mise's python@X.Y (not a uv-fetched copy).

  uvenv create -l <path> --python X.Y
    →  mise install python@X.Y
    →  mise exec python@X.Y -- uv venv <path>
        Same, but venv lives at the given path.

  uvenv activate <name|path>
    →  resolves: $UVENV_HOME/<arg>  first,  else  <arg>  as a path
    →  source <resolved>/bin/activate
        Must be a SOURCED shell function — a binary can't mutate this shell.

  uvenv deactivate
    →  deactivate    (the venv-provided function)

  uvenv install [-y] <pkg>...
    inside a venv:  →  uv pip install <pkg>...
    no venv active:
       prompts:     "Continue with --system install?" (skip with -y/--yes)
       on yes:      →  uv pip install --system <pkg>...   (writes to base mise python)
        ★ SAFETY: refuses to silently touch the base mise Python.

  uvenv update <pkg>...                        →  uv pip install --upgrade <pkg>...
  uvenv update --all
    →  uv pip list --outdated  →  uv pip install --upgrade <each>
  uvenv update --self  (a.k.a. uvenv self-update)
    →  bash $UVENV_PREFIX/install.sh           (the bundled installer)

  uvenv exec <name|path> -- <cmd>...
    →  (subshell)  source <env>/bin/activate  &&  <cmd>...
        Scoped — your shell is never modified.

  uvenv freeze [<name|path>]                   →  uv pip freeze  (in target env)

  uvenv tool install <pkg> [--python X.Y]
    no --python:    →  uv tool install <pkg>
    with --python:  →  remember:  prev = mise current python
                       mise install python@X.Y
                       mise use -g python@X.Y          ← global mise change
                       uv tool install <pkg>
                       mise use -g python@<prev>       ← always restored
        ★ SAFETY: the restore runs via an EXIT trap inside a subshell, so
                  it fires on success, failure, AND Ctrl+C / signals.

  uvenv tool uninstall <pkg>                   →  uv tool uninstall <pkg>
  uvenv tool upgrade <pkg> | --all             →  uv tool upgrade <pkg> | --all
  uvenv tool list                              →  uv tool list

  uvenv list                                   →  three sections:
                                                    - $UVENV_HOME/* (global venvs)
                                                    - ./.venv, ./venv (local venvs)
                                                    - mise ls python  (available Pythons)

  uvenv remove <name|path>
    →  refuses if the target is the currently-active venv
    →  rm -rf <resolved target>

  uvenv status   → which mise, which uv, which venv (none / uvenv / external)
  uvenv doctor   → PASS/FAIL on deps, paths, rc integration
  uvenv which    → echo $UVENV_HOME

═══════════════════════════════════════════════════════════════════════════
 Safety rails baked in
═══════════════════════════════════════════════════════════════════════════

  • `uvenv install <pkg>` with NO venv active warns + prompts before
    `uv pip install --system` would modify the base mise Python's
    site-packages. Skip the prompt with -y for scripts.

  • `uvenv tool install --python X.Y` changes mise's global Python only
    for the duration of the install, and the restore is guaranteed by an
    EXIT trap inside a subshell (covers success, failure, signals).

  • `uvenv remove <name|path>` resolves paths before comparing against
    $VIRTUAL_ENV, so it correctly refuses to delete the currently-active
    venv no matter how it was referenced.

  • `uvenv create` refuses if the target name OR path already exists,
    rather than overwriting.

  • The installer atomic-swaps the install dir and keeps the previous
    version at $UVENV_PREFIX.bak — one-step rollback if anything breaks.

═══════════════════════════════════════════════════════════════════════════
 Underlying commands you can run directly if you ever want to bypass uvenv
═══════════════════════════════════════════════════════════════════════════

  Python management (mise)
    mise install python@X.Y           install a Python
    mise use -g python@X.Y            set as global default
    mise current python               which Python is active right now
    mise ls python                    list installed Pythons
    mise exec python@X.Y -- <cmd>     run cmd with that Python

  Venvs and packages (uv)
    uv venv <dir> [--python X.Y]      create a venv
    uv pip install <pkg>              install into active venv
    uv pip install --upgrade <pkg>    upgrade
    uv pip install --system <pkg>     install into the active Python (no venv)
    uv pip list [--outdated]          list (outdated) packages
    uv pip uninstall <pkg>            uninstall
    uv pip freeze                     dump installed packages

  Standalone tools (uv)
    uv tool install <pkg>             install a CLI tool in its own venv
    uv tool upgrade <pkg> | --all     upgrade tools
    uv tool list                      list tools
    uv tool uninstall <pkg>           uninstall

  Hint: every one of those is what uvenv runs underneath. uvenv only adds
        orchestration (mise+uv together), name/path resolution, and the
        safety rails listed above.
EOF
}
