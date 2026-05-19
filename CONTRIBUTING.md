# Contributing to uvenv

Thanks for the interest. uvenv is intentionally small — a shell wrapper over
`mise` + `uv`, no more — and contributions that keep it that way are very
welcome.

## Project goals (please honor these)

1. **Stay shell.** `uvenv activate` mutates the calling shell, which a binary
   can't do. We stay bash/zsh-compatible, sourced from rc files.
2. **Stay small.** The dispatcher is ~60 lines; each subcommand lives in its
   own `lib/<cmd>.sh` file and should typically be under 100 lines. If a
   feature needs more, propose splitting it first.
3. **Don't reinvent.** mise picks Pythons. uv creates venvs and installs
   packages. uvenv only orchestrates. If you find yourself reimplementing
   something mise or uv already does, stop and reach for theirs.

## Repository layout

```
uvenv.sh                  # dispatcher (sourced into user shells)
install.sh                # installer (bundled in tarball; reused by self-update)
VERSION                   # single source of truth for the version string
lib/                      # one file per subcommand, lazy-sourced on demand
  common.sh                 #   shared helpers (logging, confirm, pyvenv.cfg)
  create.sh / activate.sh / list.sh / ...
completions/              # bash + zsh completion scripts
  uvenv.bash
  uvenv.zsh
USER_GUIDE.md             # top-level user docs
.github/workflows/
  ci.yml                    # shellcheck + smoke tests
  release.yml               # builds tarball, uploads release assets
```

## Local dev setup

```bash
git clone https://github.com/sidhanthapoddar99/uvenv.git
cd uvenv
```

Run uvenv from the checkout without installing:

```bash
UVENV_PREFIX="$PWD" source ./uvenv.sh
uvenv version       # should print "uvenv 0.X.Y"
```

Setting `UVENV_PREFIX` to the repo root lets the dispatcher find `lib/` and
`completions/` in place.

Re-run after every edit:

```bash
unset -f uvenv      # forget the cached function
# also forget any cached subcommand functions so they re-source
for f in $(declare -F | awk '/_uvenv_/ {print $3}'); do unset -f "$f"; done
source ./uvenv.sh
```

## Adding a new subcommand

1. Create `lib/<cmd>.sh` with a function `_uvenv_<cmd>` (and any internal
   helpers prefixed `_uvenv__`).
2. Register the command in `uvenv.sh`'s dispatcher case statement.
3. Add a usage line in `lib/help.sh`.
4. Add completion entries in `completions/uvenv.bash` and `completions/uvenv.zsh`.
5. Add a section in `USER_GUIDE.md`.
6. Add a smoke-test invocation in `.github/workflows/ci.yml`.

Example skeleton:

```bash
# lib/example.sh

_uvenv_example() {
    local arg="${1:-}"
    if [ -z "$arg" ]; then
        _uvenv_log error "usage: uvenv example <arg>"
        return 1
    fi
    _uvenv_log info "running example with $arg"
}
```

Then in `uvenv.sh`:

```bash
example) libfile=example ;;
```

## Style

- POSIX-ish bash; no zsh-only constructs in `lib/*.sh` (completions can be
  shell-specific).
- Use `_uvenv_log error|warn|info` for user-facing output. Avoid raw `echo`.
- Use `_uvenv__confirm` for yes/no prompts.
- Prefer shell builtins to external commands (see the README discussion on
  shell performance — the cost is forks, not file size).
- Single-line comments only; no decorative banners. The "why" should land in
  the PR description, not the file.

## Testing

Local:

```bash
shellcheck uvenv.sh install.sh lib/*.sh
```

CI runs shellcheck and a smoke test that exercises create / activate / install
/ deactivate / remove. PRs adding new subcommands should add a smoke call too.

## Releases (maintainers)

1. Bump `VERSION` (e.g. `0.2.0` → `0.2.1`).
2. Commit + push.
3. Tag: `git tag v0.2.1 && git push --tags`.
4. The `release.yml` workflow builds `uvenv-v0.2.1.tar.gz` and uploads it
   alongside `install.sh` to the GitHub release.

The `VERSION` file is the source of truth; CI warns if `VERSION` and the tag
disagree.

## License

MIT — by contributing you agree your changes ship under the same license.
