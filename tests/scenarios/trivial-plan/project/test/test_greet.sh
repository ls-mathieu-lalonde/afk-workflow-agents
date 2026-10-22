#!/bin/sh
set -eu
root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
out=$("$root/src/greet.sh")
[ "$out" = "Hello, world!" ] || { echo "FAIL: got '$out'" >&2; exit 1; }
echo "ok"
