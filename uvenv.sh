#!/usr/bin/env bash
# uvenv — named global Python venvs, backed by mise + uv
# https://github.com/sidhanthapoddar99/uvenv
#
# This file is meant to be SOURCED from your shell rc, not executed:
#   source ~/.config/uvenv/uvenv.sh
#
# Dispatcher only: real work lives in lib/*.sh, lazy-sourced on demand
# so shell startup stays fast no matter how many subcommands exist.

UVENV_HOME="${UVENV_HOME:-$HOME/.uvenv}"
UVENV_PREFIX="${UVENV_PREFIX:-$HOME/.config/uvenv}"
UVENV_LIB="${UVENV_LIB:-$UVENV_PREFIX/lib}"
UVENV_REPO="${UVENV_REPO:-sidhanthapoddar99/uvenv}"

if [ -f "$UVENV_PREFIX/VERSION" ]; then
    UVENV_VERSION="$(cat "$UVENV_PREFIX/VERSION" 2>/dev/null)"
else
    UVENV_VERSION="dev"
fi

uvenv() {
    local cmd="${1:-help}"
    [ $# -gt 0 ] && shift

    # Aliases / flag forms
    case "$cmd" in
        ls)             cmd=list ;;
        rm)             cmd=remove ;;
        where)          cmd=which ;;
        --help|-h)      cmd=help ;;
        --version|-V)   cmd=version ;;
    esac

    # Ensure shared helpers are loaded
    if ! declare -F _uvenv_log >/dev/null 2>&1; then
        # shellcheck disable=SC1090,SC1091
        if ! . "$UVENV_LIB/common.sh" 2>/dev/null; then
            printf 'uvenv: lib not found at %s\n' "$UVENV_LIB" >&2
            printf '       try reinstalling: curl -fsSL https://github.com/%s/releases/latest/download/install.sh | bash\n' "$UVENV_REPO" >&2
            return 1
        fi
    fi

    # Map subcommand -> lib file (some commands share one file)
    local libfile
    case "$cmd" in
        create)              libfile=create ;;
        activate|deactivate) libfile=activate ;;
        list)                libfile=list ;;
        remove)              libfile=remove ;;
        install)             libfile=install_pkg ;;
        which)               libfile=which ;;
        version|help)        libfile=help ;;
        info)                libfile=info ;;
        status)              libfile=status ;;
        set)                 libfile=set ;;
        tool)                libfile=tool ;;
        update|self-update)  libfile=update ;;
        completions)         libfile=completions ;;
        exec)                libfile=exec ;;
        freeze)              libfile=freeze ;;
        doctor)              libfile=doctor ;;
        *)
            _uvenv_log error "unknown command '$cmd'. Try: uvenv help"
            return 1
            ;;
    esac

    # Function name = _uvenv_<cmd> with dashes -> underscores (self-update)
    local fn="_uvenv_${cmd//-/_}"
    if ! declare -F "$fn" >/dev/null 2>&1; then
        # shellcheck disable=SC1090
        if ! . "$UVENV_LIB/${libfile}.sh" 2>/dev/null; then
            _uvenv_log error "lib missing: $UVENV_LIB/${libfile}.sh"
            return 1
        fi
    fi
    "$fn" "$@"
}
