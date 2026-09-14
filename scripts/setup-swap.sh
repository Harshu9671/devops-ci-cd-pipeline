#!/usr/bin/env bash
# ==============================================================================
# Setup Swap Space for AWS Free Tier (t2.micro / t3.micro)
# Reason: t2.micro has only 1GB RAM. Jenkins + Docker builds will crash without swap!
# ==============================================================================

set -euo pipefail

SWAP_SIZE="2G"
SWAP_FILE="/swapfile"

echo "==> Checking existing swap space..."
if free -h | grep -q "Swap: *0B"; then
    echo "==> No active swap detected. Creating ${SWAP_SIZE} swap file..."
    sudo fallocate -l "${SWAP_SIZE}" "${SWAP_FILE}" || sudo dd if=/dev/zero of="${SWAP_FILE}" bs=1M count=2048
    sudo chmod 600 "${SWAP_FILE}"
    sudo mkswap "${SWAP_FILE}"
    sudo swapon "${SWAP_FILE}"

    # Make swap permanent across reboots
    if ! grep -q "${SWAP_FILE}" /etc/fstab; then
        echo "${SWAP_FILE} none swap sw 0 0" | sudo tee -a /etc/fstab
    fi

    # Adjust swappiness for optimal responsiveness
    sudo sysctl vm.swappiness=10
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

    echo "==> Swap space created successfully!"
    free -h
else
    echo "==> Active swap space already present:"
    free -h
fi
