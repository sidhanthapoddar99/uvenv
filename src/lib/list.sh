# shellcheck shell=bash
# uvenv list — three sections:
#   1. Global venvs (under $UVENV_HOME)
#   2. Local venvs (./.venv or ./venv in cwd)
#   3. Available mise Pythons
# Active venv is marked with a coloured `*` in either section, or shown
# in a "Active venv (elsewhere)" footer if it lives outside both.

_uvenv_list() {
    _uvenv__list_global_venvs
    printf '\n'
    _uvenv__list_local_venvs
    printf '\n'
    _uvenv__list_mise_pythons
    _uvenv__list_active_elsewhere
}

_uvenv__active_marker() {
    # echoes a green '*' (or plain '*') if $1 matches $VIRTUAL_ENV, else ' '
    local d="$1"
    if [ -n "${VIRTUAL_ENV:-}" ] && [ "$d" = "$VIRTUAL_ENV" ]; then
        printf '%s*%s' "${_UVENV_C_BOLD}${_UVENV_C_GREEN}" "${_UVENV_C_RESET}"
    else
        printf ' '
    fi
}

_uvenv__list_global_venvs() {
    printf '%sGlobal venvs%s (%s)\n' \
        "$_UVENV_C_BOLD" "$_UVENV_C_RESET" "$UVENV_HOME"
    if [ ! -d "$UVENV_HOME" ] || [ -z "$(ls -A "$UVENV_HOME" 2>/dev/null)" ]; then
        printf '  %s(none — create with: uvenv create -n <name>)%s\n' \
            "$_UVENV_C_DIM" "$_UVENV_C_RESET"
        return 0
    fi
    printf '  %s %-20s %-10s %s\n' " " "NAME" "PYTHON" "BASE"
    local d name pyver base marker
    for d in "$UVENV_HOME"/*/; do
        [ -d "$d" ] || continue
        d="${d%/}"
        name="$(basename "$d")"
        pyver="$(_uvenv__venv_python "$d" 2>/dev/null || echo '?')"
        base="$(_uvenv__venv_base   "$d" 2>/dev/null || echo '?')"
        marker="$(_uvenv__active_marker "$d")"
        printf '  %s %-20s %-10s %s\n' "$marker" "$name" "$pyver" "$base"
    done
}

_uvenv__list_local_venvs() {
    printf '%sLocal venvs%s (%s)\n' \
        "$_UVENV_C_BOLD" "$_UVENV_C_RESET" "$PWD"
    local found=0 d pyver path marker
    for d in .venv venv; do
        if [ -d "$d" ] && [ -f "$d/pyvenv.cfg" ]; then
            pyver="$(_uvenv__venv_python "$d" 2>/dev/null || echo '?')"
            path="$(_uvenv__abspath "$d" || true)"
            marker="$(_uvenv__active_marker "${path:-$PWD/$d}")"
            printf '  %s %-10s python %-10s %s\n' \
                "$marker" "$d" "$pyver" "${path:-$PWD/$d}"
            found=1
        fi
    done
    [ "$found" -eq 0 ] && printf '  %s(none here)%s\n' "$_UVENV_C_DIM" "$_UVENV_C_RESET"
}

_uvenv__list_mise_pythons() {
    printf '%sAvailable mise pythons%s\n' "$_UVENV_C_BOLD" "$_UVENV_C_RESET"
    if ! command -v mise >/dev/null 2>&1; then
        printf '  %s(mise not on PATH)%s\n' "$_UVENV_C_DIM" "$_UVENV_C_RESET"
        return 0
    fi
    local out
    out="$(mise ls python 2>/dev/null)"
    if [ -z "$out" ]; then
        printf '  %s(none installed — try: uvenv set --python=3.13)%s\n' \
            "$_UVENV_C_DIM" "$_UVENV_C_RESET"
    else
        printf '%s\n' "$out" | sed 's/^/  /'
    fi
}

_uvenv__list_active_elsewhere() {
    # If a venv is active but it didn't get marked anywhere above, surface it.
    [ -z "${VIRTUAL_ENV:-}" ] && return 0

    # In $UVENV_HOME?  already marked.
    case "$VIRTUAL_ENV" in
        "$UVENV_HOME"/*) return 0 ;;
    esac

    # Listed local venv? compare resolved abs paths.
    local venv_abs d local_abs
    venv_abs="$(_uvenv__abspath "$VIRTUAL_ENV" || echo "$VIRTUAL_ENV")"
    for d in .venv venv; do
        if [ -d "$d" ] && [ -f "$d/pyvenv.cfg" ]; then
            local_abs="$(_uvenv__abspath "$d" || true)"
            [ -n "$local_abs" ] && [ "$local_abs" = "$venv_abs" ] && return 0
        fi
    done

    printf '\n%sActive venv (outside the listed sections)%s\n' \
        "$_UVENV_C_BOLD" "$_UVENV_C_RESET"
    printf '  %s*%s %s\n' \
        "${_UVENV_C_BOLD}${_UVENV_C_GREEN}" "$_UVENV_C_RESET" "$VIRTUAL_ENV"
}
