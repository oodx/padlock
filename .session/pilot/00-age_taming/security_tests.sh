#!/bin/bash
# Age Automation Security Validation Suite
# Security Guardian: Edgar - Comprehensive Security Testing

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR="/tmp/age_taming_security_tests_$$"
readonly SECURITY_LOG="/tmp/age_security_tests_audit.log"

# Test results tracking
declare -i TESTS_TOTAL=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0

# Security audit logging
security_log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [TEST] $message" | tee -a "$SECURITY_LOG"
}

# Test result tracking
test_result() {
    local test_name="$1"
    local result="$2"
    local details="${3:-}"
    
    ((TESTS_TOTAL++))
    
    if [[ "$result" == "PASS" ]]; then
        ((TESTS_PASSED++))
        echo "✅ $test_name: PASS"
        security_log "INFO" "TEST PASS: $test_name - $details"
    else
        ((TESTS_FAILED++))
        echo "❌ $test_name: FAIL - $details"
        security_log "ERROR" "TEST FAIL: $test_name - $details"
    fi
}

# Setup secure test environment
setup_test_environment() {
    security_log "INFO" "Setting up secure test environment"
    
    # Create secure test directory
    mkdir -p "$TEST_DIR"
    chmod 700 "$TEST_DIR"
    
    # Verify age_automator.sh is available
    if [[ ! -x "$SCRIPT_DIR/age_automator.sh" ]]; then
        echo "ERROR: age_automator.sh not found or not executable" >&2
        exit 1
    fi
    
    security_log "INFO" "Test environment ready: $TEST_DIR"
}

# Cleanup test environment
cleanup_test_environment() {
    security_log "INFO" "Cleaning up test environment"
    
    if [[ -d "$TEST_DIR" ]]; then
        # Secure cleanup of test files
        find "$TEST_DIR" -type f -exec shred -vfz -n 3 {} \; 2>/dev/null || true
        rm -rf "$TEST_DIR" 2>/dev/null || true
    fi
    
    security_log "INFO" "Test environment cleaned"
}

# Test basic encryption/decryption functionality
test_basic_encryption_decryption() {
    local test_name="Basic Encryption/Decryption"
    security_log "INFO" "Starting: $test_name"
    
    local input_file="$TEST_DIR/basic_test.txt"
    local encrypted_file="$TEST_DIR/basic_test.age"
    local decrypted_file="$TEST_DIR/basic_test_decrypted.txt"
    local passphrase="BasicTestPassphrase123"
    
    # Create test content
    echo "Basic test content for encryption validation" > "$input_file"
    
    # Test encryption
    if "$SCRIPT_DIR/age_automator.sh" encrypt "$input_file" "$encrypted_file" "$passphrase" >/dev/null 2>&1; then
        # Test decryption
        if "$SCRIPT_DIR/age_automator.sh" decrypt "$encrypted_file" "$decrypted_file" "$passphrase" >/dev/null 2>&1; then
            # Verify content integrity
            if diff "$input_file" "$decrypted_file" >/dev/null 2>&1; then
                test_result "$test_name" "PASS" "Content integrity verified"
                return 0
            else
                test_result "$test_name" "FAIL" "Content integrity check failed"
                return 1
            fi
        else
            test_result "$test_name" "FAIL" "Decryption failed"
            return 1
        fi
    else
        test_result "$test_name" "FAIL" "Encryption failed"
        return 1
    fi
}

# Test special character handling in passphrases
test_special_character_passphrases() {
    local test_name="Special Character Passphrases"
    security_log "INFO" "Starting: $test_name"
    
    local input_file="$TEST_DIR/special_chars_test.txt"
    local encrypted_file="$TEST_DIR/special_chars_test.age"
    local decrypted_file="$TEST_DIR/special_chars_test_decrypted.txt"
    
    # Test various special character combinations
    local special_passphrases=(
        'Password!@#$%^&*()'
        'Pass"word with quotes'
        "Pass'word with single quotes"
        'Password with spaces and !@# symbols'
        'Password|with|pipes&ampersands'
        'Password\with\backslashes'
        'Password$with$dollar$signs'
        'Password`with`backticks'
    )
    
    local special_test_passed=true
    
    for passphrase in "${special_passphrases[@]}"; do
        echo "Test content for special chars: $passphrase" > "$input_file"
        
        if "$SCRIPT_DIR/age_automator.sh" encrypt "$input_file" "$encrypted_file" "$passphrase" >/dev/null 2>&1; then
            if "$SCRIPT_DIR/age_automator.sh" decrypt "$encrypted_file" "$decrypted_file" "$passphrase" >/dev/null 2>&1; then
                if ! diff "$input_file" "$decrypted_file" >/dev/null 2>&1; then
                    special_test_passed=false
                    break
                fi
            else
                special_test_passed=false
                break
            fi
        else
            special_test_passed=false
            break
        fi
        
        # Cleanup for next iteration
        rm -f "$encrypted_file" "$decrypted_file"
    done
    
    if $special_test_passed; then
        test_result "$test_name" "PASS" "All special character passphrases handled correctly"
        return 0
    else
        test_result "$test_name" "FAIL" "Special character handling failed"
        return 1
    fi
}

# Test injection attack prevention
test_injection_prevention() {
    local test_name="Command Injection Prevention"
    security_log "INFO" "Starting: $test_name"
    
    local input_file="$TEST_DIR/injection_test.txt"
    local encrypted_file="$TEST_DIR/injection_test.age"
    local decrypted_file="$TEST_DIR/injection_test_decrypted.txt"
    
    # Test malicious passphrase patterns
    local malicious_passphrases=(
        'password; rm -rf /'
        'password && touch /tmp/injection_test_marker'
        'password | cat /etc/passwd'
        'password $(echo "injection_attempt")'
        'password `echo "backtick_injection"`'
        $'password\necho "newline_injection"'
        'password; echo $HOME'
    )
    
    echo "Test content for injection prevention" > "$input_file"
    
    local injection_test_passed=true
    
    for passphrase in "${malicious_passphrases[@]}"; do
        # Attempt encryption with malicious passphrase
        if "$SCRIPT_DIR/age_automator.sh" encrypt "$input_file" "$encrypted_file" "$passphrase" >/dev/null 2>&1; then
            # If encryption succeeds, verify no injection occurred
            if [[ -f "/tmp/injection_test_marker" ]]; then
                injection_test_passed=false
                rm -f "/tmp/injection_test_marker"
                break
            fi
            
            # Test decryption with same passphrase
            if "$SCRIPT_DIR/age_automator.sh" decrypt "$encrypted_file" "$decrypted_file" "$passphrase" >/dev/null 2>&1; then
                # Verify content integrity and no injection
                if ! diff "$input_file" "$decrypted_file" >/dev/null 2>&1; then
                    injection_test_passed=false
                    break
                fi
            fi
        fi
        
        # Cleanup for next iteration
        rm -f "$encrypted_file" "$decrypted_file"
    done
    
    if $injection_test_passed; then
        test_result "$test_name" "PASS" "All injection attempts prevented"
        return 0
    else
        test_result "$test_name" "FAIL" "Injection vulnerability detected"
        return 1
    fi
}

# Test passphrase validation security
test_passphrase_validation() {
    local test_name="Passphrase Validation Security"
    security_log "INFO" "Starting: $test_name"
    
    local input_file="$TEST_DIR/validation_test.txt"
    local encrypted_file="$TEST_DIR/validation_test.age"
    
    echo "Test content for validation" > "$input_file"
    
    # Test oversized passphrase (should be rejected)
    local oversized_passphrase=$(printf 'a%.0s' {1..2000})  # 2000 characters
    
    if ! "$SCRIPT_DIR/age_automator.sh" encrypt "$input_file" "$encrypted_file" "$oversized_passphrase" >/dev/null 2>&1; then
        # Test null byte injection (should be rejected)
        local null_passphrase=$'password\0injection'
        
        if ! "$SCRIPT_DIR/age_automator.sh" encrypt "$input_file" "$encrypted_file" "$null_passphrase" >/dev/null 2>&1; then
            test_result "$test_name" "PASS" "Validation correctly rejected malformed passphrases"
            return 0
        else
            test_result "$test_name" "FAIL" "Null byte injection not prevented"
            return 1
        fi
    else
        test_result "$test_name" "FAIL" "Oversized passphrase not rejected"
        return 1
    fi
}

# Test secure cleanup functionality
test_secure_cleanup() {
    local test_name="Secure Cleanup Functionality"
    security_log "INFO" "Starting: $test_name"
    
    local input_file="$TEST_DIR/cleanup_test.txt"
    local encrypted_file="$TEST_DIR/cleanup_test.age"
    local passphrase="CleanupTestPassphrase"
    
    echo "Test content for cleanup validation" > "$input_file"
    
    # Run encryption with intentional interruption
    (
        # Start encryption process
        "$SCRIPT_DIR/age_automator.sh" encrypt "$input_file" "$encrypted_file" "$passphrase" &
        local age_pid=$!
        
        # Let it start, then interrupt
        sleep 1
        kill -TERM $age_pid 2>/dev/null || true
        wait $age_pid 2>/dev/null || true
    ) >/dev/null 2>&1
    
    # Check for leftover temporary files (should be cleaned up)
    local temp_files_remaining=false
    
    # Look for age_auto temporary directories
    if find /tmp -maxdepth 1 -name "age_auto_*" -type d 2>/dev/null | grep -q .; then
        temp_files_remaining=true
    fi
    
    if ! $temp_files_remaining; then
        test_result "$test_name" "PASS" "Temporary files properly cleaned up"
        return 0
    else
        test_result "$test_name" "FAIL" "Temporary files not cleaned up"
        return 1
    fi
}

# Test error handling robustness
test_error_handling() {
    local test_name="Error Handling Robustness"
    security_log "INFO" "Starting: $test_name"
    
    local error_tests_passed=true
    
    # Test with non-existent input file
    if "$SCRIPT_DIR/age_automator.sh" encrypt "/nonexistent/file" "/tmp/test.age" "password" >/dev/null 2>&1; then
        error_tests_passed=false
    fi
    
    # Test with invalid output directory
    local input_file="$TEST_DIR/error_test.txt"
    echo "Error test content" > "$input_file"
    
    if "$SCRIPT_DIR/age_automator.sh" encrypt "$input_file" "/nonexistent/dir/test.age" "password" >/dev/null 2>&1; then
        error_tests_passed=false
    fi
    
    # Test decryption with wrong passphrase
    local encrypted_file="$TEST_DIR/error_test.age"
    "$SCRIPT_DIR/age_automator.sh" encrypt "$input_file" "$encrypted_file" "correct_password" >/dev/null 2>&1
    
    if "$SCRIPT_DIR/age_automator.sh" decrypt "$encrypted_file" "/tmp/decrypted.txt" "wrong_password" >/dev/null 2>&1; then
        error_tests_passed=false
    fi
    
    if $error_tests_passed; then
        test_result "$test_name" "PASS" "All error conditions handled correctly"
        return 0
    else
        test_result "$test_name" "FAIL" "Error handling insufficient"
        return 1
    fi
}

# Test audit logging functionality
test_audit_logging() {
    local test_name="Audit Logging Functionality"
    security_log "INFO" "Starting: $test_name"
    
    local input_file="$TEST_DIR/audit_test.txt"
    local encrypted_file="$TEST_DIR/audit_test.age"
    local passphrase="AuditTestPassphrase"
    
    echo "Test content for audit logging" > "$input_file"
    
    # Clear previous audit logs
    : > "$SECURITY_LOG"
    
    # Perform encryption operation
    "$SCRIPT_DIR/age_automator.sh" encrypt "$input_file" "$encrypted_file" "$passphrase" >/dev/null 2>&1
    
    # Check audit log was created and contains expected entries
    if [[ -f "$SECURITY_LOG" ]] && grep -q "Starting automated encryption" "$SECURITY_LOG" && \
       grep -q "Encryption completed successfully" "$SECURITY_LOG"; then
        test_result "$test_name" "PASS" "Audit logging working correctly"
        return 0
    else
        test_result "$test_name" "FAIL" "Audit logging not functioning"
        return 1
    fi
}

# Run all security tests
run_all_security_tests() {
    echo "🛡️ Age Automation Security Test Suite - Starting Comprehensive Validation"
    echo "========================================================================"
    
    security_log "INFO" "Starting comprehensive security test suite"
    
    # Setup environment
    setup_test_environment
    
    # Run all test functions
    test_basic_encryption_decryption
    test_special_character_passphrases
    test_injection_prevention
    test_passphrase_validation
    test_secure_cleanup
    test_error_handling
    test_audit_logging
    
    # Report results
    echo ""
    echo "========================================================================"
    echo "🛡️ Age Automation Security Test Results:"
    echo "   Total Tests: $TESTS_TOTAL"
    echo "   Passed: $TESTS_PASSED"
    echo "   Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "   Status: ✅ ALL SECURITY TESTS PASSED"
        echo ""
        echo "🛡️ Age Automation Pilot: SECURITY VALIDATION COMPLETE"
        echo "   TTY automation solution is PRODUCTION READY"
        security_log "INFO" "All security tests passed - Age automation validated"
        cleanup_test_environment
        return 0
    else
        echo "   Status: ❌ SECURITY VALIDATION FAILED"
        echo ""
        echo "🚨 Critical security issues detected - DO NOT DEPLOY"
        security_log "ERROR" "Security validation failed - $TESTS_FAILED tests failed"
        cleanup_test_environment
        return 1
    fi
}

# Trap for cleanup
trap cleanup_test_environment EXIT INT TERM

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_security_tests "$@"
fi