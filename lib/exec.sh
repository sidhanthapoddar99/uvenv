# uvenv exec <name|path> -- <cmd> [args ...]
#
# Run a command using a uvenv env's python/bin without activating in this
# shell. The double-dash separator is required so we can pass flags through
# to the command.
#
# Resolution mirrors `uvenv activate`: $UVENV_HOME/<arg> first, then <arg>
# as a path.

_uvenv_exec() {
    local arg="${1:-}"
    [ $# -gt 0 ] && shift
    if [ -z "$arg" ] || [ "${1:-}" != "--" ]; then
        _uvenv_log error "usage: uvenv exec <name|path> -- <cmd> [args...]"
        return 1
    fi
    shift   # drop the --
    if [ $# -eq 0 ]; then
        _uvenv_log error "no command given after --"
        return 1
    fi

    local target
    if [ -d "$UVENV_HOME/$arg" ] && [ -f "$UVENV_HOME/$arg/bin/activate" ]; then
        target="$UVENV_HOME/$arg"
    elif [ -d "$arg" ] && [ -f "$arg/bin/activate" ]; then
        target="$arg"
    else
        _uvenv_log error "'$arg' is not a uvenv name or a venv path"
        return 1
    fi

    # Run in a subshell so the activation is scoped to this command only.
    (
        # shellcheck disable=SC1091
        . "$target/bin/activate"
        "$@"
    )
}
