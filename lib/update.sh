# uvenv update [pkg ...] | --all | --self
# uvenv self-update                  (alias for --self)
#
# Default: upgrade given packages (or --all) in the active venv.
# --self: re-run the bundled installer to update uvenv itself.

_uvenv_update() {
    local self=0 all=0
    local args=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --self) self=1; shift ;;
            --all)  all=1;  shift ;;
            *) args+=("$1"); shift ;;
        esac
    done

    if [ "$self" -eq 1 ]; then
        _uvenv_self_update
        return $?
    fi

    if [ -z "${VIRTUAL_ENV:-}" ]; then
        _uvenv_log error "no venv active — activate one, or run 'uvenv update --self' to update uvenv itself"
        return 1
    fi

    if [ "$all" -eq 1 ]; then
        local outdated
        outdated="$(uv pip list --outdated 2>/dev/null | awk 'NR>2 {print $1}')"
        if [ -z "$outdated" ]; then
            _uvenv_log info "all packages up to date"
            return 0
        fi
        _uvenv_log info "upgrading: $(echo "$outdated" | tr '\n' ' ')"
        # shellcheck disable=SC2086
        uv pip install --upgrade $outdated
        return $?
    fi

    if [ ${#args[@]} -eq 0 ]; then
        _uvenv_log error "usage: uvenv update <pkg>... | --all | --self"
        return 1
    fi
    uv pip install --upgrade "${args[@]}"
}

_uvenv_self_update() {
    local installer="$UVENV_PREFIX/install.sh"
    if [ -f "$installer" ]; then
        _uvenv_log info "running bundled installer: $installer"
        bash "$installer"
    else
        local url="https://github.com/$UVENV_REPO/releases/latest/download/install.sh"
        _uvenv_log info "no bundled installer found; fetching $url"
        curl -fsSL "$url" | bash
    fi
}
