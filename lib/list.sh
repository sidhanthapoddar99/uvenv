# uvenv list — three sections:
#   1. Global venvs (under $UVENV_HOME)
#   2. Local venvs (./.venv or ./venv in cwd)
#   3. Available mise Pythons

_uvenv_list() {
    _uvenv__list_global_venvs
    printf '\n'
    _uvenv__list_local_venvs
    printf '\n'
    _uvenv__list_mise_pythons
}

_uvenv__list_global_venvs() {
    printf 'Global venvs (%s)\n' "$UVENV_HOME"
    if [ ! -d "$UVENV_HOME" ] || [ -z "$(ls -A "$UVENV_HOME" 2>/dev/null)" ]; then
        printf '  (none — create with: uvenv create -n <name>)\n'
        return 0
    fi
    printf '  %s %-20s %-10s %s\n' " " "NAME" "PYTHON" "BASE"
    local d name pyver base active
    for d in "$UVENV_HOME"/*/; do
        [ -d "$d" ] || continue
        d="${d%/}"
        name="$(basename "$d")"
        pyver="$(_uvenv__venv_python "$d" 2>/dev/null || echo '?')"
        base="$(_uvenv__venv_base   "$d" 2>/dev/null || echo '?')"
        if [ "$d" = "${VIRTUAL_ENV:-}" ]; then active='*'; else active=' '; fi
        printf '  %s %-20s %-10s %s\n' "$active" "$name" "$pyver" "$base"
    done
}

_uvenv__list_local_venvs() {
    printf 'Local venvs (%s)\n' "$PWD"
    local found=0 d pyver path
    for d in .venv venv; do
        if [ -d "$d" ] && [ -f "$d/pyvenv.cfg" ]; then
            pyver="$(_uvenv__venv_python "$d" 2>/dev/null || echo '?')"
            path="$(cd "$d" 2>/dev/null && pwd)"
            printf '    %-10s python %-10s %s\n' "$d" "$pyver" "${path:-$PWD/$d}"
            found=1
        fi
    done
    [ "$found" -eq 0 ] && printf '  (none here)\n'
}

_uvenv__list_mise_pythons() {
    printf 'Available mise pythons\n'
    if ! command -v mise >/dev/null 2>&1; then
        printf '  (mise not on PATH)\n'
        return 0
    fi
    local out
    out="$(mise ls python 2>/dev/null)"
    if [ -z "$out" ]; then
        printf '  (none installed — try: uvenv set --python 3.13)\n'
    else
        printf '%s\n' "$out" | sed 's/^/  /'
    fi
}
