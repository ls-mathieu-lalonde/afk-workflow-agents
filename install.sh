#!/bin/sh
set -eu

force=false
destination="${HOME}/.opencode/agents"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf 'Usage: %s [--force] [destination]\n' "$0"
  exit 0
fi

if [ "${1:-}" = "--force" ]; then
  force=true
  shift
fi

if [ "$#" -gt 1 ]; then
  printf 'Usage: %s [--force] [destination]\n' "$0" >&2
  exit 2
fi

if [ "$#" -eq 1 ]; then
  destination=$1
fi

source_dir=$(CDPATH= cd "$(dirname "$0")/agents" && pwd)
mkdir -p "$destination"

for source in "$source_dir"/*.md; do
  name=$(basename "$source")
  target="$destination/$name"

  if [ -e "$target" ] && [ "$force" = false ]; then
    printf 'Refusing to overwrite %s (use --force)\n' "$target" >&2
    exit 1
  fi

  cp "$source" "$target"
  printf 'Installed %s\n' "$target"
done
