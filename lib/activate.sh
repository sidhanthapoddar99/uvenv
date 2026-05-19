# uvenv activate <name>   /   uvenv deactivate

_uvenv_activate() {
    local name="${1:-}"
    if [ -z "$name" ]; then
        _uvenv_log error "usage: uvenv activate <name>"
        return 1
    fi
    local script="$UVENV_HOME/$name/bin/activate"
    if [ ! -f "$script" ]; then
        _uvenv_log error "'$name' not found in $UVENV_HOME"
        _uvenv_log error "       uvenv list  — to see available envs"
        return 1
    fi
    # shellcheck disable=SC1090
    . "$script"
    _uvenv_log info "activated '$name'"
}

_uvenv_deactivate() {
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        _uvenv_log error "no venv currently active"
        return 1
    fi
    deactivate
    _uvenv_log info "deactivated"
}
