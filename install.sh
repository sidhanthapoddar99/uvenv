#!/usr/bin/env bash
# uvenv installer
#
# Usage:
#   curl -fsSL https://github.com/sidhanthapoddar99/uvenv/releases/latest/download/install.sh | bash
#
# Optional env vars:
#   UVENV_VERSION   pin a release tag (e.g. v0.2.0). Default: latest
#   UVENV_REF       fetch the repo from a branch/commit (e.g. main) instead of a release tarball
#   UVENV_PREFIX    install dir. Default: ~/.config/uvenv
#   UVENV_REPO      override repo. Default: sidhanthapoddar99/uvenv
#
# This installer is ALSO bundled inside the release tarball, so
# `uvenv self-update` re-runs it without needing the network for the script itself.

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

for dep in curl tar; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        die "$dep not found. Install $dep, then re-run this installer."
    fi
done
ok "curl + tar found"

echo

# ---------- 2. Resolve download URL ----------

TMPDIR_INSTALL="$(mktemp -d)"
# shellcheck disable=SC2064
trap "rm -rf '$TMPDIR_INSTALL'" EXIT

TARBALL="$TMPDIR_INSTALL/uvenv.tar.gz"

if [ -n "$REF" ]; then
    # Branch / commit / tag from the repo (no release artifact needed).
    URL="https://github.com/$REPO/archive/$REF.tar.gz"
    info "Fetching repo from ref: $REF"
elif [ "$VERSION" = "latest" ]; then
    # Resolve "latest" to the actual tag so we know the inner directory name.
    info "Resolving latest release..."
    VERSION="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -1)"
    if [ -z "$VERSION" ]; then
        die "Could not resolve latest release tag. Set UVENV_VERSION=vX.Y.Z explicitly."
    fi
    info "Latest is: $VERSION"
    URL="https://github.com/$REPO/releases/download/$VERSION/uvenv-$VERSION.tar.gz"
else
    URL="https://github.com/$REPO/releases/download/$VERSION/uvenv-$VERSION.tar.gz"
    info "Fetching uvenv $VERSION"
fi

# ---------- 3. Download ----------

if ! curl -fsSL "$URL" -o "$TARBALL"; then
    die "Failed to download from $URL
       Check network, or specify UVENV_REF=main to install from main branch."
fi
ok "Downloaded tarball ($(du -h "$TARBALL" | awk '{print $1}'))"

# ---------- 4. Extract + verify ----------

STAGE="$TMPDIR_INSTALL/stage"
mkdir -p "$STAGE"
tar -xzf "$TARBALL" -C "$STAGE" || die "Failed to extract tarball"

# Tarball top-level is a single directory; find it.
INNER="$(find "$STAGE" -mindepth 1 -maxdepth 1 -type d | head -1)"
if [ -z "$INNER" ] || [ ! -d "$INNER" ]; then
    die "Tarball has no top-level directory"
fi

# Sanity: must contain uvenv.sh with the function definition
if [ ! -f "$INNER/uvenv.sh" ] || ! grep -q '^uvenv() {' "$INNER/uvenv.sh"; then
    die "Tarball doesn't look like uvenv (no valid uvenv.sh inside)"
fi

# Sanity: must contain the lib/ directory
if [ ! -d "$INNER/lib" ]; then
    die "Tarball is missing lib/ — refusing to install"
fi
ok "Tarball verified"

# ---------- 5. Atomic swap ----------

mkdir -p "$(dirname "$PREFIX")"

# Move any existing install aside (keep last one as .bak for rollback)
if [ -d "$PREFIX" ]; then
    rm -rf "$PREFIX.bak"
    mv "$PREFIX" "$PREFIX.bak"
    info "Existing install moved to $PREFIX.bak"
fi

mv "$INNER" "$PREFIX" || {
    # Restore on failure
    if [ -d "$PREFIX.bak" ]; then
        mv "$PREFIX.bak" "$PREFIX"
        die "Install failed — restored previous version from .bak"
    fi
    die "Install failed and no backup to restore"
}
ok "Installed to $PREFIX"

# ---------- 6. Add source line to shell rc ----------

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

if [ "$RC_UPDATED" -eq 0 ] \
   && ! grep -q 'uvenv/uvenv.sh' "$HOME/.bashrc" 2>/dev/null \
   && ! grep -q 'uvenv/uvenv.sh' "$HOME/.zshrc"  2>/dev/null; then
    warn "No .bashrc or .zshrc found. Add this line manually to your shell rc:"
    echo "      $SOURCE_LINE"
fi

# ---------- 7. Source for current shell (best-effort) ----------

# shellcheck disable=SC1090,SC1091
. "$PREFIX/uvenv.sh" 2>/dev/null || true

echo
green "Done!"
bold "Next steps:"
info "1. Open a new shell  (or run: source $PREFIX/uvenv.sh )"
info "2. Verify:           uvenv version"
info "3. Try it:           uvenv create -n scratch --python 3.13"
info "4. Tab completions:  eval \"\$(uvenv completions bash)\"   # or zsh"
echo
info "Docs:    https://github.com/$REPO/blob/main/USER_GUIDE.md"
info "Update:  uvenv self-update"
