#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CLI="$SCRIPT_DIR/diagnostic.sh"

echo "===== DIAGNOSTIC HEALTH CHECK ====="

for command in help system disk; do
    if "$CLI" "$command" >/dev/null; then
        echo "PASS: $command"
    else
        echo "FAIL: $command"
        exit 1
    fi
done

rc=0
"$CLI" invalid-command >/dev/null 2>&1 || rc=$?

if (( rc == 2 )); then
    echo "PASS: Invalid command rejected with exit 2"
else
    echo "FAIL: Invalid command returned exit $rc"
    exit 1
fi

echo "HEALTH CHECK PASSED"
