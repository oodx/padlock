#!/bin/bash
# Age Automation Integration Patterns
# Security Guardian: Edgar - Production Deployment Examples

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Example 1: CI/CD Pipeline Integration
ci_cd_integration_example() {
    echo "🔧 CI/CD Pipeline Integration Example"
    echo "===================================="
    
    cat << 'EOF'
# Example GitHub Actions workflow for padlock integration

name: Secure Repository Encryption Test
on: [push, pull_request]

jobs:
  encryption-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Age
        run: |
          curl -L https://github.com/FiloSottile/age/releases/latest/download/age-v1.1.1-linux-amd64.tar.gz | tar xz
          sudo mv age/age /usr/local/bin/
          
      - name: Install expect for TTY automation
        run: sudo apt-get install -y expect
        
      - name: Test Age Automation
        env:
          TEST_PASSPHRASE: ${{ secrets.TEST_ENCRYPTION_PASSPHRASE }}
        run: |
          # Create test repository
          mkdir test-repo
          echo "Sensitive test data" > test-repo/secret.txt
          
          # Test encryption
          ./pilot/00-age_taming/age_automator.sh encrypt \
            test-repo/secret.txt \
            test-repo/secret.txt.age \
            "$TEST_PASSPHRASE"
          
          # Test decryption
          ./pilot/00-age_taming/age_automator.sh decrypt \
            test-repo/secret.txt.age \
            test-repo/decrypted.txt \
            "$TEST_PASSPHRASE"
          
          # Verify integrity
          diff test-repo/secret.txt test-repo/decrypted.txt
          
      - name: Security Validation
        run: |
          # Run comprehensive security tests
          ./pilot/00-age_taming/security_tests.sh
EOF
    
    echo ""
    echo "✅ CI/CD integration enables automated repository encryption testing"
    echo ""
}

# Example 2: Emergency Response Automation
emergency_response_example() {
    echo "🚨 Emergency Response Automation Example"
    echo "========================================"
    
    cat << 'EOF'
#!/bin/bash
# Emergency repository lockdown script

set -euo pipefail

EMERGENCY_PASSPHRASE="$1"
REPOSITORY_PATH="$2"

# Lock down repository immediately
echo "🚨 EMERGENCY LOCKDOWN INITIATED"

# Encrypt all sensitive files
find "$REPOSITORY_PATH" -name "*.env" -o -name "*.key" -o -name "*.pem" | while read -r file; do
    echo "Encrypting: $file"
    ./age_automator.sh encrypt "$file" "$file.emergency.age" "$EMERGENCY_PASSPHRASE"
    
    # Secure deletion of original
    shred -vfz -n 3 "$file"
    rm "$file"
done

echo "✅ Emergency lockdown complete"
EOF
    
    echo ""
    echo "✅ Emergency automation enables rapid repository security response"
    echo ""
}

# Example 3: Backup Automation Pattern
backup_automation_example() {
    echo "💾 Backup Automation Pattern Example"
    echo "===================================="
    
    cat << 'EOF'
#!/bin/bash
# Automated encrypted backup system

set -euo pipefail

BACKUP_PASSPHRASE="$1"
SOURCE_DIR="$2"
BACKUP_DIR="$3"

# Create encrypted backup
echo "📦 Creating encrypted backup..."

# Archive source directory
tar -czf "$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz" -C "$SOURCE_DIR" .

# Encrypt the archive
./age_automator.sh encrypt \
    "$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz" \
    "$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz.age" \
    "$BACKUP_PASSPHRASE"

# Secure deletion of unencrypted archive
shred -vfz -n 3 "$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
rm "$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz"

echo "✅ Encrypted backup created successfully"
EOF
    
    echo ""
    echo "✅ Backup automation enables secure, unattended data protection"
    echo ""
}

# Example 4: Monitoring Integration
monitoring_integration_example() {
    echo "📊 Monitoring Integration Example"
    echo "================================="
    
    cat << 'EOF'
#!/bin/bash
# Monitoring integration for Age automation

set -euo pipefail

# Health check function
age_automation_health_check() {
    local temp_dir="/tmp/age_health_check_$$"
    mkdir -p "$temp_dir"
    
    local test_file="$temp_dir/health_test.txt"
    local encrypted_file="$temp_dir/health_test.age"
    local decrypted_file="$temp_dir/health_test_decrypted.txt"
    local test_passphrase="HealthCheckPassphrase123"
    
    echo "Health check content" > "$test_file"
    
    # Test encryption/decryption cycle
    if ./age_automator.sh encrypt "$test_file" "$encrypted_file" "$test_passphrase" && \
       ./age_automator.sh decrypt "$encrypted_file" "$decrypted_file" "$test_passphrase" && \
       diff "$test_file" "$decrypted_file" > /dev/null; then
        
        echo "age_automation_healthy 1"
        rm -rf "$temp_dir"
        return 0
    else
        echo "age_automation_healthy 0"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Prometheus metrics endpoint
cat << 'METRICS_EOF'
# HELP age_automation_healthy Age automation system health status
# TYPE age_automation_healthy gauge
age_automation_healthy 1

# HELP age_automation_operations_total Total Age automation operations
# TYPE age_automation_operations_total counter
age_automation_operations_total{operation="encrypt"} 42
age_automation_operations_total{operation="decrypt"} 38

# HELP age_automation_operation_duration_seconds Age operation duration
# TYPE age_automation_operation_duration_seconds histogram
age_automation_operation_duration_seconds_bucket{operation="encrypt",le="1.0"} 35
age_automation_operation_duration_seconds_bucket{operation="encrypt",le="5.0"} 42
age_automation_operation_duration_seconds_bucket{operation="encrypt",le="+Inf"} 42
METRICS_EOF
EOF
    
    echo ""
    echo "✅ Monitoring integration enables operational visibility and alerting"
    echo ""
}

# Example 5: Rust FFI Integration Preview
rust_ffi_preview() {
    echo "🦀 Rust FFI Integration Preview"
    echo "==============================="
    
    cat << 'EOF'
// Example Rust wrapper for Age automation
// File: src/age_automation.rs

use std::process::Command;
use std::path::Path;

pub struct AgeAutomator {
    script_path: String,
}

impl AgeAutomator {
    pub fn new(script_path: &str) -> Self {
        Self {
            script_path: script_path.to_string(),
        }
    }
    
    pub fn encrypt(&self, input: &Path, output: &Path, passphrase: &str) -> Result<(), String> {
        let output = Command::new(&self.script_path)
            .arg("encrypt")
            .arg(input.to_str().unwrap())
            .arg(output.to_str().unwrap())
            .arg(passphrase)
            .output()
            .map_err(|e| format!("Failed to execute age automation: {}", e))?;
        
        if output.status.success() {
            Ok(())
        } else {
            Err(String::from_utf8_lossy(&output.stderr).to_string())
        }
    }
    
    pub fn decrypt(&self, input: &Path, output: &Path, passphrase: &str) -> Result<(), String> {
        let output = Command::new(&self.script_path)
            .arg("decrypt")
            .arg(input.to_str().unwrap())
            .arg(output.to_str().unwrap())
            .arg(passphrase)
            .output()
            .map_err(|e| format!("Failed to execute age automation: {}", e))?;
        
        if output.status.success() {
            Ok(())
        } else {
            Err(String::from_utf8_lossy(&output.stderr).to_string())
        }
    }
}

// Usage example
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let age_automator = AgeAutomator::new("./pilot/00-age_taming/age_automator.sh");
    
    age_automator.encrypt(
        Path::new("input.txt"),
        Path::new("output.age"),
        "secure_passphrase"
    )?;
    
    age_automator.decrypt(
        Path::new("output.age"),
        Path::new("decrypted.txt"),
        "secure_passphrase"
    )?;
    
    Ok(())
}
EOF
    
    echo ""
    echo "✅ Rust FFI pattern enables seamless integration with padlock core"
    echo ""
}

# Main demonstration function
run_integration_examples() {
    echo "🛡️ Age Automation Integration Patterns"
    echo "======================================"
    echo ""
    echo "This demonstrates production-ready integration patterns for the Age automation"
    echo "solution, showing how the TTY automation can be deployed across different"
    echo "environments and use cases."
    echo ""
    
    ci_cd_integration_example
    emergency_response_example
    backup_automation_example
    monitoring_integration_example
    rust_ffi_preview
    
    echo "🛡️ Integration Patterns Summary:"
    echo "   ✅ CI/CD Pipeline Ready"
    echo "   ✅ Emergency Response Capable"
    echo "   ✅ Backup Automation Enabled"
    echo "   ✅ Monitoring Integration Supported"
    echo "   ✅ Rust FFI Migration Path Defined"
    echo ""
    echo "The Age automation pilot provides a complete foundation for eliminating"
    echo "TTY interaction requirements while maintaining security standards."
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_examples "$@"
fi