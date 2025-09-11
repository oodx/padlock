# Padlock Test Suite

This directory contains the comprehensive test suite for the Padlock Age automation and authority chain systems.

## Test Structure

```
tests/
├── cli/                    # CLI interface tests
│   ├── test_cli_comprehensive.sh     # Complete CLI functionality testing
│   └── test_workflow_integration.sh  # Generate→Status workflow validation
├── integration/            # Integration and end-to-end tests  
│   ├── test_age_basic.rs              # Basic Age integration validation
│   ├── test_authority_operations_direct.rs  # Direct authority operations
│   ├── test_authority_workflow_simple.rs    # Authority workflow testing
│   └── test_end_to_end_workflow.rs          # Complete E2E workflow
└── comprehensive_api_tests.rs         # Complete API test coverage
```

## Running Tests

### Unit and API Tests
```bash
# Run all Rust unit tests
cargo test

# Run specific test file
cargo test --test comprehensive_api_tests
```

### CLI Tests
```bash
# Run complete CLI functionality tests
./tests/cli/test_cli_comprehensive.sh

# Run workflow integration tests
./tests/cli/test_workflow_integration.sh
```

### Integration Tests
```bash
# Build and run specific integration test
rustc tests/integration/test_age_basic.rs && ./test_age_basic

# Run authority operations test
rustc tests/integration/test_authority_operations_direct.rs --extern padlock=target/debug/libpadlock.rlib -L target/debug/deps && ./test_authority_operations_direct
```

### All Tests
```bash
# Run everything (requires Age binaries installed)
cargo test && ./tests/cli/test_cli_comprehensive.sh
```

## Test Categories

### 1. Unit Tests (`comprehensive_api_tests.rs`)
- Complete API coverage for all modules
- Authority chain functionality
- Age automation components  
- Ignition key workflows
- Security and validation tests

### 2. CLI Tests (`cli/`)
- **Comprehensive CLI Testing**: Both `cli_age` and `cli_auth` interfaces
- **Regression Testing**: Flag changes and functionality preservation
- **Workflow Integration**: Critical generate→status workflow validation
- **Consistency Testing**: Flag patterns and user experience

### 3. Integration Tests (`integration/`)
- **Age Basic**: Core Age encryption/decryption functionality
- **Authority Operations**: Direct authority chain operations testing
- **Workflow Simple**: Authority workflow validation
- **End-to-End**: Complete system integration testing

## Prerequisites

### Required
- Rust/Cargo toolchain
- `age` and `age-keygen` binaries installed

### Installation
```bash
# On Ubuntu/Debian
sudo apt install age

# On macOS
brew install age

# Or install from source: https://github.com/FiloSottile/age
```

## Test Results

All tests should pass for a production-ready system:

```
✅ Unit Tests: PASSED  
✅ CLI Tests: PASSED
✅ Integration Tests: PASSED
✅ Regression Tests: PASSED
```

## Troubleshooting

### Common Issues
1. **Age binary not found**: Install `age` and `age-keygen`
2. **Permission denied**: Ensure test scripts are executable (`chmod +x`)  
3. **Compilation errors**: Ensure `cargo build` succeeds first
4. **TTY automation tests**: Some tests may require actual Age binary interaction

### Debug Mode
Add `--verbose` flag to CLI tests for detailed output:
```bash
./tests/cli/test_cli_comprehensive.sh --verbose
```