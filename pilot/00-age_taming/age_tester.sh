#!/bin/bash
# Age TTY Automation Testing - Avatar's Intelligence Methods
# Security Guardian: Edgar - Testing Proven Patterns

set -euo pipefail

readonly TEST_DIR="/tmp/age_test_$$"
readonly TEST_PASSPHRASE="TestPass123"

# Setup test environment
setup_test() {
    mkdir -p "$TEST_DIR"
    echo "Test content for Age automation" > "$TEST_DIR/input.txt"
    echo "🔧 Testing Age TTY automation methods..."
}

# Cleanup test environment
cleanup_test() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

trap cleanup_test EXIT

# Test Method 1: script with heredoc
test_script_heredoc() {
    echo "Method 1: script with heredoc"
    
    if script -q -c "age -p -o '$TEST_DIR/test1.age' '$TEST_DIR/input.txt'" /dev/null <<< "$TEST_PASSPHRASE
$TEST_PASSPHRASE"; then
        if [[ -f "$TEST_DIR/test1.age" && -s "$TEST_DIR/test1.age" ]]; then
            echo "✅ Method 1: SUCCESS - script with heredoc works"
            return 0
        fi
    fi
    echo "❌ Method 1: FAILED"
    return 1
}

# Test Method 2: expect automation
test_expect() {
    echo "Method 2: expect automation"
    
    if expect -c "
        spawn age -p -o $TEST_DIR/test2.age $TEST_DIR/input.txt
        expect \"Enter passphrase*\"
        send \"$TEST_PASSPHRASE\r\"
        expect \"Confirm passphrase*\"
        send \"$TEST_PASSPHRASE\r\"
        expect eof
    " >/dev/null 2>&1; then
        if [[ -f "$TEST_DIR/test2.age" && -s "$TEST_DIR/test2.age" ]]; then
            echo "✅ Method 2: SUCCESS - expect automation works"
            return 0
        fi
    fi
    echo "❌ Method 2: FAILED"
    return 1
}

# Test Method 3: unbuffer with EOF
test_unbuffer() {
    echo "Method 3: unbuffer with EOF"
    
    if unbuffer age -p -o "$TEST_DIR/test3.age" "$TEST_DIR/input.txt" <<EOF >/dev/null 2>&1
$TEST_PASSPHRASE
$TEST_PASSPHRASE
EOF
    then
        if [[ -f "$TEST_DIR/test3.age" && -s "$TEST_DIR/test3.age" ]]; then
            echo "✅ Method 3: SUCCESS - unbuffer with EOF works"
            return 0
        fi
    fi
    echo "❌ Method 3: FAILED"
    return 1
}

# Test Method 4: socat exec with pty (most promising)
test_socat_exec() {
    echo "Method 4: socat exec with pty"
    
    if command -v socat >/dev/null 2>&1; then
        if printf '%s\n%s\n' "$TEST_PASSPHRASE" "$TEST_PASSPHRASE" | \
           socat - exec:"age -p -o $TEST_DIR/test4.age $TEST_DIR/input.txt",pty,setsid,stderr >/dev/null 2>&1; then
            if [[ -f "$TEST_DIR/test4.age" && -s "$TEST_DIR/test4.age" ]]; then
                echo "✅ Method 4: SUCCESS - socat exec with pty works"
                return 0
            fi
        fi
        echo "❌ Method 4: FAILED"
    else
        echo "❌ Method 4: SKIPPED - socat not available"
    fi
    return 1
}

# Test Method 5: yes for repeated input (might work for simple cases)
test_yes_method() {
    echo "Method 5: yes for repeated input"
    
    if timeout 10 yes "$TEST_PASSPHRASE" | age -p -o "$TEST_DIR/test5.age" "$TEST_DIR/input.txt" >/dev/null 2>&1; then
        if [[ -f "$TEST_DIR/test5.age" && -s "$TEST_DIR/test5.age" ]]; then
            echo "✅ Method 5: SUCCESS - yes method works"
            return 0
        fi
    fi
    echo "❌ Method 5: FAILED"
    return 1
}

# Run all tests and report results
run_all_tests() {
    setup_test
    
    echo "🛡️ Age TTY Automation Testing Suite"
    echo "==================================="
    
    local successful_methods=()
    
    if test_script_heredoc; then
        successful_methods+=("script_heredoc")
    fi
    
    if test_expect; then
        successful_methods+=("expect")
    fi
    
    if test_unbuffer; then
        successful_methods+=("unbuffer")
    fi
    
    if test_socat_exec; then
        successful_methods+=("socat_exec")
    fi
    
    if test_yes_method; then
        successful_methods+=("yes_method")
    fi
    
    echo ""
    echo "🛡️ Test Results Summary:"
    echo "   Successful methods: ${#successful_methods[@]}"
    
    if [[ ${#successful_methods[@]} -gt 0 ]]; then
        echo "   Working approaches: ${successful_methods[*]}"
        echo ""
        echo "✅ TTY AUTOMATION SOLUTION FOUND!"
        echo "   Primary method: ${successful_methods[0]}"
        return 0
    else
        echo "   No working methods found"
        echo ""
        echo "❌ TTY AUTOMATION CHALLENGE PERSISTS"
        return 1
    fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests "$@"
fi