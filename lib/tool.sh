# uvenv tool {install|uninstall|list}
#
# `install --python X.Y` switches the global mise Python, runs `uv tool install`,
# then restores the previous mise Python — in a subshell with EXIT trap so the
# restore runs whether the install succeeds, fails, or is interrupted.

_uvenv_tool() {
    local sub="${1:-}"
    [ $# -gt 0 ] && shift
    case "$sub" in
        install)   _uvenv__tool_install   "$@" ;;
        uninstall) _uvenv__tool_uninstall "$@" ;;
        list)      uv tool list ;;
        ""|-h|--help)
            cat <<EOF
Usage:
  uvenv tool install <pkg> [--python X.Y]   Install a uv tool (optionally pin Python)
  uvenv tool uninstall <pkg>                Uninstall a uv tool
  uvenv tool list                           List installed uv tools
EOF
            ;;
        *) _uvenv_log error "unknown 'uvenv tool' subcommand: $sub"; return 1 ;;
    esac
}

_uvenv__tool_install() {
    local pkg="" pyver=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --python) pyver="$2"; shift 2 ;;
            python=*) pyver="${1#python=}"; shift ;;
            *) if [ -z "$pkg" ]; then pkg="$1"; else pkg="$pkg $1"; fi; shift ;;
        esac
    done
    if [ -z "$pkg" ]; then
        _uvenv_log error "usage: uvenv tool install <pkg> [--python X.Y]"
        return 1
    fi

    if [ -z "$pyver" ]; then
        # shellcheck disable=SC2086
        uv tool install $pkg
        return $?
    fi

    # Remember the current mise python so we can restore it.
    local prev_py
    prev_py="$(_uvenv__mise_current_python 2>/dev/null || true)"
    _uvenv_log info "switching mise python -> $pyver (was: ${prev_py:-none})"

    # Run the switch + install inside a subshell so the EXIT trap always fires.
    (
        # shellcheck disable=SC2317
        _uvenv__restore_py() {
            if [ -n "$prev_py" ]; then
                mise use -g "python@$prev_py" >/dev/null 2>&1 || true
            fi
        }
        trap _uvenv__restore_py EXIT

        mise install "python@$pyver" || exit 1
        mise use -g  "python@$pyver" >/dev/null || exit 1
        # shellcheck disable=SC2086
        uv tool install $pkg
    )
    local rc=$?

    if [ -n "$prev_py" ]; then
        _uvenv_log info "restored mise python -> $prev_py"
    fi
    return "$rc"
}

_uvenv__tool_uninstall() {
    local pkg="${1:-}"
    if [ -z "$pkg" ]; then
        _uvenv_log error "usage: uvenv tool uninstall <pkg>"
        return 1
    fi
    uv tool uninstall "$pkg"
}
