## What does this change?

<!-- One or two sentences. The "why" matters more than the "what" — the diff
     shows the what. -->

## Scope check

uvenv aims to stay small. If you're adding a new subcommand, please confirm:

- [ ] It's a thin wrapper over `mise` / `uv` and not a re-implementation
- [ ] It has a dedicated `lib/<cmd>.sh` (not a bolt-on inside the dispatcher)
- [ ] Help text in `lib/help.sh` updated
- [ ] Bash + zsh completions updated
- [ ] `USER_GUIDE.md` has a section for it
- [ ] CI smoke test in `.github/workflows/ci.yml` exercises it

If it's a bug fix:

- [ ] Repro added to CI (or explained why not possible)

## Tested where?

- [ ] Linux
- [ ] macOS
- [ ] WSL2
