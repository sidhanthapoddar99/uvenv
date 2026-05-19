#compdef uvenv
# zsh completion for uvenv
# Install: place this file on $fpath as `_uvenv`, or:
#   eval "$(uvenv completions zsh)"

_uvenv() {
    local -a cmds
    cmds=(
        'create:Create a named env'
        'activate:Activate an env in this shell'
        'deactivate:Deactivate current venv'
        'list:List envs (global + local + mise)'
        'ls:Alias for list'
        'remove:Delete an env'
        'rm:Alias for remove'
        'install:uv pip install into active env (or base with confirm)'
        'update:Upgrade packages, or uvenv itself with --self'
        'self-update:Update uvenv itself'
        'tool:uv tool wrapper (install/uninstall/list)'
        'set:Set the global mise Python (mise use -g python@X.Y)'
        'status:Show mise / uv / venv status'
        'info:Cheat sheet of mise + uv commands'
        'which:Print storage dir'
        'version:Print uvenv version'
        'help:Show help'
        'completions:Print completion script'
        'exec:Run a command in an env without activating'
        'freeze:uv pip freeze (active env or named)'
        'doctor:Sanity-check deps and install'
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
                    if (( CURRENT == 2 )); then
                        _values 'tool subcommand' install uninstall upgrade list
                    fi
                    ;;
                update)
                    _values 'flag' --all --self
                    ;;
                completions)
                    _values 'shell' bash zsh
                    ;;
                create|set)
                    case "$words[CURRENT-1]" in
                        --python)
                            local -a pys
                            pys=( "${(@f)$(mise ls python 2>/dev/null | awk '{print $2}' | grep -E '^[0-9]')}" )
                            _describe 'python' pys
                            ;;
                        -l)
                            _directories
                            ;;
                        *)
                            _values 'flag' -n -l --python
                            ;;
                    esac
                    ;;
            esac
            ;;
    esac
}

_uvenv "$@"
