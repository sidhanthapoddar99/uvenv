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

# UVENV_VERSION is consumed by lib/help.sh, lib/info.sh, lib/doctor.sh.
# Sourced files share scope; shellcheck can't see across files.
# shellcheck disable=SC2034
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

    # Ensure shared helpers are loaded.
    # `typeset -f <name>` works in both bash and zsh ("does this function
    # exist?"). NB: do NOT use `declare -F` — in zsh that means "declare
    # a float variable" and silently creates one, returning 0.
    #
    # IMPORTANT: do NOT redirect stderr on this source. common.sh runs
    # `[ -t 2 ]` to detect colour support; redirecting fd 2 here would
    # make it think stderr isn't a tty and disable colours permanently
    # for the shell session.
    if ! typeset -f _uvenv_log >/dev/null 2>&1; then
        if [ ! -f "$UVENV_LIB/common.sh" ]; then
            printf 'uvenv: lib not found at %s\n' "$UVENV_LIB" >&2
            printf '       try reinstalling: curl -fsSL https://github.com/%s/releases/latest/download/install.sh | bash\n' "$UVENV_REPO" >&2
            return 1
        fi
        # shellcheck disable=SC1090,SC1091
        . "$UVENV_LIB/common.sh"
    fi

    # Map subcommand -> lib file (some commands share one file).
    # Values are quoted because words like `exec` are also shell builtins
    # and shellcheck warns about them looking like `var=$(exec)`.
    local libfile
    case "$cmd" in
        create)              libfile="create" ;;
        activate|deactivate) libfile="activate" ;;
        list)                libfile="list" ;;
        remove)              libfile="remove" ;;
        install)             libfile="install_pkg" ;;
        which)               libfile="which" ;;
        version|help)        libfile="help" ;;
        info)                libfile="info" ;;
        status)              libfile="status" ;;
        set)                 libfile="set" ;;
        tool)                libfile="tool" ;;
        update|self-update)  libfile="update" ;;
        completions)         libfile="completions" ;;
        exec)                libfile="exec" ;;
        freeze)              libfile="freeze" ;;
        doctor)              libfile="doctor" ;;
        *)
            _uvenv_log error "unknown command '$cmd'. Try: uvenv help"
            return 1
            ;;
    esac

    # Function name = _uvenv_<cmd> with dashes -> underscores (self-update)
    local fn="_uvenv_${cmd//-/_}"
    if ! typeset -f "$fn" >/dev/null 2>&1; then
        if [ ! -f "$UVENV_LIB/${libfile}.sh" ]; then
            _uvenv_log error "lib missing: $UVENV_LIB/${libfile}.sh"
            return 1
        fi
        # shellcheck disable=SC1090
        . "$UVENV_LIB/${libfile}.sh"
    fi
    "$fn" "$@"
}

# ───── inherited-venv consistency ─────
# If $VIRTUAL_ENV was inherited from a parent shell (e.g. you ran
# `uvenv activate ml` then typed `zsh`), the child shell might have a
# rebuilt $PATH that no longer puts $VIRTUAL_ENV/bin first — for instance,
# mise's activate hook reconstructs $PATH from its own tool config and
# doesn't know about uvenv venvs. The result is an inconsistent state:
# $VIRTUAL_ENV is set (so powerlevel10k shows the venv) but `python`
# resolves to mise's instead of the venv's.
#
# Restore consistency by re-prepending $VIRTUAL_ENV/bin. If the venv
# directory no longer exists (deleted in another shell), unset $VIRTUAL_ENV.
if [ -n "${VIRTUAL_ENV:-}" ]; then
    if [ ! -d "$VIRTUAL_ENV/bin" ]; then
        unset VIRTUAL_ENV
    else
        case ":$PATH:" in
            :"$VIRTUAL_ENV/bin":*) ;;  # already first — consistent, no-op
            *)
                PATH="$(printf '%s' "$PATH" | awk -v RS=: -v ORS=: -v bad="$VIRTUAL_ENV/bin" '$0 != bad' | sed 's/:$//')"
                PATH="$VIRTUAL_ENV/bin:$PATH"
                export PATH
                hash -r 2>/dev/null || true
                ;;
        esac
    fi
fi

# ───── auto-enable tab completion ─────
# Sourced from the user's rc, so the user gets completion for free as soon
# as they install uvenv — no extra `eval "$(uvenv completions ...)"` step.
if [ -d "$UVENV_PREFIX/completions" ]; then
    if [ -n "${BASH_VERSION:-}" ] && [ -f "$UVENV_PREFIX/completions/uvenv.bash" ]; then
        # shellcheck disable=SC1090,SC1091
        . "$UVENV_PREFIX/completions/uvenv.bash" 2>/dev/null
    elif [ -n "${ZSH_VERSION:-}" ] && [ -f "$UVENV_PREFIX/completions/uvenv.zsh" ]; then
        # zsh needs compinit to be loaded before `compdef` works. If it's
        # available now, register immediately; otherwise defer until the
        # first prompt fires so compinit (almost always in user's rc) has
        # had a chance to run.
        if command -v compdef >/dev/null 2>&1; then
            # shellcheck disable=SC1090,SC1091
            . "$UVENV_PREFIX/completions/uvenv.zsh" 2>/dev/null
        else
            _uvenv_init_completion() {
                if command -v compdef >/dev/null 2>&1; then
                    # shellcheck disable=SC1090,SC1091
                    . "$UVENV_PREFIX/completions/uvenv.zsh" 2>/dev/null
                fi
                # Self-remove so it only runs once.
                if typeset -f add-zsh-hook >/dev/null 2>&1; then
                    add-zsh-hook -d precmd _uvenv_init_completion 2>/dev/null
                fi
            }
            if autoload -Uz add-zsh-hook 2>/dev/null; then
                add-zsh-hook precmd _uvenv_init_completion 2>/dev/null
            fi
        fi
    fi
fi
