#!/usr/bin/env bash
# ==============================================================================
# Setup Swap Space for AWS Free Tier (t2.micro / t3.micro)
# Reason: t2.micro has only 1GB RAM. Jenkins + Docker builds will crash without swap!
# ==============================================================================

set -euo pipefail

SWAP_SIZE="2G"
SWAP_FILE="/swapfile"

echo "==> Checking existing swap space..."
if swapon --show --noheadings | grep -q .; then
    echo "==> Active swap space already present:"
    free -h
else
    echo "==> No active swap detected. Creating or activating ${SWAP_SIZE} swap file..."
    if [[ ! -f "${SWAP_FILE}" ]]; then
        sudo fallocate -l "${SWAP_SIZE}" "${SWAP_FILE}" || sudo dd if=/dev/zero of="${SWAP_FILE}" bs=1M count=2048
        sudo chmod 600 "${SWAP_FILE}"
    else
        sudo chmod 600 "${SWAP_FILE}"
    fi

    # Reuse a valid existing swap file; format it only when activation fails.
    if ! sudo swapon "${SWAP_FILE}"; then
        sudo mkswap "${SWAP_FILE}"
        sudo swapon "${SWAP_FILE}"
    fi

    # Make swap permanent across reboots
    if ! grep -q "${SWAP_FILE}" /etc/fstab; then
        echo "${SWAP_FILE} none swap sw 0 0" | sudo tee -a /etc/fstab
    fi

    # Adjust swappiness for optimal responsiveness
    sudo sysctl vm.swappiness=10
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

    echo "==> Swap space created successfully!"
    free -h
fi
