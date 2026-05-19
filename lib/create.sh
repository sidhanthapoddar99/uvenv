# uvenv create -n <name> [--python X.Y]
# uvenv create -l <path> [--python X.Y]   # local venv at the given path
#
# -n and -l are mutually exclusive. With -l the path is taken as-is (relative
# or absolute); the parent must exist. Mise still picks the Python.

_uvenv_create() {
    local name="" pyver="" local_path=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -n)        name="$2"; shift 2 ;;
            -l)        local_path="$2"; shift 2 ;;
            --python)  pyver="$2"; shift 2 ;;
            python=*)  pyver="${1#python=}"; shift ;;
            *) _uvenv_log error "unknown arg '$1'"; return 1 ;;
        esac
    done

    if [ -n "$name" ] && [ -n "$local_path" ]; then
        _uvenv_log error "-n and -l are mutually exclusive"
        return 1
    fi
    if [ -z "$name" ] && [ -z "$local_path" ]; then
        _uvenv_log error "usage: uvenv create -n <name> [--python X.Y]"
        _uvenv_log error "       uvenv create -l <path> [--python X.Y]"
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
        _uvenv_log info "ensuring mise has python@$pyver..."
        mise install "python@$pyver" || return 1
        mise exec "python@$pyver" -- uv venv "$target" || return 1
    else
        uv venv "$target" || return 1
    fi

    if [ -n "$local_path" ]; then
        _uvenv_log info "created $label. Activate with: uvenv activate $target"
    else
        _uvenv_log info "created $label. Activate with: uvenv activate $name"
    fi
}
