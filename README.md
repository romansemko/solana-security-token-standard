# Solana Security Token Standard

A comprehensive security token implementation on Solana using Token-2022 extensions, providing KYC/AML compliance, transfer restrictions, and corporate actions support.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Building](#building)
- [Testing](#testing)
- [Deployment](#deployment)
- [Documentation](#documentation)
- [Development](#development)

## Requirements

Before you begin, ensure you have the following installed:

- **Rust** (latest stable version)
  - Install from [https://rustup.rs/](https://rustup.rs/)
  - Required components: `rustfmt`, `clippy`
- **Solana CLI** (v1.18.0 or later)
  - Install: `sh -c "$(curl -sSfL https://release.solana.com/stable/install)"`
  - Verify: `solana --version`

- **Node.js** (v18 or later) and **pnpm**
  - Install Node.js from [https://nodejs.org/](https://nodejs.org/)
  - Install pnpm: `npm install -g pnpm`

- **Cargo Tools** (optional but recommended):
  - `cargo-audit` - Security vulnerability scanning
  - `cargo-deny` - Dependency linting
  - `cargo-expand` - Macro expansion for debugging

## Installation

### Quick Setup

Run the automated setup script to install all dependencies and configure your environment:

```bash
./scripts/setup.sh
```

This script will:

- Verify Rust and Solana CLI installations
- Install required Rust components (`rustfmt`, `clippy`)
- Install recommended cargo tools (`cargo-audit`, `cargo-deny`, `cargo-expand`)
- Configure Solana CLI for devnet
- Generate a keypair if one doesn't exist
- Build both the main program and transfer hook

### Manual Setup

If you prefer manual setup:

```bash
# Install Rust components
rustup component add rustfmt clippy

# Install cargo tools
cargo install cargo-audit cargo-deny cargo-expand

# Configure Solana for devnet
solana config set --url https://api.devnet.solana.com

# Generate keypair (if needed)
solana-keygen new --no-bip39-passphrase

# Install Node.js dependencies
pnpm install

# Build programs
./scripts/build.sh
```

## Building

### Build Programs

Build both the main security token program and the transfer hook:

```bash
./scripts/build.sh
```

This compiles:

- Security Token Program (`program/`)
- Transfer Hook Program (`transfer_hook/`)

For SBF-only builds (skip host build):

```bash
./scripts/build.sh sbf
```

### Build with Clients

Generate IDL and client libraries:

```bash
# Build everything including clients
pnpm build-all

# Or step by step:
pnpm build              # Build programs
pnpm generate-idl       # Generate IDL from program
pnpm generate-clients   # Generate Rust and TypeScript clients
```

### Code Formatting

Format all Rust code in the project:

```bash
./scripts/format.sh
```

## Testing

The project includes comprehensive unit and integration tests.

### Run All Tests

```bash
./scripts/test.sh
```

This will:

1. Clean previous builds
2. Build all workspace components
3. Run program unit tests
4. Run client library tests
5. Build programs for SBF
6. Run integration tests
7. Run BPF program tests

### Run Specific Tests

**Unit Tests (Program):**

```bash
cargo test --manifest-path program/Cargo.toml
```

**Client Tests:**

```bash
cargo test --manifest-path clients/rust/Cargo.toml
```

**Integration Tests:**

```bash
# Build programs first
./scripts/build.sh sbf

# Run integration tests
SBF_OUT_DIR=$(pwd)/target/deploy cargo test --manifest-path tests/Cargo.toml
```

**Quick Test (via npm):**

```bash
pnpm test
```

**Run with Code Quality Checks:**

The test script automatically runs additional quality checks:

- Code formatting (`cargo fmt --check`)
- Linting (`cargo clippy`)
- Security audit (`cargo audit` - if installed)
- License compliance (`cargo deny` - if installed)

These checks run automatically and don't require any parameters.

## Deployment

### Prerequisites

Ensure you have SOL in your wallet for deployment fees:

```bash
# Check your balance
solana balance

# Request airdrop on devnet (2 SOL)
solana airdrop 2
```

**Note:** If the airdrop fails (common on devnet due to rate limits), use the [Solana Faucet](https://faucet.solana.com/) to request devnet SOL manually.

### Deploy Programs

By default, programs deploy to **devnet**. To deploy to a different cluster (testnet or mainnet), pass the cluster name as an argument.

**Deploy both programs (recommended):**

```bash
# Devnet (default)
pnpm deploy:all

# Other clusters
pnpm deploy:all -- testnet
pnpm deploy:all -- mainnet
```

**Deploy individual programs:**

```bash
# Main program only
./scripts/deploy.sh [devnet|testnet|mainnet]

# Transfer hook only
./scripts/deploy-transfer-hook.sh [devnet|testnet|mainnet]
```

### Post-Deployment

After deployment, the program IDs are saved to:

- `program_id.txt` - Main security token program ID
- `transfer_hook_program_id.txt` - Transfer hook program ID

Verify deployment:

```bash
solana program show <PROGRAM_ID>
```

## Documentation

- **[Program Instructions](./docs/program-instructions.md)** - Complete instruction reference, account structures, and authorization model
- **[IDL](./idl/security_token_program.json)** - Codama IDL for client generation

## Development

### Available Scripts

| Script                              | Description               |
| ----------------------------------- | ------------------------- |
| `./scripts/setup.sh`                | Initial environment setup |
| `./scripts/build.sh`                | Build programs            |
| `./scripts/test.sh`                 | Run all tests             |
| `./scripts/format.sh`               | Format code               |
| `./scripts/deploy.sh`               | Deploy main program       |
| `./scripts/deploy-transfer-hook.sh` | Deploy transfer hook      |

### NPM Scripts

```bash
pnpm build              # Build programs
pnpm build-all          # Build + generate IDL + generate clients
pnpm test               # Run tests
pnpm generate-idl       # Generate IDL from program
pnpm generate-clients   # Generate client libraries
pnpm deploy:all         # Deploy both programs
pnpm deploy:program     # Deploy main program
pnpm deploy:transfer-hook # Deploy transfer hook
```

### Project Structure

```
├── program/              # Main security token program
├── transfer_hook/        # Transfer hook program
├── clients/
│   ├── rust/            # Rust client library
│   └── typescript/      # TypeScript client library
├── tests/               # Integration tests
├── scripts/             # Build and deployment scripts
├── idl/                 # Generated IDL
└── docs/                # Documentation
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `./scripts/test.sh`
5. Format code: `./scripts/format.sh`
6. Submit a pull request

## License

- [Apache-2.0](LICENSE.md)
- [Third Party Notices](THIRD_PARTY_NOTICES.md)
