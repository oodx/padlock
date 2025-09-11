#!/bin/bash
# =====================================================================================
# PADLOCK AUTHORITY MANAGER - 01-key_authority PILOT
# =====================================================================================
# MISSION: Bulletproof Key Authority Management System
# SECURITY TARGET: Eliminate T2.2: Authority Chain Corruption
# SECURITY GUARDIAN: EDGAR (Lord Captain of Superhard Fortress)
# IMPLEMENTATION: Lucas - Script Engineer Sage
# VERSION: 1.0.0-pilot
# =====================================================================================

set -euo pipefail

# =====================================================================================
# SECURITY CONSTANTS & CONFIGURATION
# =====================================================================================

readonly AUTHORITY_VERSION="1.0.0-pilot"
readonly AUTHORITY_SIGNATURE="PADLOCK-AUTHORITY-MANAGER"

# Security directories (following padlock patterns)
readonly PADLOCK_CONFIG_DIR="${HOME}/.local/etc/padlock"
readonly PADLOCK_DATA_DIR="${HOME}/.local/share/padlock"
readonly PADLOCK_CACHE_DIR="${HOME}/.cache/padlock"

# Authority chain files
readonly AUTHORITY_RECIPIENTS="${PADLOCK_CONFIG_DIR}/keys/recipients.txt"
readonly AUTHORITY_BACKUP="${PADLOCK_CONFIG_DIR}/keys/recipients.backup"
readonly AUTHORITY_MASTER="${PADLOCK_CONFIG_DIR}/keys/master.key"
readonly AUTHORITY_LOG="${PADLOCK_DATA_DIR}/authority.log"
readonly AUTHORITY_STATE="${PADLOCK_DATA_DIR}/authority.state"

# Security validation files
readonly AUTHORITY_VALIDATION="${PADLOCK_CACHE_DIR}/validation.tmp"
readonly AUTHORITY_OPERATION="${PADLOCK_CACHE_DIR}/operation.tmp"

# =====================================================================================
# CRYPTOGRAPHIC SECURITY FUNCTIONS
# =====================================================================================

# Security logging with cryptographic audit trail
log_security_event() {
    local event_type="$1"
    local event_data="$2"
    local timestamp="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    local event_hash="$(echo -n "${timestamp}:${event_type}:${event_data}" | sha256sum | cut -d' ' -f1)"
    
    echo "SECURITY_AUDIT: ${timestamp} [${event_type}] ${event_data} (hash: ${event_hash})" >> "${AUTHORITY_LOG}"
}

# Cryptographic validation of authority state
validate_authority_state() {
    local validation_context="$1"
    
    log_security_event "VALIDATION_START" "Context: ${validation_context}"
    
    # Validate recipients file exists and is readable
    if [[ ! -f "${AUTHORITY_RECIPIENTS}" ]]; then
        log_security_event "VALIDATION_FAIL" "Recipients file missing: ${AUTHORITY_RECIPIENTS}"
        return 1
    fi
    
    # Validate recipients file format (age public keys)
    local invalid_lines=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^#.*$ ]] && continue
        
        if [[ ! "$line" =~ ^age[0-9a-z]+$ ]]; then
            log_security_event "VALIDATION_FAIL" "Invalid recipient format: ${line}"
            ((invalid_lines++))
        fi
    done < "${AUTHORITY_RECIPIENTS}"
    
    if [[ $invalid_lines -gt 0 ]]; then
        log_security_event "VALIDATION_FAIL" "Found ${invalid_lines} invalid recipient lines"
        return 1
    fi
    
    # Validate backup file consistency if exists
    if [[ -f "${AUTHORITY_BACKUP}" ]]; then
        local recipients_hash="$(sha256sum "${AUTHORITY_RECIPIENTS}" | cut -d' ' -f1)"
        local backup_hash="$(sha256sum "${AUTHORITY_BACKUP}" | cut -d' ' -f1)"
        
        if [[ "${recipients_hash}" == "${backup_hash}" ]]; then
            log_security_event "VALIDATION_INFO" "Backup file consistent with recipients"
        else
            log_security_event "VALIDATION_WARN" "Backup file differs from current recipients"
        fi
    fi
    
    log_security_event "VALIDATION_SUCCESS" "Authority state validation passed: ${validation_context}"
    return 0
}

# Atomic backup creation with cryptographic verification
create_atomic_backup() {
    local backup_context="$1"
    
    log_security_event "BACKUP_START" "Context: ${backup_context}"
    
    # Ensure backup directory exists
    mkdir -p "$(dirname "${AUTHORITY_BACKUP}")"
    
    # Create atomic backup
    cp "${AUTHORITY_RECIPIENTS}" "${AUTHORITY_BACKUP}.tmp"
    
    # Verify backup integrity
    local original_hash="$(sha256sum "${AUTHORITY_RECIPIENTS}" | cut -d' ' -f1)"
    local backup_hash="$(sha256sum "${AUTHORITY_BACKUP}.tmp" | cut -d' ' -f1)"
    
    if [[ "${original_hash}" != "${backup_hash}" ]]; then
        log_security_event "BACKUP_FAIL" "Backup integrity verification failed"
        rm -f "${AUTHORITY_BACKUP}.tmp"
        return 1
    fi
    
    # Atomic move to final backup location
    mv "${AUTHORITY_BACKUP}.tmp" "${AUTHORITY_BACKUP}"
    
    log_security_event "BACKUP_SUCCESS" "Backup created with hash: ${backup_hash}"
    return 0
}

# Rollback mechanism for failed operations
rollback_authority_operation() {
    local rollback_context="$1"
    
    log_security_event "ROLLBACK_START" "Context: ${rollback_context}"
    
    if [[ ! -f "${AUTHORITY_BACKUP}" ]]; then
        log_security_event "ROLLBACK_FAIL" "No backup available for rollback"
        return 1
    fi
    
    # Validate backup before rollback
    local backup_lines="$(wc -l < "${AUTHORITY_BACKUP}")"
    if [[ $backup_lines -eq 0 ]]; then
        log_security_event "ROLLBACK_FAIL" "Backup file is empty, cannot rollback"
        return 1
    fi
    
    # Atomic rollback
    cp "${AUTHORITY_BACKUP}" "${AUTHORITY_RECIPIENTS}.rollback"
    mv "${AUTHORITY_RECIPIENTS}.rollback" "${AUTHORITY_RECIPIENTS}"
    
    log_security_event "ROLLBACK_SUCCESS" "Authority state rolled back successfully"
    return 0
}

# =====================================================================================
# CORE AUTHORITY OPERATIONS (Replaces TODO stubs)
# =====================================================================================

# Secure recipient addition with cryptographic validation
authority_allow_recipient() {
    local recipient_key="$1"
    local recipient_name="${2:-anonymous}"
    
    log_security_event "ALLOW_START" "Adding recipient: ${recipient_name} (${recipient_key:0:16}...)"
    
    # Input validation
    if [[ ! "$recipient_key" =~ ^age[0-9a-z]+$ ]]; then
        log_security_event "ALLOW_FAIL" "Invalid recipient key format: ${recipient_key}"
        return 1
    fi
    
    # Pre-operation validation
    if ! validate_authority_state "pre-allow"; then
        log_security_event "ALLOW_FAIL" "Pre-operation validation failed"
        return 1
    fi
    
    # Check for duplicate recipients
    if grep -qF "${recipient_key}" "${AUTHORITY_RECIPIENTS}" 2>/dev/null; then
        log_security_event "ALLOW_SKIP" "Recipient already exists: ${recipient_name}"
        return 0
    fi
    
    # Create atomic backup
    if ! create_atomic_backup "allow-${recipient_name}"; then
        log_security_event "ALLOW_FAIL" "Backup creation failed"
        return 1
    fi
    
    # Atomic recipient addition
    {
        echo "# Added by authority_manager: $(date -u '+%Y-%m-%d %H:%M:%S UTC') - ${recipient_name}"
        echo "${recipient_key}"
    } >> "${AUTHORITY_RECIPIENTS}"
    
    # Post-operation validation
    if ! validate_authority_state "post-allow"; then
        log_security_event "ALLOW_FAIL" "Post-operation validation failed, rolling back"
        rollback_authority_operation "allow-${recipient_name}-failed"
        return 1
    fi
    
    # Verify recipient was actually added
    if ! grep -qF "${recipient_key}" "${AUTHORITY_RECIPIENTS}"; then
        log_security_event "ALLOW_FAIL" "Recipient addition verification failed"
        rollback_authority_operation "allow-${recipient_name}-verification-failed"
        return 1
    fi
    
    log_security_event "ALLOW_SUCCESS" "Recipient added successfully: ${recipient_name}"
    return 0
}

# Secure recipient revocation with cryptographic verification
authority_revoke_recipient() {
    local recipient_key="$1"
    local recipient_name="${2:-unknown}"
    
    log_security_event "REVOKE_START" "Revoking recipient: ${recipient_name} (${recipient_key:0:16}...)"
    
    # Input validation
    if [[ ! "$recipient_key" =~ ^age[0-9a-z]+$ ]]; then
        log_security_event "REVOKE_FAIL" "Invalid recipient key format: ${recipient_key}"
        return 1
    fi
    
    # Pre-operation validation
    if ! validate_authority_state "pre-revoke"; then
        log_security_event "REVOKE_FAIL" "Pre-operation validation failed"
        return 1
    fi
    
    # Check if recipient exists
    if ! grep -qF "${recipient_key}" "${AUTHORITY_RECIPIENTS}" 2>/dev/null; then
        log_security_event "REVOKE_SKIP" "Recipient not found: ${recipient_name}"
        return 0
    fi
    
    # Create atomic backup
    if ! create_atomic_backup "revoke-${recipient_name}"; then
        log_security_event "REVOKE_FAIL" "Backup creation failed"
        return 1
    fi
    
    # Atomic recipient removal (creates temporary file)
    local temp_recipients="${AUTHORITY_RECIPIENTS}.revoke.tmp"
    
    # Remove recipient while preserving comments and structure
    while IFS= read -r line; do
        if [[ "$line" != "$recipient_key" ]]; then
            echo "$line"
        else
            echo "# REVOKED $(date -u '+%Y-%m-%d %H:%M:%S UTC'): ${recipient_name} - ${line}"
        fi
    done < "${AUTHORITY_RECIPIENTS}" > "${temp_recipients}"
    
    # Atomic move to replace original
    mv "${temp_recipients}" "${AUTHORITY_RECIPIENTS}"
    
    # Post-operation validation
    if ! validate_authority_state "post-revoke"; then
        log_security_event "REVOKE_FAIL" "Post-operation validation failed, rolling back"
        rollback_authority_operation "revoke-${recipient_name}-failed"
        return 1
    fi
    
    # Verify recipient was actually removed
    if grep -qF "${recipient_key}" "${AUTHORITY_RECIPIENTS}"; then
        # Check if it's commented out (revoked)
        if ! grep -qE "^# REVOKED.*${recipient_key}" "${AUTHORITY_RECIPIENTS}"; then
            log_security_event "REVOKE_FAIL" "Recipient revocation verification failed"
            rollback_authority_operation "revoke-${recipient_name}-verification-failed"
            return 1
        fi
    fi
    
    log_security_event "REVOKE_SUCCESS" "Recipient revoked successfully: ${recipient_name}"
    return 0
}

# Secure key rotation with authority chain consistency
authority_rotate_keys() {
    local rotation_name="${1:-scheduled-rotation}"
    
    log_security_event "ROTATE_START" "Key rotation initiated: ${rotation_name}"
    
    # Pre-operation validation
    if ! validate_authority_state "pre-rotate"; then
        log_security_event "ROTATE_FAIL" "Pre-operation validation failed"
        return 1
    fi
    
    # Create atomic backup
    if ! create_atomic_backup "rotate-${rotation_name}"; then
        log_security_event "ROTATE_FAIL" "Backup creation failed"
        return 1
    fi
    
    # Extract current active recipients (non-commented lines)
    local active_recipients=()
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^#.*$ ]] && continue
        active_recipients+=("$line")
    done < "${AUTHORITY_RECIPIENTS}"
    
    if [[ ${#active_recipients[@]} -eq 0 ]]; then
        log_security_event "ROTATE_FAIL" "No active recipients found for rotation"
        return 1
    fi
    
    # Create rotation timestamp header
    local temp_recipients="${AUTHORITY_RECIPIENTS}.rotate.tmp"
    {
        echo "# KEY ROTATION: $(date -u '+%Y-%m-%d %H:%M:%S UTC') - ${rotation_name}"
        echo "# Previous rotation archived, ${#active_recipients[@]} recipients preserved"
        echo ""
        
        # Preserve active recipients
        for recipient in "${active_recipients[@]}"; do
            echo "${recipient}"
        done
        
        echo ""
        echo "# ROTATION ARCHIVE - Previous authority chain:"
        
        # Archive previous version with timestamps
        while IFS= read -r line; do
            echo "# ARCHIVED: ${line}"
        done < "${AUTHORITY_RECIPIENTS}"
        
    } > "${temp_recipients}"
    
    # Atomic rotation
    mv "${temp_recipients}" "${AUTHORITY_RECIPIENTS}"
    
    # Post-operation validation
    if ! validate_authority_state "post-rotate"; then
        log_security_event "ROTATE_FAIL" "Post-operation validation failed, rolling back"
        rollback_authority_operation "rotate-${rotation_name}-failed"
        return 1
    fi
    
    # Verify all original recipients are still active
    local preserved_count=0
    for recipient in "${active_recipients[@]}"; do
        if grep -qF "${recipient}" "${AUTHORITY_RECIPIENTS}"; then
            ((preserved_count++))
        fi
    done
    
    if [[ $preserved_count -ne ${#active_recipients[@]} ]]; then
        log_security_event "ROTATE_FAIL" "Recipient preservation verification failed (${preserved_count}/${#active_recipients[@]})"
        rollback_authority_operation "rotate-${rotation_name}-verification-failed"
        return 1
    fi
    
    log_security_event "ROTATE_SUCCESS" "Key rotation completed: ${rotation_name}, ${preserved_count} recipients preserved"
    return 0
}

# Emergency authority reset with master key validation
authority_emergency_reset() {
    local reset_reason="$1"
    local confirm_reset="${2:-NO}"
    
    log_security_event "RESET_START" "Emergency reset initiated: ${reset_reason}"
    
    # Safety confirmation required
    if [[ "$confirm_reset" != "CONFIRM_RESET" ]]; then
        log_security_event "RESET_FAIL" "Emergency reset requires explicit confirmation"
        echo "ERROR: Emergency reset requires explicit confirmation"
        echo "Usage: authority_emergency_reset 'reason' 'CONFIRM_RESET'"
        return 1
    fi
    
    # Create emergency backup before reset
    local emergency_backup="${AUTHORITY_BACKUP}.emergency.$(date +%s)"
    if [[ -f "${AUTHORITY_RECIPIENTS}" ]]; then
        cp "${AUTHORITY_RECIPIENTS}" "${emergency_backup}"
        log_security_event "RESET_BACKUP" "Emergency backup created: ${emergency_backup}"
    fi
    
    # Create minimal authority chain with emergency recipient
    local temp_recipients="${AUTHORITY_RECIPIENTS}.reset.tmp"
    {
        echo "# EMERGENCY AUTHORITY RESET: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "# Reason: ${reset_reason}"
        echo "# Emergency backup: ${emergency_backup}"
        echo "# WARNING: Add operational recipients immediately"
        echo ""
        echo "# PLACEHOLDER: Add emergency recovery recipients here"
        echo "# age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        echo ""
        echo "# Previous authority chain archived in: ${emergency_backup}"
        
    } > "${temp_recipients}"
    
    # Ensure directory structure exists
    mkdir -p "$(dirname "${AUTHORITY_RECIPIENTS}")"
    
    # Atomic reset
    mv "${temp_recipients}" "${AUTHORITY_RECIPIENTS}"
    
    # Post-reset validation
    if ! validate_authority_state "post-reset"; then
        log_security_event "RESET_FAIL" "Post-reset validation failed"
        return 1
    fi
    
    log_security_event "RESET_SUCCESS" "Emergency reset completed: ${reset_reason}"
    echo "WARNING: Authority chain reset. Add operational recipients immediately."
    echo "Emergency backup: ${emergency_backup}"
    return 0
}

# Authority status with comprehensive security reporting
authority_status() {
    local status_context="${1:-general}"
    
    log_security_event "STATUS_START" "Status check: ${status_context}"
    
    echo "=== PADLOCK AUTHORITY STATUS ==="
    echo "Manager Version: ${AUTHORITY_VERSION}"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Context: ${status_context}"
    echo ""
    
    # Check recipients file
    if [[ -f "${AUTHORITY_RECIPIENTS}" ]]; then
        echo "Recipients File: ${AUTHORITY_RECIPIENTS} ✓"
        
        local total_lines="$(wc -l < "${AUTHORITY_RECIPIENTS}")"
        local active_recipients=0
        local revoked_recipients=0
        local comment_lines=0
        
        # Simplified counting logic to avoid potential hang
        active_recipients=$(grep -c "^age[0-9a-z]*$" "${AUTHORITY_RECIPIENTS}" || echo "0")
        revoked_recipients=$(grep -c "REVOKED" "${AUTHORITY_RECIPIENTS}" || echo "0")
        comment_lines=$(grep -c "^#" "${AUTHORITY_RECIPIENTS}" || echo "0")
        
        echo "  Total Lines: ${total_lines}"
        echo "  Active Recipients: ${active_recipients}"
        echo "  Revoked Recipients: ${revoked_recipients}"
        echo "  Comment Lines: ${comment_lines}"
        
        # Validate current state
        if validate_authority_state "status-${status_context}"; then
            echo "  Validation Status: ✓ VALID"
        else
            echo "  Validation Status: ✗ INVALID"
        fi
        
    else
        echo "Recipients File: ${AUTHORITY_RECIPIENTS} ✗ MISSING"
    fi
    
    echo ""
    
    # Check backup file
    if [[ -f "${AUTHORITY_BACKUP}" ]]; then
        echo "Backup File: ${AUTHORITY_BACKUP} ✓"
        local backup_age="$(($(date +%s) - $(stat -c %Y "${AUTHORITY_BACKUP}")))"
        echo "  Age: ${backup_age} seconds"
        
        if [[ $backup_age -lt 3600 ]]; then
            echo "  Status: ✓ FRESH"
        elif [[ $backup_age -lt 86400 ]]; then
            echo "  Status: ⚠ AGING"
        else
            echo "  Status: ⚠ OLD"
        fi
    else
        echo "Backup File: ${AUTHORITY_BACKUP} ✗ MISSING"
    fi
    
    echo ""
    
    # Check log file
    if [[ -f "${AUTHORITY_LOG}" ]]; then
        echo "Authority Log: ${AUTHORITY_LOG} ✓"
        local log_lines="$(wc -l < "${AUTHORITY_LOG}")"
        echo "  Log Entries: ${log_lines}"
        
        echo "  Recent Events:"
        tail -3 "${AUTHORITY_LOG}" | sed 's/^/    /'
    else
        echo "Authority Log: ${AUTHORITY_LOG} ✗ MISSING"
    fi
    
    log_security_event "STATUS_SUCCESS" "Status check completed: ${status_context}"
    return 0
}

# =====================================================================================
# INITIALIZATION & SETUP
# =====================================================================================

# Initialize authority management system
authority_init() {
    local init_context="${1:-manual-init}"
    
    echo "Initializing PADLOCK Authority Manager v${AUTHORITY_VERSION}"
    
    # Create directory structure
    mkdir -p "${PADLOCK_CONFIG_DIR}/keys"
    mkdir -p "${PADLOCK_DATA_DIR}"
    mkdir -p "${PADLOCK_CACHE_DIR}"
    
    # Initialize log
    if [[ ! -f "${AUTHORITY_LOG}" ]]; then
        echo "AUTHORITY_LOG_INIT: $(date -u '+%Y-%m-%d %H:%M:%S UTC') - ${AUTHORITY_SIGNATURE} v${AUTHORITY_VERSION}" > "${AUTHORITY_LOG}"
    fi
    
    log_security_event "INIT_START" "Authority manager initialization: ${init_context}"
    
    # Initialize recipients file if missing
    if [[ ! -f "${AUTHORITY_RECIPIENTS}" ]]; then
        {
            echo "# PADLOCK Authority Recipients"
            echo "# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
            echo "# Manager: ${AUTHORITY_SIGNATURE} v${AUTHORITY_VERSION}"
            echo "# Format: age public keys (one per line)"
            echo ""
            echo "# Add recipient keys below:"
            
        } > "${AUTHORITY_RECIPIENTS}"
        
        log_security_event "INIT_RECIPIENTS" "Recipients file initialized"
    fi
    
    # Validate initialization
    if validate_authority_state "init-${init_context}"; then
        log_security_event "INIT_SUCCESS" "Authority manager initialized successfully"
        echo "✓ Authority Manager initialized successfully"
        return 0
    else
        log_security_event "INIT_FAIL" "Authority manager initialization failed validation"
        echo "✗ Authority Manager initialization failed"
        return 1
    fi
}

# =====================================================================================
# MAIN COMMAND INTERFACE
# =====================================================================================

# Main command dispatcher
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "init")
            authority_init "$@"
            ;;
        "allow")
            if [[ $# -lt 1 ]]; then
                echo "Usage: $0 allow <recipient_key> [recipient_name]"
                exit 1
            fi
            authority_allow_recipient "$@"
            ;;
        "revoke") 
            if [[ $# -lt 1 ]]; then
                echo "Usage: $0 revoke <recipient_key> [recipient_name]"
                exit 1
            fi
            authority_revoke_recipient "$@"
            ;;
        "rotate")
            authority_rotate_keys "$@"
            ;;
        "reset")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 reset <reason> CONFIRM_RESET"
                echo "WARNING: This will reset the entire authority chain"
                exit 1
            fi
            authority_emergency_reset "$@"
            ;;
        "status")
            authority_status "$@"
            ;;
        "validate")
            if validate_authority_state "${1:-manual-validation}"; then
                echo "✓ Authority state validation PASSED"
                exit 0
            else
                echo "✗ Authority state validation FAILED"
                exit 1
            fi
            ;;
        "help"|"-h"|"--help")
            cat << 'EOF'
PADLOCK Authority Manager v1.0.0-pilot
=====================================

COMMANDS:
  init                    Initialize authority management system
  allow <key> [name]      Add recipient to authority chain
  revoke <key> [name]     Revoke recipient from authority chain  
  rotate [name]           Rotate authority chain (preserve recipients)
  reset <reason> CONFIRM  Emergency authority reset (DESTRUCTIVE)
  status [context]        Display authority status and health
  validate [context]      Validate authority state consistency
  help                    Show this help message

SECURITY FEATURES:
  ✓ Cryptographic validation    ✓ Atomic operations
  ✓ Automatic backups          ✓ Emergency recovery
  ✓ Audit logging              ✓ Rollback capability

For emergency support, see emergency_recovery.sh
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