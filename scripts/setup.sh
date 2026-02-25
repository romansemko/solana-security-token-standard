#!/bin/bash

# Security Token Development Setup Script
# This script sets up the development environment for the Security Token Standard

set -euo pipefail

echo "🔧 Setting up Security Token Standard development environment..."

# Ensure cargo binaries are available in this shell.
export PATH="$HOME/.cargo/bin:$PATH"

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust is not installed. Please install Rust first: https://rustup.rs/"
    exit 1
fi

# Check if Node.js is installed (required for pnpm + IDL/client generation)
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first: https://nodejs.org/"
    exit 1
fi

node_major="$(node -p 'parseInt(process.versions.node.split(\".\")[0], 10)')"
if [ "${node_major}" -lt 18 ]; then
    echo "❌ Node.js 18+ is required. Found: $(node --version)"
    exit 1
fi

# Check if Solana CLI is installed (pinned version)
SOLANA_CLI_VERSION="2.2.0"
SOLANA_INSTALL_BIN="$HOME/.local/share/solana/install/active_release/bin"
if command -v solana &> /dev/null; then
    current_solana_version="$(solana --version | awk '{print $2}')"
else
    current_solana_version=""
fi

if [ "$current_solana_version" != "$SOLANA_CLI_VERSION" ]; then
    echo "📦 Installing Solana CLI v$SOLANA_CLI_VERSION..."
    sh -c "$(curl -sSfL https://release.anza.xyz/v${SOLANA_CLI_VERSION}/install)"
    export PATH="$SOLANA_INSTALL_BIN:$PATH"
else
    echo "✅ Solana CLI v$SOLANA_CLI_VERSION already installed"
fi

# Prefer the pinned Solana toolchain path for this script run.
if [ -d "$SOLANA_INSTALL_BIN" ]; then
    export PATH="$SOLANA_INSTALL_BIN:$PATH"
fi

resolved_solana_version="$(solana --version | awk '{print $2}')"
if [ "$resolved_solana_version" != "$SOLANA_CLI_VERSION" ]; then
    echo "❌ Solana CLI version mismatch. Expected $SOLANA_CLI_VERSION, found $resolved_solana_version."
    echo "   Ensure pinned Solana is first in PATH:"
    echo "   export PATH=\"$SOLANA_INSTALL_BIN:\$PATH\""
    exit 1
fi

# Install required Rust components
echo "🦀 Installing Rust components..."
RUST_TOOLCHAIN_VERSION="1.87.0"
rustup component add --toolchain "$RUST_TOOLCHAIN_VERSION" rustfmt clippy

# Install cargo tools (pinned versions for Rust 1.87 compatibility)
echo "🔨 Installing cargo tools..."
CARGO_AUDIT_VERSION="0.22.1"
CARGO_DENY_VERSION="0.18.3"
CARGO_EXPAND_VERSION="1.0.118"
SHANK_CLI_VERSION="0.4.5"

install_cargo_tool() {
    local package="$1"
    local binary="$2"
    local version="$3"

    if command -v "$binary" &> /dev/null; then
        local current
        current="$("$binary" --version | awk '{print $2}')"
        if [ "$current" = "$version" ]; then
            echo "✅ $binary $version already installed"
            return 0
        fi
    fi

    cargo install "$package" --version "$version" --locked --force
}

install_cargo_tool_unpinned() {
    local package="$1"
    local binary="$2"

    if command -v "$binary" &> /dev/null; then
        echo "✅ $binary already installed"
        return 0
    fi

    cargo install "$package" --locked
}

install_cargo_tool cargo-audit cargo-audit "$CARGO_AUDIT_VERSION"
install_cargo_tool cargo-deny cargo-deny "$CARGO_DENY_VERSION"
install_cargo_tool cargo-expand cargo-expand "$CARGO_EXPAND_VERSION"
install_cargo_tool shank-cli shank "$SHANK_CLI_VERSION"
install_cargo_tool_unpinned solana-verify solana-verify

if ! command -v shank &> /dev/null; then
    echo "❌ shank is required for 'pnpm generate-idl' but was not found in PATH."
    exit 1
fi

# Ensure pnpm is present. Prefer corepack-managed pnpm when available.
if ! command -v pnpm &> /dev/null; then
    if command -v corepack &> /dev/null; then
        echo "📦 Enabling pnpm via corepack..."
        corepack enable
        corepack prepare pnpm@10.30.2 --activate
    fi
fi

if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm is required. Install it with: npm install -g pnpm"
    exit 1
fi

echo "📦 Installing Node.js dependencies..."
pnpm install --frozen-lockfile

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
echo "Toolchain summary:"
echo "- Solana CLI: $(solana --version)"
echo "- Rust: $(rustc --version)"
echo "- Node.js: $(node --version)"
echo "- pnpm: $(pnpm --version)"
echo "- shank: $(shank --version)"
echo "- solana-verify: $(solana-verify --version)"
echo ""
echo "Next steps:"
echo "1. Deploy your program: ./scripts/deploy.sh"
echo "2. Run integration tests: SBF_OUT_DIR=\$(pwd)/target/deploy cargo test --manifest-path tests/Cargo.toml"
echo "3. Start developing! 🚀"
