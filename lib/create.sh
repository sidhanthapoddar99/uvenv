# shellcheck shell=bash
# uvenv create [--python=X.Y] [-y] (-n <name> | -l <path>)
#
# Always confirms which python will be used before creating the venv. The
# python source is shown in yellow; if there's an active venv on a different
# X.Y, a red mismatch banner is shown. -y skips the prompt for scripting.
#
# Uses `mise exec` (not `mise use -g`) to pin the python — no global config
# mutation, no PATH-staleness window.

_uvenv_create() {
    local name="" pyver="" local_path="" force=0
    while [ $# -gt 0 ]; do
        case "$1" in
            -n|--name)        name="$2"; shift 2 ;;
            -l|--local)       local_path="$2"; shift 2 ;;
            --python)         pyver="$2"; shift 2 ;;
            --python=*)       pyver="${1#--python=}"; shift ;;
            python=*)         pyver="${1#python=}"; shift ;;
            -y|--yes)         force=1; shift ;;
            -h|--help)
                _uvenv_log plain "usage: uvenv create [--python=X.Y] [-y] -n <name>"
                _uvenv_log plain "       uvenv create [--python=X.Y] [-y] -l <path>"
                return 0
                ;;
            *) _uvenv_log error "unknown arg '$1'"; return 1 ;;
        esac
    done

    if [ -n "$name" ] && [ -n "$local_path" ]; then
        _uvenv_log error "-n and -l are mutually exclusive"
        return 1
    fi
    if [ -z "$name" ] && [ -z "$local_path" ]; then
        _uvenv_log error "usage: uvenv create [--python=X.Y] [-y] -n <name>"
        _uvenv_log error "       uvenv create [--python=X.Y] [-y] -l <path>"
        return 1
    fi

    local target label kind subject
    if [ -n "$local_path" ]; then
        target="$local_path"
        label="local venv at $target"
        kind="Create local venv"
        subject="$target"
    else
        mkdir -p "$UVENV_HOME"
        target="$UVENV_HOME/$name"
        label="'$name'"
        kind="Create global env"
        subject="$name"
    fi

    if [ -e "$target" ]; then
        _uvenv_log error "$target already exists"
        return 1
    fi

    # Always confirm — shows the python version regardless of whether --python
    # was given. -y skips the interactive prompt but still prints the block.
    _uvenv__confirm_python_use "$kind" "$subject" "$pyver" "$force" \
        || { _uvenv_log info "aborted"; return 1; }

    # Always go through `mise exec` so the python we promised in the prompt
    # is the python we actually use. No global config change, no stale PATH.
    if [ -n "$pyver" ]; then
        mise exec "python@$pyver" -- uv venv "$target" || return 1
    else
        local current_py
        current_py="$(_uvenv__mise_current_python || true)"
        if [ -n "$current_py" ]; then
            mise exec "python@$current_py" -- uv venv "$target" || return 1
        else
            uv venv "$target" || return 1
        fi
    fi

    if [ -n "$local_path" ]; then
        _uvenv_log success "created $label. Activate with: uvenv activate $target"
    else
        _uvenv_log success "created $label. Activate with: uvenv activate $name"
    fi
}
