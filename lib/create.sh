# shellcheck shell=bash
# uvenv create [--python=X.Y] (-n <name> | -l <path>)
#
# Grammar: all flags are uvenv's. There is no passthrough section because
# `uv venv` doesn't need extra args from the user — uvenv constructs the
# full uv invocation. `mise exec python@X.Y` auto-installs the version on
# demand, so we don't run an explicit `mise install` (it's redundant and
# emits a confusing "installed but not activated" warning).

_uvenv_create() {
    local name="" pyver="" local_path=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -n|--name)        name="$2"; shift 2 ;;
            -l|--local)       local_path="$2"; shift 2 ;;
            --python)         pyver="$2"; shift 2 ;;
            --python=*)       pyver="${1#--python=}"; shift ;;
            python=*)         pyver="${1#python=}"; shift ;;
            -h|--help)
                _uvenv_log plain "usage: uvenv create [--python=X.Y] -n <name>"
                _uvenv_log plain "       uvenv create [--python=X.Y] -l <path>"
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
        _uvenv_log error "usage: uvenv create [--python=X.Y] -n <name>"
        _uvenv_log error "       uvenv create [--python=X.Y] -l <path>"
        return 1
    fi

    local target label
    if [ -n "$local_path" ]; then
        target="$local_path"
        label="local venv at $target"
    else
        mkdir -p "$UVENV_HOME"
        target="$UVENV_HOME/$name"
        label="'$name'"
    fi

    if [ -e "$target" ]; then
        _uvenv_log error "$target already exists"
        return 1
    fi

    if [ -n "$pyver" ]; then
        # mise exec auto-installs python@X.Y if not present (modern mise).
        mise exec "python@$pyver" -- uv venv "$target" || return 1
    else
        uv venv "$target" || return 1
    fi

    if [ -n "$local_path" ]; then
        _uvenv_log success "created $label. Activate with: uvenv activate $target"
    else
        _uvenv_log success "created $label. Activate with: uvenv activate $name"
    fi
}
