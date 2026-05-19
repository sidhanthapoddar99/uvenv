# shellcheck shell=bash
# uvenv activate <name|path>   — activates a named global env OR a local path
# uvenv deactivate             — robust: guarantees $VIRTUAL_ENV is unset on return
#
# Resolution order for activate:
#   1. $UVENV_HOME/<arg>/bin/activate    (named global env)
#   2. <arg>/bin/activate                (path, relative or absolute)
# Explicit "./foo" or "/abs/foo" effectively skips the name lookup because
# $UVENV_HOME/./foo doesn't exist.

_uvenv_activate() {
    local arg="${1:-}"
    if [ -z "$arg" ]; then
        _uvenv_log error "usage: uvenv activate <name>     # global env in \$UVENV_HOME"
        _uvenv_log error "       uvenv activate <path>     # e.g. ./venv"
        return 1
    fi

    local target script label
    if [ -f "$UVENV_HOME/$arg/bin/activate" ]; then
        target="$UVENV_HOME/$arg"
        label="'$arg'"
    elif [ -f "$arg/bin/activate" ]; then
        target="$arg"
        label="venv at $arg"
    else
        _uvenv_log error "'$arg' is not a uvenv name (in $UVENV_HOME) or a venv path"
        _uvenv_log error "       uvenv list  — to see available envs"
        return 1
    fi

    script="$target/bin/activate"
    # shellcheck disable=SC1090
    . "$script"
    _uvenv_log success "activated $label"
}

_uvenv_deactivate() {
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        _uvenv_log error "no venv currently active"
        return 1
    fi

    local was="$VIRTUAL_ENV"

    # Clean path: call the venv's deactivate function if it's defined.
    # This handles PS1 / PYTHONHOME / hash properly via venv-provided logic.
    if typeset -f deactivate >/dev/null 2>&1; then
        deactivate 2>/dev/null || true
    fi

    # Defensive cleanup. Runs unconditionally if VIRTUAL_ENV is still set
    # (i.e. the venv's deactivate function was missing or failed). This is
    # the contract: after this function returns success, $VIRTUAL_ENV is
    # always unset and $PATH no longer contains the venv's bin/.
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        local venv_bin="$was/bin"
        # Strip every PATH entry that exactly equals $venv_bin.
        PATH="$(printf '%s' "$PATH" | awk -v RS=: -v ORS=: -v bad="$venv_bin" '$0 != bad' | sed 's/:$//')"
        export PATH
        unset VIRTUAL_ENV
        if [ -n "${_OLD_VIRTUAL_PS1:-}" ]; then
            PS1="$_OLD_VIRTUAL_PS1"
            unset _OLD_VIRTUAL_PS1
        fi
        if [ -n "${_OLD_VIRTUAL_PYTHONHOME:-}" ]; then
            export PYTHONHOME="$_OLD_VIRTUAL_PYTHONHOME"
            unset _OLD_VIRTUAL_PYTHONHOME
        fi
        hash -r 2>/dev/null || true
    fi

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        _uvenv_log error "could not fully deactivate (\$VIRTUAL_ENV still set: $VIRTUAL_ENV)"
        return 1
    fi
    _uvenv_log success "deactivated"
}
