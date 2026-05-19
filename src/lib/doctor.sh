# shellcheck shell=bash
# uvenv doctor — coloured PASS/FAIL sanity check.

_uvenv_doctor() {
    local fails=0
    local rc_found=0

    _uvenv__doc_pass() {
        printf '  %s[PASS]%s %s' "${_UVENV_C_BOLD}${_UVENV_C_GREEN}" "${_UVENV_C_RESET}" "$1"
        [ -n "$2" ] && printf '%s  (%s)%s' "$_UVENV_C_DIM" "$2" "$_UVENV_C_RESET"
        printf '\n'
    }
    _uvenv__doc_fail() {
        printf '  %s[FAIL]%s %s' "${_UVENV_C_BOLD}${_UVENV_C_RED}" "${_UVENV_C_RESET}" "$1"
        [ -n "$2" ] && printf '%s  (%s)%s' "$_UVENV_C_YELLOW" "$2" "$_UVENV_C_RESET"
        printf '\n'
        fails=$((fails + 1))
    }

    printf '%suvenv doctor%s — uvenv %s\n\n' \
        "$_UVENV_C_BOLD" "$_UVENV_C_RESET" "$UVENV_VERSION"

    printf '%sDependencies%s\n' "$_UVENV_C_BOLD" "$_UVENV_C_RESET"
    if command -v mise >/dev/null 2>&1; then
        _uvenv__doc_pass "mise on PATH" "$(command -v mise)"
    else
        _uvenv__doc_fail "mise on PATH" "install: https://mise.run"
    fi
    if command -v uv >/dev/null 2>&1; then
        _uvenv__doc_pass "uv on PATH" "$(command -v uv)"
    else
        _uvenv__doc_fail "uv on PATH" "install: mise use -g uv@latest"
    fi

    local py
    py="$(_uvenv__mise_current_python 2>/dev/null || true)"
    if [ -n "$py" ]; then
        _uvenv__doc_pass "mise has a Python" "$py"
    else
        _uvenv__doc_fail "mise has a Python" "set one: uvenv set --python=3.13"
    fi

    printf '\n%sPaths%s\n' "$_UVENV_C_BOLD" "$_UVENV_C_RESET"

    if [ -d "$UVENV_PREFIX" ] && [ -f "$UVENV_PREFIX/uvenv.sh" ]; then
        _uvenv__doc_pass "UVENV_PREFIX install OK" "$UVENV_PREFIX"
    else
        _uvenv__doc_fail "UVENV_PREFIX install OK" "$UVENV_PREFIX (missing files)"
    fi
    if [ -d "$UVENV_PREFIX/lib" ]; then
        _uvenv__doc_pass "lib/ present"
    else
        _uvenv__doc_fail "lib/ present" "modular layout missing — reinstall"
    fi
    if mkdir -p "$UVENV_HOME" 2>/dev/null && [ -w "$UVENV_HOME" ]; then
        _uvenv__doc_pass "UVENV_HOME writable" "$UVENV_HOME"
    else
        _uvenv__doc_fail "UVENV_HOME writable" "$UVENV_HOME"
    fi

    printf '\n%sShell integration%s\n' "$_UVENV_C_BOLD" "$_UVENV_C_RESET"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] || continue
        if grep -q 'uvenv/uvenv.sh' "$rc"; then
            _uvenv__doc_pass "$rc sources uvenv"
            rc_found=1
        fi
    done
    [ "$rc_found" -eq 0 ] && _uvenv__doc_fail "rc sources uvenv" "add: source $UVENV_PREFIX/uvenv.sh"

    # Completion registration check. _uvenv_complete (bash) / _uvenv (zsh)
    # should be a function if completions auto-loaded correctly.
    if [ -n "${BASH_VERSION:-}" ]; then
        if typeset -f _uvenv_complete >/dev/null 2>&1; then
            _uvenv__doc_pass "bash completion loaded"
        else
            _uvenv__doc_fail "bash completion loaded" "re-source $UVENV_PREFIX/uvenv.sh"
        fi
    elif [ -n "${ZSH_VERSION:-}" ]; then
        if typeset -f _uvenv >/dev/null 2>&1 || (( ${+_comps[uvenv]:-0} )); then
            _uvenv__doc_pass "zsh completion loaded"
        else
            _uvenv__doc_fail "zsh completion loaded" "ensure compinit is called BEFORE sourcing uvenv.sh"
        fi
    fi

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        printf '\n%sActive venv:%s %s\n' "$_UVENV_C_BOLD" "$_UVENV_C_RESET" "$VIRTUAL_ENV"
    fi

    printf '\n'
    if [ "$fails" -eq 0 ]; then
        printf '%sAll checks passed.%s\n' \
            "${_UVENV_C_BOLD}${_UVENV_C_GREEN}" "$_UVENV_C_RESET"
        return 0
    fi
    printf '%s%d check(s) failed.%s\n' \
        "${_UVENV_C_BOLD}${_UVENV_C_RED}" "$fails" "$_UVENV_C_RESET"
    return 1
}
