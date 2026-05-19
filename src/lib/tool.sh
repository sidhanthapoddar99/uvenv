# shellcheck shell=bash
# uvenv tool [--python=X.Y] [-y] <action> [args ...]
#
# Grammar:
#
#   uvenv tool --python=3.13 install dstack -U
#           └─ uvenv's flags ─┘ └─ verbatim to uv ─┘
#
# uvenv flags BEFORE the action; everything after is forwarded verbatim to
# `uv tool <action>`. The action is one of install / uninstall / upgrade /
# list (anything else is passed through too).
#
# For `install`, uvenv runs `mise exec python@X.Y -- uv tool install --python X.Y`
# so the python is pinned both in PATH and via uv's --python flag. No
# global mise-config mutation; no subshell-trap restore dance.
#
# `install` always confirms (with -y to skip): shows the python version
# in yellow and any active-venv mismatch in red.

_uvenv_tool() {
    local pyver=""
    local force=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --python)   pyver="$2"; shift 2 ;;
            --python=*) pyver="${1#--python=}"; shift ;;
            -y|--yes)   force=1; shift ;;
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
        install)   _uvenv__tool_install "$pyver" "$force" "$@" ;;
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
  uvenv tool [--python=X.Y] [-y] install <pkg> [uv flags...]
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
    local force="$1"; shift

    if [ $# -eq 0 ]; then
        _uvenv_log error "usage: uvenv tool [--python=X.Y] [-y] install <pkg> [uv flags...]"
        return 1
    fi

    # First positional that isn't a flag is the package name (for display only).
    local pkg=""
    local a
    for a in "$@"; do
        case "$a" in -*) ;; *) pkg="$a"; break ;; esac
    done
    [ -z "$pkg" ] && pkg="<args>"

    _uvenv__confirm_python_use "Install uv tool" "$pkg" "$pyver" "$force" \
        || { _uvenv_log info "aborted"; return 1; }

    # Pin python via mise exec so the version in the confirmation block is
    # actually what runs. Pass --python to uv too as belt + suspenders.
    if [ -n "$pyver" ]; then
        mise exec "python@$pyver" -- uv tool install --python "$pyver" "$@"
    else
        local current_py
        current_py="$(_uvenv__mise_current_python || true)"
        if [ -n "$current_py" ]; then
            mise exec "python@$current_py" -- uv tool install "$@"
        else
            uv tool install "$@"
        fi
    fi
}
