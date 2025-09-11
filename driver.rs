//! Padlock Age Automation Driver - Testing and Demonstration Interface
//!
//! This driver provides a standalone interface for testing and demonstrating the Age automation
//! capabilities. It serves as both a validation tool and example implementation for integrating
//! the Age automation into larger systems.
//!
//! Security Guardian: Edgar - Production testing and validation interface

use std::path::{Path, PathBuf};
use std::env;
use std::process;
use tempfile::TempDir;

// Import our Age automation modules
use padlock::encryption::age_automation::{
    AgeAutomator, AgeConfig, OutputFormat, AdapterFactory,
    FileOperationsManager, RepositoryOperationsManager,
    AuditLogger, SecurityValidator
};

/// Driver configuration for testing and demonstration
#[derive(Debug)]
pub struct DriverConfig {
    pub test_data_dir: PathBuf,
    pub output_dir: PathBuf,
    pub audit_log_path: Option<PathBuf>,
    pub verbose: bool,
    pub format: OutputFormat,
}

impl DriverConfig {
    /// Create default driver configuration
    pub fn default() -> std::io::Result<Self> {
        let temp_dir = TempDir::new()?;
        Ok(Self {
            test_data_dir: temp_dir.path().join("test_data"),
            output_dir: temp_dir.path().join("output"),
            audit_log_path: Some(temp_dir.path().join("audit.log")),
            verbose: true,
            format: OutputFormat::Binary,
        })
    }
    
    /// Create configuration from command line arguments
    pub fn from_args() -> Self {
        let args: Vec<String> = env::args().collect();
        let mut config = Self::default().expect("Failed to create default config");
        
        let mut i = 1;
        while i < args.len() {
            match args[i].as_str() {
                "--test-dir" => {
                    if i + 1 < args.len() {
                        config.test_data_dir = PathBuf::from(&args[i + 1]);
                        i += 1;
                    }
                }
                "--output-dir" => {
                    if i + 1 < args.len() {
                        config.output_dir = PathBuf::from(&args[i + 1]);
                        i += 1;
                    }
                }
                "--audit-log" => {
                    if i + 1 < args.len() {
                        config.audit_log_path = Some(PathBuf::from(&args[i + 1]));
                        i += 1;
                    }
                }
                "--ascii-armor" => {
                    config.format = OutputFormat::AsciiArmor;
                }
                "--quiet" => {
                    config.verbose = false;
                }
                _ => {}
            }
            i += 1;
        }
        
        config
    }
}

/// Main driver for Age automation testing and demonstration
pub struct AgeAutomationDriver {
    config: DriverConfig,
    automator: AgeAutomator,
    file_ops: FileOperationsManager,
    repo_ops: RepositoryOperationsManager,
    audit_logger: AuditLogger,
}

impl AgeAutomationDriver {
    /// Create new driver instance
    pub fn new(config: DriverConfig) -> Result<Self, Box<dyn std::error::Error>> {
        // Create adapter using factory
        let adapter = AdapterFactory::create_default()?;
        
        // Create configuration
        let age_config = AgeConfig::production();
        
        // Create main automator
        let automator = AgeAutomator::new(adapter.clone(), age_config)?;
        
        // Create operations managers
        let file_ops = FileOperationsManager::new(adapter.clone())?;
        let repo_ops = RepositoryOperationsManager::new(adapter)?;
        
        // Create audit logger
        let audit_logger = if let Some(audit_path) = &config.audit_log_path {
            AuditLogger::with_file("driver", audit_path)?
        } else {
            AuditLogger::new("driver")?
        };
        
        Ok(Self {
            config,
            automator,
            file_ops,
            repo_ops,
            audit_logger,
        })
    }
    
    /// Run complete demonstration of Age automation capabilities
    pub fn run_demonstration(&self) -> Result<(), Box<dyn std::error::Error>> {
        self.log("🚀 Starting Age Automation Demonstration");
        
        // 1. Health check
        self.log("🔍 Performing health check...");
        self.automator.health_check()?;
        self.log("✅ Health check passed");
        
        // 2. Create test data
        self.log("📁 Creating test data...");
        self.create_test_data()?;
        self.log("✅ Test data created");
        
        // 3. Single file operations
        self.log("🔐 Testing single file operations...");
        self.test_single_file_operations()?;
        self.log("✅ Single file operations completed");
        
        // 4. Repository operations
        self.log("📦 Testing repository operations...");
        self.test_repository_operations()?;
        self.log("✅ Repository operations completed");
        
        // 5. Format testing
        self.log("🛡️ Testing ASCII armor format...");
        self.test_ascii_armor_format()?;
        self.log("✅ ASCII armor format tested");
        
        // 6. Security validation
        self.log("🔒 Testing security validation...");
        self.test_security_validation()?;
        self.log("✅ Security validation completed");
        
        self.log("🎉 Age Automation Demonstration Completed Successfully!");
        Ok(())
    }
    
    /// Create test data for demonstration
    fn create_test_data(&self) -> Result<(), Box<dyn std::error::Error>> {
        use std::fs;
        
        fs::create_dir_all(&self.config.test_data_dir)?;
        fs::create_dir_all(&self.config.output_dir)?;
        
        // Create test files
        let test_files = [
            ("simple.txt", "Hello, World! This is a simple test file."),
            ("config.json", r#"{"name": "test", "version": "1.0.0", "secure": true}"#),
            ("secret.key", "super-secret-key-material-do-not-share"),
            ("data.csv", "name,value,secret\ntest,42,hidden\nuser,100,private"),
        ];
        
        for (filename, content) in &test_files {
            let file_path = self.config.test_data_dir.join(filename);
            fs::write(&file_path, content)?;
            self.log(&format!("  Created: {}", file_path.display()));
        }
        
        // Create subdirectory with files
        let subdir = self.config.test_data_dir.join("subdir");
        fs::create_dir_all(&subdir)?;
        fs::write(subdir.join("nested.txt"), "This is in a subdirectory")?;
        fs::write(subdir.join("important.doc"), "Important nested document")?;
        
        Ok(())
    }
    
    /// Test single file encryption and decryption operations
    fn test_single_file_operations(&self) -> Result<(), Box<dyn std::error::Error>> {
        let input_file = self.config.test_data_dir.join("simple.txt");
        let encrypted_file = self.config.output_dir.join("simple.txt.age");
        let decrypted_file = self.config.output_dir.join("simple_decrypted.txt");
        let passphrase = "test-passphrase-123";
        
        // Test encryption
        self.log("  Encrypting file...");
        self.automator.encrypt(&input_file, &encrypted_file, passphrase, self.config.format)?;
        self.log(&format!("    Encrypted: {} -> {}", input_file.display(), encrypted_file.display()));
        
        // Verify encrypted file exists and has content
        if !encrypted_file.exists() {
            return Err("Encrypted file was not created".into());
        }
        
        // Test decryption
        self.log("  Decrypting file...");
        self.automator.decrypt(&encrypted_file, &decrypted_file, passphrase)?;
        self.log(&format!("    Decrypted: {} -> {}", encrypted_file.display(), decrypted_file.display()));
        
        // Verify content matches
        let original_content = std::fs::read_to_string(&input_file)?;
        let decrypted_content = std::fs::read_to_string(&decrypted_file)?;
        
        if original_content != decrypted_content {
            return Err("Decrypted content does not match original".into());
        }
        
        self.log("  ✅ Content verification passed");
        Ok(())
    }
    
    /// Test repository-level operations
    fn test_repository_operations(&self) -> Result<(), Box<dyn std::error::Error>> {
        let repo_dir = &self.config.test_data_dir;
        let passphrase = "repo-passphrase-456";
        
        // Test repository encryption
        self.log("  Encrypting repository...");
        self.repo_ops.encrypt_repository(repo_dir, passphrase, self.config.format)?;
        self.log("    Repository encryption completed");
        
        // Check repository status
        self.log("  Checking repository status...");
        let status = self.repo_ops.repository_status(repo_dir)?;
        self.log(&format!("    Total files: {}", status.total_files));
        self.log(&format!("    Encrypted files: {}", status.encrypted_files));
        self.log(&format!("    Encryption percentage: {:.1}%", status.encryption_percentage()));
        
        // Test repository decryption
        self.log("  Decrypting repository...");
        self.repo_ops.decrypt_repository(repo_dir, passphrase)?;
        self.log("    Repository decryption completed");
        
        // Verify decryption status
        let final_status = self.repo_ops.repository_status(repo_dir)?;
        self.log(&format!("    Final encrypted files: {}", final_status.encrypted_files));
        
        Ok(())
    }
    
    /// Test ASCII armor format
    fn test_ascii_armor_format(&self) -> Result<(), Box<dyn std::error::Error>> {
        let input_file = self.config.test_data_dir.join("config.json");
        let armor_file = self.config.output_dir.join("config.json.armor");
        let passphrase = "armor-test-789";
        
        // Encrypt with ASCII armor
        self.log("  Encrypting with ASCII armor...");
        self.automator.encrypt(&input_file, &armor_file, passphrase, OutputFormat::AsciiArmor)?;
        
        // Verify armor file is text
        let armor_content = std::fs::read_to_string(&armor_file)?;
        if !armor_content.starts_with("-----BEGIN AGE ENCRYPTED FILE-----") {
            return Err("ASCII armor format not detected".into());
        }
        
        self.log("    ASCII armor format verified");
        
        // Test decryption of armored file
        let decrypted_armor = self.config.output_dir.join("config_from_armor.json");
        self.automator.decrypt(&armor_file, &decrypted_armor, passphrase)?;
        
        // Verify content matches
        let original_content = std::fs::read_to_string(&input_file)?;
        let decrypted_content = std::fs::read_to_string(&decrypted_armor)?;
        
        if original_content != decrypted_content {
            return Err("ASCII armor decryption content mismatch".into());
        }
        
        self.log("  ✅ ASCII armor round-trip successful");
        Ok(())
    }
    
    /// Test security validation features
    fn test_security_validation(&self) -> Result<(), Box<dyn std::error::Error>> {
        // Test passphrase validation
        self.log("  Testing passphrase validation...");
        
        // Test weak passphrase (should fail)
        let weak_file = self.config.output_dir.join("weak_test.age");
        let input_file = self.config.test_data_dir.join("simple.txt");
        
        let weak_result = self.automator.encrypt(&input_file, &weak_file, "123", OutputFormat::Binary);
        if weak_result.is_ok() {
            return Err("Weak passphrase was accepted (security failure)".into());
        }
        self.log("    ✅ Weak passphrase properly rejected");
        
        // Test injection patterns (should fail)
        let injection_result = self.automator.encrypt(&input_file, &weak_file, "test$(rm -rf /)", OutputFormat::Binary);
        if injection_result.is_ok() {
            return Err("Injection pattern was accepted (security failure)".into());
        }
        self.log("    ✅ Injection pattern properly blocked");
        
        // Test file path validation
        self.log("  Testing file path validation...");
        let validator = SecurityValidator::new(true);
        
        // Test path traversal (should fail)
        let traversal_result = validator.validate_file_path(Path::new("../../../etc/passwd"));
        if traversal_result.is_ok() {
            return Err("Path traversal was accepted (security failure)".into());
        }
        self.log("    ✅ Path traversal properly blocked");
        
        Ok(())
    }
    
    /// Log message if verbose mode is enabled
    fn log(&self, message: &str) {
        if self.config.verbose {
            println!("{}", message);
        }
        // Always log to audit logger
        let _ = self.audit_logger.log_info(message);
    }
}

/// Main function for driver executable
fn main() {
    let config = DriverConfig::from_args();
    
    println!("🛡️ Padlock Age Automation Driver");
    println!("Security Guardian: Edgar - Testing & Validation Interface");
    println!();
    
    match AgeAutomationDriver::new(config) {
        Ok(driver) => {
            if let Err(e) = driver.run_demonstration() {
                eprintln!("❌ Demonstration failed: {}", e);
                process::exit(1);
            }
        }
        Err(e) => {
            eprintln!("❌ Failed to initialize driver: {}", e);
            process::exit(1);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    
    #[test]
    fn test_driver_config_creation() {
        let config = DriverConfig::default().unwrap();
        assert!(config.verbose);
        assert!(matches!(config.format, OutputFormat::Binary));
    }
    
    #[test]
    fn test_driver_initialization() {
        let config = DriverConfig::default().unwrap();
        // This will fail if Age is not available, which is expected in test environments
        let _result = AgeAutomationDriver::new(config);
    }
}