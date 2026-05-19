# uvenv create -n <name> [--python X.Y]

_uvenv_create() {
    local name="" pyver=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -n)        name="$2"; shift 2 ;;
            --python)  pyver="$2"; shift 2 ;;
            python=*)  pyver="${1#python=}"; shift ;;
            *) _uvenv_log error "unknown arg '$1'"; return 1 ;;
        esac
    done
    if [ -z "$name" ]; then
        _uvenv_log error "usage: uvenv create -n <name> [--python X.Y]"
        return 1
    fi

    mkdir -p "$UVENV_HOME"
    local target="$UVENV_HOME/$name"
    if [ -d "$target" ]; then
        _uvenv_log error "'$name' already exists at $target"
        return 1
    fi

    if [ -n "$pyver" ]; then
        _uvenv_log info "ensuring mise has python@$pyver..."
        mise install "python@$pyver" || return 1
        mise exec "python@$pyver" -- uv venv "$target" || return 1
    else
        uv venv "$target" || return 1
    fi
    _uvenv_log info "created '$name'. Activate with: uvenv activate $name"
}
