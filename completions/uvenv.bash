# bash completion for uvenv
# Install: source this file from ~/.bashrc, or:
#   eval "$(uvenv completions bash)"

_uvenv_complete() {
    local cur prev cword
    COMPREPLY=()
    cword="$COMP_CWORD"
    cur="${COMP_WORDS[cword]}"
    prev="${COMP_WORDS[cword-1]}"

    local cmds="create activate deactivate list ls remove rm install update self-update tool set status info which version help completions"

    if [ "$cword" -eq 1 ]; then
        # shellcheck disable=SC2207
        COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
        return
    fi

    local sub="${COMP_WORDS[1]}"
    local home="${UVENV_HOME:-$HOME/.uvenv}"

    case "$sub" in
        activate|remove|rm)
            local envs
            envs="$(ls -1 "$home" 2>/dev/null)"
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "$envs" -- "$cur") )
            ;;
        create|set)
            if [ "$prev" = "--python" ]; then
                local pyvers
                pyvers="$(mise ls python 2>/dev/null | awk '{print $2}' | grep -E '^[0-9]')"
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "$pyvers" -- "$cur") )
            else
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "-n --python" -- "$cur") )
            fi
            ;;
        tool)
            if [ "$cword" -eq 2 ]; then
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "install uninstall list" -- "$cur") )
            elif [ "$prev" = "--python" ]; then
                local pyvers
                pyvers="$(mise ls python 2>/dev/null | awk '{print $2}' | grep -E '^[0-9]')"
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "$pyvers" -- "$cur") )
            fi
            ;;
        update)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "--all --self" -- "$cur") )
            ;;
        completions)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "bash zsh" -- "$cur") )
            ;;
    esac
}

complete -F _uvenv_complete uvenv
