#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'HELP'
Diagnostic CLI - Linux System and Network Toolkit

Usage:
  diagnostic system
  diagnostic network <host>
  diagnostic disk
  diagnostic help

Exit codes:
  0  Success
  1  Operational failure
  2  Invalid command or input
HELP
}

invalid() {
    printf 'ERROR: %s\n' "$1" >&2
    usage >&2
    exit 2
}

system_info() {
    local os

    if [[ -r /etc/os-release ]]; then
        os=$(
            . /etc/os-release
            printf '%s' "${PRETTY_NAME:-Linux}"
        )
    else
        os="$(uname -s)"
    fi

    echo "===== SYSTEM DIAGNOSTICS ====="
    printf 'Hostname: %s\n' "$(hostname)"
    printf 'User:     %s\n' "$(id -un 2>/dev/null || id -u)"
    printf 'Date:     %s\n' "$(date -Is)"
    printf 'OS:       %s\n' "$os"
    printf 'Kernel:   %s\n' "$(uname -r)"
    printf 'Uptime:   %s\n' "$(uptime -p)"
    printf 'CPUs:     %s\n' "$(nproc)"
    printf 'PWD:      %s\n' "$PWD"

    echo
    echo "===== MEMORY ====="
    free -h
}

disk_info() {
    echo "===== DISK INFORMATION ====="

    if ! df -h /; then
        echo "ERROR: Unable to inspect filesystem." >&2
        return 1
    fi
}

network_info() {
    local host="$1"
    local address=""

    if [[ ! "$host" =~ ^[A-Za-z0-9:][A-Za-z0-9._:-]*$ ]] ||
       (( ${#host} > 253 )); then
        invalid "Invalid hostname or IP address."
    fi

    echo "===== NETWORK DIAGNOSTICS ====="
    printf 'Host: %s\n' "$host"

    address="$(
        getent ahosts "$host" 2>/dev/null |
            awk 'NR == 1 {print $1}'
    )" || true

    if [[ -z "$address" ]]; then
        address="$(
            getent hosts "$host" 2>/dev/null |
                awk 'NR == 1 {print $1}'
        )" || true
    fi

    if [[ -z "$address" ]]; then
        echo "ERROR: Host resolution failed." >&2
        return 1
    fi

    printf 'Resolved IP: %s\n' "$address"

    if command -v ip >/dev/null 2>&1; then
        echo
        echo "===== NETWORK INTERFACES ====="
        ip -brief address || true
    fi

    echo
    echo "===== CONNECTIVITY ====="

    if timeout 4 ping -n -c 1 -W 2 "$host" \
        >/dev/null 2>&1; then
        echo "Connectivity: SUCCESS"
        return 0
    fi

    echo "Connectivity: FAILED"
    return 1
}

if (( $# == 0 )); then
    invalid "Missing command."
fi

COMMAND="$1"
shift

case "$COMMAND" in
    help)
        (( $# == 0 )) || invalid "Unexpected help arguments."
        usage
        ;;
    system)
        (( $# == 0 )) || invalid "Unexpected system arguments."
        system_info
        ;;
    disk)
        (( $# == 0 )) || invalid "Unexpected disk arguments."
        disk_info
        ;;
    network)
        (( $# == 1 )) || invalid "Network requires one hostname."
        network_info "$1"
        ;;
    *)
        invalid "Unknown command: $COMMAND"
        ;;
esac
