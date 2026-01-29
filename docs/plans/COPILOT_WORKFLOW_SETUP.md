# Copilot Workflow Setup - Complete

## ✅ Files Created

### 1. `.github/copilot-instructions.md`
**Purpose**: Instructions for GitHub Copilot to follow on every code change

**Key Requirements**:
- ✅ Compile after every change
- ✅ Run all tests
- ✅ Create integration tests for new features
- ✅ Launch app to verify
- ✅ Manual verification in browser

**Location**: `.github/copilot-instructions.md`

### 2. `verify_changes.sh`
**Purpose**: Automated verification script

**What it does**:
1. ✅ Clean build
2. ✅ Install dependencies
3. ✅ Run code generation
4. ✅ Static analysis
5. ✅ Run all unit tests
6. ✅ Run integration tests
7. ✅ Build for web
8. ✅ Launch app in Chrome

**Location**: `verify_changes.sh`

---

## 🚀 How to Use

### Quick Verification

After making code changes, run:

```bash
./verify_changes.sh
```

This will automatically:
- Check compilation
- Run all tests
- Build the app
- Launch in Chrome
- Show you the results

### Expected Output

```
╔══════════════════════════════════════════════════════════════════╗
║            🔍 FOSDEM App Verification Script 🔍                  ║
╚══════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 CHECK 1: Clean Build
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PASS: Clean successful

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 CHECK 2: Get Dependencies
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PASS: Dependencies installed

... (more checks) ...

╔══════════════════════════════════════════════════════════════════╗
║              ✅ ALL VERIFICATIONS PASSED! ✅                      ║
╚══════════════════════════════════════════════════════════════════╝

Next steps:
  1. Open Chrome browser
  2. Navigate to: http://localhost:8080
  3. Open DevTools (F12)
  4. Test the feature manually
```

---

## 📋 Manual Workflow

If you prefer to run commands individually:

```bash
# 1. Compile
cd fosdem_flutter
flutter build web --release

# 2. Run tests
flutter test

# 3. Launch app
flutter run -d chrome --web-port 8080
```

---

## 🎯 Copilot Workflow

When GitHub Copilot makes changes, it will:

### Step 1: Make Code Changes
```dart
// Edit files as requested
```

### Step 2: Verify Compilation
```bash
flutter build web --release
```

### Step 3: Run Tests
```bash
flutter test
```

### Step 4: Launch App
```bash
flutter run -d chrome --web-port 8080
```

### Step 5: Create Verification Report
```markdown
## Verification Report

✅ Compilation: PASS
✅ Tests: 32/32 PASS
✅ App Launch: SUCCESS
✅ Manual Verification: DONE
```

---

## 🧪 Testing Standards

### Unit Tests
- **Location**: `test/` (mirrors `lib/`)
- **Naming**: `<file_name>_test.dart`
- **Coverage**: 80% minimum

### Integration Tests
- **Location**: `test/integration/`
- **Naming**: `<feature>_integration_test.dart`
- **Purpose**: End-to-end feature testing

### Creating Integration Tests

Example template:

```dart
// test/integration/my_feature_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/core/di/injection_container.dart' as di;

void main() {
  group('My Feature Integration Tests', () {
    setUpAll(() async {
      await di.init();
    });

    test('should complete full workflow', () async {
      // Arrange
      final service = di.sl<MyService>();
      
      // Act
      final result = await service.doSomething();
      
      // Assert
      expect(result, isNotNull);
      expect(result.success, isTrue);
    });
  });
}
```

---

## 🚫 What NOT to Do

### ❌ BAD - No Verification
```
"I've fixed the issue by changing X"
```

### ✅ GOOD - With Verification
```
"I've fixed the issue by changing X

Verification:
- ✅ Compiled successfully
- ✅ Tests: 32/32 passing
- ✅ App launches in Chrome
- ✅ Feature tested manually
- ✅ No console errors
```

---

## 📊 Success Criteria

A change is **complete** when:

| Check | Status |
|-------|--------|
| Code compiles | ✅ |
| All tests pass | ✅ |
| Integration tests created | ✅ |
| App launches | ✅ |
| Manual verification done | ✅ |
| Documentation updated | ✅ |

---

## 🔍 Troubleshooting

### Verification Script Fails

If `verify_changes.sh` fails:

1. **Read the error message** - it tells you what failed
2. **Fix the issue** in your code
3. **Run the script again**

### Common Issues

#### Compilation Error
```bash
# Check what's wrong:
cd fosdem_flutter
flutter analyze lib/
```

#### Test Failure
```bash
# Run specific test to see error:
flutter test path/to/failing_test.dart
```

#### App Won't Launch
```bash
# Check for port conflict:
lsof -i :8080
kill <PID>

# Try again:
flutter run -d chrome --web-port 8080
```

---

## 📁 File Structure

```
fosdemApp/
├── .github/
│   └── copilot-instructions.md    # Copilot workflow rules
├── verify_changes.sh               # Automated verification
├── fosdem_flutter/
│   ├── lib/                        # Source code
│   └── test/                       # Tests
│       ├── core/                   # Unit tests
│       ├── data/                   # Data layer tests
│       ├── integration/            # Integration tests
│       └── widgets/                # Widget tests
└── COPILOT_WORKFLOW_SETUP.md      # This file
```

---

## 🎯 Quick Commands Reference

```bash
# Run verification script
./verify_changes.sh

# Compile only
cd fosdem_flutter && flutter build web --release

# Test only
cd fosdem_flutter && flutter test

# Launch only
cd fosdem_flutter && flutter run -d chrome

# Run specific test
cd fosdem_flutter && flutter test test/path/to/test.dart

# Check for errors
cd fosdem_flutter && flutter analyze

# Clean and rebuild
cd fosdem_flutter && flutter clean && flutter pub get
```

---

## ✅ Summary

| File | Purpose | Usage |
|------|---------|-------|
| `.github/copilot-instructions.md` | Copilot workflow rules | Automatic |
| `verify_changes.sh` | Automated verification | `./verify_changes.sh` |
| `COPILOT_WORKFLOW_SETUP.md` | Documentation | Reference |

**Key Principle**: 
> Every code change must be compiled, tested, and verified in a running app before being considered complete.

---

**Created**: 2026-01-13  
**Version**: 1.0  
**Status**: ✅ ACTIVE
