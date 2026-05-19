# shellcheck shell=bash
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

# _UVENV_C_* are referenced by lib/*.sh files via $-interpolation; shellcheck
# can't see across sourced files.
# shellcheck disable=SC2034
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

_uvenv__confirm_python_use() {
    # Show a confirmation block before a python-pinning operation.
    #
    # Args:
    #   $1 = kind        e.g. "Create global env", "Create local venv", "Install uv tool"
    #   $2 = subject     e.g. "ml", "./venv", "dstack"
    #   $3 = pyver       requested python version (empty = "use mise's current")
    #   $4 = force       "1" to skip the prompt (still prints the block)
    #
    # Returns 0 to proceed, 1 to abort.
    # Renders python version in yellow; mismatch banner (active venv on a
    # different X.Y) in red. Default answer is Y normally, N on mismatch.
    local kind="$1" subject="$2" pyver="$3" force="${4:-0}"

    # 1. Resolve which python this operation will actually use.
    local effective_ver source_label
    if [ -n "$pyver" ]; then
        effective_ver="$pyver"
        source_label="(--python=$pyver)"
    else
        effective_ver="$(_uvenv__mise_current_python 2>/dev/null || echo unknown)"
        source_label="(mise's current)"
    fi

    # 2. Resolve the python install path via mise (best-effort).
    local install_path=""
    if [ "$effective_ver" != "unknown" ] && command -v mise >/dev/null 2>&1; then
        local mise_root
        mise_root="$(mise where "python@$effective_ver" 2>/dev/null || true)"
        [ -n "$mise_root" ] && install_path="$mise_root/bin/python"
    fi

    # 3. Render the header + python line.
    printf '\n%s%s: %s%s\n' "$_UVENV_C_BOLD" "$kind" "$subject" "$_UVENV_C_RESET"
    printf '  python:  %s%s%s  %s%s%s\n' \
        "$_UVENV_C_YELLOW" "$effective_ver" "$_UVENV_C_RESET" \
        "$_UVENV_C_DIM" "$source_label" "$_UVENV_C_RESET"
    [ -n "$install_path" ] && printf '  source:  %s%s%s\n' \
        "$_UVENV_C_DIM" "$install_path" "$_UVENV_C_RESET"

    # 4. Detect mismatch against active venv (compare X.Y only — patch differences
    #    are common between mise pythons and venv pyvenv.cfg versions).
    local has_mismatch=0
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        local venv_ver venv_name
        venv_ver="$(_uvenv__venv_python "$VIRTUAL_ENV" 2>/dev/null || true)"
        venv_name="$(basename "$VIRTUAL_ENV")"
        if [ -n "$venv_ver" ]; then
            local effective_xy venv_xy
            effective_xy="${effective_ver%%.*}.$(printf '%s\n' "$effective_ver" | cut -d. -f2)"
            venv_xy="${venv_ver%%.*}.$(printf '%s\n' "$venv_ver" | cut -d. -f2)"
            if [ "$effective_xy" != "$venv_xy" ]; then
                has_mismatch=1
                printf '\n  %s⚠ Active venv '\''%s'\'' is on python %s — mismatch.%s\n' \
                    "${_UVENV_C_BOLD}${_UVENV_C_RED}" "$venv_name" "$venv_ver" "$_UVENV_C_RESET"
                printf '  %sPass --python=%s if you meant to match it.%s\n' \
                    "$_UVENV_C_DIM" "$venv_xy" "$_UVENV_C_RESET"
            fi
        fi
    fi

    # 5. Skip prompt on -y.
    if [ "$force" = "1" ]; then
        printf '\n'
        return 0
    fi

    # 6. Prompt. Default Y on no mismatch, N on mismatch.
    local prompt_label default_yes
    if [ "$has_mismatch" -eq 1 ]; then
        prompt_label="[y/N]"
        default_yes=0
    else
        prompt_label="[Y/n]"
        default_yes=1
    fi

    printf '\nContinue? %s%s%s ' "$_UVENV_C_BOLD" "$prompt_label" "$_UVENV_C_RESET" >&2
    local ans
    if ! read -r ans; then
        printf '\n' >&2
        return 1
    fi

    case "$ans" in
        y|Y|yes|YES|Yes) return 0 ;;
        n|N|no|NO|No)    return 1 ;;
        "")
            [ "$default_yes" -eq 1 ] && return 0
            return 1
            ;;
        *) return 1 ;;
    esac
}
