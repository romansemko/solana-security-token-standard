#!/bin/bash

# Security Token Development Setup Script
# This script sets up the development environment for the Security Token Standard

set -e

echo "🔧 Setting up Security Token Standard development environment..."

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust is not installed. Please install Rust first: https://rustup.rs/"
    exit 1
fi

# Check if Solana CLI is installed (pinned version)
SOLANA_CLI_VERSION="2.2.0"
if command -v solana &> /dev/null; then
    current_solana_version="$(solana --version | awk '{print $2}')"
else
    current_solana_version=""
fi

if [ "$current_solana_version" != "$SOLANA_CLI_VERSION" ]; then
    echo "📦 Installing Solana CLI v$SOLANA_CLI_VERSION..."
    sh -c "$(curl -sSfL https://release.anza.xyz/v${SOLANA_CLI_VERSION}/install)"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
else
    echo "✅ Solana CLI v$SOLANA_CLI_VERSION already installed"
fi

# Install required Rust components
echo "🦀 Installing Rust components..."
rustup component add rustfmt clippy

# Install cargo tools (pinned versions for Rust 1.87 compatibility)
echo "🔨 Installing cargo tools..."
CARGO_AUDIT_VERSION="0.22.1"
CARGO_DENY_VERSION="0.18.3"
CARGO_EXPAND_VERSION="1.0.118"

install_cargo_tool() {
    local name="$1"
    local version="$2"

    if command -v "$name" &> /dev/null; then
        local current
        current="$("$name" --version | awk '{print $2}')"
        if [ "$current" = "$version" ]; then
            echo "✅ $name $version already installed"
            return 0
        fi
    fi

    cargo install "$name" --version "$version" --locked --force
}

install_cargo_tool cargo-audit "$CARGO_AUDIT_VERSION"
install_cargo_tool cargo-deny "$CARGO_DENY_VERSION"
install_cargo_tool cargo-expand "$CARGO_EXPAND_VERSION"

# Set Solana to devnet
echo "🌐 Configuring Solana CLI for devnet..."
solana config set --url https://api.devnet.solana.com

# Generate a new keypair if it doesn't exist
if [ ! -f ~/.config/solana/id.json ]; then
    echo "🔑 Generating new Solana keypair..."
    solana-keygen new --no-bip39-passphrase
fi

# Clean previous builds to avoid stale artifacts (especially after toolchain changes)
echo "🧹 Cleaning previous builds..."
cargo clean

# Build the program
echo "🏗️  Building Security Token program..."
cargo build-sbf --manifest-path program/Cargo.toml

# Build the hook
echo "🏗️  Building Security Token transfer hook..."
cargo build-sbf --manifest-path transfer_hook/Cargo.toml

# Build the client
echo "📚 Building Rust client..."
cargo build --manifest-path clients/rust/Cargo.toml

# Run tests
echo "🧪 Running tests..."
export SBF_OUT_DIR="$(pwd)/target/deploy"
export BPF_OUT_DIR="$SBF_OUT_DIR"
cargo test --all

# Request airdrop for development
echo "💰 Requesting SOL airdrop for development..."
solana airdrop 2 || echo "Airdrop failed, you may need to request manually"

echo "✅ Development environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Deploy your program: ./scripts/deploy.sh"
echo "2. Run integration tests: SBF_OUT_DIR=\$(pwd)/target/deploy cargo test --manifest-path tests/Cargo.toml"
echo "3. Start developing! 🚀"
