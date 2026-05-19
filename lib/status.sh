# uvenv status — show mise, uv, and active venv state

_uvenv_status() {
    printf 'uvenv %s\n' "$UVENV_VERSION"
    printf '\n'

    printf 'mise\n'
    if command -v mise >/dev/null 2>&1; then
        printf '  binary:  %s\n' "$(command -v mise)"
        printf '  version: %s\n' "$(mise --version 2>/dev/null | head -1)"
        printf '  python:  %s\n' "$(_uvenv__mise_current_python || echo '(none)')"
    else
        printf '  (not on PATH)\n'
    fi
    printf '\n'

    printf 'uv\n'
    if command -v uv >/dev/null 2>&1; then
        printf '  binary:  %s\n' "$(command -v uv)"
        printf '  version: %s\n' "$(uv --version 2>/dev/null)"
    else
        printf '  (not on PATH)\n'
    fi
    printf '\n'

    printf 'Active venv\n'
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        local pyver base name
        pyver="$(_uvenv__venv_python "$VIRTUAL_ENV" 2>/dev/null || echo '?')"
        base="$(_uvenv__venv_base   "$VIRTUAL_ENV" 2>/dev/null || echo '?')"
        if name="$(_uvenv__active_venv_name 2>/dev/null)"; then
            printf '  name:    %s   (uvenv-managed)\n' "$name"
        else
            printf '  name:    (external venv, not uvenv-managed)\n'
        fi
        printf '  path:    %s\n' "$VIRTUAL_ENV"
        printf '  python:  %s\n' "$pyver"
        printf '  base:    %s\n' "$base"
    else
        printf '  (none — installs would target the base mise Python)\n'
    fi
}
