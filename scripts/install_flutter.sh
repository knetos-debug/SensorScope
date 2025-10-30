#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.22.2}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
INSTALL_ROOT="${FLUTTER_HOME:-$PWD/.flutter-sdk}"

ARCHIVE_NAME="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
DEFAULT_BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux"
BASE_URL="${FLUTTER_BASE_URL:-$DEFAULT_BASE_URL}"
DOWNLOAD_URL="${BASE_URL%/}/${ARCHIVE_NAME}"

TMPDIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

log() {
  echo "[install_flutter] $*"
}

command -v curl >/dev/null 2>&1 || { log "curl is required"; exit 1; }
command -v tar >/dev/null 2>&1 || { log "tar is required"; exit 1; }

log "Downloading Flutter SDK ${FLUTTER_VERSION} (${FLUTTER_CHANNEL})"
if ! curl -fL "$DOWNLOAD_URL" -o "$TMPDIR/$ARCHIVE_NAME"; then
  log "Primary download URL failed: $DOWNLOAD_URL"
  if [[ -n "${FLUTTER_MIRROR_BASE_URL:-}" ]]; then
    MIRROR_URL="${FLUTTER_MIRROR_BASE_URL%/}/${ARCHIVE_NAME}"
    log "Attempting mirror URL: $MIRROR_URL"
    curl -fL "$MIRROR_URL" -o "$TMPDIR/$ARCHIVE_NAME"
  else
    log "Set FLUTTER_BASE_URL or FLUTTER_MIRROR_BASE_URL to use a different mirror."
    exit 1;
  fi
fi

log "Extracting archive"
mkdir -p "$TMPDIR/unpack"
tar -xJf "$TMPDIR/$ARCHIVE_NAME" -C "$TMPDIR/unpack"

log "Installing to $INSTALL_ROOT"
rm -rf "$INSTALL_ROOT"
mkdir -p "$(dirname "$INSTALL_ROOT")"
mv "$TMPDIR/unpack/flutter" "$INSTALL_ROOT"

log "Flutter SDK installed. Add the following to your PATH:"
log "  export PATH=\"$INSTALL_ROOT/bin:\$PATH\""
