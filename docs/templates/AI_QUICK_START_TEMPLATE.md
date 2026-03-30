# AI Quick Start Guide Template

> **Purpose**: Quick start guide template for AI to quickly gather context at the start of new conversations  
> **Version**: 1.0.0  
> **Last Updated**: 2026-03-28

---

## 🚀 Step 1: Required Reading (In Order)

At the start of each new conversation, immediately read the following files:

1. **`.github/copilot-instructions.md`** - Current task status and progress
2. **`.clinerules`** - Core rules and technology stack constraints
3. **This file** - Quick context

---

## 📋 Current Project Overview

### Project Name
**[PROJECT_NAME]** - [Brief project description]

### Technology Stack (Mandatory)
- **Framework**: [FRAMEWORK] (e.g., React, Vue, Angular, Flutter)
- **State Management**: [STATE_MANAGEMENT] (e.g., Redux, MobX, Riverpod)
- **Routing System**: [ROUTING_SYSTEM] (e.g., React Router, GoRouter)
- **Package Manager**: [PACKAGE_MANAGER] (e.g., npm, yarn, pnpm, pub)
- **Build Tool**: [BUILD_TOOL] (e.g., Webpack, Vite, Flutter CLI)
- **Testing Framework**: [TEST_FRAMEWORK] (e.g., Jest, Mocha, Flutter Test)

### Core Feature Modules
- [Feature Module 1]
- [Feature Module 2]
- [Feature Module 3]
- [Feature Module 4]

---

## ⚡ Common Command Cheat Sheet

### Development Environment
```bash
[PACKAGE_MANAGER] install          # Install dependencies
[PACKAGE_MANAGER] dev              # Start development server
[PACKAGE_MANAGER] clean            # Clean build
```

### Code Quality
```bash
[PACKAGE_MANAGER] lint             # Code check
[PACKAGE_MANAGER] format           # Format code
[PACKAGE_MANAGER] test             # Run tests
```

### Build Commands
```bash
[PACKAGE_MANAGER] build            # Production build
[PACKAGE_MANAGER] build:dev        # Development build
[PACKAGE_MANAGER] build:prod       # Production build
```

### Code Generation
```bash
[PACKAGE_MANAGER] generate         # Generate code
[PACKAGE_MANAGER] codegen          # Code generation
```

---

## 🎯 Decision Framework

### When to Execute Autonomously
- ✅ Bug fixes with clear root cause
- ✅ Documentation updates
- ✅ UI styling adjustments
- ✅ Dependency version updates
- ✅ Code formatting

### When to Ask User
- ❓ Architecture changes
- ❓ New feature implementation
- ❓ Security-related modifications
- ❓ Performance optimizations affecting core flows
- ❓ Database structure changes

### When to Use Full Communication Protocol
- 📋 All "significant changes" (see `AI_COLLABORATION_WORKFLOW.md`)
- 📋 Changes affecting multiple modules
- 📋 Changes with unclear rollback strategy
- 📋 Changes involving finance/payments

---

## 📚 Key Documentation Index

| Document | Purpose | When to Reference |
|----------|---------|-------------------|
| `.github/copilot-instructions.md` | Task tracking | Start of each conversation |
| `docs/AI_COLLABORATION_WORKFLOW.md` | Communication protocol | For significant changes |
| `docs/ARCHITECTURE.md` | Architecture design | For technical decisions |
| `docs/COMMANDS.md` | Command reference | Before executing commands |
| `docs/TESTING.md` | Testing guide | When writing tests |
| `docs/templates/CHANGE_TEMPLATE.md` | Change template | For significant change communication |

---

## 🔧 Common Workflows

### New Feature Development
1. Read `copilot-instructions.md` to understand current phase
2. Use `CHANGE_TEMPLATE.md` for communication
3. Implement feature (following architecture layers)
4. Write tests (Unit + Integration)
5. Update documentation and task status

### Bug Fix
1. Reproduce the issue
2. Analyze root cause
3. Implement fix
4. Add regression test
5. Update `DEBUG_NOTES/` (if applicable)

### Performance Optimization
1. Performance analysis (Profile mode)
2. Identify bottlenecks
3. Implement optimization
4. Verify results
5. Document optimization results

---

## ⚠️ Important Reminders

### Architecture Rules
1. **[Architecture Rule 1]**: [Description]
2. **[Architecture Rule 2]**: [Description]
3. **[Architecture Rule 3]**: [Description]

### Code Quality
- Follow `[LINT_CONFIG]` rules
- Use meaningful variable names
- Add comments for complex business logic
- Keep functions under [MAX_LINES] lines

### Testing Requirements
- New features: minimum [MIN_TESTS] tests
- Bug fixes: regression test required
- Model changes: serialization/deserialization tests required

---

## 🆘 Encountering Issues?

### Compilation Errors
→ Check `docs/ERROR_PATTERNS.md`

### Runtime Errors
→ Check `DEBUG_NOTES/` directory

### Test Failures
→ Reference `docs/TESTING.md`

### Unsure How to Decide
→ Follow the "Decision Framework" in this file

---

**Document Status**: ✅ Active  
**Maintainer**: AI Assistant  
**Update Frequency**: Continuously updated with project evolution