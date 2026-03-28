# Core Rules Template for Any Project

> **Purpose**: Core rules template for quick migration to any project  
> **Version**: 1.0.0  
> **Last Updated**: 2026-03-28

---

## 📋 How to Use This Template

### Using This Template
1. Copy this file to project root directory, rename to `.clinerules`
2. Modify placeholders like `[PROJECT_NAME]` based on project characteristics
3. Adjust technology stack and constraints
4. Add project-specific rules

---

# [PROJECT_NAME] Core Rules Index

# 1. Navigation Instructions
At the start of each conversation, immediately read and strictly follow the project specifications and task progress in the following paths:
- Core instructions file: .github/copilot-instructions.md
- Quick start guide: docs/AI_QUICK_START.md

# 2. Technology Stack Constraints
- Framework: [FRAMEWORK] (must use)
- State Management: [STATE_MANAGEMENT] (must use)
- Routing System: [ROUTING_SYSTEM] (must use)
- Package Manager: [PACKAGE_MANAGER] (must use)
- Language Requirements: [LANGUAGE_REQUIREMENTS]

# 3. Automation Tasks
- Task Tracking: After completing a task, update the [ ] status in .github/copilot-instructions.md
- Code Generation: [CODE_GENERATION_REQUIREMENTS]

# 4. AI Behavior Rules
## 4.1 Decision Framework
### Tasks that can be executed autonomously:
- ✅ Bug fixes with clear root cause
- ✅ Documentation updates
- ✅ UI styling adjustments
- ✅ Dependency version updates
- ✅ Code formatting

### Tasks that require user consultation:
- ❓ Architecture changes
- ❓ New feature implementation
- ❓ Security-related modifications
- ❓ Performance optimizations affecting core flows
- ❓ Database structure changes

### Tasks that must use full communication protocol:
- 📋 All "significant changes" (see docs/AI_COLLABORATION_WORKFLOW.md)
- 📋 Changes affecting multiple modules
- 📋 Changes with unclear rollback strategy
- 📋 Changes involving finance/payments

## 4.2 Response Style
- Maintain direct and technical tone
- Avoid conversational fillers
- Always include task_progress checklist
- Document command execution results

## 4.3 Error Handling
- First check docs/ERROR_PATTERNS.md
- Check DEBUG_NOTES/ directory
- If it's a new error, document the solution for future reference
- Never assume success, must verify

## 4.4 Code Quality Standards
- Follow [LINT_CONFIG] rules
- Use meaningful variable names
- Add comments for complex business logic
- Keep functions under [MAX_FUNCTION_LINES] lines
- [SPECIFIC_CODE_RULE_1]
- [SPECIFIC_CODE_RULE_2]
- [SPECIFIC_CODE_RULE_3]

## 4.5 Testing Requirements
- New features: minimum [MIN_UNIT_TESTS] Unit + [MIN_WIDGET_TESTS] Widget/Integration tests
- Bug fixes: regression test required
- Model changes: serialization/deserialization tests required
- Before commit: [TEST_COMMAND]

---

## 📝 Placeholder Description

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `[PROJECT_NAME]` | Project name | MyApp |
| `[FRAMEWORK]` | Framework name | React, Vue, Flutter |
| `[STATE_MANAGEMENT]` | State management | Redux, MobX, Riverpod |
| `[ROUTING_SYSTEM]` | Routing system | React Router, GoRouter |
| `[PACKAGE_MANAGER]` | Package manager | npm, yarn, pnpm, pub |
| `[LANGUAGE_REQUIREMENTS]` | Language requirements | Chinese/English only |
| `[CODE_GENERATION_REQUIREMENTS]` | Code generation requirements | Must run build_runner after modifying models |
| `[LINT_CONFIG]` | Lint configuration | analysis_options.yaml, .eslintrc |
| `[MAX_FUNCTION_LINES]` | Maximum function lines | 50 |
| `[SPECIFIC_CODE_RULE_*]` | Specific code rules | Money fields must use JsonNumConverter.toDouble |
| `[MIN_UNIT_TESTS]` | Minimum unit tests | 1 |
| `[MIN_WIDGET_TESTS]` | Minimum widget tests | 1 |
| `[TEST_COMMAND]` | Test command | fvm flutter test, npm test |

---

## 🎯 Project Type Examples

### Flutter Project
```markdown
# 2. Technology Stack Constraints
- Framework: Flutter (must use)
- State Management: Riverpod (must use)
- Routing System: GoRouter (must use)
- Package Manager: pub (must use)
- Language Requirements: Korean prohibited, Chinese/English only for replies and comments

# 3. Automation Tasks
- Task Tracking: After completing a task, update the [ ] status in .github/copilot-instructions.md
- Code Generation: Must run build_runner after modifying models

# 4.4 Code Quality Standards
- Follow analysis_options.yaml rules
- Use meaningful variable names
- Add comments for complex business logic
- Keep functions under 50 lines
- Money fields must use JsonNumConverter.toDouble
- Business logic in build() method must not exceed 3 lines
- Prohibit hardcoding colors/sizes, use generated design tokens

# 4.5 Testing Requirements
- New features: minimum 1 Unit + 1 Widget test
- Bug fixes: regression test required
- Model changes: must test fromJson/toJson
- Before commit: fvm flutter analyze && fvm flutter test
```

### React Project
```markdown
# 2. Technology Stack Constraints
- Framework: React 18 (must use)
- State Management: Redux Toolkit (must use)
- Routing System: React Router v6 (must use)
- Package Manager: pnpm (must use)
- Language Requirements: Chinese/English only

# 3. Automation Tasks
- Task Tracking: After completing a task, update the [ ] status in .github/copilot-instructions.md
- Code Generation: Must run codegen after modifying API types

# 4.4 Code Quality Standards
- Follow .eslintrc rules
- Use meaningful variable names
- Add comments for complex business logic
- Keep functions under 50 lines
- Components must use TypeScript
- Prohibit using any type
- Must handle error boundaries

# 4.5 Testing Requirements
- New features: minimum 1 Unit + 1 Integration test
- Bug fixes: regression test required
- API changes: must test request/response
- Before commit: pnpm test && pnpm lint
```

### Node.js Backend Project
```markdown
# 2. Technology Stack Constraints
- Runtime: Node.js 18 (must use)
- Framework: Express.js (must use)
- Database: PostgreSQL (must use)
- ORM: Prisma (must use)
- Package Manager: npm (must use)
- Language Requirements: Chinese/English only

# 3. Automation Tasks
- Task Tracking: After completing a task, update the [ ] status in .github/copilot-instructions.md
- Code Generation: Must run prisma generate after modifying schema

# 4.4 Code Quality Standards
- Follow .eslintrc rules
- Use meaningful variable names
- Add comments for complex business logic
- Keep functions under 50 lines
- Must use async/await
- Must handle errors and exceptions
- Must validate input data

# 4.5 Testing Requirements
- New features: minimum 1 Unit + 1 Integration test
- Bug fixes: regression test required
- API changes: must test endpoints
- Before commit: npm test && npm run lint
```

---

## 🔧 Customization Checklist

### Basic Configuration
- [ ] Replace all `[PROJECT_NAME]` placeholders
- [ ] Update technology stack list
- [ ] Adjust automation tasks
- [ ] Modify decision framework

### Code Quality
- [ ] Set up lint configuration
- [ ] Define function line limits
- [ ] Add project-specific code rules
- [ ] Configure testing requirements

### Team-Specific
- [ ] Adjust response style
- [ ] Update error handling process
- [ ] Modify communication protocol
- [ ] Add team standards

---

## 📚 Related Documents

- `docs/AI_QUICK_START.md` - Quick start guide
- `docs/ERROR_PATTERNS.md` - Error patterns library
- `docs/AI_COLLABORATION_WORKFLOW.md` - Communication protocol
- `.github/copilot-instructions.md` - Task tracking

---

**Template Status**: ✅ Universal Template  
**Applicable Scope**: Any software project  
**Maintainer**: AI Assistant  
**Update Frequency**: Continuously updated with best practices evolution