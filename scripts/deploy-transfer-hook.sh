#!/bin/bash

# Security Token Transfer Hook Deployment Script

set -e

PROGRAM_NAME="security_token_transfer_hook"
OUT_DIR="${SBF_OUT_DIR:-${BPF_OUT_DIR:-target/deploy}}"
PROGRAM_PATH="${TRANSFER_HOOK_PROGRAM_PATH:-${OUT_DIR}/${PROGRAM_NAME}.so}"
PROGRAM_KEYPAIR_PATH="${TRANSFER_HOOK_KEYPAIR_PATH:-${OUT_DIR}/${PROGRAM_NAME}-keypair.json}"
DEPLOYER_KEYPAIR="${DEPLOYER_KEYPAIR:-${SOLANA_KEYPAIR:-$HOME/.config/solana/id.json}}"

echo "🚀 Deploying Security Token Transfer Hook..."

# Check if program exists
if [ ! -f "$PROGRAM_PATH" ]; then
    echo "❌ Program not found. Building..."
    cargo build-sbf --manifest-path transfer_hook/Cargo.toml
fi
if [ ! -f "$PROGRAM_KEYPAIR_PATH" ]; then
    echo "❌ Program keypair not found: $PROGRAM_KEYPAIR_PATH"
    echo "Run 'cargo build-sbf --manifest-path transfer_hook/Cargo.toml' to generate it."
    exit 1
fi
if [ ! -f "$DEPLOYER_KEYPAIR" ]; then
    echo "❌ Deployer keypair not found: $DEPLOYER_KEYPAIR"
    echo "Set DEPLOYER_KEYPAIR or SOLANA_KEYPAIR to override."
    exit 1
fi

# Deploy to devnet by default
CLUSTER=${1:-devnet}
echo "📡 Deploying to $CLUSTER..."

# Set cluster
solana config set --url https://api.$CLUSTER.solana.com

# Request airdrop if needed (only for devnet/testnet)
if [ "$CLUSTER" = "devnet" ] || [ "$CLUSTER" = "testnet" ]; then
    echo "💰 Requesting airdrop..."
    solana airdrop 2 --keypair "$DEPLOYER_KEYPAIR" || echo "Airdrop failed, continuing..."
fi

# Deploy the program
echo "📦 Deploying program..."
solana program deploy "$PROGRAM_PATH" \
  --program-id "$PROGRAM_KEYPAIR_PATH" \
  --keypair "$DEPLOYER_KEYPAIR" \
  --url "https://api.$CLUSTER.solana.com"

# Get program ID
PROGRAM_ID=$(solana-keygen pubkey "$PROGRAM_KEYPAIR_PATH")
echo "✅ Program deployed successfully!"
echo "📋 Program ID: $PROGRAM_ID"
echo "🌐 Cluster: $CLUSTER"

# Save program ID to file
echo "$PROGRAM_ID" > transfer_hook_program_id.txt
echo "💾 Program ID saved to transfer_hook_program_id.txt"

# Verify deployment
echo "🔍 Verifying deployment..."
solana program show "$PROGRAM_ID" --url https://api.$CLUSTER.solana.com

echo ""
echo "🎉 Deployment complete!"
echo "You can now interact with your program using the following ID:"
echo "$PROGRAM_ID"
