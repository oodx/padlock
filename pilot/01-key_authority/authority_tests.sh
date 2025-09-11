#!/bin/bash
# =====================================================================================
# PADLOCK AUTHORITY TESTS - 01-key_authority PILOT
# =====================================================================================
# MISSION: Comprehensive Security Validation Framework
# SECURITY TARGET: Validate T2.2: Authority Chain Corruption countermeasures
# SECURITY GUARDIAN: EDGAR (Lord Captain of Superhard Fortress)  
# IMPLEMENTATION: Lucas - Script Engineer Sage
# VERSION: 1.0.0-pilot
# =====================================================================================

set -euo pipefail

# =====================================================================================
# TEST FRAMEWORK CONFIGURATION
# =====================================================================================

readonly TEST_VERSION="1.0.0-pilot"
readonly TEST_SIGNATURE="PADLOCK-AUTHORITY-TESTS"

# Test environment setup
readonly TEST_BASE_DIR="/tmp/padlock-authority-tests-$$"
readonly TEST_HOME="${TEST_BASE_DIR}/home"
readonly AUTHORITY_MANAGER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/authority_manager.sh"

# Test counters
TEST_COUNT=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test keys for validation (sample age keys for testing)
readonly TEST_KEY_1="age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
readonly TEST_KEY_2="age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"  
readonly TEST_KEY_3="age1zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
readonly INVALID_KEY="invalid-key-format"

# =====================================================================================
# TEST FRAMEWORK FUNCTIONS
# =====================================================================================

# Test setup and teardown
setup_test_environment() {
    echo "=== Setting up test environment ==="
    
    # Create isolated test environment
    rm -rf "${TEST_BASE_DIR}"
    mkdir -p "${TEST_HOME}"
    
    # Set isolated HOME for testing
    export HOME="${TEST_HOME}"
    export XDG_CONFIG_HOME="${TEST_HOME}/.config"
    export XDG_DATA_HOME="${TEST_HOME}/.local/share"
    export XDG_CACHE_HOME="${TEST_HOME}/.cache"
    
    echo "Test environment: ${TEST_BASE_DIR}"
    echo "Test HOME: ${TEST_HOME}"
    echo "Authority Manager: ${AUTHORITY_MANAGER}"
    
    # Verify authority manager exists
    if [[ ! -x "${AUTHORITY_MANAGER}" ]]; then
        echo "ERROR: Authority manager not found or not executable: ${AUTHORITY_MANAGER}"
        exit 1
    fi
    
    echo "✓ Test environment setup complete"
}

cleanup_test_environment() {
    echo "=== Cleaning up test environment ==="
    rm -rf "${TEST_BASE_DIR}"
    echo "✓ Test environment cleaned"
}

# Test execution framework
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TEST_COUNT++))
    echo ""
    echo "[$TEST_COUNT] Running test: $test_name"
    echo "----------------------------------------"
    
    if $test_function; then
        echo "✓ PASSED: $test_name"
        ((PASSED_TESTS++))
        return 0
    else
        echo "✗ FAILED: $test_name"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Assertion helpers
assert_command_success() {
    local description="$1"
    shift
    
    if "$@"; then
        echo "  ✓ $description"
        return 0
    else
        echo "  ✗ $description (command failed: $*)"
        return 1
    fi
}

assert_command_failure() {
    local description="$1" 
    shift
    
    if "$@"; then
        echo "  ✗ $description (command should have failed: $*)"
        return 1
    else
        echo "  ✓ $description"
        return 0
    fi
}

assert_file_exists() {
    local file="$1"
    local description="${2:-File exists: $file}"
    
    if [[ -f "$file" ]]; then
        echo "  ✓ $description"
        return 0
    else
        echo "  ✗ $description"
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2" 
    local description="${3:-File contains pattern: $pattern}"
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  ✓ $description"
        return 0
    else
        echo "  ✗ $description"
        return 1
    fi
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local description="${3:-File does not contain pattern: $pattern}"
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  ✗ $description"
        return 1
    else
        echo "  ✓ $description" 
        return 0
    fi
}

# =====================================================================================
# SECURITY TEST CASES
# =====================================================================================

# Test 1: Authority Manager Initialization
test_authority_initialization() {
    echo "Testing authority manager initialization..."
    
    assert_command_success "Initialize authority manager" \
        "${AUTHORITY_MANAGER}" init test-initialization
    
    # Verify directory structure
    assert_file_exists "${HOME}/.local/etc/padlock/keys/recipients.txt" "Recipients file created"
    assert_file_exists "${HOME}/.local/share/padlock/authority.log" "Authority log created"
    
    # Verify initial content
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "PADLOCK Authority Recipients" "Recipients header present"
    
    assert_file_contains "${HOME}/.local/share/padlock/authority.log" \
        "AUTHORITY_LOG_INIT" "Log initialization entry present"
    
    return 0
}

# Test 2: Recipient Addition (allow operation)
test_recipient_addition() {
    echo "Testing recipient addition..."
    
    # Initialize first
    "${AUTHORITY_MANAGER}" init test-addition >/dev/null
    
    # Test valid recipient addition
    assert_command_success "Add valid recipient" \
        "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "test-user-1"
    
    # Verify recipient was added
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "${TEST_KEY_1}" "Recipient key present in file"
    
    assert_file_contains "${HOME}/.local/share/padlock/authority.log" \
        "ALLOW_SUCCESS" "Allow operation logged successfully"
    
    # Test duplicate addition (should succeed without error)
    assert_command_success "Add duplicate recipient (should be idempotent)" \
        "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "test-user-1-duplicate"
    
    # Test invalid key format
    assert_command_failure "Reject invalid key format" \
        "${AUTHORITY_MANAGER}" allow "${INVALID_KEY}" "invalid-user"
    
    return 0
}

# Test 3: Recipient Revocation  
test_recipient_revocation() {
    echo "Testing recipient revocation..."
    
    # Initialize and add test recipients
    "${AUTHORITY_MANAGER}" init test-revocation >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "test-user-1" >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_2}" "test-user-2" >/dev/null
    
    # Test valid revocation
    assert_command_success "Revoke valid recipient" \
        "${AUTHORITY_MANAGER}" revoke "${TEST_KEY_1}" "test-user-1"
    
    # Verify recipient was revoked (commented out, not removed)
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "REVOKED.*${TEST_KEY_1}" "Recipient marked as revoked"
    
    assert_file_contains "${HOME}/.local/share/padlock/authority.log" \
        "REVOKE_SUCCESS" "Revoke operation logged successfully"
    
    # Verify other recipient still active
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "${TEST_KEY_2}" "Other recipient still present"
    
    # Test revocation of non-existent recipient (should succeed without error)
    assert_command_success "Revoke non-existent recipient (should be idempotent)" \
        "${AUTHORITY_MANAGER}" revoke "${TEST_KEY_3}" "non-existent-user"
    
    # Test invalid key format
    assert_command_failure "Reject invalid key format for revocation" \
        "${AUTHORITY_MANAGER}" revoke "${INVALID_KEY}" "invalid-user"
    
    return 0
}

# Test 4: Key Rotation
test_key_rotation() {
    echo "Testing key rotation..."
    
    # Initialize and add test recipients
    "${AUTHORITY_MANAGER}" init test-rotation >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "test-user-1" >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_2}" "test-user-2" >/dev/null
    
    # Store original content for comparison
    local original_recipients=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^#.*$ ]] && continue
        original_recipients+=("$line")
    done < "${HOME}/.local/etc/padlock/keys/recipients.txt"
    
    # Test key rotation
    assert_command_success "Perform key rotation" \
        "${AUTHORITY_MANAGER}" rotate "test-rotation"
    
    # Verify rotation was logged
    assert_file_contains "${HOME}/.local/share/padlock/authority.log" \
        "ROTATE_SUCCESS" "Rotation operation logged successfully"
    
    # Verify rotation header added
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "KEY ROTATION:" "Rotation header present"
    
    # Verify original recipients preserved
    for recipient in "${original_recipients[@]}"; do
        assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
            "$recipient" "Original recipient preserved: ${recipient:0:16}..."
    done
    
    # Verify previous version archived
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "ROTATION ARCHIVE" "Previous version archived"
    
    return 0
}

# Test 5: Emergency Reset
test_emergency_reset() {
    echo "Testing emergency reset..."
    
    # Initialize and add test recipients
    "${AUTHORITY_MANAGER}" init test-reset >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "test-user-1" >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_2}" "test-user-2" >/dev/null
    
    # Test reset without confirmation (should fail)
    assert_command_failure "Reject reset without confirmation" \
        "${AUTHORITY_MANAGER}" reset "test-reset-reason"
    
    # Test reset with wrong confirmation (should fail)
    assert_command_failure "Reject reset with wrong confirmation" \
        "${AUTHORITY_MANAGER}" reset "test-reset-reason" "WRONG"
    
    # Test proper emergency reset
    assert_command_success "Perform emergency reset with confirmation" \
        "${AUTHORITY_MANAGER}" reset "test-reset-reason" "CONFIRM_RESET"
    
    # Verify reset was logged
    assert_file_contains "${HOME}/.local/share/padlock/authority.log" \
        "RESET_SUCCESS" "Reset operation logged successfully"
    
    # Verify reset header
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "EMERGENCY AUTHORITY RESET" "Reset header present"
    
    # Verify emergency backup was created
    local backup_count=$(find "${HOME}/.local/etc/padlock/keys/" -name "recipients.backup.emergency.*" | wc -l)
    if [[ $backup_count -ge 1 ]]; then
        echo "  ✓ Emergency backup created"
    else
        echo "  ✗ Emergency backup not found"
        return 1
    fi
    
    return 0
}

# Test 6: Authority Status Reporting
test_authority_status() {
    echo "Testing authority status reporting..."
    
    # Initialize and add test data
    "${AUTHORITY_MANAGER}" init test-status >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "test-user-1" >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_2}" "test-user-2" >/dev/null
    "${AUTHORITY_MANAGER}" revoke "${TEST_KEY_1}" "test-user-1" >/dev/null
    
    # Test status command
    local status_output
    status_output=$("${AUTHORITY_MANAGER}" status test-status)
    
    # Verify status output contains expected information
    if echo "$status_output" | grep -q "PADLOCK AUTHORITY STATUS"; then
        echo "  ✓ Status header present"
    else
        echo "  ✗ Status header missing"
        return 1
    fi
    
    if echo "$status_output" | grep -q "Active Recipients: 1"; then
        echo "  ✓ Correct active recipient count"
    else
        echo "  ✗ Incorrect active recipient count"
        return 1
    fi
    
    if echo "$status_output" | grep -q "Revoked Recipients: 1"; then
        echo "  ✓ Correct revoked recipient count"
    else
        echo "  ✗ Incorrect revoked recipient count"
        return 1
    fi
    
    if echo "$status_output" | grep -q "Validation Status: ✓ VALID"; then
        echo "  ✓ Validation status correct"
    else
        echo "  ✗ Validation status incorrect"
        return 1
    fi
    
    return 0
}

# Test 7: Backup and Recovery Operations
test_backup_recovery() {
    echo "Testing backup and recovery operations..."
    
    # Initialize and add test recipients
    "${AUTHORITY_MANAGER}" init test-backup >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "test-user-1" >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_2}" "test-user-2" >/dev/null
    
    # Verify backup file was created during operations
    assert_file_exists "${HOME}/.local/etc/padlock/keys/recipients.backup" "Backup file exists"
    
    # Verify backup integrity
    local original_hash=$(sha256sum "${HOME}/.local/etc/padlock/keys/recipients.txt" | cut -d' ' -f1)
    local backup_hash=$(sha256sum "${HOME}/.local/etc/padlock/keys/recipients.backup" | cut -d' ' -f1)
    
    if [[ "$original_hash" == "$backup_hash" ]]; then
        echo "  ✓ Backup integrity verified"
    else
        echo "  ✗ Backup integrity check failed"
        return 1
    fi
    
    # Test validation command
    assert_command_success "Validate authority state" \
        "${AUTHORITY_MANAGER}" validate test-backup
    
    return 0
}

# Test 8: Concurrent Operation Safety
test_concurrent_safety() {
    echo "Testing concurrent operation safety..."
    
    # Initialize
    "${AUTHORITY_MANAGER}" init test-concurrent >/dev/null
    
    # Test multiple rapid operations (simulating concurrent access)
    local pids=()
    
    # Start multiple allow operations in background
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "concurrent-user-1" &
    pids+=($!)
    
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_2}" "concurrent-user-2" &
    pids+=($!)
    
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_3}" "concurrent-user-3" &
    pids+=($!)
    
    # Wait for all operations to complete
    local all_success=true
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            all_success=false
        fi
    done
    
    if $all_success; then
        echo "  ✓ Concurrent operations completed successfully"
    else
        echo "  ✗ Some concurrent operations failed"
        return 1
    fi
    
    # Verify final state integrity
    assert_command_success "Validate state after concurrent operations" \
        "${AUTHORITY_MANAGER}" validate test-concurrent
    
    # Verify all recipients were added
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "${TEST_KEY_1}" "First concurrent recipient added"
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "${TEST_KEY_2}" "Second concurrent recipient added" 
    assert_file_contains "${HOME}/.local/etc/padlock/keys/recipients.txt" \
        "${TEST_KEY_3}" "Third concurrent recipient added"
    
    return 0
}

# Test 9: Error Handling and Edge Cases
test_error_handling() {
    echo "Testing error handling and edge cases..."
    
    # Test operations without initialization
    assert_command_failure "Reject operations without initialization" \
        "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "no-init-user"
    
    # Initialize for remaining tests
    "${AUTHORITY_MANAGER}" init test-errors >/dev/null
    
    # Test empty/invalid inputs
    assert_command_failure "Reject empty recipient key" \
        "${AUTHORITY_MANAGER}" allow "" "empty-key-user"
    
    # Test malformed recipients file (simulate corruption)
    echo "invalid line that breaks format" >> "${HOME}/.local/etc/padlock/keys/recipients.txt"
    
    assert_command_failure "Detect corrupted recipients file" \
        "${AUTHORITY_MANAGER}" validate test-errors
    
    # Clean up corruption for next test
    "${AUTHORITY_MANAGER}" init test-errors-clean >/dev/null
    
    # Test operations with missing backup directory
    rm -rf "${HOME}/.local/etc/padlock/keys"
    mkdir -p "${HOME}/.local/etc/padlock/keys"
    echo "${TEST_KEY_1}" > "${HOME}/.local/etc/padlock/keys/recipients.txt"
    
    assert_command_success "Handle missing backup directory" \
        "${AUTHORITY_MANAGER}" allow "${TEST_KEY_2}" "missing-backup-dir"
    
    return 0
}

# Test 10: Security Audit Trail
test_audit_trail() {
    echo "Testing security audit trail..."
    
    # Initialize and perform various operations
    "${AUTHORITY_MANAGER}" init test-audit >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_1}" "audit-user-1" >/dev/null
    "${AUTHORITY_MANAGER}" allow "${TEST_KEY_2}" "audit-user-2" >/dev/null
    "${AUTHORITY_MANAGER}" revoke "${TEST_KEY_1}" "audit-user-1" >/dev/null
    "${AUTHORITY_MANAGER}" rotate "audit-rotation" >/dev/null
    "${AUTHORITY_MANAGER}" status test-audit >/dev/null
    
    local log_file="${HOME}/.local/share/padlock/authority.log"
    
    # Verify all major operations are logged
    assert_file_contains "$log_file" "INIT_SUCCESS" "Initialization logged"
    assert_file_contains "$log_file" "ALLOW_SUCCESS" "Allow operations logged"
    assert_file_contains "$log_file" "REVOKE_SUCCESS" "Revoke operation logged"
    assert_file_contains "$log_file" "ROTATE_SUCCESS" "Rotation logged" 
    assert_file_contains "$log_file" "STATUS_SUCCESS" "Status check logged"
    
    # Verify log format includes timestamps and hashes
    assert_file_contains "$log_file" "SECURITY_AUDIT.*UTC.*hash:" "Log format includes security elements"
    
    # Verify log entries are properly sequenced
    local log_count=$(grep -c "SECURITY_AUDIT" "$log_file")
    if [[ $log_count -ge 10 ]]; then
        echo "  ✓ Adequate audit log coverage ($log_count entries)"
    else
        echo "  ✗ Insufficient audit log coverage ($log_count entries)"
        return 1
    fi
    
    return 0
}

# =====================================================================================
# TEST EXECUTION MAIN
# =====================================================================================

# Test suite execution
run_test_suite() {
    echo "======================================"
    echo "PADLOCK AUTHORITY TESTS v${TEST_VERSION}"
    echo "======================================"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Target: Authority Manager Security Validation"
    echo "Threat: T2.2: Authority Chain Corruption"
    echo ""
    
    # Execute all tests
    run_test "Authority Initialization" test_authority_initialization
    run_test "Recipient Addition" test_recipient_addition
    run_test "Recipient Revocation" test_recipient_revocation
    run_test "Key Rotation" test_key_rotation
    run_test "Emergency Reset" test_emergency_reset
    run_test "Authority Status" test_authority_status
    run_test "Backup Recovery" test_backup_recovery
    run_test "Concurrent Safety" test_concurrent_safety
    run_test "Error Handling" test_error_handling
    run_test "Audit Trail" test_audit_trail
    
    # Test results summary
    echo ""
    echo "======================================"
    echo "TEST RESULTS SUMMARY"
    echo "======================================"
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo ""
        echo "🛡️ ALL TESTS PASSED - SECURITY VALIDATED ✓"
        echo "Authority Chain Corruption (T2.2) countermeasures verified"
        echo "Authority Manager ready for integration"
        return 0
    else
        echo ""
        echo "🚨 SOME TESTS FAILED - SECURITY ISSUES DETECTED ✗"
        echo "Authority Chain Corruption (T2.2) countermeasures incomplete"
        echo "Do NOT integrate until all tests pass"
        return 1
    fi
}

# Main execution
main() {
    local command="${1:-run}"
    
    case "$command" in
        "run"|"test")
            setup_test_environment
            if run_test_suite; then
                cleanup_test_environment
                exit 0
            else
                cleanup_test_environment
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            cat << 'EOF'
PADLOCK Authority Tests v1.0.0-pilot
===================================

USAGE:
  ./authority_tests.sh [command]

COMMANDS:
  run, test    Run complete test suite (default)
  help         Show this help message

SECURITY VALIDATION:
  ✓ Authority initialization security
  ✓ Recipient addition/revocation operations  
  ✓ Key rotation and emergency reset procedures
  ✓ Backup/recovery mechanisms
  ✓ Concurrent operation safety
  ✓ Error handling and edge cases
  ✓ Security audit trail verification

TARGET THREAT: T2.2: Authority Chain Corruption
COVERAGE: Complete authority management validation

For emergency procedures, see emergency_recovery.sh
EOF
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi