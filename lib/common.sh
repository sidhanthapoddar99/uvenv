# uvenv shared helpers — sourced once by the dispatcher on first call.
# Functions: _uvenv_log, _uvenv__confirm, _uvenv__venv_python,
#            _uvenv__venv_base, _uvenv__active_venv_name,
#            _uvenv__mise_current_python.

_uvenv_log() {
    local level="$1"; shift
    case "$level" in
        error|warn) printf 'uvenv: %s\n' "$*" >&2 ;;
        info)       printf 'uvenv: %s\n' "$*" ;;
        plain)      printf '%s\n' "$*" ;;
        *)          printf 'uvenv: %s\n' "$level $*" ;;
    esac
}

_uvenv__confirm() {
    # _uvenv__confirm "prompt text"  -> 0 = yes, 1 = no
    local ans
    printf '%s [y/N] ' "$1" >&2
    if ! read -r ans; then
        printf '\n' >&2
        return 1
    fi
    case "$ans" in
        y|Y|yes|YES|Yes) return 0 ;;
        *) return 1 ;;
    esac
}

_uvenv__venv_python() {
    # Read python version from a venv's pyvenv.cfg
    local venv="$1"
    [ -f "$venv/pyvenv.cfg" ] || return 1
    grep -E '^version' "$venv/pyvenv.cfg" 2>/dev/null \
        | head -1 | cut -d= -f2 | tr -d ' '
}

_uvenv__venv_base() {
    # Read 'home' from pyvenv.cfg — the base Python's bin/ dir.
    local venv="$1"
    [ -f "$venv/pyvenv.cfg" ] || return 1
    grep -E '^home' "$venv/pyvenv.cfg" 2>/dev/null \
        | head -1 | cut -d= -f2- | sed 's/^ *//'
}

_uvenv__active_venv_name() {
    # If $VIRTUAL_ENV points inside $UVENV_HOME, return its basename.
    [ -z "${VIRTUAL_ENV:-}" ] && return 1
    case "$VIRTUAL_ENV" in
        "$UVENV_HOME"/*) basename "$VIRTUAL_ENV" ;;
        *) return 1 ;;
    esac
}

_uvenv__mise_current_python() {
    # Best-effort: returns the python version mise currently resolves to.
    # May reflect a directory-local override rather than the strict global —
    # documented in the user guide.
    command -v mise >/dev/null 2>&1 || return 1
    mise current python 2>/dev/null
}
