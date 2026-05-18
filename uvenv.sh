#!/usr/bin/env bash
# uvenv — named global Python venvs, backed by mise + uv
# https://github.com/sidhanthapoddar99/uvenv
#
# This file is meant to be SOURCED from your shell rc, not executed:
#   source ~/.config/uvenv/uvenv.sh
#
# Dependency check (mise + uv) is performed by install.sh at install time.
# At runtime, individual commands surface the underlying error if either is
# missing — keeps the function small and the activate path fast.

UVENV_HOME="${UVENV_HOME:-$HOME/.uvenv}"
UVENV_VERSION="0.1.0"

uvenv() {
    local cmd="${1:-help}"
    [ $# -gt 0 ] && shift

    case "$cmd" in
        create)
            local name="" pyver=""
            while [ $# -gt 0 ]; do
                case "$1" in
                    -n)        name="$2"; shift 2 ;;
                    --python)  pyver="$2"; shift 2 ;;
                    python=*)  pyver="${1#python=}"; shift ;;
                    *)         echo "uvenv: unknown arg '$1'" >&2; return 1 ;;
                esac
            done
            if [ -z "$name" ]; then
                echo "uvenv: usage: uvenv create -n <name> [--python X.Y]" >&2
                return 1
            fi
            mkdir -p "$UVENV_HOME"
            local target="$UVENV_HOME/$name"
            if [ -d "$target" ]; then
                echo "uvenv: '$name' already exists at $target" >&2
                return 1
            fi
            if [ -n "$pyver" ]; then
                # mise is the source of truth for Python versions.
                # Ensure mise has it, then build the venv against THAT Python.
                echo "uvenv: ensuring mise has python@$pyver..."
                mise install "python@$pyver" || return 1
                mise exec "python@$pyver" -- uv venv "$target" || return 1
            else
                # Use whichever Python is currently active (mise controls PATH).
                uv venv "$target" || return 1
            fi
            echo "uvenv: created '$name'. Activate with: uvenv activate $name"
            ;;

        activate)
            local name="${1:-}"
            if [ -z "$name" ]; then
                echo "uvenv: usage: uvenv activate <name>" >&2
                return 1
            fi
            local activate_script="$UVENV_HOME/$name/bin/activate"
            if [ ! -f "$activate_script" ]; then
                echo "uvenv: '$name' not found in $UVENV_HOME" >&2
                echo "       uvenv list  — to see available envs" >&2
                return 1
            fi
            # shellcheck disable=SC1090
            . "$activate_script"
            echo "uvenv: activated '$name'"
            ;;

        deactivate)
            if [ -z "${VIRTUAL_ENV:-}" ]; then
                echo "uvenv: no venv currently active" >&2
                return 1
            fi
            deactivate
            echo "uvenv: deactivated"
            ;;

        list|ls)
            if [ ! -d "$UVENV_HOME" ] || [ -z "$(ls -A "$UVENV_HOME" 2>/dev/null)" ]; then
                echo "uvenv: no envs yet. Create one with: uvenv create -n <name>"
                return 0
            fi
            local d name pyver
            for d in "$UVENV_HOME"/*/; do
                [ -d "$d" ] || continue
                name="$(basename "$d")"
                pyver="$(grep -E '^version' "$d/pyvenv.cfg" 2>/dev/null | cut -d= -f2 | tr -d ' ')"
                [ -z "$pyver" ] && pyver="?"
                if [ "$UVENV_HOME/$name" = "${VIRTUAL_ENV:-}" ]; then
                    printf "* %-24s python %s\n" "$name" "$pyver"
                else
                    printf "  %-24s python %s\n" "$name" "$pyver"
                fi
            done
            ;;

        remove|rm)
            local name="${1:-}"
            if [ -z "$name" ]; then
                echo "uvenv: usage: uvenv remove <name>" >&2
                return 1
            fi
            local target="$UVENV_HOME/$name"
            if [ ! -d "$target" ]; then
                echo "uvenv: '$name' not found" >&2
                return 1
            fi
            if [ "$target" = "${VIRTUAL_ENV:-}" ]; then
                echo "uvenv: '$name' is currently active — deactivate first" >&2
                return 1
            fi
            rm -rf "$target"
            echo "uvenv: removed '$name'"
            ;;

        install)
            if [ -z "${VIRTUAL_ENV:-}" ]; then
                echo "uvenv: no env active. Activate one first: uvenv activate <name>" >&2
                return 1
            fi
            uv pip install "$@"
            ;;

        which|where)
            echo "$UVENV_HOME"
            ;;

        version|--version|-V)
            echo "uvenv $UVENV_VERSION"
            ;;

        help|--help|-h|"")
            cat <<EOF
uvenv $UVENV_VERSION — named global Python venvs (mise + uv)

Usage:
  uvenv create -n <name> [--python X.Y]   Create a named env
  uvenv activate <name>                   Activate it in this shell
  uvenv deactivate                        Deactivate current venv
  uvenv list                              List all envs (* = active)
  uvenv remove <name>                     Delete an env
  uvenv install <pkg> [<pkg>...]          uv pip install into active env
  uvenv which                             Print storage dir
  uvenv version                           Print uvenv version

Storage: \$UVENV_HOME (default ~/.uvenv)
Repo:    https://github.com/sidhanthapoddar99/uvenv
EOF
            ;;

        *)
            echo "uvenv: unknown command '$cmd'. Try: uvenv help" >&2
            return 1
            ;;
    esac
}
