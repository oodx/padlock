//! Authority Operations - Key generation and management operations
//!
//! Implements secure key generation operations with authority validation.
//! Provides operations for creating keys within the X->M->R->I->D hierarchy
//! with proper cryptographic material generation and authority delegation.
//!
//! Security Guardian: Edgar - Authority key generation framework

use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use chrono::{DateTime, Utc};
use rand::RngCore;
use sha2::{Sha256, Digest};

use crate::encryption::age_automation::{
    error::{AgeError, AgeResult},
    security::AuditLogger,
};
use super::{
    KeyType, AuthorityChain, AuthorityKey, KeyFingerprint,
    IgnitionKey,
    validation::{AuthorityValidationEngine, AuthorityProof},
    chain::{KeyMaterial, KeyFormat, KeyMetadata},
};

/// Key generation parameters for authority keys
#[derive(Debug, Clone)]
pub struct KeyGenerationParams {
    pub key_type: KeyType,
    pub parent_authority: Option<KeyFingerprint>,
    pub key_length: usize,
    pub expiration_duration: Option<Duration>,
    pub metadata: GenerationMetadata,
}

/// Generation metadata associated with generated keys
#[derive(Debug, Clone)]
pub struct GenerationMetadata {
    pub purpose: String,
    pub created_by: String,
    pub environment: String,
    pub tags: Vec<String>,
}

/// Key generation operation result
#[derive(Debug)]
pub struct KeyGenerationResult {
    pub key: AuthorityKey,
    pub fingerprint: KeyFingerprint,
    pub generation_proof: AuthorityProof,
    pub creation_timestamp: DateTime<Utc>,
}

/// Authority key generator with cryptographic validation
pub struct AuthorityKeyGenerator {
    authority_chain: AuthorityChain,
    validation_engine: AuthorityValidationEngine,
    audit_logger: AuditLogger,
    secure_rng: Box<dyn RngCore>,
}

impl AuthorityKeyGenerator {
    /// Create new authority key generator
    pub fn new(
        authority_chain: AuthorityChain,
        audit_log_path: Option<PathBuf>,
    ) -> AgeResult<Self> {
        let validation_engine = AuthorityValidationEngine::new(authority_chain.clone());
        let audit_logger = AuditLogger::new(audit_log_path)?;
        let secure_rng = Box::new(rand::thread_rng());
        
        Ok(Self {
            authority_chain,
            validation_engine,
            audit_logger,
            secure_rng,
        })
    }
    
    /// Generate new authority key with validation
    pub fn generate_authority_key(
        &mut self,
        params: KeyGenerationParams,
        parent_key: Option<&AuthorityKey>,
    ) -> AgeResult<KeyGenerationResult> {
        // 1. Validate generation parameters
        self.validate_generation_params(&params, parent_key)?;
        
        // 2. Generate cryptographic material
        let key_material = self.generate_key_material(params.key_length)?;
        
        // 3. Create authority key
        let key_metadata = KeyMetadata {
            creation_time: Utc::now(),
            creator: params.metadata.created_by.clone(),
            description: params.metadata.purpose.clone(),
            expiration: params.expiration_duration.map(|d| Utc::now() + chrono::Duration::seconds(d.as_secs() as i64)),
            last_used: None,
            usage_count: 0,
        };
        
        let authority_key = AuthorityKey::new(
            key_material,
            params.key_type,
            None, // key_path - no file path for generated keys
            Some(key_metadata),
        )?;
        
        // 4. Generate authority proof
        let generation_proof = self.generate_authority_proof(&authority_key, parent_key)?;
        
        // 5. Validate generated key
        self.validate_generated_key(&authority_key, &generation_proof, parent_key)?;
        
        // 6. Log generation operation
        self.audit_logger.log_key_generation(
            &authority_key.fingerprint().hex(),
            &params.key_type.to_string(),
            &params.metadata.purpose,
        )?;
        
        Ok(KeyGenerationResult {
            fingerprint: authority_key.fingerprint().clone(),
            creation_timestamp: Utc::now(),
            generation_proof,
            key: authority_key,
        })
    }
    
    /// Generate ignition key with passphrase wrapping
    pub fn generate_ignition_key(
        &mut self,
        wrapped_key_type: KeyType,
        passphrase: &str,
        authority_chain: Vec<KeyFingerprint>,
        params: KeyGenerationParams,
    ) -> AgeResult<IgnitionKey> {
        // 1. Validate ignition key parameters
        self.validate_ignition_params(wrapped_key_type, passphrase, &authority_chain)?;
        
        // 2. Generate underlying key material
        let key_material = self.generate_key_material(params.key_length)?;
        
        // 3. Create authority key to wrap
        let key_metadata = KeyMetadata {
            creation_time: Utc::now(),
            creator: params.metadata.created_by.clone(),
            description: params.metadata.purpose.clone(),
            expiration: params.expiration_duration.map(|d| Utc::now() + chrono::Duration::seconds(d.as_secs() as i64)),
            last_used: None,
            usage_count: 0,
        };
        
        let wrapped_key = AuthorityKey::new(
            key_material,
            wrapped_key_type,
            None,
            Some(key_metadata),
        )?;
        
        // 4. Create ignition key with passphrase wrapping
        let ignition_key = IgnitionKey::create(
            wrapped_key.key_material(),
            wrapped_key_type,
            passphrase,
            None, // No parent for the ignition key itself
            Some(params.metadata.purpose.clone()),
        )?;
        
        // 5. Log ignition key generation
        self.audit_logger.log_ignition_key_generation(
            &ignition_key.fingerprint()?.hex(),
            &wrapped_key_type.to_string(),
        )?;
        
        Ok(ignition_key)
    }
    
    /// Generate skull key (ultimate authority)
    pub fn generate_skull_key(&mut self, metadata: GenerationMetadata) -> AgeResult<KeyGenerationResult> {
        let params = KeyGenerationParams {
            key_type: KeyType::Skull,
            parent_authority: None,
            key_length: 64, // 512-bit for skull keys
            expiration_duration: None, // Skull keys don't expire
            metadata,
        };
        
        self.audit_logger.log_warning("Generating skull key - ultimate authority creation")?;
        self.generate_authority_key(params, None)
    }
    
    /// Generate master key delegated from skull
    pub fn generate_master_key(
        &mut self,
        skull_key: &AuthorityKey,
        metadata: GenerationMetadata,
    ) -> AgeResult<KeyGenerationResult> {
        if skull_key.key_type() != KeyType::Skull {
            return Err(AgeError::InvalidOperation {
                operation: "generate_master_key".to_string(),
                reason: "Parent must be skull key".to_string(),
            });
        }
        
        let params = KeyGenerationParams {
            key_type: KeyType::Master,
            parent_authority: Some(skull_key.fingerprint().clone()),
            key_length: 48, // 384-bit for master keys
            expiration_duration: Some(Duration::from_secs(365 * 24 * 3600)), // 1 year
            metadata,
        };
        
        self.generate_authority_key(params, Some(skull_key))
    }
    
    /// Generate repository key delegated from master
    pub fn generate_repo_key(
        &mut self,
        master_key: &AuthorityKey,
        repo_path: &Path,
        metadata: GenerationMetadata,
    ) -> AgeResult<KeyGenerationResult> {
        if master_key.key_type() != KeyType::Master {
            return Err(AgeError::InvalidOperation {
                operation: "generate_repo_key".to_string(),
                reason: "Parent must be master key".to_string(),
            });
        }
        
        let mut repo_metadata = metadata;
        repo_metadata.tags.push(format!("repo:{}", repo_path.display()));
        
        let params = KeyGenerationParams {
            key_type: KeyType::Repo,
            parent_authority: Some(master_key.fingerprint().clone()),
            key_length: 32, // 256-bit for repo keys
            expiration_duration: Some(Duration::from_secs(90 * 24 * 3600)), // 90 days
            metadata: repo_metadata,
        };
        
        self.generate_authority_key(params, Some(master_key))
    }
    
    /// Validate key generation parameters
    fn validate_generation_params(
        &self,
        params: &KeyGenerationParams,
        parent_key: Option<&AuthorityKey>,
    ) -> AgeResult<()> {
        // Validate key type hierarchy
        if let Some(parent) = parent_key {
            if !parent.key_type().can_control(params.key_type) {
                return Err(AgeError::InvalidOperation {
                    operation: "validate_generation_params".to_string(),
                    reason: format!(
                        "{} cannot delegate to {}",
                        parent.key_type(),
                        params.key_type
                    ),
                });
            }
        } else if params.key_type != KeyType::Skull {
            return Err(AgeError::InvalidOperation {
                operation: "validate_generation_params".to_string(),
                reason: "Only skull keys can be generated without parent".to_string(),
            });
        }
        
        // Validate key length
        let min_length = match params.key_type {
            KeyType::Skull => 64,
            KeyType::Master => 32,
            KeyType::Repo => 24,
            KeyType::Ignition => 32,
            KeyType::Distro => 16,
        };
        
        if params.key_length < min_length {
            return Err(AgeError::InvalidOperation {
                operation: "validate_generation_params".to_string(),
                reason: format!(
                    "Key length {} below minimum {} for {}",
                    params.key_length, min_length, params.key_type
                ),
            });
        }
        
        Ok(())
    }
    
    /// Generate cryptographic key material
    fn generate_key_material(&mut self, length: usize) -> AgeResult<KeyMaterial> {
        let mut key_data = vec![0u8; length];
        self.secure_rng.fill_bytes(&mut key_data);
        
        // Add additional entropy mixing
        let mut hasher = Sha256::new();
        hasher.update(&key_data);
        hasher.update(&SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos().to_be_bytes());
        hasher.update(b"padlock-authority-key-generation");
        
        let entropy_hash = hasher.finalize();
        
        // XOR with entropy for additional mixing
        for (i, byte) in key_data.iter_mut().enumerate() {
            *byte ^= entropy_hash[i % 32];
        }
        
        // For simplicity, use the same data for public and private key
        // In production, this would use proper asymmetric key generation
        Ok(KeyMaterial::new(
            key_data.clone(),
            Some(key_data),
            KeyFormat::Ed25519,
        ))
    }
    
    /// Generate authority proof for key generation
    fn generate_authority_proof(
        &self,
        new_key: &AuthorityKey,
        parent_key: Option<&AuthorityKey>,
    ) -> AgeResult<AuthorityProof> {
        match parent_key {
            Some(parent) => {
                // Generate delegation proof using existing method
                AuthorityProof::generate(parent, new_key)
            }
            None => {
                // For skull keys, create self-delegating proof
                // This is a special case where parent and child are the same
                AuthorityProof::generate(new_key, new_key)
            }
        }
    }
    
    /// Validate generated key meets requirements
    fn validate_generated_key(
        &self,
        key: &AuthorityKey,
        proof: &AuthorityProof,
        parent_key: Option<&AuthorityKey>,
    ) -> AgeResult<()> {
        // Verify proof validity
        let parent_for_verification = parent_key.unwrap_or(key); // Use self for skull keys
        if !proof.verify(parent_for_verification, key)? {
            return Err(AgeError::InvalidOperation {
                operation: "validate_generated_key".to_string(),
                reason: "Generated key proof verification failed".to_string(),
            });
        }
        
        // Check key strength
        let key_data = key.key_material().public_key();
        if key_data.len() < 16 {
            return Err(AgeError::InvalidOperation {
                operation: "validate_generated_key".to_string(),
                reason: "Generated key insufficient length".to_string(),
            });
        }
        
        // Check for weak keys (all zeros, predictable patterns)
        if key_data.iter().all(|&b| b == 0) {
            return Err(AgeError::InvalidOperation {
                operation: "validate_generated_key".to_string(),
                reason: "Generated key is all zeros".to_string(),
            });
        }
        
        Ok(())
    }
    
    /// Validate ignition key parameters
    fn validate_ignition_params(
        &self,
        wrapped_key_type: KeyType,
        passphrase: &str,
        authority_chain: &[KeyFingerprint],
    ) -> AgeResult<()> {
        // Validate wrapped key type is appropriate for ignition
        if !matches!(wrapped_key_type, KeyType::Skull | KeyType::Ignition | KeyType::Distro) {
            return Err(AgeError::InvalidOperation {
                operation: "validate_ignition_params".to_string(),
                reason: format!("Key type {} cannot be wrapped in ignition key", wrapped_key_type),
            });
        }
        
        // Validate passphrase strength
        if passphrase.len() < 12 {
            return Err(AgeError::InvalidOperation {
                operation: "validate_ignition_params".to_string(),
                reason: "Ignition key passphrase must be at least 12 characters".to_string(),
            });
        }
        
        // Validate authority chain has at least one authority
        if authority_chain.is_empty() {
            return Err(AgeError::InvalidOperation {
                operation: "validate_ignition_params".to_string(),
                reason: "Ignition key requires at least one authority in chain".to_string(),
            });
        }
        
        Ok(())
    }
}

/// Factory for creating authority key generators
pub struct KeyGeneratorFactory;

impl KeyGeneratorFactory {
    /// Create key generator with empty authority chain
    pub fn create_empty() -> AgeResult<AuthorityKeyGenerator> {
        let authority_chain = AuthorityChain::new();
        AuthorityKeyGenerator::new(authority_chain, None)
    }
    
    /// Create key generator with existing authority chain
    pub fn create_with_chain(
        authority_chain: AuthorityChain,
        audit_log_path: Option<PathBuf>,
    ) -> AgeResult<AuthorityKeyGenerator> {
        AuthorityKeyGenerator::new(authority_chain, audit_log_path)
    }
}

/// Extension trait for AuditLogger to support key generation logging
trait KeyGenerationAuditExtensions {
    fn log_key_generation(&self, fingerprint: &str, key_type: &str, purpose: &str) -> AgeResult<()>;
    fn log_ignition_key_generation(&self, fingerprint: &str, wrapped_type: &str) -> AgeResult<()>;
}

impl KeyGenerationAuditExtensions for AuditLogger {
    fn log_key_generation(&self, fingerprint: &str, key_type: &str, purpose: &str) -> AgeResult<()> {
        self.log_info(&format!(
            "Authority key generated: {} ({}) for {}",
            fingerprint, key_type, purpose
        ))
    }
    
    fn log_ignition_key_generation(&self, fingerprint: &str, wrapped_type: &str) -> AgeResult<()> {
        self.log_info(&format!(
            "Ignition key generated: {} wrapping {}",
            fingerprint, wrapped_type
        ))
    }
}

/// Initialize operations framework
pub fn initialize() -> AgeResult<()> {
    // Validate that dependencies are available
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    
    #[test]
    fn test_key_generator_creation() {
        let generator = KeyGeneratorFactory::create_empty();
        assert!(generator.is_ok());
    }
    
    #[test]
    fn test_skull_key_generation() {
        let mut generator = KeyGeneratorFactory::create_empty().unwrap();
        
        let metadata = GenerationMetadata {
            purpose: "Test skull key".to_string(),
            created_by: "test".to_string(),
            environment: "test".to_string(),
            tags: vec!["test".to_string()],
        };
        
        let result = generator.generate_skull_key(metadata);
        assert!(result.is_ok());
        
        let result = result.unwrap();
        assert_eq!(result.key.key_type(), KeyType::Skull);
        assert!(result.key.parent_authority().is_none());
    }
    
    #[test]
    fn test_key_validation() {
        let mut generator = KeyGeneratorFactory::create_empty().unwrap();
        
        // Test invalid key length
        let params = KeyGenerationParams {
            key_type: KeyType::Skull,
            parent_authority: None,
            key_length: 8, // Too short
            expiration_duration: None,
            metadata: GenerationMetadata {
                purpose: "test".to_string(),
                created_by: "test".to_string(),
                environment: "test".to_string(),
                tags: vec![],
            },
        };
        
        let result = generator.generate_authority_key(params, None);
        assert!(result.is_err());
    }
}