# uvenv shared helpers — sourced once by the dispatcher on first call.
# Functions: _uvenv_log, _uvenv__confirm, _uvenv__venv_python,
#            _uvenv__venv_base, _uvenv__active_venv_name,
#            _uvenv__mise_current_python.

# ───── color setup ─────
# Honour the NO_COLOR (https://no-color.org) and FORCE_COLOR conventions, then
# fall back to a tty check on stderr. Set once at load time. _UVENV_C_* are
# empty strings when colors are off, so callers can interpolate them
# unconditionally without sprinkling conditionals.
if [ -n "${NO_COLOR:-}" ]; then
    _uvenv__use_color=0
elif [ -n "${FORCE_COLOR:-}" ]; then
    _uvenv__use_color=1
elif [ -t 2 ]; then
    _uvenv__use_color=1
else
    _uvenv__use_color=0
fi

if [ "$_uvenv__use_color" -eq 1 ]; then
    _UVENV_C_RED=$'\033[31m'
    _UVENV_C_GREEN=$'\033[32m'
    _UVENV_C_YELLOW=$'\033[33m'
    _UVENV_C_CYAN=$'\033[36m'
    _UVENV_C_BOLD=$'\033[1m'
    _UVENV_C_DIM=$'\033[2m'
    _UVENV_C_RESET=$'\033[0m'
else
    _UVENV_C_RED=''
    _UVENV_C_GREEN=''
    _UVENV_C_YELLOW=''
    _UVENV_C_CYAN=''
    _UVENV_C_BOLD=''
    _UVENV_C_DIM=''
    _UVENV_C_RESET=''
fi

_uvenv_log() {
    local level="$1"; shift
    case "$level" in
        error)
            printf '%suvenv: error:%s %s\n' \
                "${_UVENV_C_BOLD}${_UVENV_C_RED}" "${_UVENV_C_RESET}" "$*" >&2
            ;;
        warn)
            printf '%suvenv: warn:%s %s\n' \
                "${_UVENV_C_BOLD}${_UVENV_C_YELLOW}" "${_UVENV_C_RESET}" "$*" >&2
            ;;
        success)
            printf '%suvenv:%s %s\n' \
                "${_UVENV_C_BOLD}${_UVENV_C_GREEN}" "${_UVENV_C_RESET}" "$*"
            ;;
        info)
            printf '%suvenv:%s %s\n' \
                "${_UVENV_C_DIM}" "${_UVENV_C_RESET}" "$*"
            ;;
        plain)
            printf '%s\n' "$*"
            ;;
        *)
            printf 'uvenv: %s %s\n' "$level" "$*"
            ;;
    esac
}

_uvenv__confirm() {
    # _uvenv__confirm "prompt text"  -> 0 = yes, 1 = no
    local ans
    printf '%s%s [y/N]%s ' "${_UVENV_C_BOLD}" "$1" "${_UVENV_C_RESET}" >&2
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
    command -v mise >/dev/null 2>&1 || return 1
    mise current python 2>/dev/null
}

_uvenv__abspath() {
    # Echo the resolved absolute path of a directory, or empty.
    [ -z "${1:-}" ] && return 1
    [ -d "$1" ] || return 1
    (cd "$1" 2>/dev/null && pwd)
}
