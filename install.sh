#!/usr/bin/env bash
# uvenv installer
# Usage:
#   curl -fsSL https://github.com/sidhanthapoddar99/uvenv/releases/latest/download/install.sh | bash
#
# Optional env vars:
#   UVENV_VERSION   pin a specific tag (e.g. v0.1.0). Default: latest release
#   UVENV_PREFIX    install dir for uvenv.sh. Default: ~/.config/uvenv
#   UVENV_REPO      override repo. Default: sidhanthapoddar99/uvenv
#   UVENV_REF       fetch from a branch (e.g. main) instead of a release tag

set -euo pipefail

REPO="${UVENV_REPO:-sidhanthapoddar99/uvenv}"
PREFIX="${UVENV_PREFIX:-$HOME/.config/uvenv}"
VERSION="${UVENV_VERSION:-latest}"
REF="${UVENV_REF:-}"

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

info()  { printf '  %s\n' "$*"; }
ok()    { green "✓ $*"; }
warn()  { yellow "! $*"; }
die()   { red "✗ $*"; exit 1; }

bold "Installing uvenv..."
echo

# ---------- 1. Dependency checks ----------

info "Checking dependencies..."

if ! command -v mise >/dev/null 2>&1; then
    die "mise not found. Install it first: https://mise.run
       Then re-run this installer."
fi
ok "mise found ($(mise --version 2>/dev/null | head -1))"

if ! command -v uv >/dev/null 2>&1; then
    die "uv not found. Install it via mise:
         mise use -g uv@latest
       Then re-run this installer."
fi
ok "uv found ($(uv --version 2>/dev/null))"

if ! command -v curl >/dev/null 2>&1; then
    die "curl not found. Install curl, then re-run this installer."
fi
ok "curl found"

echo

# ---------- 2. Determine download URL ----------

if [ -n "$REF" ]; then
    # Branch / commit ref
    UVENV_URL="https://raw.githubusercontent.com/$REPO/$REF/uvenv.sh"
    info "Fetching uvenv.sh from ref: $REF"
elif [ "$VERSION" = "latest" ]; then
    UVENV_URL="https://github.com/$REPO/releases/latest/download/uvenv.sh"
    info "Fetching uvenv.sh from latest release"
else
    UVENV_URL="https://github.com/$REPO/releases/download/$VERSION/uvenv.sh"
    info "Fetching uvenv.sh from release: $VERSION"
fi

# ---------- 3. Download ----------

mkdir -p "$PREFIX"
TARGET="$PREFIX/uvenv.sh"

if ! curl -fsSL "$UVENV_URL" -o "$TARGET.tmp"; then
    die "Failed to download from $UVENV_URL
       Check network, or specify UVENV_REF=main to install from main branch."
fi

# Sanity check — must contain the function definition
if ! grep -q '^uvenv() {' "$TARGET.tmp"; then
    rm -f "$TARGET.tmp"
    die "Downloaded file doesn't look like uvenv.sh. Aborting."
fi

mv "$TARGET.tmp" "$TARGET"
ok "Downloaded to $TARGET"

# ---------- 4. Add source line to shell rc ----------

SOURCE_LINE="[ -f $PREFIX/uvenv.sh ] && source $PREFIX/uvenv.sh"
RC_UPDATED=0
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue
    if grep -q 'uvenv/uvenv.sh' "$rc"; then
        info "$rc already sources uvenv — skipping"
    else
        {
            echo ""
            echo "# uvenv — https://github.com/$REPO"
            echo "$SOURCE_LINE"
        } >> "$rc"
        ok "Added source line to $rc"
        RC_UPDATED=1
    fi
done

if [ "$RC_UPDATED" -eq 0 ] && ! grep -q 'uvenv/uvenv.sh' "$HOME/.bashrc" 2>/dev/null \
   && ! grep -q 'uvenv/uvenv.sh' "$HOME/.zshrc" 2>/dev/null; then
    warn "No .bashrc or .zshrc found. Add this line manually to your shell rc:"
    echo "      $SOURCE_LINE"
fi

# ---------- 5. Source for current shell (if interactive) ----------

# shellcheck disable=SC1090
. "$TARGET" || true

echo
green "Done!"
bold "Next steps:"
info "1. Open a new shell  (or run: source $TARGET )"
info "2. Verify:           uvenv help"
info "3. Try it:           uvenv create -n scratch --python 3.14"
echo
info "Docs:  https://github.com/$REPO"
