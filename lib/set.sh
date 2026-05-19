# uvenv set --python X.Y   — wraps `mise use -g python@X.Y`

_uvenv_set() {
    local pyver=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --python) pyver="$2"; shift 2 ;;
            python=*) pyver="${1#python=}"; shift ;;
            *) _uvenv_log error "unknown arg '$1'"; return 1 ;;
        esac
    done
    if [ -z "$pyver" ]; then
        _uvenv_log error "usage: uvenv set --python X.Y"
        return 1
    fi
    _uvenv_log info "ensuring mise has python@$pyver..."
    mise install "python@$pyver" || return 1
    _uvenv_log info "setting global mise python -> $pyver"
    mise use -g "python@$pyver"
}
