#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/.build/verification"
OUT_BIN="$OUT_DIR/SteadyTapVerification"

mkdir -p "$OUT_DIR"

swiftc \
  "$ROOT/Core/Extensions.swift" \
  "$ROOT/Core/Models.swift" \
  "$ROOT/Core/CalibrationEngine.swift" \
  "$ROOT/Core/PersistenceStore.swift" \
  "$ROOT/Core/IntroQuickStartContent.swift" \
  "$ROOT/Verification/SteadyTapVerification.swift" \
  -o "$OUT_BIN"

"$OUT_BIN"
