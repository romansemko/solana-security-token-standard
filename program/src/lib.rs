//! Security Token Standard program for Solana blockchain
//!
//! This program provides a foundation for security tokens with compliance features.

#![allow(clippy::arithmetic_side_effects)]
// NOTE: Temporary commented out. Tired of fixing missing docs.
// #![deny(missing_docs)]

/// Constants
pub mod constants;
/// Program entrypoint
pub mod entrypoint;
/// Error types
pub mod error;
/// Instruction definitions
pub mod instruction;
/// Instruction wrappers
pub mod instructions;
/// Macros used throughout the Security Token program
pub mod macros;
/// Merkle tree utilities
pub mod merkle_tree_utils;
/// Security Token program modules (verification & operations)
pub mod modules;
/// Instruction processor
pub mod processor;
/// State structures
pub mod state;
/// Implementations for SPL Token 2022 extensions
pub mod token22_extensions;

/// Utility functions for testing
#[cfg(test)]
pub mod test_utils;
/// Utility functions
pub mod utils;
use pinocchio_pubkey::declare_id;
#[cfg(not(feature = "no-entrypoint"))]
use solana_security_txt::security_txt;

declare_id!("SSTS8Qk2bW3aVaBEsY1Ras95YdbaaYQQx21JWHxvjap");

#[cfg(not(feature = "no-entrypoint"))]
security_txt! {
    name: "SSTS Security Token Program",
    project_url: "https://ssts.org",
    contacts: "link:https://ssts.org/.well-known/security.txt",
    policy: "https://github.com/Solana-Security-Token-Standard/solana-security-token-standard/blob/main/SECURITY.md",
    source_code: "https://github.com/Solana-Security-Token-Standard/solana-security-token-standard"
}
