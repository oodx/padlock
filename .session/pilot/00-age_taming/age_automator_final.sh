#!/bin/bash
# Age Automation - Final Implementation with Reliable TTY Automation
# Security Guardian: Edgar - Tested and Consistent Solution

set -euo pipefail

# Security Configuration
readonly SCRIPT_NAME="age_automator_final"
readonly TEMP_DIR_PREFIX="/tmp/age_auto_final_$$"
readonly MAX_PASSPHRASE_LENGTH=1024
readonly SECURITY_LOG="/tmp/age_automator_final_audit.log"

# Security audit logging
security_log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [PID:$$] $message" >> "$SECURITY_LOG"
}

# Cleanup function for security
cleanup_security() {
    local exit_code=$?
    security_log "INFO" "Cleanup initiated with exit code: $exit_code"
    
    # Secure cleanup of temporary files
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        find "$TEMP_DIR" -type f -exec shred -vfz -n 3 {} \; 2>/dev/null || true
        rm -rf "$TEMP_DIR" 2>/dev/null || true
        security_log "INFO" "Temporary directory securely cleaned: $TEMP_DIR"
    fi
    
    # Clear environment variables that might contain sensitive data
    unset PASSPHRASE TEMP_DIR AGE_PASSPHRASE
    
    security_log "INFO" "Security cleanup completed"
    exit $exit_code
}

# Set security cleanup trap
trap cleanup_security EXIT INT TERM

# Initialize secure temporary directory
init_secure_temp() {
    TEMP_DIR=$(mktemp -d "${TEMP_DIR_PREFIX}_XXXXXX")
    chmod 700 "$TEMP_DIR"
    security_log "INFO" "Secure temporary directory created: $TEMP_DIR"
}

# Validate passphrase security
validate_passphrase() {
    local passphrase="$1"
    
    # Check length
    if [[ ${#passphrase} -gt $MAX_PASSPHRASE_LENGTH ]]; then
        security_log "ERROR" "Passphrase exceeds maximum length"
        echo "ERROR: Passphrase too long (max: $MAX_PASSPHRASE_LENGTH chars)" >&2
        return 1
    fi
    
    # Basic validation - reject empty passphrases
    if [[ -z "$passphrase" ]]; then
        security_log "ERROR" "Empty passphrase detected"
        echo "ERROR: Empty passphrase not allowed" >&2
        return 1
    fi
    
    security_log "INFO" "Passphrase validation passed"
    return 0
}

# Most reliable TTY automation using printf and pipes
age_encrypt_automated() {
    local input_file="$1"
    local output_file="$2"
    local passphrase="$3"
    
    security_log "INFO" "Starting automated encryption: $input_file -> $output_file"
    
    # Validate inputs
    if [[ ! -f "$input_file" ]]; then
        security_log "ERROR" "Input file not found: $input_file"
        echo "ERROR: Input file not found: $input_file" >&2
        return 1
    fi
    
    if ! validate_passphrase "$passphrase"; then
        return 1
    fi
    
    # Use the most reliable method: printf to handle passphrase securely
    if printf '%s\n%s\n' "$passphrase" "$passphrase" | age -p -o "$output_file" "$input_file" 2>/dev/null; then
        security_log "INFO" "Encryption completed successfully"
        
        # Verify output file was created and has content
        if [[ -f "$output_file" && -s "$output_file" ]]; then
            security_log "INFO" "Output file verified: $output_file"
            return 0
        else
            security_log "ERROR" "Output file not created or empty: $output_file"
            echo "ERROR: Encryption failed - no valid output file created" >&2
            return 1
        fi
    else
        local exit_code=$?
        security_log "ERROR" "Encryption failed with exit code: $exit_code"
        echo "ERROR: Age encryption failed" >&2
        return $exit_code
    fi
}

# Reliable TTY automation for decryption
age_decrypt_automated() {
    local input_file="$1"
    local output_file="$2"
    local passphrase="$3"
    
    security_log "INFO" "Starting automated decryption: $input_file -> $output_file"
    
    # Validate inputs
    if [[ ! -f "$input_file" ]]; then
        security_log "ERROR" "Input file not found: $input_file"
        echo "ERROR: Input file not found: $input_file" >&2
        return 1
    fi
    
    if ! validate_passphrase "$passphrase"; then
        return 1
    fi
    
    # Use printf for reliable passphrase handling
    if printf '%s\n' "$passphrase" | age -d -o "$output_file" "$input_file" 2>/dev/null; then
        security_log "INFO" "Decryption completed successfully"
        
        # Verify output file was created and has content
        if [[ -f "$output_file" && -s "$output_file" ]]; then
            security_log "INFO" "Output file verified: $output_file"
            return 0
        else
            security_log "ERROR" "Output file not created or empty: $output_file"
            echo "ERROR: Decryption failed - no valid output file created" >&2
            return 1
        fi
    else
        local exit_code=$?
        security_log "ERROR" "Decryption failed with exit code: $exit_code"
        echo "ERROR: Age decryption failed" >&2
        return $exit_code
    fi
}

# Test function for validation
run_automation_tests() {
    echo "Testing Age automation capabilities (final implementation)..."
    
    # Create test file
    local test_file="$TEMP_DIR/test_input.txt"
    local encrypted_file="$TEMP_DIR/test_encrypted.age"
    local decrypted_file="$TEMP_DIR/test_decrypted.txt"
    local test_passphrase="TestPassphrase123"
    
    echo "Test content for final age automation implementation" > "$test_file"
    
    # Test encryption
    echo "Testing encryption..."
    if age_encrypt_automated "$test_file" "$encrypted_file" "$test_passphrase"; then
        echo "✅ Encryption test passed"
        
        # Verify encrypted file is different from original
        if ! diff "$test_file" "$encrypted_file" >/dev/null 2>&1; then
            echo "✅ Encrypted file differs from original (expected)"
        else
            echo "❌ Encrypted file identical to original (unexpected)"
            return 1
        fi
    else
        echo "❌ Encryption test failed"
        return 1
    fi
    
    # Test decryption
    echo "Testing decryption..."
    if age_decrypt_automated "$encrypted_file" "$decrypted_file" "$test_passphrase"; then
        echo "✅ Decryption test passed"
    else
        echo "❌ Decryption test failed"
        return 1
    fi
    
    # Verify content integrity
    if diff "$test_file" "$decrypted_file" >/dev/null 2>&1; then
        echo "✅ Content integrity verified"
        echo "🛡️ Age automation final implementation: ALL TESTS PASSED"
        echo "🔧 TTY automation solution is CONSISTENT and PREDICTABLE"
        return 0
    else
        echo "❌ Content integrity check failed"
        return 1
    fi
}

# Public API functions
main() {
    local command="$1"
    shift
    
    case "$command" in
        "encrypt")
            if [[ $# -ne 3 ]]; then
                echo "Usage: $0 encrypt <input_file> <output_file> <passphrase>" >&2
                return 1
            fi
            init_secure_temp
            age_encrypt_automated "$1" "$2" "$3"
            ;;
        "decrypt")
            if [[ $# -ne 3 ]]; then
                echo "Usage: $0 decrypt <input_file> <output_file> <passphrase>" >&2
                return 1
            fi
            init_secure_temp
            age_decrypt_automated "$1" "$2" "$3"
            ;;
        "test")
            echo "Running final age automation tests..."
            init_secure_temp
            run_automation_tests
            ;;
        *)
            echo "Usage: $0 {encrypt|decrypt|test} [args...]" >&2
            echo ""
            echo "Commands:"
            echo "  encrypt <input_file> <output_file> <passphrase>"
            echo "  decrypt <input_file> <output_file> <passphrase>"
            echo "  test                                           # Run validation tests"
            return 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    security_log "INFO" "Age automator final started with command: $*"
    main "$@"
fi