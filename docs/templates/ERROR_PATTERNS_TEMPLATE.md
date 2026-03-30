# Common Error Patterns & Solutions Template

> **Purpose**: Error patterns template for quick migration to any project  
> **Version**: 1.0.0  
> **Last Updated**: 2026-03-28

---

## 📋 How to Use This Document

### Using This Document
1. When encountering an error, search this document for the error message
2. Follow the provided solutions to fix the issue
3. If it's a new error pattern, add it to this document

### Error Categories
- 🔴 Compilation Errors
- 🟡 Runtime Errors
- 🟠 Build Errors
- 🔵 Test Failures
- 🟣 Dependency Errors

---

## 🔴 Compilation Errors

### Pattern: "Target of URI doesn't exist"
**Error Message**: `Error: The target of URI doesn't exist: 'package:xxx/xxx.dart'`

**Root Cause Analysis**:
- File path changed or deleted
- Import statement error
- Dependencies not properly installed

**Solution**:
```bash
# 1. Check if file exists
ls -la [FILE_PATH]

# 2. Clean and reinstall dependencies
[PACKAGE_MANAGER] clean
[PACKAGE_MANAGER] install

# 3. Check if import statement matches actual path
# Ensure import 'package:project_name/path/to/file.dart';
```

**Prevention**:
- Use IDE refactoring when renaming files
- Run `[LINT_COMMAND]` regularly

---

### Pattern: "The method 'xxx' isn't defined"
**Error Message**: `The method 'xxx' isn't defined for the type 'YYY'`

**Root Cause Analysis**:
- Method name typo
- API change (method renamed or deleted)
- File containing the method not imported

**Solution**:
```[LANGUAGE]
// 1. Check method name spelling
// Wrong: contrller.doSomething()
// Correct: controller.doSomething()

// 2. Search codebase for similar method names
// Use IDE global search

// 3. Check package changelog
// Look for breaking changes
```

**Prevention**:
- Use IDE auto-completion
- Regularly update dependencies and check changelog

---

### Pattern: "Type mismatch"
**Error Message**: `A value of type 'XXX' can't be assigned to 'YYY'`

**Root Cause Analysis**:
- Type mismatch
- Type conversion not handled correctly

**Solution**:
```[LANGUAGE]
// Option 1: Use type conversion
final value = someValue as TargetType;

// Option 2: Use type check
if (someValue is TargetType) {
  // Use someValue
}

// Option 3: Use default value
final value = someValue ?? defaultValue;
```

**Prevention**:
- Use strong typing
- Add type checks

---

## 🟡 Runtime Errors

### Pattern: "Null reference"
**Error Message**: `Null check operator used on a null value` or `Cannot read property 'xxx' of null`

**Root Cause Analysis**:
- Using a value that might be null
- Not properly handling nullable types

**Solution**:
```[LANGUAGE]
// Wrong example
String name = user!.name!;

// Correct example
String name = user?.name ?? 'Unknown';

// Or use conditional check
if (user != null && user.name != null) {
  String name = user.name!;
}
```

**Prevention**:
- Avoid overusing `!` operator
- Use `?.` and `??` for safe access

---

### Pattern: "State update after dispose"
**Error Message**: `setState() called after dispose()` or similar state update errors

**Root Cause Analysis**:
- Async operation completed after component was destroyed
- Not checking if component is still mounted

**Solution**:
```[LANGUAGE]
// Check mounted before calling setState
if (mounted) {
  setState(() {
    // Update state
  });
}

// Or use cancellation token
final cancelToken = CancelToken();
// Cancel on dispose
```

**Prevention**:
- Save mounted state before async operations
- Use state management library to avoid this issue

---

### Pattern: "Layout overflow"
**Error Message**: `A RenderFlex overflowed by X pixels on the bottom/right`

**Root Cause Analysis**:
- Content exceeds screen or container size
- Not properly handling responsive layout

**Solution**:
```[LANGUAGE]
// Option 1: Use scroll container
SingleChildScrollView(
  child: Column(
    children: [...],
  ),
)

// Option 2: Use flexible layout
Row(
  children: [
    Expanded(
      child: Text('Long text...'),
    ),
  ],
)

// Option 3: Use dynamic size calculation
Container(
  height: MediaQuery.of(context).size.height * 0.5,
  child: ...,
)
```

**Prevention**:
- Use responsive design library
- Test different screen sizes

---

## 🟠 Build Errors

### Pattern: "Build failed"
**Error Message**: `FAILURE: Build failed with an exception`

**Root Cause Analysis**:
- Configuration issues
- Dependency conflicts
- Environment issues

**Solution**:
```bash
# 1. Run fix script (if available)
./tool/fix_[PLATFORM].sh

# 2. Check configuration file
cat [CONFIG_FILE]

# 3. Clean and rebuild
[PACKAGE_MANAGER] clean
[PACKAGE_MANAGER] install
[PACKAGE_MANAGER] build
```

**Prevention**:
- Don't commit sensitive configuration to Git
- Use configuration templates

---

### Pattern: "Dependency conflict"
**Error Message**: `Could not find compatible versions for pod 'xxx'` or similar dependency conflicts

**Root Cause Analysis**:
- Dependency version conflicts
- Lock file doesn't match configuration

**Solution**:
```bash
# 1. Run fix script (if available)
./tool/fix_[PLATFORM].sh

# 2. Clean dependency cache
[PACKAGE_MANAGER] clean
rm -rf [CACHE_DIR]

# 3. Reinstall dependencies
[PACKAGE_MANAGER] install
```

**Prevention**:
- Regularly update dependencies
- Use `update` instead of `install`

---

### Pattern: "Platform build error"
**Error Message**: Various platform-specific build errors

**Root Cause Analysis**:
- Platform version incompatibility
- Certificate or configuration file issues
- Platform-specific code issues

**Solution**:
```bash
# 1. Clean platform cache
rm -rf [PLATFORM_CACHE_DIR]

# 2. Update platform dependencies
[PLATFORM_UPDATE_COMMAND]

# 3. Check platform version
[PLATFORM_VERSION_COMMAND]

# 4. Regenerate project
[PACKAGE_MANAGER] clean
[PACKAGE_MANAGER] install
```

**Prevention**:
- Keep platform tools updated
- Use project-specified versions

---

## 🔵 Test Failures

### Pattern: "Widget not found"
**Error Message**: `Expected: exactly one matching node in the widget tree`

**Root Cause Analysis**:
- Component not found
- Component not properly rendered in test
- Search criteria inaccurate

**Solution**:
```[LANGUAGE]
// 1. Ensure component is rendered
await tester.pumpAndSettle();

// 2. Use precise search criteria
// Wrong: find.text('Submit')
// Correct: find.text('Submit', skipOffstage: false)

// 3. Use Key to find
final button = find.byKey(Key('submit_button'));
expect(button, findsOneWidget);

// 4. Print component tree for debugging
debugDumpApp();
```

**Prevention**:
- Add Keys to important components
- Use `pumpAndSettle()` to wait for animations

---

### Pattern: "Timer pending"
**Error Message**: `Timer still pending after test completed`

**Root Cause Analysis**:
- Unfinished Timer in test
- Async operations not properly awaited

**Solution**:
```[LANGUAGE]
// Option 1: Use fakeAsync
testWidgets('test with timer', (tester) async {
  await tester.pumpWidget(MyWidget());
  // Use tester.pump() to advance time
  await tester.pump(Duration(seconds: 1));
});

// Option 2: Ensure all async operations complete
await tester.pumpAndSettle();
```

**Prevention**:
- Avoid using real Timers in tests
- Use `pumpAndSettle()` to wait for all animations

---

## 🟣 Dependency Errors

### Pattern: "Package not found"
**Error Message**: `Could not find package "xxx" at "https://pub.dev"`

**Root Cause Analysis**:
- Package name typo
- Package removed or renamed
- Network issues

**Solution**:
```bash
# 1. Check package name spelling
# Search on package manager website

# 2. Clean cache
[PACKAGE_MANAGER] clean
rm -rf [CACHE_DIR]

# 3. Use mirror (if needed)
export [MIRROR_ENV_VAR]=[MIRROR_URL]

# 4. Reinstall dependencies
[PACKAGE_MANAGER] install
```

**Prevention**:
- Use IDE auto-completion to add dependencies
- Regularly check if dependencies are still maintained

---

### Pattern: "Version solving failed"
**Error Message**: `Because every version of xxx depends on yyy...`

**Root Cause Analysis**:
- Dependency version conflicts
- Some packages require specific dependency versions

**Solution**:
```yaml
# [CONFIG_FILE]

# Option 1: Relax version constraints
dependencies:
  package_a: ^1.0.0  # Allow 1.x.x
  package_b: any     # Allow any version

# Option 2: Use dependency_overrides
dependency_overrides:
  conflicting_package: ^2.0.0

# Option 3: Use specific version
dependencies:
  package_a: 1.2.3   # Lock to specific version
```

**Prevention**:
- Regularly run `[PACKAGE_MANAGER] outdated`
- Avoid using `any` version constraint

---

## 🔧 Framework-Specific Errors

### Pattern: "Component not mounted"
**Error Message**: Component not mounted or already unmounted

**Root Cause Analysis**:
- Component lifecycle issues
- Async operation when component already destroyed

**Solution**:
```[LANGUAGE]
// 1. Check if component is mounted
if (mounted) {
  // Execute operation
}

// 2. Use cancellation token
final cancelToken = CancelToken();
// Cancel on component unmount

// 3. Use state management library
// Avoid directly manipulating component state
```

**Prevention**:
- Use state management library
- Properly handle component lifecycle

---

### Pattern: "Platform exception"
**Error Message**: `PlatformException(error, xxx, null, null)`

**Root Cause Analysis**:
- Native platform code error
- Permissions not configured
- Platform-specific feature called on wrong platform

**Solution**:
```[LANGUAGE]
// 1. Check platform permissions
// [PLATFORM_1]: [PERMISSION_FILE_1]
// [PLATFORM_2]: [PERMISSION_FILE_2]

// 2. Use try-catch to catch exception
try {
  await platformChannel.invokeMethod('methodName');
} on PlatformException catch (e) {
  print('Platform error: ${e.message}');
}

// 3. Check platform-specific code
if (Platform.is[PLATFORM_1]) {
  // [PLATFORM_1] specific code
} else if (Platform.is[PLATFORM_2]) {
  // [PLATFORM_2] specific code
}
```

**Prevention**:
- Configure correct platform permissions
- Use conditional imports to handle platform differences

---

## 📊 Error Statistics & Trends

### Top 5 Common Errors
1. **[ERROR_1]** - [PERCENTAGE_1]%
2. **[ERROR_2]** - [PERCENTAGE_2]%
3. **[ERROR_3]** - [PERCENTAGE_3]%
4. **[ERROR_4]** - [PERCENTAGE_4]%
5. **[ERROR_5]** - [PERCENTAGE_5]%

### Resolution Time Baseline
- Compilation errors: [TIME_1] minutes
- Runtime errors: [TIME_2] minutes
- Build errors: [TIME_3] minutes
- Dependency errors: [TIME_4] minutes

---

## 🆘 Can't Resolve?

### If This Document Doesn't Have Your Error
1. Search `DEBUG_NOTES/` directory
2. Check Stack Overflow
3. Check framework official documentation
4. Search project Issues

### Adding New Error Patterns
When encountering and resolving a new error, add it to this document:
1. Copy template format
2. Fill in error message, cause, solution
3. Update document

---

**Document Status**: ✅ Active  
**Maintainer**: AI Assistant  
**Update Frequency**: Continuously updated as new error patterns are discovered