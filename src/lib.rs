//! Padlock - Cryptographic Repository Management System
//!
//! This crate provides comprehensive Age-based encryption and authority management
//! for repository security operations with X->M->R->I->D authority chain.
//!
//! Security Guardian: Edgar - Production cryptographic system library

pub mod encryption;
pub mod authority;

// Re-export key modules for convenience
pub use encryption::age_automation;
pub use authority::{KeyType, AuthorityChain, AuthorityKey};