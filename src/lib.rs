//! Padlock - Cryptographic Repository Management System
//!
//! This crate provides comprehensive Age-based encryption and authority management
//! for repository security operations.
//!
//! Security Guardian: Edgar - Production cryptographic system library

pub mod encryption;

// Re-export Age automation for convenience
pub use encryption::age_automation;