# uvenv remove <name>

_uvenv_remove() {
    local name="${1:-}"
    if [ -z "$name" ]; then
        _uvenv_log error "usage: uvenv remove <name>"
        return 1
    fi
    local target="$UVENV_HOME/$name"
    if [ ! -d "$target" ]; then
        _uvenv_log error "'$name' not found"
        return 1
    fi
    if [ "$target" = "${VIRTUAL_ENV:-}" ]; then
        _uvenv_log error "'$name' is currently active — deactivate first"
        return 1
    fi
    rm -rf "$target"
    _uvenv_log info "removed '$name'"
}
