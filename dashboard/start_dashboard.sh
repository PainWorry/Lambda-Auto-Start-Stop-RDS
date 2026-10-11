#!/usr/bin/env bash
# ==============================================================================
# AWS CloudOps & Cost Governance Portal Launcher
# ==============================================================================
set -euo pipefail

PORT=8080
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================================================="
echo "  AWS CloudOps & Cost Governance - Interactive Portal"
echo "  Directory: ${DIR}"
echo "  URL:       http://localhost:${PORT}"
echo "=============================================================================="

# Check if port is already in use
if lsof -Pi :${PORT} -sTCP:LISTEN -t >/dev/null ; then
    echo "[!] Port ${PORT} is already in use. Opening browser..."
else
    echo "[*] Starting local HTTP server on port ${PORT}..."
    (cd "${DIR}" && python3 -m http.server ${PORT}) &
    SERVER_PID=$!
    trap "kill ${SERVER_PID} 2>/dev/null || true" EXIT
    sleep 1
fi

# Attempt to open browser automatically
if command -v xdg-open >/dev/null; then
    xdg-open "http://localhost:${PORT}" 2>/dev/null || true
elif command -v open >/dev/null; then
    open "http://localhost:${PORT}" 2>/dev/null || true
fi

echo "[OK] Portal running. Press Ctrl+C to terminate."
wait
