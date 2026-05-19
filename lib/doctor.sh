# uvenv doctor — sanity-check the install + dependencies.
# Prints PASS/FAIL per check and exits non-zero if any FAIL.

_uvenv_doctor() {
    local fails=0
    local rc_found=0

    _uvenv__doc_check() {
        # _uvenv__doc_check "label" 0|1 "detail"
        if [ "$2" -eq 0 ]; then
            printf '  [PASS] %s' "$1"
            [ -n "$3" ] && printf '  (%s)' "$3"
            printf '\n'
        else
            printf '  [FAIL] %s' "$1"
            [ -n "$3" ] && printf '  (%s)' "$3"
            printf '\n'
            fails=$((fails + 1))
        fi
    }

    printf 'uvenv doctor — uvenv %s\n\n' "$UVENV_VERSION"

    printf 'Dependencies\n'
    if command -v mise >/dev/null 2>&1; then
        _uvenv__doc_check "mise on PATH" 0 "$(command -v mise)"
    else
        _uvenv__doc_check "mise on PATH" 1 "install: https://mise.run"
    fi

    if command -v uv >/dev/null 2>&1; then
        _uvenv__doc_check "uv on PATH" 0 "$(command -v uv)"
    else
        _uvenv__doc_check "uv on PATH" 1 "install: mise use -g uv@latest"
    fi

    local py
    py="$(_uvenv__mise_current_python 2>/dev/null || true)"
    if [ -n "$py" ]; then
        _uvenv__doc_check "mise has a Python" 0 "$py"
    else
        _uvenv__doc_check "mise has a Python" 1 "set one: uvenv set --python 3.13"
    fi

    printf '\nPaths\n'

    if [ -d "$UVENV_PREFIX" ] && [ -f "$UVENV_PREFIX/uvenv.sh" ]; then
        _uvenv__doc_check "UVENV_PREFIX install OK" 0 "$UVENV_PREFIX"
    else
        _uvenv__doc_check "UVENV_PREFIX install OK" 1 "$UVENV_PREFIX (missing files)"
    fi

    if [ -d "$UVENV_PREFIX/lib" ]; then
        _uvenv__doc_check "lib/ present" 0
    else
        _uvenv__doc_check "lib/ present" 1 "modular layout missing — reinstall"
    fi

    if mkdir -p "$UVENV_HOME" 2>/dev/null && [ -w "$UVENV_HOME" ]; then
        _uvenv__doc_check "UVENV_HOME writable" 0 "$UVENV_HOME"
    else
        _uvenv__doc_check "UVENV_HOME writable" 1 "$UVENV_HOME"
    fi

    printf '\nShell integration\n'

    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] || continue
        if grep -q 'uvenv/uvenv.sh' "$rc"; then
            _uvenv__doc_check "$rc sources uvenv" 0
            rc_found=1
        fi
    done
    if [ "$rc_found" -eq 0 ]; then
        _uvenv__doc_check "rc sources uvenv" 1 "add: source $UVENV_PREFIX/uvenv.sh"
    fi

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        printf '\nActive venv: %s\n' "$VIRTUAL_ENV"
    fi

    printf '\n'
    if [ "$fails" -eq 0 ]; then
        printf 'All checks passed.\n'
        return 0
    fi
    printf '%d check(s) failed.\n' "$fails"
    return 1
}
