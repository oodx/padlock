#!/bin/bash
# =====================================================================================
# PADLOCK EMERGENCY RECOVERY - 01-key_authority PILOT  
# =====================================================================================
# MISSION: Fail-Safe Recovery Procedures for Authority Chain Emergencies
# SECURITY TARGET: Address SR-004: Emergency Recovery Mechanisms 
# SECURITY GUARDIAN: EDGAR (Lord Captain of Superhard Fortress)
# IMPLEMENTATION: Lucas - Script Engineer Sage
# VERSION: 1.0.0-pilot
# =====================================================================================

set -euo pipefail

# =====================================================================================
# EMERGENCY RECOVERY CONFIGURATION
# =====================================================================================

readonly RECOVERY_VERSION="1.0.0-pilot"
readonly RECOVERY_SIGNATURE="PADLOCK-EMERGENCY-RECOVERY"

# Emergency response directories
readonly PADLOCK_CONFIG_DIR="${HOME}/.local/etc/padlock"
readonly PADLOCK_DATA_DIR="${HOME}/.local/share/padlock"
readonly PADLOCK_CACHE_DIR="${HOME}/.cache/padlock"

# Critical recovery files
readonly AUTHORITY_RECIPIENTS="${PADLOCK_CONFIG_DIR}/keys/recipients.txt"
readonly AUTHORITY_BACKUP="${PADLOCK_CONFIG_DIR}/keys/recipients.backup"
readonly AUTHORITY_LOG="${PADLOCK_DATA_DIR}/authority.log"
readonly EMERGENCY_LOG="${PADLOCK_DATA_DIR}/emergency.log"

# Emergency backup locations
readonly EMERGENCY_BACKUP_DIR="${PADLOCK_DATA_DIR}/emergency_backups"
readonly RECOVERY_STATE_FILE="${PADLOCK_CACHE_DIR}/recovery.state"

# Authority manager integration
readonly AUTHORITY_MANAGER="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/authority_manager.sh"

# =====================================================================================
# EMERGENCY LOGGING & REPORTING
# =====================================================================================

# Emergency event logging with critical priority
log_emergency_event() {
    local event_type="$1" 
    local event_data="$2"
    local timestamp="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    local event_hash="$(echo -n "${timestamp}:${event_type}:${event_data}" | sha256sum | cut -d' ' -f1)"
    
    local log_entry="EMERGENCY: ${timestamp} [${event_type}] ${event_data} (hash: ${event_hash})"
    
    # Ensure emergency log directory exists
    mkdir -p "$(dirname "${EMERGENCY_LOG}")"
    
    # Log to emergency log
    echo "$log_entry" >> "${EMERGENCY_LOG}"
    
    # Also log to stdout for immediate visibility
    echo "$log_entry" >&2
    
    # Log to authority log if available
    if [[ -f "${AUTHORITY_LOG}" ]]; then
        echo "$log_entry" >> "${AUTHORITY_LOG}"
    fi
}

# Emergency status reporting
report_emergency_status() {
    local situation="$1"
    
    echo "🚨 EMERGENCY RECOVERY STATUS 🚨"
    echo "==============================="
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Recovery Version: ${RECOVERY_VERSION}"
    echo "Situation: $situation"
    echo ""
    
    # System state assessment
    echo "SYSTEM STATE ASSESSMENT:"
    echo "------------------------"
    
    if [[ -f "${AUTHORITY_RECIPIENTS}" ]]; then
        echo "✓ Recipients file exists: ${AUTHORITY_RECIPIENTS}"
        local recipient_count=0
        local active_recipients=0
        
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            ((recipient_count++))
            if [[ ! "$line" =~ ^#.*$ ]]; then
                ((active_recipients++))
            fi
        done < "${AUTHORITY_RECIPIENTS}" 2>/dev/null || true
        
        echo "  Total lines: $recipient_count"
        echo "  Active recipients: $active_recipients"
    else
        echo "✗ Recipients file missing: ${AUTHORITY_RECIPIENTS}"
    fi
    
    if [[ -f "${AUTHORITY_BACKUP}" ]]; then
        echo "✓ Backup file exists: ${AUTHORITY_BACKUP}"
        local backup_age="$(($(date +%s) - $(stat -c %Y "${AUTHORITY_BACKUP}" 2>/dev/null || echo 0)))"
        echo "  Backup age: ${backup_age} seconds"
    else
        echo "✗ Backup file missing: ${AUTHORITY_BACKUP}"
    fi
    
    if [[ -x "${AUTHORITY_MANAGER}" ]]; then
        echo "✓ Authority manager available: ${AUTHORITY_MANAGER}"
    else
        echo "✗ Authority manager not available: ${AUTHORITY_MANAGER}"
    fi
    
    echo ""
}

# =====================================================================================
# EMERGENCY BACKUP PROCEDURES
# =====================================================================================

# Create emergency backup with timestamp
create_emergency_backup() {
    local backup_reason="$1"
    local backup_timestamp="$(date +%Y%m%d_%H%M%S)"
    local backup_name="emergency_${backup_timestamp}_${backup_reason}"
    
    log_emergency_event "BACKUP_START" "Creating emergency backup: ${backup_name}"
    
    # Ensure emergency backup directory exists
    mkdir -p "${EMERGENCY_BACKUP_DIR}"
    
    # Create comprehensive emergency backup
    local backup_dir="${EMERGENCY_BACKUP_DIR}/${backup_name}"
    mkdir -p "${backup_dir}"
    
    # Backup all critical files
    if [[ -f "${AUTHORITY_RECIPIENTS}" ]]; then
        cp "${AUTHORITY_RECIPIENTS}" "${backup_dir}/recipients.txt.backup"
        log_emergency_event "BACKUP_FILE" "Recipients file backed up"
    fi
    
    if [[ -f "${AUTHORITY_BACKUP}" ]]; then
        cp "${AUTHORITY_BACKUP}" "${backup_dir}/recipients.backup.backup"
        log_emergency_event "BACKUP_FILE" "Backup file backed up"
    fi
    
    if [[ -f "${AUTHORITY_LOG}" ]]; then
        cp "${AUTHORITY_LOG}" "${backup_dir}/authority.log.backup"
        log_emergency_event "BACKUP_FILE" "Authority log backed up"
    fi
    
    # Create backup manifest
    {
        echo "EMERGENCY BACKUP MANIFEST"
        echo "========================"
        echo "Backup Name: ${backup_name}"
        echo "Created: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "Reason: ${backup_reason}"
        echo "Recovery Version: ${RECOVERY_VERSION}"
        echo ""
        echo "BACKED UP FILES:"
        ls -la "${backup_dir}/" | sed 's/^/  /'
        echo ""
        echo "SYSTEM STATE AT BACKUP TIME:"
        report_emergency_status "emergency_backup" | sed 's/^/  /'
        
    } > "${backup_dir}/MANIFEST.txt"
    
    log_emergency_event "BACKUP_SUCCESS" "Emergency backup created: ${backup_dir}"
    echo "✓ Emergency backup created: ${backup_dir}"
    
    return 0
}

# List available emergency backups
list_emergency_backups() {
    echo "AVAILABLE EMERGENCY BACKUPS:"
    echo "============================"
    
    if [[ ! -d "${EMERGENCY_BACKUP_DIR}" ]]; then
        echo "No emergency backups found (directory doesn't exist)"
        return 0
    fi
    
    local backup_count=0
    for backup_dir in "${EMERGENCY_BACKUP_DIR}"/emergency_*; do
        if [[ -d "$backup_dir" ]]; then
            ((backup_count++))
            local backup_name="$(basename "$backup_dir")"
            echo ""
            echo "[$backup_count] $backup_name"
            
            if [[ -f "$backup_dir/MANIFEST.txt" ]]; then
                # Extract key info from manifest
                grep -E "Created:|Reason:" "$backup_dir/MANIFEST.txt" | sed 's/^/  /'
            else
                echo "  (No manifest available)"
            fi
            
            # Show contents
            echo "  Contents: $(ls -1 "$backup_dir" | grep -v MANIFEST.txt | tr '\n' ' ')"
        fi
    done
    
    if [[ $backup_count -eq 0 ]]; then
        echo "No emergency backups found"
    else
        echo ""
        echo "Total: $backup_count emergency backup(s)"
    fi
    
    return 0
}

# =====================================================================================
# RECOVERY PROCEDURES
# =====================================================================================

# Master key recovery procedure
master_key_recovery() {
    local master_key_path="$1"
    local confirmation="${2:-NO}"
    
    log_emergency_event "MASTER_RECOVERY_START" "Master key recovery initiated"
    
    # Safety confirmation
    if [[ "$confirmation" != "CONFIRM_MASTER_RECOVERY" ]]; then
        echo "ERROR: Master key recovery requires explicit confirmation"
        echo "WARNING: This will reset the authority chain using master key"
        echo "Usage: emergency_recovery master-key <master_key_path> CONFIRM_MASTER_RECOVERY"
        return 1
    fi
    
    # Validate master key file
    if [[ ! -f "$master_key_path" ]]; then
        log_emergency_event "MASTER_RECOVERY_FAIL" "Master key file not found: $master_key_path"
        echo "ERROR: Master key file not found: $master_key_path"
        return 1
    fi
    
    # Create emergency backup before recovery
    create_emergency_backup "master_key_recovery"
    
    # Validate master key format (should be age private key)
    if ! grep -q "AGE-SECRET-KEY-" "$master_key_path"; then
        log_emergency_event "MASTER_RECOVERY_FAIL" "Invalid master key format"
        echo "ERROR: Invalid master key format (expecting AGE-SECRET-KEY-*)"
        return 1
    fi
    
    # Generate corresponding public key from master key
    local master_public_key
    if ! master_public_key=$(age-keygen -y < "$master_key_path" 2>/dev/null); then
        log_emergency_event "MASTER_RECOVERY_FAIL" "Cannot derive public key from master key"
        echo "ERROR: Cannot derive public key from master key"
        return 1
    fi
    
    log_emergency_event "MASTER_RECOVERY_PROGRESS" "Master public key derived: ${master_public_key:0:16}..."
    
    # Initialize fresh authority chain with master key
    mkdir -p "$(dirname "${AUTHORITY_RECIPIENTS}")"
    
    {
        echo "# MASTER KEY RECOVERY: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "# Recovery performed by: ${RECOVERY_SIGNATURE} v${RECOVERY_VERSION}"
        echo "# Master key source: $master_key_path"
        echo "# WARNING: Add operational recipients immediately"
        echo ""
        echo "# Master recovery key (emergency access only):"
        echo "$master_public_key"
        echo ""
        echo "# SECURITY NOTICE: This authority chain has been reset"
        echo "# All previous recipients have been revoked"
        echo "# Add operational recipients using: authority_manager.sh allow <key> <name>"
        
    } > "${AUTHORITY_RECIPIENTS}"
    
    # Verify recovery using authority manager
    if [[ -x "${AUTHORITY_MANAGER}" ]]; then
        if "${AUTHORITY_MANAGER}" validate master-key-recovery; then
            log_emergency_event "MASTER_RECOVERY_SUCCESS" "Master key recovery completed successfully"
            echo "✓ Master key recovery completed successfully"
            echo "⚠  WARNING: Add operational recipients immediately"
            echo "   Command: ${AUTHORITY_MANAGER} allow <recipient_key> <name>"
            return 0
        else
            log_emergency_event "MASTER_RECOVERY_FAIL" "Recovery validation failed"
            echo "ERROR: Recovery validation failed"
            return 1
        fi
    else
        log_emergency_event "MASTER_RECOVERY_WARNING" "Cannot validate recovery (authority manager unavailable)"
        echo "⚠  WARNING: Cannot validate recovery (authority manager unavailable)"
        echo "✓ Master key recovery completed (validation skipped)"
        return 0
    fi
}

# Backup authority recovery
backup_authority_recovery() {
    local backup_recipient="$1"
    local confirmation="${2:-NO}"
    
    log_emergency_event "BACKUP_RECOVERY_START" "Backup authority recovery initiated"
    
    # Safety confirmation
    if [[ "$confirmation" != "CONFIRM_BACKUP_RECOVERY" ]]; then
        echo "ERROR: Backup authority recovery requires explicit confirmation"
        echo "WARNING: This will restore from backup authority"
        echo "Usage: emergency_recovery backup-authority <backup_recipient> CONFIRM_BACKUP_RECOVERY" 
        return 1
    fi
    
    # Validate backup recipient format
    if [[ ! "$backup_recipient" =~ ^age[0-9a-z]+$ ]]; then
        log_emergency_event "BACKUP_RECOVERY_FAIL" "Invalid backup recipient format"
        echo "ERROR: Invalid backup recipient format (expecting age public key)"
        return 1
    fi
    
    # Create emergency backup before recovery
    create_emergency_backup "backup_authority_recovery"
    
    # Check if backup file exists
    if [[ ! -f "${AUTHORITY_BACKUP}" ]]; then
        log_emergency_event "BACKUP_RECOVERY_FAIL" "No backup file available"
        echo "ERROR: No backup file available: ${AUTHORITY_BACKUP}"
        echo "Try: emergency_recovery list-backups"
        return 1
    fi
    
    # Validate backup file
    local backup_lines="$(wc -l < "${AUTHORITY_BACKUP}")"
    if [[ $backup_lines -eq 0 ]]; then
        log_emergency_event "BACKUP_RECOVERY_FAIL" "Backup file is empty"
        echo "ERROR: Backup file is empty: ${AUTHORITY_BACKUP}"
        return 1
    fi
    
    # Restore from backup and add emergency recipient
    {
        echo "# BACKUP AUTHORITY RECOVERY: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "# Recovery performed by: ${RECOVERY_SIGNATURE} v${RECOVERY_VERSION}"
        echo "# Backup source: ${AUTHORITY_BACKUP}"
        echo "# Emergency recipient: ${backup_recipient:0:16}..."
        echo ""
        echo "# Emergency access recipient:"
        echo "$backup_recipient"
        echo ""
        echo "# RESTORED AUTHORITY CHAIN:"
        
        # Include original backup content
        while IFS= read -r line; do
            if [[ -z "$line" || "$line" =~ ^#.*$ ]]; then
                echo "$line"
            else
                echo "$line  # Restored from backup"
            fi
        done < "${AUTHORITY_BACKUP}"
        
    } > "${AUTHORITY_RECIPIENTS}"
    
    # Verify recovery
    if [[ -x "${AUTHORITY_MANAGER}" ]]; then
        if "${AUTHORITY_MANAGER}" validate backup-authority-recovery; then
            log_emergency_event "BACKUP_RECOVERY_SUCCESS" "Backup authority recovery completed"
            echo "✓ Backup authority recovery completed successfully"
            echo "✓ Emergency recipient added: ${backup_recipient:0:16}..."
            echo "✓ Original authority chain restored from backup"
            return 0
        else
            log_emergency_event "BACKUP_RECOVERY_FAIL" "Recovery validation failed"
            echo "ERROR: Recovery validation failed"
            return 1
        fi
    else
        log_emergency_event "BACKUP_RECOVERY_WARNING" "Cannot validate recovery"
        echo "⚠  WARNING: Cannot validate recovery (authority manager unavailable)"
        echo "✓ Backup authority recovery completed (validation skipped)"
        return 0
    fi
}

# Security state reset (DESTRUCTIVE)
security_state_reset() {
    local reset_reason="$1"
    local confirmation="${2:-NO}"
    
    log_emergency_event "STATE_RESET_START" "Security state reset initiated: $reset_reason"
    
    # Safety confirmation
    if [[ "$confirmation" != "CONFIRM_STATE_RESET" ]]; then
        echo "ERROR: Security state reset requires explicit confirmation"
        echo "WARNING: This will completely remove all padlock security state"
        echo "WARNING: Repository data will be preserved but security will be reset"
        echo "Usage: emergency_recovery security-reset '<reason>' CONFIRM_STATE_RESET"
        return 1
    fi
    
    # Create comprehensive emergency backup
    create_emergency_backup "security_state_reset"
    
    # List what will be reset
    echo "SECURITY STATE RESET PROCEDURE:"
    echo "==============================="
    echo "The following will be REMOVED:"
    
    local reset_items=()
    
    if [[ -f "${AUTHORITY_RECIPIENTS}" ]]; then
        echo "  ✓ Authority recipients: ${AUTHORITY_RECIPIENTS}"
        reset_items+=("${AUTHORITY_RECIPIENTS}")
    fi
    
    if [[ -f "${AUTHORITY_BACKUP}" ]]; then
        echo "  ✓ Authority backup: ${AUTHORITY_BACKUP}"
        reset_items+=("${AUTHORITY_BACKUP}")
    fi
    
    if [[ -d "${PADLOCK_CONFIG_DIR}" ]]; then
        echo "  ✓ Configuration directory: ${PADLOCK_CONFIG_DIR}"
        reset_items+=("${PADLOCK_CONFIG_DIR}")
    fi
    
    if [[ -d "${PADLOCK_CACHE_DIR}" ]]; then
        echo "  ✓ Cache directory: ${PADLOCK_CACHE_DIR}"
        reset_items+=("${PADLOCK_CACHE_DIR}")
    fi
    
    echo ""
    echo "The following will be PRESERVED:"
    echo "  ✓ Repository data (not managed by padlock)"
    echo "  ✓ Emergency backups: ${EMERGENCY_BACKUP_DIR}"
    echo "  ✓ Emergency log: ${EMERGENCY_LOG}"
    
    if [[ ${#reset_items[@]} -eq 0 ]]; then
        log_emergency_event "STATE_RESET_SKIP" "No security state found to reset"
        echo "ℹ  No security state found to reset"
        return 0
    fi
    
    # Final confirmation prompt
    echo ""
    echo "🚨 FINAL CONFIRMATION REQUIRED 🚨"
    echo "Type 'RESET_CONFIRMED' to proceed with destructive reset:"
    read -r final_confirmation
    
    if [[ "$final_confirmation" != "RESET_CONFIRMED" ]]; then
        log_emergency_event "STATE_RESET_ABORT" "Reset aborted by user"
        echo "Reset aborted by user"
        return 1
    fi
    
    # Perform reset
    log_emergency_event "STATE_RESET_EXECUTE" "Executing security state reset"
    
    for item in "${reset_items[@]}"; do
        if [[ -f "$item" ]]; then
            rm -f "$item"
            log_emergency_event "STATE_RESET_REMOVED" "File removed: $item"
        elif [[ -d "$item" ]]; then
            rm -rf "$item"
            log_emergency_event "STATE_RESET_REMOVED" "Directory removed: $item"
        fi
    done
    
    log_emergency_event "STATE_RESET_SUCCESS" "Security state reset completed: $reset_reason"
    
    echo ""
    echo "✓ Security state reset completed successfully"
    echo "✓ All padlock security configuration removed"
    echo "✓ Repository data preserved"
    echo ""
    echo "To reinitialize padlock security:"
    echo "  1. Run: ${AUTHORITY_MANAGER} init"
    echo "  2. Add recipients: ${AUTHORITY_MANAGER} allow <key> <name>"
    echo "  3. Encrypt repository: padlock encrypt"
    
    return 0
}

# =====================================================================================
# EMERGENCY DIAGNOSTICS
# =====================================================================================

# Comprehensive emergency diagnostics
emergency_diagnostics() {
    local diagnostic_context="${1:-general}"
    
    log_emergency_event "DIAGNOSTICS_START" "Emergency diagnostics: $diagnostic_context"
    
    echo "🔍 EMERGENCY DIAGNOSTICS 🔍"
    echo "==========================="
    echo "Context: $diagnostic_context"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo ""
    
    # System environment
    echo "SYSTEM ENVIRONMENT:"
    echo "-------------------"
    echo "User: $(whoami)"
    echo "Home: $HOME"
    echo "PWD: $(pwd)"
    echo "Shell: $SHELL"
    echo "PATH: $PATH"
    echo ""
    
    # Padlock directories
    echo "PADLOCK DIRECTORY STRUCTURE:"
    echo "-----------------------------"
    
    for dir in "$PADLOCK_CONFIG_DIR" "$PADLOCK_DATA_DIR" "$PADLOCK_CACHE_DIR" "$EMERGENCY_BACKUP_DIR"; do
        if [[ -d "$dir" ]]; then
            echo "✓ $dir"
            echo "  Contents: $(ls -1 "$dir" 2>/dev/null | wc -l) items"
            echo "  Permissions: $(ls -ld "$dir" | cut -d' ' -f1)"
        else
            echo "✗ $dir (missing)"
        fi
    done
    echo ""
    
    # Critical files
    echo "CRITICAL FILE STATUS:" 
    echo "---------------------"
    
    local files=(
        "$AUTHORITY_RECIPIENTS:Authority Recipients"
        "$AUTHORITY_BACKUP:Authority Backup"
        "$AUTHORITY_LOG:Authority Log"
        "$EMERGENCY_LOG:Emergency Log"
        "$AUTHORITY_MANAGER:Authority Manager"
    )
    
    for file_info in "${files[@]}"; do
        local file_path="${file_info%:*}"
        local file_desc="${file_info#*:}"
        
        if [[ -f "$file_path" ]]; then
            echo "✓ $file_desc: $file_path"
            echo "  Size: $(wc -c < "$file_path") bytes"
            echo "  Lines: $(wc -l < "$file_path") lines"
            echo "  Modified: $(date -d "@$(stat -c %Y "$file_path")" '+%Y-%m-%d %H:%M:%S')"
            if [[ -x "$file_path" ]]; then
                echo "  Executable: Yes"
            fi
        else
            echo "✗ $file_desc: $file_path (missing)"
        fi
    done
    echo ""
    
    # Authority manager functionality test
    echo "AUTHORITY MANAGER TEST:"
    echo "-----------------------"
    
    if [[ -x "${AUTHORITY_MANAGER}" ]]; then
        echo "✓ Authority manager executable"
        
        # Test help command
        if "${AUTHORITY_MANAGER}" help >/dev/null 2>&1; then
            echo "✓ Help command functional"
        else
            echo "✗ Help command failed"
        fi
        
        # Test status command if initialized
        if [[ -f "${AUTHORITY_RECIPIENTS}" ]]; then
            if "${AUTHORITY_MANAGER}" status diagnostic >/dev/null 2>&1; then
                echo "✓ Status command functional"
            else
                echo "⚠ Status command failed (authority state issue)"
            fi
            
            if "${AUTHORITY_MANAGER}" validate diagnostic >/dev/null 2>&1; then
                echo "✓ Validation command passed"
            else
                echo "✗ Validation command failed (authority corruption detected)"
            fi
        else
            echo "ℹ Authority not initialized (cannot test status/validate)"
        fi
    else
        echo "✗ Authority manager not executable or missing"
    fi
    echo ""
    
    # Recent emergency events
    echo "RECENT EMERGENCY EVENTS:"
    echo "------------------------"
    
    if [[ -f "${EMERGENCY_LOG}" ]]; then
        echo "Last 10 emergency events:"
        tail -10 "${EMERGENCY_LOG}" | sed 's/^/  /'
    else
        echo "No emergency events logged"
    fi
    echo ""
    
    # Available recovery options
    echo "AVAILABLE RECOVERY OPTIONS:"
    echo "---------------------------"
    
    local recovery_options=()
    
    if [[ -f "${AUTHORITY_BACKUP}" ]]; then
        recovery_options+=("backup-authority: Restore from authority backup")
    fi
    
    if [[ -d "${EMERGENCY_BACKUP_DIR}" ]]; then
        local backup_count=$(find "${EMERGENCY_BACKUP_DIR}" -maxdepth 1 -name "emergency_*" -type d | wc -l)
        if [[ $backup_count -gt 0 ]]; then
            recovery_options+=("emergency-backups: $backup_count emergency backup(s) available")
        fi
    fi
    
    recovery_options+=("master-key: Recovery using master key (if available)")
    recovery_options+=("security-reset: Complete security state reset (destructive)")
    
    for option in "${recovery_options[@]}"; do
        echo "  ✓ $option"
    done
    
    if [[ ${#recovery_options[@]} -eq 0 ]]; then
        echo "  ⚠ No recovery options available"
    fi
    
    log_emergency_event "DIAGNOSTICS_SUCCESS" "Emergency diagnostics completed: $diagnostic_context"
    
    return 0
}

# =====================================================================================
# MAIN COMMAND INTERFACE
# =====================================================================================

# Emergency recovery command dispatcher
main() {
    local command="${1:-help}"
    shift || true
    
    # Always show emergency status first (except for help)
    if [[ "$command" != "help" && "$command" != "-h" && "$command" != "--help" ]]; then
        report_emergency_status "$command"
        echo ""
    fi
    
    case "$command" in
        "master-key")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 master-key <master_key_path> CONFIRM_MASTER_RECOVERY"
                echo "WARNING: This will reset the authority chain using master key"
                exit 1
            fi
            master_key_recovery "$@"
            ;;
        "backup-authority")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 backup-authority <backup_recipient> CONFIRM_BACKUP_RECOVERY"
                echo "WARNING: This will restore from backup authority"
                exit 1
            fi
            backup_authority_recovery "$@"
            ;;
        "security-reset")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 security-reset '<reason>' CONFIRM_STATE_RESET"
                echo "WARNING: This will completely remove all padlock security state"
                exit 1
            fi
            security_state_reset "$@"
            ;;
        "diagnostics"|"diag")
            emergency_diagnostics "$@"
            ;;
        "backup")
            if [[ $# -lt 1 ]]; then
                echo "Usage: $0 backup <reason>"
                exit 1
            fi
            create_emergency_backup "$@"
            ;;
        "list-backups"|"backups")
            list_emergency_backups
            ;;
        "status")
            report_emergency_status "${1:-manual-status-check}"
            ;;
        "help"|"-h"|"--help")
            cat << 'EOF'
PADLOCK Emergency Recovery v1.0.0-pilot
======================================

🚨 EMERGENCY RECOVERY PROCEDURES 🚨

COMMANDS:
  master-key <key_path> CONFIRM      Recover using master key (resets authority)
  backup-authority <key> CONFIRM     Recover using backup authority  
  security-reset <reason> CONFIRM    Complete security state reset (DESTRUCTIVE)
  
DIAGNOSTICS:
  diagnostics [context]              Run comprehensive emergency diagnostics
  status [context]                   Show current emergency status
  backup <reason>                    Create emergency backup manually
  list-backups                       List available emergency backups

SECURITY CONFIRMATIONS REQUIRED:
  master-key:       CONFIRM_MASTER_RECOVERY
  backup-authority: CONFIRM_BACKUP_RECOVERY
  security-reset:   CONFIRM_STATE_RESET + manual confirmation

EMERGENCY SCENARIOS:
  Authority Chain Corruption → backup-authority or master-key
  Complete Repository Lockout → master-key recovery
  Unknown Security State → diagnostics + appropriate recovery
  Start Fresh → security-reset (DESTRUCTIVE)

⚠  WARNING: All recovery operations create emergency backups
⚠  WARNING: Some operations are DESTRUCTIVE and cannot be undone
⚠  CRITICAL: Verify system state before and after recovery

For normal operations, use authority_manager.sh
EOF
            ;;
        *)
            echo "Unknown emergency command: $command"
            echo "Use '$0 help' for emergency recovery procedures"
            echo ""
            echo "🚨 If this is a critical emergency:"
            echo "   1. Run: $0 diagnostics"
            echo "   2. Review system state"  
            echo "   3. Choose appropriate recovery procedure"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi