#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/.build/verification"
OUT_BIN="$OUT_DIR/SteadyTapVerification"

mkdir -p "$OUT_DIR"

swiftc \
  "$ROOT/Tests/CoreSources/Extensions.swift" \
  "$ROOT/Tests/CoreSources/Models.swift" \
  "$ROOT/Tests/CoreSources/CalibrationEngine.swift" \
  "$ROOT/Tests/CoreSources/PersistenceStore.swift" \
  "$ROOT/Core/IntroQuickStartContent.swift" \
  "$ROOT/Verification/SteadyTapVerification.swift" \
  -o "$OUT_BIN"

"$OUT_BIN"
