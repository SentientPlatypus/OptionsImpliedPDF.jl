#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JULIA_BIN="$(command -v julia 2>/dev/null || echo "${HOME}/.juliaup/bin/julia")"
exec "$JULIA_BIN" --startup-file=no --project="$ROOT" -e 'using OptionsImpliedPDF; println("OptionsImpliedPDF OK")'
