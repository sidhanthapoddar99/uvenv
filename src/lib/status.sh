# shellcheck shell=bash
# uvenv status — show mise, uv, and active venv state (coloured headers).

_uvenv_status() {
    printf '%suvenv%s %s\n\n' "$_UVENV_C_BOLD" "$_UVENV_C_RESET" "$UVENV_VERSION"

    printf '%smise%s\n' "$_UVENV_C_BOLD" "$_UVENV_C_RESET"
    if command -v mise >/dev/null 2>&1; then
        printf '  binary:  %s\n' "$(command -v mise)"
        printf '  version: %s\n' "$(mise --version 2>/dev/null | head -1)"
        printf '  python:  %s\n' "$(_uvenv__mise_current_python || echo '(none)')"
    else
        printf '  %s(not on PATH)%s\n' "$_UVENV_C_DIM" "$_UVENV_C_RESET"
    fi
    printf '\n'

    printf '%suv%s\n' "$_UVENV_C_BOLD" "$_UVENV_C_RESET"
    if command -v uv >/dev/null 2>&1; then
        printf '  binary:  %s\n' "$(command -v uv)"
        printf '  version: %s\n' "$(uv --version 2>/dev/null)"
    else
        printf '  %s(not on PATH)%s\n' "$_UVENV_C_DIM" "$_UVENV_C_RESET"
    fi
    printf '\n'

    printf '%sActive venv%s\n' "$_UVENV_C_BOLD" "$_UVENV_C_RESET"
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        local pyver base name
        pyver="$(_uvenv__venv_python "$VIRTUAL_ENV" 2>/dev/null || echo '?')"
        base="$(_uvenv__venv_base   "$VIRTUAL_ENV" 2>/dev/null || echo '?')"
        if name="$(_uvenv__active_venv_name 2>/dev/null)"; then
            printf '  name:    %s%s%s   (uvenv-managed)\n' \
                "${_UVENV_C_BOLD}${_UVENV_C_GREEN}" "$name" "$_UVENV_C_RESET"
        else
            printf '  name:    %s(external venv, not uvenv-managed)%s\n' \
                "$_UVENV_C_DIM" "$_UVENV_C_RESET"
        fi
        printf '  path:    %s\n' "$VIRTUAL_ENV"
        printf '  python:  %s\n' "$pyver"
        printf '  base:    %s\n' "$base"
    else
        printf '  %s(none — installs would target the base mise Python)%s\n' \
            "$_UVENV_C_DIM" "$_UVENV_C_RESET"
    fi
}
