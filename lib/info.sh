# uvenv info — detailed translation map: what each uvenv command runs
# underneath, what guarantees / safety rails it adds, and how the four
# kinds of env (base / uv tool / global / local) relate.

_uvenv_info() {
    cat <<EOF
${_UVENV_C_BOLD}uvenv info${_UVENV_C_RESET} — what every command actually does

═══════════════════════════════════════════════════════════════════════════
 ${_UVENV_C_BOLD}Grammar${_UVENV_C_RESET}
═══════════════════════════════════════════════════════════════════════════

    uvenv tool ${_UVENV_C_CYAN}--python=3.13${_UVENV_C_RESET} install ${_UVENV_C_GREEN}dstack -U${_UVENV_C_RESET}
            └─ ${_UVENV_C_CYAN}uvenv's flags${_UVENV_C_RESET} ─┘ └─ ${_UVENV_C_GREEN}verbatim to uv${_UVENV_C_RESET} ─┘

  • All uvenv-specific flags come BEFORE the action verb.
  • Everything after the action is forwarded verbatim to \`uv\` (or \`mise\`).
  • Use \`--\` after uvenv's flags when you need to disambiguate
    (e.g. \`uvenv install -- numpy --pre\`).

═══════════════════════════════════════════════════════════════════════════
 ${_UVENV_C_BOLD}Four kinds of Python environment uvenv touches${_UVENV_C_RESET}
═══════════════════════════════════════════════════════════════════════════

  1. ${_UVENV_C_BOLD}BASE${_UVENV_C_RESET}  — the Python mise resolves on your PATH right now.
            Nothing is "activated"; \`python\` is whatever mise points at.
            Touching this is global: it affects every shell and every
            tool that uses mise's Python.
                                                              uvenv set,
                                                              uvenv install -y

  2. ${_UVENV_C_BOLD}uv TOOL env${_UVENV_C_RESET} — an isolated venv per CLI tool (ruff, yt-dlp, ...).
            Created by \`uv tool install\`. The CLI lands on PATH; the
            Python it uses is invisible to you.
                                                              uvenv tool ...

  3. ${_UVENV_C_BOLD}GLOBAL venv${_UVENV_C_RESET}  — a named venv under \$UVENV_HOME (~/.uvenv/<name>).
            You activate it explicitly; lives forever until you remove it.
            This is the "conda activate ml" use case.
                                                              uvenv create -n
                                                              uvenv activate <name>

  4. ${_UVENV_C_BOLD}LOCAL venv${_UVENV_C_RESET}   — a venv at an arbitrary path (e.g. ./venv).
            Project-local; lives with the project, not under \$UVENV_HOME.
                                                              uvenv create -l
                                                              uvenv activate <path>

═══════════════════════════════════════════════════════════════════════════
 ${_UVENV_C_BOLD}Command → underlying calls (the "translation table")${_UVENV_C_RESET}
═══════════════════════════════════════════════════════════════════════════

  uvenv set --python=X.Y
    →  mise use -g python@X.Y                (auto-installs if missing)

  uvenv create --python=X.Y -n <name>
    →  mise exec python@X.Y -- uv venv \$UVENV_HOME/<name>
        Result: a venv whose Python IS mise's python@X.Y.

  uvenv create --python=X.Y -l <path>
    →  mise exec python@X.Y -- uv venv <path>
        Same, but venv lives at the given path.

  uvenv activate <name|path>
    →  resolves: \$UVENV_HOME/<arg>  first,  else  <arg>  as a path
    →  source <resolved>/bin/activate
        Must be a SOURCED shell function — a binary can't mutate this shell.

  uvenv deactivate
    →  deactivate    (the venv-provided function)

  uvenv install [-y] [--] <pkg>... [uv flags]
    inside a venv:  →  uv pip install <pkg>...
    no venv active:
       prompts:     "Continue with --system install?" (skip with -y/--yes)
       on yes:      →  uv pip install --system <pkg>...
        ${_UVENV_C_YELLOW}★ SAFETY${_UVENV_C_RESET}: refuses to silently touch the base mise Python.

  uvenv update <pkg>...                   →  uv pip install --upgrade <pkg>...
  uvenv update --all
    →  uv pip list --outdated  →  uv pip install --upgrade <each>
  uvenv update --self  (a.k.a. uvenv self-update)
    →  bash \$UVENV_PREFIX/install.sh        (the bundled installer)

  uvenv exec <name|path> -- <cmd>...
    →  (subshell)  source <env>/bin/activate  &&  <cmd>...
        Scoped — your shell is never modified.

  uvenv freeze [<name|path>]              →  uv pip freeze  (in target env)

  uvenv tool [--python=X.Y] install <pkg> [flags]
    no --python:    →  uv tool install <pkg> <flags>...
    with --python:  →  remember:  prev = mise current python
                       mise use -g python@X.Y         ← global mise change
                       uv tool install <pkg> <flags>  ← uses mise's X.Y
                       mise use -g python@<prev>      ← always restored
        ${_UVENV_C_YELLOW}★ SAFETY${_UVENV_C_RESET}: the restore runs via an EXIT trap inside a subshell, so
                  it fires on success, failure, AND Ctrl+C / signals.

  uvenv tool uninstall <pkg>              →  uv tool uninstall <pkg>
  uvenv tool upgrade <pkg> | --all        →  uv tool upgrade <pkg> | --all
  uvenv tool list                         →  uv tool list

  uvenv list                              →  three sections:
                                              - \$UVENV_HOME/* (global venvs)
                                              - ./.venv, ./venv (local venvs)
                                              - mise ls python  (available Pythons)
                                            Active venv is marked with a green *.

  uvenv remove <name|path>
    →  refuses if the target is the currently-active venv
    →  rm -rf <resolved target>

  uvenv status   → which mise, which uv, which venv (none / uvenv / external)
  uvenv doctor   → coloured PASS/FAIL on deps, paths, rc integration, completions
  uvenv which    → echo \$UVENV_HOME

═══════════════════════════════════════════════════════════════════════════
 ${_UVENV_C_BOLD}Safety rails baked in${_UVENV_C_RESET}
═══════════════════════════════════════════════════════════════════════════

  • \`uvenv install <pkg>\` with NO venv active warns + prompts before
    \`uv pip install --system\` would modify the base mise Python's
    site-packages. Skip the prompt with -y for scripts.

  • \`uvenv tool --python=X.Y install <pkg>\` changes mise's global Python
    only for the duration of the install, and the restore is guaranteed
    by an EXIT trap inside a subshell (covers success, failure, signals).

  • \`uvenv remove <name|path>\` resolves paths before comparing against
    \$VIRTUAL_ENV, so it correctly refuses to delete the currently-active
    venv no matter how it was referenced.

  • \`uvenv create\` refuses if the target name OR path already exists,
    rather than overwriting.

  • The installer atomic-swaps the install dir and keeps the previous
    version at \$UVENV_PREFIX.bak — one-step rollback if anything breaks.

═══════════════════════════════════════════════════════════════════════════
 ${_UVENV_C_BOLD}Bypass commands you can run directly if you ever skip uvenv${_UVENV_C_RESET}
═══════════════════════════════════════════════════════════════════════════

  Python management (mise)
    mise use -g python@X.Y            install + set as global default
    mise current python               which Python is active right now
    mise ls python                    list installed Pythons
    mise exec python@X.Y -- <cmd>     run cmd with that Python

  Venvs and packages (uv)
    uv venv <dir> [--python X.Y]      create a venv
    uv pip install <pkg>              install into active venv
    uv pip install --upgrade <pkg>    upgrade
    uv pip install --system <pkg>     install into the active Python (no venv)
    uv pip list [--outdated]          list (outdated) packages
    uv pip freeze                     dump installed packages

  Standalone tools (uv)
    uv tool install <pkg> [-U ...]    install / upgrade a CLI tool in its own venv
    uv tool upgrade <pkg> | --all     upgrade tools
    uv tool list                      list tools
    uv tool uninstall <pkg>           uninstall

  Hint: every one of those is what uvenv runs underneath. uvenv only adds
        orchestration (mise+uv together), name/path resolution, and the
        safety rails listed above.
EOF
}
