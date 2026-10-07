#!/usr/bin/env bash
# Normalizes trailing whitespace across the package.
set -euo pipefail
for f in ledger/*.py tests/*.py; do
  python3 - "$f" <<'PY'
import sys
path = sys.argv[1]
lines = [line.rstrip() + "\n" for line in open(path)]
open(path, "w").writelines(lines)
PY
done
echo "formatted"
