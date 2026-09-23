#!/usr/bin/env sh
# Exercise a real set/get/restore cycle without touching the user's npm config.
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

command -v moon >/dev/null 2>&1 || { echo 'moon is required' >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo 'npm is required' >&2; exit 1; }

# Keep both npm's user config and MoonChsrc's history inside this disposable
# directory. Creating it below the checkout also works on small root volumes.
demo_dir=$(mktemp -d "$PWD/.moonchsrc-demo.XXXXXX")
trap 'rm -rf -- "$demo_dir"' EXIT HUP INT TERM
export NPM_CONFIG_USERCONFIG="$demo_dir/npmrc"
export XDG_STATE_HOME="$demo_dir/state"

official='https://registry.npmjs.org/'
mirror='https://registry.npmmirror.com/'
npm config set registry "$official" --location=user

echo '1. Preview the change (no mutation)'
moon run cmd/main -- set --dry-run npm npmmirror user
test "$(npm config get registry --location=user)" = "$official"

echo '2. Apply the mirror and verify the actual npm config'
moon run cmd/main -- set npm npmmirror user
test "$(npm config get registry --location=user)" = "$mirror"
moon run cmd/main -- get npm user
test -s "$XDG_STATE_HOME/moonchsrc/history.json"

echo '3. Restore the captured value and verify it again'
moon run cmd/main -- restore npm user
test "$(npm config get registry --location=user)" = "$official"
echo 'PASS: npm source changed and restored in an isolated environment'
