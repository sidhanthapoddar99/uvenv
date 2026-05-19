# bash completion for uvenv
# Auto-sourced by uvenv.sh when running under bash. Also available via:
#   eval "$(uvenv completions bash)"

_uvenv_complete() {
    local cur prev cword
    COMPREPLY=()
    cword="$COMP_CWORD"
    cur="${COMP_WORDS[cword]}"
    prev="${COMP_WORDS[cword-1]}"

    local cmds="create activate deactivate list ls remove rm install update self-update tool exec freeze set status info doctor which version help completions"
    local home="${UVENV_HOME:-$HOME/.uvenv}"

    if [ "$cword" -eq 1 ]; then
        # shellcheck disable=SC2207
        COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
        return
    fi

    local sub="${COMP_WORDS[1]}"

    case "$sub" in
        activate|remove|rm|exec|freeze)
            local envs
            envs="$(ls -1 "$home" 2>/dev/null)"
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "$envs" -- "$cur") $(compgen -d -- "$cur") )
            ;;
        create)
            case "$prev" in
                --python)
                    local pyvers
                    pyvers="$(mise ls python 2>/dev/null | awk '{print $2}' | grep -E '^[0-9]')"
                    # shellcheck disable=SC2207
                    COMPREPLY=( $(compgen -W "$pyvers" -- "$cur") )
                    ;;
                -l|--local)
                    # shellcheck disable=SC2207
                    COMPREPLY=( $(compgen -d -- "$cur") )
                    ;;
                -n|--name)
                    ;;  # free-form name
                *)
                    # shellcheck disable=SC2207
                    COMPREPLY=( $(compgen -W "-n --name -l --local --python --python=" -- "$cur") )
                    ;;
            esac
            ;;
        set)
            if [[ "$cur" == --python=* ]]; then
                local pyvers
                pyvers="$(mise ls python 2>/dev/null | awk '{print $2}' | grep -E '^[0-9]')"
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "$pyvers" -P "--python=" -- "${cur#--python=}") )
            else
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "--python --python=" -- "$cur") )
            fi
            ;;
        tool)
            # First non-flag is the action verb
            local action=""
            local i
            for (( i=2; i<cword; i++ )); do
                case "${COMP_WORDS[i]}" in
                    --python|--python=*) ;;
                    -*) ;;
                    *) action="${COMP_WORDS[i]}"; break ;;
                esac
            done
            if [ -z "$action" ]; then
                # No action yet — complete uvenv flags + action verbs.
                # shellcheck disable=SC2207
                COMPREPLY=( $(compgen -W "--python --python= install uninstall upgrade list" -- "$cur") )
            else
                # After action, everything is uv's — don't try to complete it.
                :
            fi
            ;;
        update)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "--all --self" -- "$cur") )
            ;;
        install)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "-y --yes --" -- "$cur") )
            ;;
        completions)
            # shellcheck disable=SC2207
            COMPREPLY=( $(compgen -W "bash zsh" -- "$cur") )
            ;;
    esac
}

complete -F _uvenv_complete uvenv
