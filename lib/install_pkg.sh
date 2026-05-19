# shellcheck shell=bash
# uvenv install [-y] [--] <pkg ...>
#
# Grammar: uvenv flags first, then optional `--`, then everything passes
# verbatim to `uv pip install`. Refuses to install into the base mise
# Python without an explicit -y / --yes.

_uvenv_install() {
    local force=0
    while [ $# -gt 0 ]; do
        case "$1" in
            -y|--yes) force=1; shift ;;
            --) shift; break ;;
            -h|--help)
                _uvenv_log plain "usage: uvenv install [-y] [--] <pkg> [uv flags...]"
                return 0
                ;;
            *) break ;;   # First non-uvenv-flag — start of passthrough.
        esac
    done

    if [ $# -eq 0 ]; then
        _uvenv_log error "usage: uvenv install [-y] [--] <pkg> [uv flags...]"
        return 1
    fi

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        uv pip install "$@"
        return $?
    fi

    # No venv active — install would target the base mise Python.
    local current
    current="$(_uvenv__mise_current_python || echo unknown)"
    _uvenv_log warn "no venv active — install will target the base mise Python ($current)"
    _uvenv_log warn "this writes to the global Python's site-packages."
    if [ "$force" -ne 1 ]; then
        _uvenv__confirm "Continue with --system install?" \
            || { _uvenv_log info "aborted"; return 1; }
    fi
    uv pip install --system "$@"
}
