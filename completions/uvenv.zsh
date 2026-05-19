#compdef uvenv
# zsh completion for uvenv.
#
# Auto-sourced by uvenv.sh when running under zsh (compinit must have run
# first; uvenv.sh defers via a precmd hook if not). Also available via:
#   eval "$(uvenv completions zsh)"

_uvenv() {
    local -a cmds
    cmds=(
        'create:Create a named env (-n) or local venv (-l)'
        'activate:Activate an env in this shell'
        'deactivate:Deactivate current venv'
        'list:List envs (global + local + mise)'
        'ls:Alias for list'
        'remove:Delete an env'
        'rm:Alias for remove'
        'install:uv pip install into active env (or base with confirm)'
        'update:Upgrade packages, or uvenv itself with --self'
        'self-update:Update uvenv itself'
        'tool:uv tool wrapper (install / uninstall / upgrade / list)'
        'exec:Run a command in an env without activating'
        'freeze:uv pip freeze (active env or named)'
        'set:Set the global mise Python'
        'status:Show mise / uv / venv status'
        'info:Detailed cheat sheet of mise + uv commands'
        'doctor:Run dependency + install sanity checks'
        'which:Print storage dir'
        'version:Print uvenv version'
        'help:Show help'
        'completions:Print completion script'
    )

    local context state line
    _arguments -C \
        '1:command:->cmds' \
        '*::arg:->args'

    case "$state" in
        cmds)
            _describe 'command' cmds
            ;;
        args)
            local home="${UVENV_HOME:-$HOME/.uvenv}"
            case "$words[1]" in
                activate|remove|rm|exec|freeze)
                    local -a envs
                    envs=( "${(@f)$(ls -1 "$home" 2>/dev/null)}" )
                    _alternative \
                        'envs:global env:(${envs})' \
                        'path:local venv path:_directories'
                    ;;
                tool)
                    # Determine if action has been typed yet.
                    local action=""
                    local i
                    for (( i=2; i<CURRENT; i++ )); do
                        case "$words[i]" in
                            --python|--python=*) ;;
                            -*) ;;
                            *) action="$words[i]"; break ;;
                        esac
                    done
                    if [ -z "$action" ]; then
                        case "$words[CURRENT-1]" in
                            --python)
                                local -a pys
                                pys=( "${(@f)$(mise ls python 2>/dev/null | awk '{print $2}' | grep -E '^[0-9]')}" )
                                _describe 'python' pys
                                ;;
                            *)
                                _values 'tool flag/action' --python --python= install uninstall upgrade list
                                ;;
                        esac
                    fi
                    # After the action, everything is uv's — leave it alone.
                    ;;
                update)
                    _values 'flag' --all --self
                    ;;
                completions)
                    _values 'shell' bash zsh
                    ;;
                create)
                    case "$words[CURRENT-1]" in
                        --python)
                            local -a pys
                            pys=( "${(@f)$(mise ls python 2>/dev/null | awk '{print $2}' | grep -E '^[0-9]')}" )
                            _describe 'python' pys
                            ;;
                        -l|--local)
                            _directories
                            ;;
                        *)
                            _values 'flag' -n --name -l --local --python --python=
                            ;;
                    esac
                    ;;
                set)
                    case "$words[CURRENT-1]" in
                        --python)
                            local -a pys
                            pys=( "${(@f)$(mise ls python 2>/dev/null | awk '{print $2}' | grep -E '^[0-9]')}" )
                            _describe 'python' pys
                            ;;
                        *)
                            _values 'flag' --python --python=
                            ;;
                    esac
                    ;;
                install)
                    _values 'flag' -y --yes --
                    ;;
            esac
            ;;
    esac
}

# When sourced directly (auto-load from uvenv.sh, or via `eval "$(uvenv
# completions zsh)"`), register the function as uvenv's completion handler.
# When autoloaded via $fpath the function is registered automatically by
# the `#compdef uvenv` magic comment above and this is a no-op.
if command -v compdef >/dev/null 2>&1; then
    compdef _uvenv uvenv 2>/dev/null
fi
