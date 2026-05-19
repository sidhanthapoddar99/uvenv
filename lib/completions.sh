# shellcheck shell=bash
# uvenv completions {bash|zsh}  — print the relevant completion script.
# Pipe it through eval, or save to a file your shell sources.

_uvenv_completions() {
    local shell="${1:-}"
    case "$shell" in
        bash) cat "$UVENV_PREFIX/completions/uvenv.bash" ;;
        zsh)  cat "$UVENV_PREFIX/completions/uvenv.zsh" ;;
        ""|-h|--help)
            cat <<EOF
Usage:
  uvenv completions bash   # print bash completion script
  uvenv completions zsh    # print zsh completion script

Enable:
  bash:  eval "\$(uvenv completions bash)"     # add to ~/.bashrc
  zsh:   eval "\$(uvenv completions zsh)"      # add to ~/.zshrc
EOF
            ;;
        *)
            _uvenv_log error "unknown shell '$shell' (try bash or zsh)"
            return 1
            ;;
    esac
}
