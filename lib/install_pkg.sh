# uvenv install [-y] <pkg>...
# Refuses to install into the base mise Python without confirmation.

_uvenv_install() {
    local force=0
    local args=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -y|--yes) force=1; shift ;;
            *) args+=("$1"); shift ;;
        esac
    done

    if [ ${#args[@]} -eq 0 ]; then
        _uvenv_log error "usage: uvenv install [-y] <pkg> [<pkg>...]"
        return 1
    fi

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        uv pip install "${args[@]}"
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
    uv pip install --system "${args[@]}"
}
