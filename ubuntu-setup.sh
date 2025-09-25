#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Update & install basic dependencies
apt-get update
apt-get install -y apt-transport-https ca-certificates curl clang llvm jq \
    libelf-dev libpcap-dev libbfd-dev binutils-dev build-essential make \
    linux-tools-common linux-tools-5.15.0-41-generic bpfcc-tools python3-dev gcc \
    python3-pip bsdutils pkgconf llvm-12 clang-12 clang-format-12 zlib1g-dev \
    protobuf-compiler python3-scapy python3-motor python3-psutil python3-pyroute2 \
    bpfcc-tools linux-headers-$(uname -r) linux-tools-$(uname -r) python3-pymongo \
    python3-fastapi python3-tinydb jc bpftrace

# Remove the '-12' suffixes safely
for tool in "clang" "llc" "llvm-strip"; do
    path=$(which $tool-12 2>/dev/null || true)
    if [ -n "$path" ] && [ ! -f "${path%-*}" ]; then
        ln -s "$path" "${path%-*}"
    fi
done

# Install JC via pip as well
python3 -m pip install --no-cache-dir jc

# --- MongoDB setup ---

# Remove old key if it exists
rm -f /usr/share/keyrings/mongodb-server-7.0.gpg

# Add GPG key and repository
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
    | tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null

# Install MongoDB
apt-get update
apt-get install -y mongodb-org

# Start MongoDB in the background (Docker-friendly)
mkdir -p /data/db
mongod --fork --logpath /var/log/mongod.log

echo "Ubuntu setup complete. Container is ready."
