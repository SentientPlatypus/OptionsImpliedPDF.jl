#!/usr/bin/env bash
# Run the stock example with settings that avoid WSL/global startup breakage.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JULIA_BIN="$(command -v julia 2>/dev/null || echo "${HOME}/.juliaup/bin/julia")"
exec "$JULIA_BIN" --startup-file=no --project="$ROOT" "$ROOT/src/0_example.jl"
