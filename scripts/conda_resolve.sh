#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
JULIA_BIN="$(command -v julia 2>/dev/null || echo "${HOME}/.juliaup/bin/julia")"
exec "$JULIA_BIN" --project="$ROOT" -e 'using CondaPkg; CondaPkg.resolve()'
