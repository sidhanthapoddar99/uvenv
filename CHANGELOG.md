# Changelog

All notable changes to uvenv are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.6] - 2026-05-19

### Fixed

- Colours never actually appeared since v0.2.3. The dispatcher sourced
  `lib/common.sh` with a trailing `2>/dev/null` (intended to swallow a missing
  lib), which made the `[ -t 2 ]` tty check inside `common.sh` see fd 2 pointing
  at `/dev/null` instead of the terminal. The colour vars got set to empty
  strings and stayed that way for the whole shell session. Replaced the
  redirect-based fallback with a `[ -f "$file" ]` existence check before
  sourcing — same lib-missing behaviour, no stderr clobber. Same change
  applied to the per-subcommand lib-source path defensively.

## [0.2.5] - 2026-05-19

### Fixed

- Child shells (e.g. typing `zsh` while a venv was active) ended up in an
  inconsistent state: `$VIRTUAL_ENV` was inherited from the parent so the
  prompt still showed the venv name, but `$PATH` had been rebuilt by mise's
  activate hook in the child shell — dropping the venv's `bin/` and making
  `python` resolve to mise's instead of the venv's. `uvenv.sh` now detects
  this on source and re-prepends `$VIRTUAL_ENV/bin` to `$PATH`. If the venv
  directory no longer exists (deleted in another shell), `$VIRTUAL_ENV` is
  unset instead, clearing stale prompt state.

### Added

- CI regressions for both the inherited-venv PATH consistency case and the
  stale-`$VIRTUAL_ENV` cleanup case.
- USER_GUIDE Troubleshooting entry "Child shell has venv name but wrong python".

## [0.2.4] - 2026-05-19

### Added

- **Always-on confirmation prompt** for `uvenv create` and `uvenv tool install`.
  Prints which python will actually be used (in yellow) with its install path
  before doing anything. If `$VIRTUAL_ENV` is set and on a different X.Y than
  the python we'd use, a red mismatch banner appears with a hint to pass
  `--python=<active>`. Default answer flips to N on mismatch. `-y` / `--yes`
  bypasses the prompt; the info block still prints for log visibility.
- Shared helper `_uvenv__confirm_python_use` in `lib/common.sh` used by
  create -n / create -l / tool install.

### Changed

- `uvenv tool --python=X.Y install` now uses
  `mise exec python@X.Y -- uv tool install --python X.Y` to pin the python.
  Replaces the previous "mutate mise global + restore on EXIT trap"
  subshell pattern, which suffered from PATH staleness (the subshell's
  PATH was captured before the global config change took effect).
- `uvenv create` likewise goes through `mise exec` so the python in the
  confirmation block is provably the one used. No global mise mutation.

### Fixed

- **`uvenv tool --python=X.Y install` no longer lands on the wrong python.**
  Previously, asking for 3.13 would frequently install against mise's
  currently-active python (e.g. 3.14) because the subshell's PATH never
  refreshed after the global mise change. Now pinned via `mise exec`.
- **`uvenv deactivate` always clears `$VIRTUAL_ENV`.** Previously called the
  venv-provided `deactivate` function unconditionally and printed "deactivated"
  even when the function was missing (e.g. in inherited-venv shells). Now
  checks `typeset -f deactivate` first and falls back to manual cleanup
  (`unset VIRTUAL_ENV`, strip `$venv/bin` from `$PATH`, restore
  `_OLD_VIRTUAL_PS1` / export `_OLD_VIRTUAL_PYTHONHOME`, `hash -r`). Returns
  non-zero only if `$VIRTUAL_ENV` is still set after both paths run.

### Removed

- The subshell + EXIT-trap restore dance in `lib/tool.sh`. No longer needed.

## [0.2.3] - 2026-05-19

### Added

- **Flags-first grammar** (hard cut). `uvenv <subcommand> [uvenv-flags]
  <action> [verbatim args]` — same convention as `git`, `docker`, `kubectl`.
  uvenv parses its own flags; everything after the action verb is forwarded
  verbatim via `"$@"` to the underlying tool. The GNU `--` end-of-flags
  marker is honoured (`uvenv install -- numpy --pre`).
- Coloured output. Errors red, warnings yellow, successes green, info dim.
  Honours `NO_COLOR`, `FORCE_COLOR`, falls back to `[ -t 2 ]`.
- Bash + zsh tab completion auto-loaded by `uvenv.sh` when sourced. No more
  manual `eval "$(uvenv completions …)"` step. `uvenv doctor` now checks
  whether the completion function actually registered.
- Grammar diagram in `uvenv help`, `uvenv info`, README, USER_GUIDE,
  DESIGN.md.
- `uvenv list` marks active local venvs with a green `*` and adds an
  "Active venv (outside listed sections)" footer when the active venv
  is somewhere else.

### Changed

- `uvenv set / create / tool` no longer call `mise install python@X.Y`
  ahead of `mise use -g` / `mise exec`. Those commands auto-install on
  demand, so the extra call only added the noisy
  "installed but not activated" warning.

### Fixed

- zsh: `-U` (and any flag) passed to `uvenv tool install` would be mashed
  into the package name because the old parser accumulated positional args
  into a single space-joined string and relied on bash's unquoted
  word-splitting (which zsh doesn't do by default). Fixed by switching to
  verbatim `"$@"` passthrough under the new grammar.

## [0.2.2] - 2026-05-19

### Fixed

- zsh: `uvenv --help` (and any subcommand call) printed
  `zsh: command not found: _uvenv_help`. Root cause: the dispatcher used
  `declare -F <name>` to test "does this function exist?", but in zsh
  `declare -F` means "declare a floating-point variable" — it silently
  created a float variable and returned 0, so the dispatcher skipped
  sourcing the lib file and then tried to call the now-variable as a
  command. Replaced both call sites with `typeset -f`, which means
  "function definition" in both shells.
- CI: added an ubuntu-only zsh regression job that exercises the full
  lifecycle and asserts `uvenv --help` works under zsh.

## [0.2.1] - 2026-05-19

### Added

- New subcommands:
  - `uvenv exec <name|path> -- <cmd>...` — run a command in an env without
    activating in this shell.
  - `uvenv freeze [<name|path>]` — `uv pip freeze` for the active or named env.
  - `uvenv doctor` — PASS/FAIL sanity check of deps + install + rc integration.
  - `uvenv tool upgrade <pkg> | --all` — wraps `uv tool upgrade`.
- `SECURITY.md`, `.github/ISSUE_TEMPLATE/{bug,feature,config}`,
  `.github/PULL_REQUEST_TEMPLATE.md` — first-class GitHub community files.
- `DESIGN.md` — extracted from the README. Why-it-works-this-way notes.
- macOS smoke test in CI alongside ubuntu (no Windows native — uvenv requires
  bash/zsh).
- VHS `.tape` files in `demo/` for a 30-second tour and a side-by-side
  comparison with conda. Generated GIFs are not committed.

### Changed

- README slimmed to quick-start + install + 5-line tour; links out to
  USER_GUIDE / CONTRIBUTING / DESIGN / SECURITY.
- `uvenv info` rewritten as a detailed translation map (uvenv → mise/uv
  call), with explicit safety-rail callouts.

## [0.2.0] - 2026-05-19

### Added

- **Modular refactor.** `uvenv.sh` becomes a thin (~70-line) dispatcher that
  lazy-sources `lib/<cmd>.sh` on first use, caching across the shell session.
  Shell startup cost stays flat as the command surface grows.
- 8 new subcommands:
  - `uvenv info` — cheat sheet of underlying mise + uv commands
  - `uvenv tool install/uninstall/list [--python X.Y]`
  - `uvenv list` enhanced — global venvs, local venvs in cwd, available mise pythons
  - `uvenv set --python X.Y`
  - `uvenv status`
  - `uvenv update <pkg>... | --all | --self`
  - `uvenv install -y` flag for unattended use
  - `uvenv completions {bash|zsh}`
- Bash + zsh completion scripts.
- `docs/USER_GUIDE.md` and `CONTRIBUTING.md`.
- `uvenv create -l <path>` for local (non-`$UVENV_HOME`) venvs.
- `uvenv activate` and `uvenv remove` accept either a name or a path.

### Changed

- Installer rewritten for tarball-based delivery. Atomic swap of the install
  dir with a `.bak` for rollback. `install.sh` is bundled inside the release
  tarball so `uvenv self-update` reuses it.
- `VERSION` file becomes the single source of truth, read at runtime by
  `uvenv.sh`.

## [0.1.0] - 2026-05-18

### Added

- Initial release. `uvenv create / activate / deactivate / list / remove /
  install / which / version / help` as a single ~150-line shell function.
- `install.sh` that fetches a single `uvenv.sh` from the latest GitHub release
  and adds a `source` line to the user's rc file.
- CI with shellcheck + a basic smoke test.

[0.2.6]: https://github.com/sidhanthapoddar99/uvenv/releases/tag/v0.2.6
[0.2.5]: https://github.com/sidhanthapoddar99/uvenv/releases/tag/v0.2.5
[0.2.4]: https://github.com/sidhanthapoddar99/uvenv/releases/tag/v0.2.4
[0.2.3]: https://github.com/sidhanthapoddar99/uvenv/releases/tag/v0.2.3
[0.2.2]: https://github.com/sidhanthapoddar99/uvenv/releases/tag/v0.2.2
[0.2.1]: https://github.com/sidhanthapoddar99/uvenv/releases/tag/v0.2.1
[0.2.0]: https://github.com/sidhanthapoddar99/uvenv/releases/tag/v0.2.0
[0.1.0]: https://github.com/sidhanthapoddar99/uvenv/releases/tag/v0.1.0
