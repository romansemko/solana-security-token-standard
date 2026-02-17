#!/bin/bash

# Host build for the whole workspace (skip if 'sbf' param is passed)
set -e

echo "🧹 Cleaning previous builds..."
cargo clean

if [ "$1" != "sbf" ]; then
  cargo build --workspace
fi

# SBF build for on-chain programs only
cargo build-sbf --manifest-path program/Cargo.toml
cargo build-sbf --manifest-path transfer_hook/Cargo.toml
