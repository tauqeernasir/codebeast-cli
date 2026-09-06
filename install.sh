#!/usr/bin/env bash
# Install the codebeast CLI binary from GitHub Releases or a local tarball.
#
# Public binaries (no GitHub account or token):
#   curl -fsSL https://raw.githubusercontent.com/tauqeernasir/codebeast-cli/main/install.sh | bash
#
# Private source repo (from a clone, with a token that can read releases):
#   CODEBEAST_REPO=tauqeernasir/codebeast CODEBEAST_GITHUB_TOKEN=... ./install.sh
#
# Local tarball (no GitHub):
#   CODEBEAST_TARBALL=./codebeast-darwin-arm64.tar.gz ./install.sh
#
# Optional environment:
#   CODEBEAST_VERSION       Release tag (e.g. v0.1.0). Default: latest
#   CODEBEAST_INSTALL_DIR   Install directory. Default: ~/.local/bin
#   CODEBEAST_REPO          GitHub owner/repo. Default: tauqeernasir/codebeast-cli
#   CODEBEAST_GITHUB_TOKEN  Token for private repos (falls back to GITHUB_TOKEN).
#                           `gh auth token` is used only after a public download fails.
#   CODEBEAST_TARBALL       Install from this .tar.gz instead of GitHub
set -euo pipefail

REPO="${CODEBEAST_REPO:-tauqeernasir/codebeast-cli}"
INSTALL_DIR="${CODEBEAST_INSTALL_DIR:-${HOME}/.local/bin}"
VERSION="${CODEBEAST_VERSION:-latest}"
TARBALL="${CODEBEAST_TARBALL:-}"

usage() {
  cat <<EOF
Install codebeast from GitHub Releases or a local tarball.

Public binaries:
  curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash

Private source repo:
  CODEBEAST_REPO=tauqeernasir/codebeast CODEBEAST_GITHUB_TOKEN=ghp_... ./install.sh
  # If public download fails, falls back to `gh auth token` automatically.

Local tarball (no GitHub):
  CODEBEAST_TARBALL=./codebeast-darwin-arm64.tar.gz ./install.sh
  make test-install

Environment:
  CODEBEAST_VERSION       Release tag (v0.1.0) or "latest" (default)
  CODEBEAST_INSTALL_DIR   Where to install the binary (default: ~/.local/bin)
  CODEBEAST_REPO          GitHub owner/repo (default: ${REPO})
  CODEBEAST_GITHUB_TOKEN  Token for private repositories
  CODEBEAST_TARBALL       Path to a release tarball to install instead of downloading
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

log() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

need_cmd tar
need_cmd uname
need_cmd mktemp

os="$(uname -s)"
arch="$(uname -m)"

case "$os" in
  Darwin) target_os="darwin" ;;
  Linux) target_os="linux" ;;
  *) die "unsupported OS '${os}'. codebeast ships macOS and Linux binaries." ;;
esac

case "$arch" in
  x86_64 | amd64) target_arch="x64" ;;
  arm64 | aarch64) target_arch="arm64" ;;
  *) die "unsupported architecture '${arch}'." ;;
esac

target="${target_os}-${target_arch}"
asset="codebeast-${target}.tar.gz"

if [ "$VERSION" = "latest" ]; then
  version_label="latest"
else
  VERSION="${VERSION#v}"
  version_label="v${VERSION}"
fi

# Explicit tokens only. `gh auth token` is a fallback after a public download
# fails, so a stale `gh` login cannot break a public install.
explicit_token() {
  if [ -n "${CODEBEAST_GITHUB_TOKEN:-}" ]; then
    printf '%s' "$CODEBEAST_GITHUB_TOKEN"
  elif [ -n "${GITHUB_TOKEN:-}" ]; then
    printf '%s' "$GITHUB_TOKEN"
  fi
}

gh_token() {
  command -v gh >/dev/null 2>&1 || return 1
  gh auth token 2>/dev/null || true
}

github_api() {
  path="$1"
  url="https://api.github.com/${path}"
  if [ -n "${GITHUB_API_TOKEN:-}" ]; then
    curl -fsSL \
      -H "Authorization: Bearer ${GITHUB_API_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$url"
  else
    curl -fsSL \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$url"
  fi
}

download_public() {
  dest="$1"
  src="$2"
  curl -fsSL -o "$dest" "$src"
}

# Prefer `gh release download` (handles the GitHub → CDN redirect without
# forwarding Authorization). Fall back to curl -L.
download_release_asset() {
  dest="$1"
  asset_id="$2"
  tag_name="$3"
  pattern="$(basename "$dest")"
  dir="$(dirname "$dest")"

  if command -v gh >/dev/null 2>&1 && [ -n "${GITHUB_API_TOKEN:-}" ] && [ -n "$tag_name" ]; then
    if GH_TOKEN="$GITHUB_API_TOKEN" gh release download "$tag_name" \
      --repo "$REPO" --pattern "$pattern" --dir "$dir" --clobber >/dev/null 2>&1; then
      [ -f "$dest" ] && return 0
    fi
  fi

  curl -fsSL -L \
    -H "Authorization: Bearer ${GITHUB_API_TOKEN}" \
    -H "Accept: application/octet-stream" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -o "$dest" \
    "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}"
}

# Prints: tag_name \t asset_id \t checksum_id  (checksum_id may be empty).
# Skips draft releases so CODEBEAST_VERSION=latest cannot install a leftover draft.
parse_release_json() {
  python3 -c '
import json, sys
want, checksum_name = sys.argv[1], sys.argv[2]
data = json.load(sys.stdin)
if isinstance(data, list):
    data = next((r for r in data if isinstance(r, dict) and not r.get("draft")), {})
elif isinstance(data, dict) and data.get("draft"):
    data = {}
if not isinstance(data, dict):
    data = {}
asset_id = checksum_id = ""
for asset in data.get("assets") or []:
    name = asset.get("name")
    if name == want:
        asset_id = str(asset.get("id") or "")
    elif name == checksum_name:
        checksum_id = str(asset.get("id") or "")
tag = data.get("tag_name") or ""
if not asset_id:
    raise SystemExit(1)
print(f"{tag}\t{asset_id}\t{checksum_id}")
' "$1" "$2"
}

fetch_release_json() {
  if [ "$VERSION" = "latest" ]; then
    if json="$(github_api "repos/${REPO}/releases/latest" 2>/dev/null)"; then
      printf '%s' "$json"
      return 0
    fi
    github_api "repos/${REPO}/releases?per_page=20"
    return
  fi
  github_api "repos/${REPO}/releases/tags/${version_label}"
}

download_via_api() {
  need_cmd python3
  log "Downloading ${asset} via GitHub API"
  release_json="$(fetch_release_json)" || die "could not read releases for ${REPO}. Check the token can access this private repo."
  parsed="$(printf '%s' "$release_json" | parse_release_json "$asset" "${asset}.sha256")" \
    || die "release ${version_label} has no asset ${asset} (drafts are skipped). Create a GitHub Release first."
  tag_name="$(printf '%s' "$parsed" | cut -f1)"
  asset_id="$(printf '%s' "$parsed" | cut -f2)"
  checksum_id="$(printf '%s' "$parsed" | cut -f3)"
  download_release_asset "${tmp}/${asset}" "$asset_id" "$tag_name" \
    || die "failed to download asset ${asset}"
  if [ -n "$checksum_id" ]; then
    download_release_asset "${tmp}/${asset}.sha256" "$checksum_id" "$tag_name" || true
  fi
}

download_via_public() {
  if [ "$VERSION" = "latest" ]; then
    download_base="https://github.com/${REPO}/releases/latest/download"
  else
    download_base="https://github.com/${REPO}/releases/download/${version_label}"
  fi
  url="${download_base}/${asset}"
  log "Downloading ${url}"
  if ! download_public "${tmp}/${asset}" "$url"; then
    return 1
  fi
  download_public "${tmp}/${asset}.sha256" "${url}.sha256" || true
  return 0
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

log "Installing codebeast (${version_label}, ${target})"

if [ -n "$TARBALL" ]; then
  [ -f "$TARBALL" ] || die "CODEBEAST_TARBALL not found: ${TARBALL}"
  log "Using local tarball ${TARBALL}"
  cp "$TARBALL" "${tmp}/${asset}"
  if [ -f "${TARBALL}.sha256" ]; then
    cp "${TARBALL}.sha256" "${tmp}/${asset}.sha256"
  fi
else
  need_cmd curl
  GITHUB_API_TOKEN="$(explicit_token)"
  if [ -n "$GITHUB_API_TOKEN" ]; then
    download_via_api
  elif download_via_public; then
    :
  else
    GITHUB_API_TOKEN="$(gh_token)"
    if [ -n "$GITHUB_API_TOKEN" ]; then
      log "Public download failed; retrying with gh auth token"
      download_via_api
    else
      die "failed to download ${asset}. For a private repo set CODEBEAST_GITHUB_TOKEN (repo scope) or run: CODEBEAST_TARBALL=path/to/${asset} $0"
    fi
  fi
fi

if [ -f "${tmp}/${asset}.sha256" ]; then
  log "Verifying checksum"
  (
    cd "$tmp"
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum -c "${asset}.sha256"
    else
      shasum -a 256 -c "${asset}.sha256"
    fi
  )
else
  printf 'warning: checksum file not found; skipped verification\n' >&2
fi

tar -xzf "${tmp}/${asset}" -C "$tmp"
if [ ! -f "${tmp}/codebeast" ]; then
  die "archive did not contain a codebeast binary"
fi
chmod +x "${tmp}/codebeast"

mkdir -p "$INSTALL_DIR"
install_path="${INSTALL_DIR}/codebeast"
mv "${tmp}/codebeast" "$install_path"
chmod +x "$install_path"

log "Installed ${install_path}"

if ! "$install_path" --help >/dev/null 2>&1; then
  printf 'warning: installed binary did not run (--help failed)\n' >&2
fi

case ":${PATH}:" in
  *:"${INSTALL_DIR}":*)
    log "Run: codebeast"
    ;;
  *)
    printf '\n%s is not on PATH. Add this to your shell profile:\n' "$INSTALL_DIR"
    printf '  export PATH="%s:$PATH"\n' "$INSTALL_DIR"
    printf 'Then restart your shell or run: source ~/.zshrc\n'
    printf 'Or invoke it directly: %s\n' "$install_path"
    ;;
esac
