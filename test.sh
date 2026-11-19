#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE="${DIAGNOSTIC_TEST_IMAGE:-diagnostic-tool:local}"

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is required." >&2
    exit 1
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Building image: $IMAGE"
    docker build -t "$IMAGE" .
fi

PASS=0
FAIL=0

OUTPUT="$(mktemp)"
trap 'rm -f "$OUTPUT"' EXIT

check_exit() {
    local expected="$1"
    local description="$2"
    shift 2

    local actual=0

    "$@" >"$OUTPUT" 2>&1 || actual=$?

    if (( actual == expected )); then
        echo "PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $description (expected=$expected actual=$actual)"
        cat "$OUTPUT"
        FAIL=$((FAIL + 1))
    fi
}

echo "===== DOCKER CLI AUTOMATED TESTS ====="

check_exit 0 "Help command" \
    docker run --rm "$IMAGE" help

check_exit 0 "System command" \
    docker run --rm "$IMAGE" system

check_exit 0 "Disk command" \
    docker run --rm "$IMAGE" disk

check_exit 2 "Invalid command rejected" \
    docker run --rm "$IMAGE" invalid-command

check_exit 2 "Missing network host rejected" \
    docker run --rm "$IMAGE" network

check_exit 2 "Invalid network host rejected" \
    docker run --rm "$IMAGE" network 'bad/host'

check_exit 2 "Unexpected system argument rejected" \
    docker run --rm "$IMAGE" system extra

check_exit 2 "Unexpected disk argument rejected" \
    docker run --rm "$IMAGE" disk extra

check_exit 2 "Unexpected help argument rejected" \
    docker run --rm "$IMAGE" help extra

check_exit 2 "Extra network argument rejected" \
    docker run --rm "$IMAGE" network localhost extra

check_exit 0 "Container health-check passes" \
    docker run --rm \
        --entrypoint /opt/diagnostic/app/health-check.sh \
        "$IMAGE"

check_exit 0 "Docker Compose configuration valid" \
    docker compose config --quiet

check_exit 0 "Docker Compose system command" \
    docker compose run --rm diagnostic system

echo
echo "===== LOCALHOST NETWORK RESOLUTION ====="

NETWORK_RC=0

docker run --rm "$IMAGE" network localhost \
    >"$OUTPUT" 2>&1 || NETWORK_RC=$?

if (( NETWORK_RC <= 1 )) &&
   grep -q 'Resolved IP:' "$OUTPUT"; then
    echo "PASS: localhost resolves inside container"
    PASS=$((PASS + 1))
else
    echo "FAIL: localhost network resolution"
    cat "$OUTPUT"
    FAIL=$((FAIL + 1))
fi

echo
echo "===== NON-ROOT EXECUTION ====="

CONTAINER_UID="$(
    docker run --rm --entrypoint id "$IMAGE" -u
)"

if [[ "$CONTAINER_UID" == 10001 ]]; then
    echo "PASS: Container runs as non-root UID 10001"
    PASS=$((PASS + 1))
else
    echo "FAIL: Unexpected container UID $CONTAINER_UID"
    FAIL=$((FAIL + 1))
fi

echo
echo "======================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "======================================"

(( FAIL == 0 ))
