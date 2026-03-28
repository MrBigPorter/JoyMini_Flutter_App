# 📚 JoyMini Architecture Quick Reference Guide

> **Purpose**: Architecture document quick navigation and common patterns reference  
> **Version**: 1.0  
> **Last Updated**: 2026-03-28

---

## 🚀 Quick Navigation

### Core Documents

| Document | Purpose | When to Reference |
|----------|---------|-------------------|
| **[ARCHITECTURE_MASTER.md](./ARCHITECTURE_MASTER.md)** | Architecture master document | Understanding overall architecture, tech stack, layered model |
| **[Core Domain Design.md](./Core%20Domain%20Design.md)** | Core domain design | Handling financial, IM, authentication features |
| **[Design System Automation.md](./Design%20System%20Automation.md)** | UI automation | Handling design tokens, UI adaptation |

### Other Related Documents

| Document | Purpose |
|----------|---------|
| [AI Quick Start Guide](../AI_QUICK_START.md) | AI quick start |
| [Error Patterns](../ERROR_PATTERNS.md) | Common error solutions |
| [Flutter Commands](../FLUTTER_COMMANDS_CHEATSHEET.md) | Flutter command quick reference |

---

## 🎯 Common Architecture Patterns

### 1. State Management (Riverpod)

```dart
// Define Provider
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

// Use in Widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return Text(state.value);
  }
}
```

**When to use**:
- Global state management
- Cross-page data sharing
- Dependency injection

---

### 2. Route Navigation (GoRouter)

```dart
// Define route
GoRoute(
  path: '/product/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return ProductPage(id: id);
  },
)

// Navigation
context.go('/product/123');
context.push('/product/123');
```

**When to use**:
- Page navigation
- DeepLink handling
- Route authentication

---

### 3. Data Model (JsonSerializable)

```dart
@JsonSerializable(checked: true)
class MyModel {
  @JsonKey(fromJson: JsonNumConverter.toDouble)
  final double amount;
  
  MyModel({required this.amount});
  
  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

**When to use**:
- API response parsing
- Data persistence
- Type safety guarantee

---

### 4. Paginated List (PageListViewPro)

```dart
PageListViewPro<MyItem>(
  controller: _pageController,
  itemBuilder: (context, item, index) {
    return MyItemWidget(item: item);
  },
  emptyBuilder: () => EmptyWidget(),
  errorBuilder: (error) => ErrorWidget(error),
)
```

**When to use**:
- Long list display
- Pull-to-refresh, load-more
- Skeleton screen, empty state, error state

---

### 5. Dirty Flag Refresh

```dart
// Define dirty flag
final transactionDirtyProvider = StateProvider<bool>((ref) => false);

// Set dirty flag
ref.read(transactionDirtyProvider.notifier).state = true;

// Monitor dirty flag
ref.listen(transactionDirtyProvider, (previous, next) {
  if (next) {
    // Execute refresh
    _refreshData();
  }
});
```

**When to use**:
- Cross-page data synchronization
- Delayed refresh
- Avoid duplicate requests

---

## 📋 Architecture Checklist

### New Feature Development

- [ ] Follow layered architecture (UI -> Logic -> State -> Domain -> Infrastructure)
- [ ] Use Riverpod for state management
- [ ] Use GoRouter for routing
- [ ] Data models use JsonSerializable
- [ ] Amount fields use JsonNumConverter
- [ ] No hardcoded colors/sizes in UI
- [ ] Write unit tests and widget tests

### Bug Fix

- [ ] Reproduce the issue
- [ ] Analyze root cause
- [ ] Implement fix
- [ ] Add regression test
- [ ] Update DEBUG_NOTES (if applicable)

### Performance Optimization

- [ ] Performance analysis (Profile mode)
- [ ] Identify bottlenecks
- [ ] Implement optimization
- [ ] Verify results
- [ ] Document optimization results

---

## ⚠️ Common Anti-Patterns

### ❌ Don't Do This

```dart
// Wrong: Hardcode color in UI
Container(color: Color(0xFFFF0000))

// Wrong: Hardcode size in UI
SizedBox(height: 24)

// Wrong: Write complex business logic in build method
Widget build(BuildContext context) {
  if (status == 3 && payStatus == 1 && amount > 100) {
    // Complex logic
  }
}

// Wrong: Use double to parse amount
double amount = json['amount'].toDouble();
```

### ✅ Should Do This

```dart
// Correct: Use design tokens
Container(color: context.colorError)

// Correct: Use design tokens
SizedBox(height: context.spacingMd)

// Correct: Encapsulate logic in Model
Widget build(BuildContext context) {
  if (item.canRequestRefund) {
    // Simple logic
  }
}

// Correct: Use JsonNumConverter
@JsonKey(fromJson: JsonNumConverter.toDouble)
final double amount;
```

---

## 🔍 Quick Lookup

### I Want to Know About...

| Question | Reference Document |
|----------|-------------------|
| Overall architecture design | ARCHITECTURE_MASTER.md Section 3 |
| Technology stack selection | ARCHITECTURE_MASTER.md Section 4 |
| Directory structure | ARCHITECTURE_MASTER.md Section 5 |
| Architecture decisions | ARCHITECTURE_MASTER.md Section 6 |
| Financial precision handling | Core Domain Design.md Section 2.1 |
| Real-time synchronization | Core Domain Design.md Section 3 |
| Authentication mechanism | Core Domain Design.md Section 4 |
| Design tokens | Design System Automation.md Section 2 |
| Cross-platform adaptation | Design System Automation.md Section 3 |

---

## 📞 Encountering Issues?

1. **Architecture Issues**: Check ARCHITECTURE_MASTER.md
2. **Domain Issues**: Check Core Domain Design.md
3. **UI Issues**: Check Design System Automation.md
4. **Error Issues**: Check ERROR_PATTERNS.md
5. **Not Sure**: Ask team or check related documents

---

**Document Status**: ✅ Active  
**Maintainer**: AI Assistant  
**Update Frequency**: Continuously updated with architecture evolution