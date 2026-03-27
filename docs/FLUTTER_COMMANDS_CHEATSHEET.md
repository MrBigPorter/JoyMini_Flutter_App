
# Flutter Command Cheatsheet (Project Specific)

> **Important**: You must review this file before executing any Flutter commands. This is a core part of the AI Collaboration Development Specification.

---

## 📋 Usage Instructions

### Why is this cheatsheet necessary?
* **Memory is unreliable**: AI lacks long-term memory and requires documentation for assistance.
* **Project Specific**: Every project has its own command habits and scripts.
* **Environment Differences**: Different environments require different command parameters.
* **Error Prevention**: Avoid issues caused by incorrect command execution.

### Usage Principles:
* **Check before execution**: Review this file every time before running a command.
* **Record commands**: All executed commands must be explicitly written in the communication.
* **Verify results**: Validate the effect of the command after execution.
* **Update documentation**: Update this file whenever new useful commands are discovered.

---

## 🚀 Command Category Index

1. Development Environment Commands
2. Code Quality Commands
3. Testing Commands
4. Execution Commands
5. Build Commands
6. Code Generation Commands
7. Project-Specific Commands
8. Debugging Commands

---

## 📝 Detailed Command List

### Important Reminder: This project uses FVM to manage Flutter versions
**All Flutter commands must be prefixed with `fvm`**. For example:
* ❌ `flutter run` → ✅ `fvm flutter run`
* ❌ `flutter pub get` → ✅ `fvm flutter pub get`
* ❌ `flutter build apk` → ✅ `fvm flutter build apk`

### 1. Development Environment Commands

#### FVM Environment Management
```bash
# Check FVM environment
fvm flutter doctor

# View current Flutter version
fvm flutter --version

# View installed Flutter versions
fvm list

# Install a specific Flutter version
fvm install 3.16.0

# Switch to a specific version
fvm use 3.16.0

# Use the stable version
fvm use stable --pin

# View FVM configuration
fvm config
```

#### Project Cleanup
```bash
# Clean build files (using FVM)
fvm flutter clean

# Clean and re-fetch dependencies
fvm flutter clean && fvm flutter pub get

# Clean all caches (including pub cache)
fvm flutter clean && rm -rf ~/.pub-cache && fvm flutter pub get
```

#### Dependency Management
```bash
# Get dependencies (using FVM)
fvm flutter pub get

# Upgrade dependencies
fvm flutter pub upgrade

# Add a dependency
fvm flutter pub add package_name

# Remove a dependency
fvm flutter pub remove package_name

# View outdated dependencies
fvm flutter pub outdated

# View dependency tree
fvm flutter pub deps
```

### 2. Code Quality Commands

#### Static Analysis
```bash
# Flutter static analysis (using FVM)
fvm flutter analyze

# Project-specific analysis script
make analyze

# Analyze only the lib directory
fvm flutter analyze lib/

# Output detailed analysis results
fvm flutter analyze --verbose
```

#### Code Formatting
```bash
# Format all Dart files
dart format .

# Format a specific directory
dart format lib/

# Check formatting (without making changes)
dart format --set-exit-if-changed .

# Fix all formatting issues
dart fix --apply
```

#### Code Inspection
```bash
# Check for unused imports
dart fix --dry-run

# Check for null safety
dart migrate --apply-changes

# Check dependency versions (using FVM)
fvm flutter pub deps --style=compact
```

### 3. Testing Commands

#### Unit Testing
```bash
# Run all tests (using FVM)
fvm flutter test

# Run a specific test file
fvm flutter test test/unit/my_test.dart

# Run tests and generate coverage report
fvm flutter test --coverage

# Run tests with verbose output
fvm flutter test --verbose
```

#### Integration Testing
```bash
# Run integration tests (using FVM)
fvm flutter test integration_test/

# Run integration tests on a specific device
fvm flutter test integration_test/ --device-id=your_device_id
```

#### Project-Specific Testing
```bash
# Use project test script
make test

# Run Widget tests (using FVM)
fvm flutter test test/widgets/

# Run Provider tests (using FVM)
fvm flutter test test/providers/
```

### 4. Execution Commands

#### Development Run
```bash
# Run app (Default Debug mode, using FVM)
fvm flutter run

# Run on a specific device
fvm flutter run -d chrome          # Web
fvm flutter run -d android         # Android
fvm flutter run -d ios             # iOS
fvm flutter run -d macos           # macOS
```

#### Project-Specific Run
```bash
# Development environment run (using project script)
make dev

# Run with Hot Reload (using FVM)
fvm flutter run --hot-reload

# Run without Hot Reload (using FVM)
fvm flutter run --no-hot-reload
```

#### Running in Different Modes
```bash
# Debug Mode (Default, using FVM)
fvm flutter run --debug

# Profile Mode (using FVM)
fvm flutter run --profile

# Release Mode (using FVM)
fvm flutter run --release

# Enable Dart Developer Tools (using FVM)
fvm flutter run --observatory-port=8888
```

### 5. Build Commands

#### Android Build
```bash
# Debug APK (using FVM)
fvm flutter build apk --debug

# Release APK (using FVM)
fvm flutter build apk --release

# Build split by ABI (reduces APK size, using FVM)
fvm flutter build apk --release --split-per-abi

# App Bundle (Google Play, using FVM)
fvm flutter build appbundle --release

# Specify build flavor (using FVM)
fvm flutter build apk --flavor prod
```

#### iOS Build
```bash
# Debug Build (using FVM)
fvm flutter build ios --debug

# Release Build (using FVM)
fvm flutter build ios --release

# Simulator Build (using FVM)
fvm flutter build ios --simulator

# Specify scheme/flavor (using FVM)
fvm flutter build ios --release --flavor prod
```

#### Web Build
```bash
# Debug Build (using FVM)
fvm flutter build web --debug

# Release Build (using FVM)
fvm flutter build web --release

# Specify target directory (using FVM)
fvm flutter build web --release --output=build/web_prod

# Enable CanvasKit renderer (using FVM)
fvm flutter build web --release --web-renderer canvaskit
```

#### Project-Specific Build
```bash
# Production environment build
make prod

# Development environment build
make build-dev

# Clean and build
make clean-build
```

### 6. Code Generation Commands

#### Build Runner
```bash
# Generate code (clean conflicting outputs)
dart run build_runner build --delete-conflicting-outputs

# Watch mode generation
dart run build_runner watch --delete-conflicting-outputs

# Generate only for specific targets
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/**"

# Clean generated files
dart run build_runner clean
```

#### Project Generation Scripts
```bash
# Run project generation script
tool/generate.sh

# Generate design tokens
tool/gen_tokens_flutter.dart

# Generate Tailwind hints
tool/gen_tw_hints.dart
```

### 7. Project-Specific Commands (Make Commands)

#### Development Workflow
```bash
# Full development startup flow
make dev

# Production build
make prod

# Code analysis
make analyze

# Run tests
make test

# Clean project
make clean
```

#### Platform-Specific Fixes
```bash
# Fix Android issues
tool/fix_android.sh

# Fix iOS issues
tool/fix_ios.sh

# Development environment setup
tool/dev.sh
```

#### Tool Scripts
```bash
# Login regression testing
tool/test_login_regression.sh

# Generate all code
tool/generate.sh
```

### 8. Debugging Commands

#### Logs and Debugging
```bash
# Enable verbose logs (using FVM)
fvm flutter run --verbose

# View device logs (using FVM)
fvm flutter logs

# Clear device logs (using FVM)
fvm flutter logs --clear

# Debug a specific Dart file (using FVM)
fvm flutter run --start-paused --dart-define=DEBUG=true
```

#### Performance Analysis
```bash
# Profile mode run (using FVM)
fvm flutter run --profile

# Trace startup performance (using FVM)
fvm flutter run --trace-startup

# Memory analysis (using FVM)
fvm flutter run --trace-skia

# Rendering performance analysis (using FVM)
fvm flutter run --trace-systrace
```

#### Device Management
```bash
# List all devices (using FVM)
fvm flutter devices

# Launch emulator (using FVM)
fvm flutter emulators --launch apple_ios_simulator

# Create new emulator (using FVM)
fvm flutter emulators --create --name my_ios_simulator
```

---

## 🔄 Common Workflows

### Daily Development Workflow (using FVM)
1. **Start the day**:
   ```bash
   fvm flutter clean
   fvm flutter pub get
   fvm flutter analyze
   make dev
   ```
2. **After modifying code**:
   ```bash
   fvm flutter analyze
   fvm flutter test
   dart format .
   ```
3. **Before submitting code**:
   ```bash
   make analyze
   make test
   dart format --set-exit-if-changed .
   ```

### Troubleshooting Workflow (using FVM)
1. **Encountering build issues**:
   ```bash
   fvm flutter clean
   fvm flutter pub get
   fvm flutter doctor
   fvm flutter analyze
   ```
2. **Encountering runtime issues**:
   * Use `fvm flutter run --verbose`
   * Check console logs
   * Check device connection
3. **Encountering test issues**:
   * Use `fvm flutter test --verbose`
   * Check test environment
   * Check test logs

### Release Workflow (using FVM)
1. **Prepare for release**:
   ```bash
   fvm flutter clean
   fvm flutter pub get
   fvm flutter analyze
   make test
   ```
2. **Build release version**:
   ```bash
   make prod
   # OR
   fvm flutter build apk --release --split-per-abi
   fvm flutter build ios --release
   fvm flutter build web --release
   ```
3. **Verify release version**:
   * Install test APK/iOS app
   * Test Web version

---

## ⚠️ Notes

### Environment Related
* **FVM Usage**: This project uses FVM to manage Flutter versions.
* **Platform Specific**:
   * Android: Requires Android Studio and SDK.
   * iOS: Requires Xcode and a developer account.
   * Web: Requires Chrome for testing.
* **Network Environment**:
   * Users in China may need to configure mirrors.
   * Ensure the network can access `pub.dev`.

### Common Problem Solutions

#### Issue 1: `fvm flutter pub get` fails
```bash
# Solution:
fvm flutter clean
rm -rf ~/.pub-cache
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
fvm flutter pub get
```

#### Issue 2: Build failure
```bash
# Solution:
fvm flutter clean
fvm flutter pub get
fvm flutter doctor
# Check platform-specific configuration
# Check for dependency version conflicts
```

---

## 📊 Command Execution Record Standard

### Required Information:
* **Command Content**: Full command string.
* **Purpose**: Why this command is being executed.
* **Expected Result**: What the command is expected to achieve.
* **Actual Result**: The actual outcome of the command.
* **Issue Record**: If the command fails, record the problem and solution.

### Record Example:
```
## Command Execution Record

### Command 1: Project Cleanup
**Command**: `fvm flutter clean`
**Purpose**: Clean old build files to avoid cache issues
**Expected**: Successfully clean all build caches
**Actual**: ✅ Executed successfully, output "Deleting build..."
**Issues**: None
```

---

**Last Updated: 2026-03-26**  
**Document Status: Active**  
**Next Review: 2026-04-02**

> **Reminder**: This file is a core part of the AI Collaboration Development Specification and must be strictly followed.

---

