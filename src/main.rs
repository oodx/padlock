//! Padlock - Cryptographic Repository Management System
//!
//! Main entry point for the padlock system, providing comprehensive Age-based
//! encryption and authority management for repository security.
//!
//! Security Guardian: Edgar - Production padlock system interface

use clap::{Parser, Subcommand};
use std::path::PathBuf;
use padlock::encryption::age_automation::{
    lifecycle::crud_manager::{CrudManager, LockOptions, UnlockOptions},
    config::{AgeConfig, OutputFormat},
    adapter::AdapterFactory,
    error::AgeResult,
};

#[derive(Parser)]
#[command(name = "padlock")]
#[command(about = "Cryptographic Repository Management System")]
#[command(version = "0.0.1")]
struct PadlockCli {
    #[command(subcommand)]
    command: Commands,
    
    #[arg(long, global = true, help = "Enable verbose output")]
    verbose: bool,
    
    #[arg(long, global = true, help = "Audit log file path")]
    audit_log: Option<PathBuf>,
}

#[derive(Subcommand)]
enum Commands {
    /// Lock (encrypt) files in repository
    Lock {
        #[arg(help = "Repository path to encrypt")]
        path: PathBuf,
        #[arg(short, long, help = "Passphrase for encryption")]
        passphrase: String,
        #[arg(long, help = "Use ASCII armor format")]
        armor: bool,
        #[arg(long, help = "Remove source files after encryption")]
        remove_source: bool,
    },
    
    /// Unlock (decrypt) files in repository
    Unlock {
        #[arg(help = "Repository path to decrypt")]
        path: PathBuf,
        #[arg(short, long, help = "Passphrase for decryption")]
        passphrase: String,
        #[arg(long, help = "Remove encrypted files after decryption")]
        remove_encrypted: bool,
    },
    
    /// Show repository encryption status
    Status {
        #[arg(help = "Repository path to check")]
        path: PathBuf,
    },
    
    /// Rotate encryption keys (re-encrypt with new passphrase)
    Rotate {
        #[arg(help = "Repository path")]
        path: PathBuf,
        #[arg(long, help = "Current passphrase")]
        old_passphrase: String,
        #[arg(long, help = "New passphrase")]
        new_passphrase: String,
    },
    
    /// Perform system health check
    Test {
        #[arg(help = "Optional test repository path")]
        path: Option<PathBuf>,
    },
    
    /// Emergency unlock with recovery procedures
    Emergency {
        #[arg(help = "Repository path for emergency unlock")]
        path: PathBuf,
        #[arg(short, long, help = "Recovery passphrase")]
        passphrase: String,
        #[arg(long, help = "Force operation despite warnings")]
        force: bool,
    },
}

fn main() -> AgeResult<()> {
    let cli = PadlockCli::parse();
    
    // Initialize the CRUD manager
    let adapter = AdapterFactory::create_default()?;
    let mut config = AgeConfig::production();
    if let Some(ref audit_path) = cli.audit_log {
        config = config.with_audit_log_path(audit_path.to_string_lossy().to_string());
    }
    let mut crud_manager = CrudManager::new(adapter, config)?;
    
    if cli.verbose {
        eprintln!("Padlock v0.0.1 - Cryptographic Repository Management");
        if let Some(ref log_path) = cli.audit_log {
            eprintln!("Audit logging to: {}", log_path.display());
        }
    }
    
    match cli.command {
        Commands::Lock { path, passphrase, armor, remove_source } => {
            let options = LockOptions {
                recursive: true,
                format: if armor { OutputFormat::AsciiArmor } else { OutputFormat::Binary },
                pattern_filter: None,
                backup_before_lock: !remove_source,  // If not removing source, create backup
            };
            
            if cli.verbose {
                eprintln!("Locking repository: {}", path.display());
            }
            
            let result = crud_manager.lock(&path, &passphrase, options)?;
            println!("Lock operation completed successfully");
            println!("Files processed: {}", result.processed_files.len());
            
            if !result.failed_files.is_empty() {
                eprintln!("Warning: {} files failed processing", result.failed_files.len());
                for failed_file in &result.failed_files {
                    eprintln!("  Failed: {}", failed_file);
                }
            }
        }
        
        Commands::Unlock { path, passphrase, remove_encrypted } => {
            let options = UnlockOptions {
                selective: false,
                verify_before_unlock: true,
                pattern_filter: None,
                preserve_encrypted: !remove_encrypted,
            };
            
            if cli.verbose {
                eprintln!("Unlocking repository: {}", path.display());
            }
            
            let result = crud_manager.unlock(&path, &passphrase, options)?;
            println!("Unlock operation completed successfully");
            println!("Files processed: {}", result.processed_files.len());
            
            if !result.failed_files.is_empty() {
                eprintln!("Warning: {} files failed processing", result.failed_files.len());
                for failed_file in &result.failed_files {
                    eprintln!("  Failed: {}", failed_file);
                }
            }
        }
        
        Commands::Status { path } => {
            if cli.verbose {
                eprintln!("Checking status of: {}", path.display());
            }
            
            let status = crud_manager.status(&path)?;
            
            println!("Repository Status: {}", path.display());
            println!("  Total files: {}", status.total_files);
            println!("  Encrypted files: {}", status.encrypted_files);
            println!("  Unencrypted files: {}", status.unencrypted_files);
            println!("  Encryption percentage: {:.1}%", status.encryption_percentage());
            
            if status.is_fully_encrypted() {
                println!("  Status: FULLY ENCRYPTED");
            } else if status.is_fully_decrypted() {
                println!("  Status: FULLY DECRYPTED");
            } else {
                println!("  Status: PARTIALLY ENCRYPTED");
            }
            
            if !status.failed_files.is_empty() {
                println!("  Failed files: {}", status.failed_files.len());
                for failed_file in &status.failed_files {
                    println!("    {}", failed_file);
                }
            }
        }
        
        Commands::Rotate { path, old_passphrase, new_passphrase } => {
            if cli.verbose {
                eprintln!("Rotating encryption for: {}", path.display());
            }
            
            let result = crud_manager.rotate(&path, &new_passphrase)?;
            println!("Rotation operation completed successfully");
            println!("Files processed: {}", result.processed_files.len());
            
            if !result.failed_files.is_empty() {
                eprintln!("Warning: {} files failed processing", result.failed_files.len());
                for failed_file in &result.failed_files {
                    eprintln!("  Failed: {}", failed_file);
                }
            }
        }
        
        Commands::Test { path } => {
            if cli.verbose {
                eprintln!("Performing system health check");
            }
            
            let test_path = path.unwrap_or_else(|| std::env::current_dir().unwrap());
            
            match crud_manager.verify(&test_path) {
                Ok(result) => {
                    println!("System health check: PASSED");
                    println!("Verified files: {}", result.verified_files.len());
                    println!("Overall status: {}", result.overall_status);
                }
                Err(e) => {
                    eprintln!("System health check: FAILED");
                    eprintln!("Error: {}", e);
                    std::process::exit(1);
                }
            }
        }
        
        Commands::Emergency { path, passphrase, force } => {
            if !force {
                eprintln!("WARNING: Emergency unlock procedure initiated");
                eprintln!("This operation bypasses normal security checks");
                eprintln!("Use --force flag to confirm this operation");
                std::process::exit(1);
            }
            
            if cli.verbose {
                eprintln!("Emergency unlock for: {}", path.display());
            }
            
            let result = crud_manager.emergency_unlock(&path, &passphrase)?;
            println!("Emergency unlock completed successfully");
            println!("Operation: {}", result.operation);
            println!("Affected files: {}", result.affected_files.len());
            
            if !result.recovery_actions.is_empty() {
                println!("Recovery actions taken:");
                for action in &result.recovery_actions {
                    println!("  {}", action);
                }
            }
            
            if !result.security_events.is_empty() {
                eprintln!("Security events recorded:");
                for event in &result.security_events {
                    eprintln!("  {}", event);
                }
            }
        }
    }
    
    Ok(())
}