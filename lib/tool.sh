# uvenv tool [--python=X.Y] <action> [args ...]
#
# Grammar (the "infographic"):
#
#   uvenv tool --python=3.13 install dstack -U
#           └── uvenv's ──┘ └── verbatim to uv ──┘
#
# All flags before <action> are uvenv's. The action (install / uninstall /
# upgrade / list) is matched verbatim. Everything from after the action
# onward is passed straight to `uv tool <action>` with no parsing — so
# any uv flag (-U, --reinstall, --no-cache, ...) works as you'd expect.
#
# With --python, the global mise python is temporarily switched for the
# install only and restored afterwards. Restore is guaranteed via an EXIT
# trap inside a subshell so it fires on success, failure, AND signals.

_uvenv_tool() {
    local pyver=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --python)   pyver="$2"; shift 2 ;;
            --python=*) pyver="${1#--python=}"; shift ;;
            -h|--help|"")
                _uvenv__tool_usage
                return 0
                ;;
            -*)
                _uvenv_log error "unknown uvenv-tool flag '$1' (uvenv flags must come BEFORE the action)"
                return 1
                ;;
            *) break ;;   # First non-flag word is the action.
        esac
    done

    local action="${1:-}"
    [ $# -gt 0 ] && shift

    case "$action" in
        install)   _uvenv__tool_install   "$pyver" "$@" ;;
        uninstall) uv tool uninstall "$@" ;;
        upgrade)   uv tool upgrade   "$@" ;;
        list)      uv tool list      "$@" ;;
        "")        _uvenv__tool_usage ;;
        *) _uvenv_log error "unknown 'uvenv tool' action: $action"; return 1 ;;
    esac
}

_uvenv__tool_usage() {
    cat <<EOF
Usage:
  uvenv tool [--python=X.Y] install <pkg> [uv flags...]
  uvenv tool uninstall <pkg>
  uvenv tool upgrade <pkg> | --all
  uvenv tool list

Examples:
  uvenv tool install ruff
  uvenv tool --python=3.13 install dstack -U
  uvenv tool upgrade --all

Everything after the action is forwarded verbatim to \`uv tool <action>\`.
EOF
}

_uvenv__tool_install() {
    local pyver="$1"; shift

    if [ $# -eq 0 ]; then
        _uvenv_log error "usage: uvenv tool [--python=X.Y] install <pkg> [uv flags...]"
        return 1
    fi

    if [ -z "$pyver" ]; then
        uv tool install "$@"
        return $?
    fi

    # Remember current mise python so we can restore it.
    local prev_py
    prev_py="$(_uvenv__mise_current_python 2>/dev/null || true)"
    _uvenv_log info "switching mise python -> $pyver (was: ${prev_py:-none})"

    # Subshell + EXIT trap guarantees restore on success / failure / signal.
    (
        # shellcheck disable=SC2317
        _uvenv__restore_py() {
            if [ -n "$prev_py" ]; then
                mise use -g "python@$prev_py" >/dev/null 2>&1 || true
            fi
        }
        trap _uvenv__restore_py EXIT

        # `mise use -g` auto-installs the python if needed.
        mise use -g "python@$pyver" >/dev/null || exit 1
        uv tool install "$@"
    )
    local rc=$?

    if [ -n "$prev_py" ]; then
        _uvenv_log info "restored mise python -> $prev_py"
    fi
    return "$rc"
}
