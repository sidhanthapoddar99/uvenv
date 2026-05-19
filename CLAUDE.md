# CLAUDE.md

Notes for AI agents (and humans new to the repo). If you're shipping a change
here, read this first.

## What this project is

`uvenv` is a shell wrapper that gives [mise](https://mise.jdx.dev) +
[uv](https://github.com/astral-sh/uv) one ergonomic affordance neither has on
its own: **named global Python venvs you can activate from anywhere**,
conda-style without conda. It is intentionally small — ~70 lines of dispatcher
plus per-subcommand `lib/*.sh` files.

## Layout

```
uvenv.sh                  thin dispatcher, sourced from .bashrc / .zshrc
install.sh                tarball-based installer; bundled in releases so
                          `uvenv self-update` reuses it
VERSION                   single source of truth for the version string
lib/                      one file per subcommand, lazy-sourced on demand
  common.sh                 shared helpers: log, confirm, colours, helpers
  create.sh / activate.sh / list.sh / ...
completions/              bash + zsh completion scripts, auto-loaded by uvenv.sh
CHANGELOG.md              Keep-a-Changelog formatted; UPDATE THIS ON EVERY BUMP
USER_GUIDE.md             user-facing reference
CONTRIBUTING.md           dev workflow, how to add a subcommand
DESIGN.md                 why uvenv is shaped the way it is
SECURITY.md               disclosure policy
.github/workflows/        ci.yml (shellcheck + smoke on linux+mac+zsh), release.yml
```

## Cross-cutting invariants

- **Stay shell.** `uvenv activate` mutates the parent shell — only a sourced
  shell function can do that. Don't propose a Rust/Go rewrite without a hybrid
  shim plan.
- **bash + zsh both work.** No `declare -F` (means "float var" in zsh —
  see `typeset -f` instead). No unquoted `$pkg` word-splitting (zsh doesn't
  word-split unquoted scalars). Test in both. CI runs `zsh -n` on every lib.
- **Flags-first grammar.** `uvenv tool --python=X.Y install <pkg> [uv args]`.
  uvenv parses uvenv flags only; everything after the action verb is forwarded
  verbatim via `"$@"`. Don't reintroduce string-joined arg accumulators.
- **`mise exec`, not `mise use -g`** for any per-command python pin. `mise use -g`
  inside a subshell suffers from PATH staleness; `mise exec` doesn't.
- **Colours**: honour `NO_COLOR` and `FORCE_COLOR` and fall back to `[ -t 2 ]`.
  Never redirect stderr (`2>/dev/null`) when sourcing `common.sh` — it
  breaks the tty check.

## Release process

**Every release must:**

1. Bump `VERSION` to the new number.
2. **Update `CHANGELOG.md`** with a new `## [X.Y.Z] - YYYY-MM-DD` block,
   grouped under Added / Changed / Fixed / Removed (Keep-a-Changelog style).
   This is non-negotiable — see the changelog policy below.
3. Commit with a release-grade message: header `vX.Y.Z: <one-line summary>`,
   body mirroring the changelog groupings with rationale.
4. Push main, then `git tag -a vX.Y.Z -m "uvenv vX.Y.Z — <summary>"`,
   then `git push origin vX.Y.Z`.
5. CI must be green on `main` (shellcheck + ubuntu + macos smoke).
6. The release workflow (`release.yml`) auto-builds `uvenv-vX.Y.Z.tar.gz`
   and uploads it alongside `install.sh` + `LICENSE` to the GitHub release.
7. Verify the release tarball downloads and extracts before considering the
   release done.

## Changelog policy (please honour this)

The user explicitly asked for proper changelogs on every version bump.
**Treat this as load-bearing.** Concretely:

- `CHANGELOG.md` follows the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
  format. Top entry is the latest release; entries are reverse-chronological;
  each entry has the date and is grouped under Added / Changed / Fixed /
  Removed (only the groups that apply).
- An "Unreleased" section at the top accumulates pending changes between tags.
- Commit messages on `main` mirror the entry structure. No one-line tag
  commits. Rationale goes in the commit body, not the changelog.
- If you bump VERSION without touching CHANGELOG.md, stop and fix the
  changelog before you commit.

### GitHub release notes are auto-generated from CHANGELOG.md

`.github/workflows/release.yml` extracts the `## [<version>]` block from
`CHANGELOG.md` and uses it as the GitHub release body via `gh release create
--notes-file`. So once you've written the changelog entry, the GitHub release
page automatically gets the same content — no separate copy/paste step. If
the extraction finds nothing for a tag (e.g. you forgot the entry), the
workflow falls back to `--generate-notes` and emits a CI warning. Don't rely
on the fallback.

## Common gotchas (real bugs we've hit, don't reintroduce)

- **`declare -F` in zsh**: declares a float variable. Use `typeset -f`.
- **Unquoted `$pkg` for arg passing in zsh**: zsh doesn't word-split. Use
  arrays + `"$@"` passthrough.
- **`mise use -g` in subshell + restore trap**: the subshell's PATH was
  set before the config change. Use `mise exec`.
- **`source file 2>/dev/null`**: breaks `[ -t 2 ]` inside the sourced file
  because fd 2 IS /dev/null during the source. Use `[ -f file ] && . file`.
- **`deactivate` not always defined in inherited-venv shells**: don't call
  it unconditionally. Check `typeset -f deactivate` first, fall back to
  manual cleanup (`unset VIRTUAL_ENV`, strip venv/bin from PATH).
- **mise rebuilds PATH on every prompt** and may drop the venv's bin. On
  shell startup `uvenv.sh` re-prepends `$VIRTUAL_ENV/bin` if missing.
- **shellcheck doesn't speak zsh**: `completions/uvenv.zsh` is excluded
  from the shellcheck job; `zsh -n` in the smoke job covers it. lib files
  need `# shellcheck shell=bash` directive at top.

## Testing locally

```bash
# Run uvenv without installing — points lib/ + completions/ at the repo:
UVENV_PREFIX="$PWD" source ./uvenv.sh
uvenv version

# Reload after edits:
for f in $(typeset -F | awk '/_uvenv_/ {print $3}'); do unset -f "$f"; done
unset -f uvenv
source ./uvenv.sh
```

CI runs `shellcheck`, plus a smoke test on `ubuntu-latest` and `macos-latest`
that exercises the full lifecycle in bash, plus a zsh regression block on
ubuntu. Match those patterns when adding subcommands.

## When making non-trivial changes

- If it's a user-facing change → also touch `USER_GUIDE.md`.
- If it's a contributor-facing change → also touch `CONTRIBUTING.md`.
- If it's a design decision → add a section to `DESIGN.md`.
- If it's a new subcommand → also add help text in `lib/help.sh`, completion
  entries in `completions/uvenv.{bash,zsh}`, and a smoke-test invocation in
  `.github/workflows/ci.yml`.
