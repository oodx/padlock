#!/bin/bash
# Age Automation - Production Implementation with PTY Emulation
# Security Guardian: Edgar - Bulletproof TTY Solution

set -euo pipefail

# Security Configuration
readonly SCRIPT_NAME="age_automator_production"
readonly TEMP_DIR_PREFIX="/tmp/age_auto_prod_$$"
readonly MAX_PASSPHRASE_LENGTH=1024
readonly SECURITY_LOG="/tmp/age_automator_production_audit.log"

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

# Production-grade TTY automation using script and unbuffer
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
    
    # Method 1: Try with script command for TTY emulation
    local script_output="$TEMP_DIR/script_output.txt"
    if script -qec "printf '%s\n%s\n' '$passphrase' '$passphrase' | age -p -o '$output_file' '$input_file'" "$script_output" >/dev/null 2>&1; then
        if [[ -f "$output_file" && -s "$output_file" ]]; then
            security_log "INFO" "Encryption completed successfully with script method"
            return 0
        fi
    fi
    
    # Method 2: Try with unbuffer (expect package)
    if command -v unbuffer >/dev/null 2>&1; then
        if printf '%s\n%s\n' "$passphrase" "$passphrase" | unbuffer -p age -p -o "$output_file" "$input_file" >/dev/null 2>&1; then
            if [[ -f "$output_file" && -s "$output_file" ]]; then
                security_log "INFO" "Encryption completed successfully with unbuffer method"
                return 0
            fi
        fi
    fi
    
    # Method 3: Try with socat PTY approach
    if command -v socat >/dev/null 2>&1; then
        local pty_master="$TEMP_DIR/pty_master"
        local pty_slave="$TEMP_DIR/pty_slave"
        
        # Create PTY pair
        if socat -d -d pty,raw,echo=0,link="$pty_master" pty,raw,echo=0,link="$pty_slave" &
        then
            local socat_pid=$!
            sleep 0.5  # Allow PTY to be established
            
            # Feed passphrase through PTY
            {
                printf '%s\n%s\n' "$passphrase" "$passphrase"
                sleep 1
            } > "$pty_master" &
            
            # Run age with PTY as stdin
            if age -p -o "$output_file" "$input_file" < "$pty_slave" >/dev/null 2>&1; then
                kill $socat_pid 2>/dev/null || true
                if [[ -f "$output_file" && -s "$output_file" ]]; then
                    security_log "INFO" "Encryption completed successfully with socat PTY method"
                    return 0
                fi
            fi
            kill $socat_pid 2>/dev/null || true
        fi
    fi
    
    # Method 4: Fallback to expect if available
    if command -v expect >/dev/null 2>&1; then
        local expect_script="$TEMP_DIR/encrypt_expect.exp"
        cat > "$expect_script" << 'EOF'
#!/usr/bin/expect -f
set timeout 30
set input_file [lindex $argv 0]
set output_file [lindex $argv 1]
set passphrase [lindex $argv 2]

log_user 0

spawn age -p -o $output_file $input_file

expect {
    "Enter passphrase*" {
        send "$passphrase\r"
        exp_continue
    }
    "Confirm passphrase*" {
        send "$passphrase\r"
        exp_continue
    }
    eof {
        catch wait result
        set exit_status [lindex $result 3]
        exit $exit_status
    }
    timeout {
        puts stderr "ERROR: Timeout waiting for age encryption"
        exit 1
    }
}
EOF
        
        chmod 700 "$expect_script"
        
        if expect "$expect_script" "$input_file" "$output_file" "$passphrase" >/dev/null 2>&1; then
            if [[ -f "$output_file" && -s "$output_file" ]]; then
                security_log "INFO" "Encryption completed successfully with expect method"
                return 0
            fi
        fi
    fi
    
    # All methods failed
    security_log "ERROR" "All encryption methods failed"
    echo "ERROR: Age encryption failed - TTY automation unsuccessful" >&2
    return 1
}

# Production-grade TTY automation for decryption
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
    
    # Method 1: Try with script command for TTY emulation
    local script_output="$TEMP_DIR/script_output.txt"
    if script -qec "printf '%s\n' '$passphrase' | age -d -o '$output_file' '$input_file'" "$script_output" >/dev/null 2>&1; then
        if [[ -f "$output_file" && -s "$output_file" ]]; then
            security_log "INFO" "Decryption completed successfully with script method"
            return 0
        fi
    fi
    
    # Method 2: Try with unbuffer (expect package)
    if command -v unbuffer >/dev/null 2>&1; then
        if printf '%s\n' "$passphrase" | unbuffer -p age -d -o "$output_file" "$input_file" >/dev/null 2>&1; then
            if [[ -f "$output_file" && -s "$output_file" ]]; then
                security_log "INFO" "Decryption completed successfully with unbuffer method"
                return 0
            fi
        fi
    fi
    
    # Method 3: Try with expect if available
    if command -v expect >/dev/null 2>&1; then
        local expect_script="$TEMP_DIR/decrypt_expect.exp"
        cat > "$expect_script" << 'EOF'
#!/usr/bin/expect -f
set timeout 30
set input_file [lindex $argv 0]
set output_file [lindex $argv 1]
set passphrase [lindex $argv 2]

log_user 0

spawn age -d -o $output_file $input_file

expect {
    "Enter passphrase*" {
        send "$passphrase\r"
        exp_continue
    }
    eof {
        catch wait result
        set exit_status [lindex $result 3]
        exit $exit_status
    }
    timeout {
        puts stderr "ERROR: Timeout waiting for age decryption"
        exit 1
    }
}
EOF
        
        chmod 700 "$expect_script"
        
        if expect "$expect_script" "$input_file" "$output_file" "$passphrase" >/dev/null 2>&1; then
            if [[ -f "$output_file" && -s "$output_file" ]]; then
                security_log "INFO" "Decryption completed successfully with expect method"
                return 0
            fi
        fi
    fi
    
    # All methods failed
    security_log "ERROR" "All decryption methods failed"
    echo "ERROR: Age decryption failed - TTY automation unsuccessful" >&2
    return 1
}

# Test function for validation
run_automation_tests() {
    echo "Testing Age automation capabilities (production implementation)..."
    
    # Create test file
    local test_file="$TEMP_DIR/test_input.txt"
    local encrypted_file="$TEMP_DIR/test_encrypted.age"
    local decrypted_file="$TEMP_DIR/test_decrypted.txt"
    local test_passphrase="TestPassphrase123"
    
    echo "Test content for production age automation implementation" > "$test_file"
    
    # Test encryption
    echo "Testing encryption with multiple TTY automation methods..."
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
    echo "Testing decryption with multiple TTY automation methods..."
    if age_decrypt_automated "$encrypted_file" "$decrypted_file" "$test_passphrase"; then
        echo "✅ Decryption test passed"
    else
        echo "❌ Decryption test failed"
        return 1
    fi
    
    # Verify content integrity
    if diff "$test_file" "$decrypted_file" >/dev/null 2>&1; then
        echo "✅ Content integrity verified"
        echo "🛡️ Age automation production implementation: ALL TESTS PASSED"
        echo "🔧 TTY automation solution is CONSISTENT and PRODUCTION-READY"
        security_log "INFO" "All tests passed - production TTY automation validated"
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
            echo "Running production age automation tests..."
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
    security_log "INFO" "Age automator production started with command: $*"
    main "$@"
fi