#!/bin/bash
# Age Automation Core Implementation - Dependency-Free Version
# Security Guardian: Edgar - Consistent TTY Automation Solution

set -euo pipefail

# Security Configuration
readonly SCRIPT_NAME="age_automator_v2"
readonly TEMP_DIR_PREFIX="/tmp/age_auto_v2_$$"
readonly MAX_PASSPHRASE_LENGTH=1024
readonly SECURITY_LOG="/tmp/age_automator_v2_audit.log"

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

# Core TTY automation using script command (more reliable than expect)
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
    
    # Create automation script using script command
    local automation_script="$TEMP_DIR/encrypt_automation.sh"
    local script_output="$TEMP_DIR/script_output.txt"
    
    cat > "$automation_script" << EOF
#!/bin/bash
set -euo pipefail

# Provide passphrase input for age
{
    echo "$passphrase"
    echo "$passphrase"  # Confirmation
} | age -p -o "$output_file" "$input_file"
EOF
    
    chmod 700 "$automation_script"
    
    # Execute using script command to simulate TTY
    if script -qec "$automation_script" "$script_output" >/dev/null 2>&1; then
        security_log "INFO" "Encryption completed successfully"
        
        # Verify output file was created
        if [[ -f "$output_file" ]]; then
            security_log "INFO" "Output file verified: $output_file"
            return 0
        else
            security_log "ERROR" "Output file not created: $output_file"
            echo "ERROR: Encryption failed - no output file created" >&2
            return 1
        fi
    else
        local exit_code=$?
        security_log "ERROR" "Encryption failed with exit code: $exit_code"
        echo "ERROR: Age encryption failed" >&2
        return $exit_code
    fi
}

# Core TTY automation for decryption
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
    
    # Create automation script using script command
    local automation_script="$TEMP_DIR/decrypt_automation.sh"
    local script_output="$TEMP_DIR/script_output.txt"
    
    cat > "$automation_script" << EOF
#!/bin/bash
set -euo pipefail

# Provide passphrase input for age
echo "$passphrase" | age -d -o "$output_file" "$input_file"
EOF
    
    chmod 700 "$automation_script"
    
    # Execute using script command to simulate TTY
    if script -qec "$automation_script" "$script_output" >/dev/null 2>&1; then
        security_log "INFO" "Decryption completed successfully"
        
        # Verify output file was created
        if [[ -f "$output_file" ]]; then
            security_log "INFO" "Output file verified: $output_file"
            return 0
        else
            security_log "ERROR" "Output file not created: $output_file"
            echo "ERROR: Decryption failed - no output file created" >&2
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
    echo "Testing Age automation capabilities (dependency-free)..."
    
    # Create test file
    local test_file="$TEMP_DIR/test_input.txt"
    local encrypted_file="$TEMP_DIR/test_encrypted.age"
    local decrypted_file="$TEMP_DIR/test_decrypted.txt"
    local test_passphrase="TestPassphrase123"
    
    echo "Test content for age automation v2" > "$test_file"
    
    # Test encryption
    echo "Testing encryption..."
    if age_encrypt_automated "$test_file" "$encrypted_file" "$test_passphrase"; then
        echo "✅ Encryption test passed"
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
    if diff "$test_file" "$decrypted_file" > /dev/null; then
        echo "✅ Content integrity verified"
        echo "🛡️ Age automation v2 pilot: ALL TESTS PASSED"
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
            echo "Running dependency-free age automation tests..."
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
    security_log "INFO" "Age automator v2 started with command: $*"
    main "$@"
fi