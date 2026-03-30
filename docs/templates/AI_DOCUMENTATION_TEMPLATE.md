# AI Documentation Template for Any Project

> **Purpose**: Universal AI documentation template for quick migration to any project  
> **Version**: 1.0.0  
> **Last Updated**: 2026-03-28

---

## 📋 How to Use This Template

### Using This Template
1. Copy the entire `docs/templates/` directory to the new project
2. Modify placeholders like `[PROJECT_NAME]` based on project characteristics
3. Adjust technology stack and commands
4. Add project-specific error patterns

### Template File List
- `AI_QUICK_START_TEMPLATE.md` - Quick start guide template
- `ERROR_PATTERNS_TEMPLATE.md` - Error patterns template
- `CLINERULES_TEMPLATE.md` - Core rules template
- `AI_BEHAVIOR_RULES_TEMPLATE.md` - AI behavior rules template

---

## 🚀 Quick Migration Steps

### Step 1: Copy Template Files
```bash
# Copy template directory to new project
cp -r docs/templates/ /path/to/new-project/docs/

# Or manually create directory structure
mkdir -p /path/to/new-project/docs/
cp docs/templates/*.md /path/to/new-project/docs/
```

### Step 2: Replace Placeholders
Replace the following placeholders in all template files:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `[PROJECT_NAME]` | Project name | MyApp |
| `[TECH_STACK]` | Technology stack | React, Node.js, PostgreSQL |
| `[STATE_MANAGEMENT]` | State management | Redux, MobX, Context API |
| `[ROUTING_SYSTEM]` | Routing system | React Router, Next.js Router |
| `[PACKAGE_MANAGER]` | Package manager | npm, yarn, pnpm |
| `[BUILD_TOOL]` | Build tool | Webpack, Vite, Rollup |
| `[TEST_FRAMEWORK]` | Testing framework | Jest, Mocha, Cypress |

### Step 3: Adjust Technology Stack Constraints
Modify `.clinerules` or create new rule files based on project technology stack.

### Step 4: Add Project-Specific Content
- Add project-specific error patterns
- Add project-specific commands
- Add project-specific workflows

---

## 📝 Template File Description

### 1. AI_QUICK_START_TEMPLATE.md
**Purpose**: Quick context gathering at the start of new conversations

**Contents**:
- Required reading list
- Project overview and tech stack quick reference
- Common command cheat sheet
- Decision framework
- Key documentation index
- Common workflow templates

**Customizable Parts**:
- Technology stack list
- Command cheat sheet
- Workflow templates
- Architecture rules

---

### 2. ERROR_PATTERNS_TEMPLATE.md
**Purpose**: Common error patterns and solutions

**Contents**:
- Error categories (compilation, runtime, build, test, dependency)
- Detailed information for each error pattern
- Solutions and prevention measures

**Customizable Parts**:
- Error categories
- Specific error patterns
- Solutions
- Prevention measures

---

### 3. CLINERULES_TEMPLATE.md
**Purpose**: Project core rules and constraints

**Contents**:
- Navigation instructions
- Technology stack constraints
- Automation tasks
- AI behavior rules

**Customizable Parts**:
- Technology stack constraints
- Decision framework
- Code quality standards
- Testing requirements

---

### 4. AI_BEHAVIOR_RULES_TEMPLATE.md
**Purpose**: AI behavior standards and decision framework

**Contents**:
- Decision framework
- Response style
- Error handling process
- Code quality standards
- Testing requirements

**Customizable Parts**:
- Decision framework
- Response style
- Code quality standards
- Testing requirements

---

## 🎯 Project Type Adaptation Guide

### Web Applications (React/Vue/Angular)
```markdown
# Technology Stack Example
- Framework: React 18
- State Management: Redux Toolkit
- Routing: React Router v6
- Build Tool: Vite
- Testing: Jest + React Testing Library
- Package Manager: pnpm

# Common Commands
pnpm install          # Install dependencies
pnpm dev              # Start development server
pnpm build            # Build production version
pnpm test             # Run tests
pnpm lint             # Code check
```

### Mobile Applications (React Native/Flutter)
```markdown
# Technology Stack Example
- Framework: Flutter 3.x
- State Management: Riverpod
- Routing: GoRouter
- Build Tool: Flutter CLI
- Testing: Flutter Test
- Package Manager: pub

# Common Commands
flutter pub get       # Install dependencies
flutter run           # Run application
flutter build apk     # Build Android
flutter build ios     # Build iOS
flutter test          # Run tests
```

### Backend Services (Node.js/Python/Go)
```markdown
# Technology Stack Example
- Runtime: Node.js 18
- Framework: Express.js
- Database: PostgreSQL
- ORM: Prisma
- Testing: Jest
- Package Manager: npm

# Common Commands
npm install           # Install dependencies
npm run dev           # Start development server
npm run build         # Build production version
npm test              # Run tests
npm run migrate       # Database migration
```

### Full-Stack Applications (Next.js/Nuxt.js)
```markdown
# Technology Stack Example
- Framework: Next.js 14
- State Management: Zustand
- Routing: Next.js App Router
- Database: Prisma + PostgreSQL
- Testing: Jest + Playwright
- Package Manager: pnpm

# Common Commands
pnpm install          # Install dependencies
pnpm dev              # Start development server
pnpm build            # Build production version
pnpm test             # Run tests
pnpm db:push          # Push database schema
```

---

## 🔧 Customization Checklist

### Basic Configuration
- [ ] Replace all `[PROJECT_NAME]` placeholders
- [ ] Update technology stack list
- [ ] Adjust common commands
- [ ] Modify decision framework

### Technology Stack Specific
- [ ] Add framework-specific error patterns
- [ ] Update build commands
- [ ] Adjust testing requirements
- [ ] Add deployment commands

### Project Specific
- [ ] Add project-specific workflows
- [ ] Update architecture rules
- [ ] Add integration documentation
- [ ] Create DEBUG_NOTES directory

### Team Specific
- [ ] Adjust communication protocol
- [ ] Update code quality standards
- [ ] Modify testing requirements
- [ ] Add team standards

---

## 📊 Migration Effectiveness Evaluation

### Evaluation Metrics
| Metric | Evaluation Standard | Target Value |
|--------|---------------------|--------------|
| Context Gathering Time | New conversation startup time | < 3 minutes |
| Error Resolution Time | Common problem resolution time | < 15 minutes |
| Decision Consistency | AI decisions meet expectations | > 85% |
| Documentation Completeness | Key documentation coverage | 100% |

### Evaluation Methods
1. **New Conversation Test**: Test if AI can quickly gather context
2. **Error Resolution Test**: Test common error resolution efficiency
3. **Decision Test**: Test AI decision consistency
4. **Completeness Check**: Check documentation coverage

---

## 🆘 FAQ

### Q1: How to handle project-specific errors?
A1: Add project-specific error patterns in `ERROR_PATTERNS.md`, including:
- Error message
- Root cause analysis
- Solution
- Prevention measures

### Q2: How to adjust the decision framework?
A2: Adjust the decision framework in `.clinerules`:
- Define tasks that can be executed autonomously
- Define tasks that require user consultation
- Define tasks that must use full communication protocol

### Q3: How to add new workflows?
A3: Create new workflow documents in `docs/workflows/` directory:
- Copy existing workflow template
- Modify to project-specific content
- Update documentation index

### Q4: How to maintain documentation?
A4: Establish documentation maintenance process:
- Regular documentation review
- Update outdated content
- Add new error patterns
- Collect team feedback

---

## 📚 Reference Resources

### General AI Documentation Best Practices
- [AI Documentation Best Practices](https://example.com)
- [Prompt Engineering Guide](https://example.com)
- [AI Collaboration Patterns](https://example.com)

### Project-Specific Documentation
- [Framework Official Documentation](https://example.com)
- [Best Practices Guide](https://example.com)
- [Community Resources](https://example.com)

---

**Template Status**: ✅ Universal Template  
**Applicable Scope**: Any software project  
**Maintainer**: AI Assistant  
**Update Frequency**: Continuously updated with best practices evolution