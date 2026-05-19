# uvenv set --python=X.Y   — wraps `mise use -g python@X.Y`
#
# `mise use -g` already auto-installs the version on demand, so no explicit
# `mise install` is needed (the extra call emits a confusing "installed but
# not activated" warning).

_uvenv_set() {
    local pyver=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --python)   pyver="$2"; shift 2 ;;
            --python=*) pyver="${1#--python=}"; shift ;;
            python=*)   pyver="${1#python=}"; shift ;;
            -h|--help)
                _uvenv_log plain "usage: uvenv set --python=X.Y"
                return 0
                ;;
            *) _uvenv_log error "unknown arg '$1'"; return 1 ;;
        esac
    done
    if [ -z "$pyver" ]; then
        _uvenv_log error "usage: uvenv set --python=X.Y"
        return 1
    fi
    _uvenv_log info "setting global mise python -> $pyver"
    mise use -g "python@$pyver"
}
