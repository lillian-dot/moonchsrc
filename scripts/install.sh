#!/bin/sh
set -eu

repo="trail-it/moonchsrc"
version="${MOONCHSRC_VERSION:-latest}"
install_dir="${MOONCHSRC_INSTALL_DIR:-${HOME}/.local/bin}"

os=$(uname -s)
arch=$(uname -m)

case "$os" in
  Linux) platform="linux" ;;
  Darwin) platform="macos" ;;
  *) echo "moonchsrc: unsupported operating system: $os" >&2; exit 1 ;;
esac

case "$arch" in
  x86_64|amd64) machine="x86_64" ;;
  arm64|aarch64) machine="aarch64" ;;
  *) echo "moonchsrc: unsupported architecture: $arch" >&2; exit 1 ;;
esac

case "${platform}-${machine}" in
  linux-x86_64|linux-aarch64|macos-aarch64) ;;
  macos-x86_64)
    echo "moonchsrc: MoonBit does not provide a native macOS x64 toolchain; use an Apple Silicon host" >&2
    exit 1
    ;;
  *) echo "moonchsrc: unsupported platform: ${platform}-${machine}" >&2; exit 1 ;;
esac

asset="moonchsrc-${machine}-${platform}"
if [ "$version" = "latest" ]; then
  base_url="https://github.com/${repo}/releases/latest/download"
else
  case "$version" in v*) tag="$version" ;; *) tag="v$version" ;; esac
  base_url="https://github.com/${repo}/releases/download/${tag}"
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

echo "Downloading ${asset}..."
curl -fL --retry 3 -o "$tmp_dir/$asset" "$base_url/$asset"
curl -fL --retry 3 -o "$tmp_dir/SHA256SUMS" "$base_url/SHA256SUMS"

expected=$(awk -v name="$asset" '$2 == name { print $1 }' "$tmp_dir/SHA256SUMS")
if [ -z "$expected" ]; then
  echo "moonchsrc: checksum for $asset is missing" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$tmp_dir/$asset" | awk '{ print $1 }')
else
  actual=$(shasum -a 256 "$tmp_dir/$asset" | awk '{ print $1 }')
fi

if [ "$actual" != "$expected" ]; then
  echo "moonchsrc: checksum verification failed" >&2
  exit 1
fi

mkdir -p "$install_dir"
install -m 0755 "$tmp_dir/$asset" "$install_dir/moonchsrc"
echo "Installed moonchsrc to $install_dir/moonchsrc"
case ":$PATH:" in
  *":$install_dir:"*) ;;
  *) echo "Add $install_dir to PATH to run moonchsrc from any directory." ;;
esac
