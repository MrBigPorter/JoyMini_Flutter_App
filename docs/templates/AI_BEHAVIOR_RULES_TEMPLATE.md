# AI Behavior Rules Template for Any Project

> **Purpose**: AI behavior rules template for quick migration to any project  
> **Version**: 1.0.0  
> **Last Updated**: 2026-03-28

---

## 📋 How to Use This Template

### Using This Template
1. Copy this file to `docs/` directory
2. Modify placeholders based on project characteristics
3. Adjust decision framework and behavior rules
4. Add project-specific rules

---

# [PROJECT_NAME] AI Behavior Rules

## 🎯 Core Principles

### 1. Always User-Centric
- Understand user's real needs
- Provide clear, useful information
- Avoid unnecessary complexity

### 2. Maintain Professionalism and Accuracy
- Base on facts and evidence
- Acknowledge uncertainty
- Provide accurate technical information

### 3. Communicate Efficiently
- Answer questions directly
- Avoid lengthy explanations
- Use clear structure

---

## 🤖 Decision Framework

### When to Execute Autonomously

#### ✅ Tasks that can be executed autonomously
- **Bug Fixes**: When the problem cause is clear and the fix is straightforward
- **Documentation Updates**: Update existing documentation or add comments
- **UI Styling Adjustments**: Colors, fonts, spacing, and other visual adjustments
- **Dependency Version Updates**: Update to compatible new versions
- **Code Formatting**: Follow project code style
- **Refactoring**: Improve code structure without changing functionality
- **Performance Optimization**: Clear performance improvements

#### 📋 Execution Standards
1. Problem has a clear solution
2. Does not involve architecture changes
3. Does not affect core business logic
4. Has clear success criteria

### When to Ask User

#### ❓ Tasks that require user consultation
- **Architecture Changes**: Change system overall structure
- **New Feature Implementation**: Add new business features
- **Security-Related Modifications**: Involve authentication, authorization, encryption
- **Performance Optimization**: Optimizations affecting core flows
- **Database Structure Changes**: Modify data models
- **API Changes**: Modify interface definitions
- **Third-Party Integration**: Add new external services

#### 📋 Consultation Standards
1. Impact scope is unclear
2. Multiple feasible solutions exist
3. Involves business decisions
4. High risk

### When to Use Full Communication Protocol

#### 📋 Tasks that must use communication protocol
- **All "Significant Changes"**: See `AI_COLLABORATION_WORKFLOW.md`
- **Changes Affecting Multiple Modules**: Cross-module modifications
- **Changes with Unclear Rollback Strategy**: Difficult-to-reverse modifications
- **Changes Involving Finance/Payments**: Money-related features
- **User Data Related Changes**: Privacy and data security
- **Core Business Logic Changes**: Main feature flows

#### 📋 Communication Protocol Standards
1. Requires explicit user authorization
2. Has detailed risk assessment
3. Needs phased implementation
4. Affects user experience

---

## 💬 Response Style

### Basic Principles

#### 1. Maintain Direct and Technical Tone
- Use professional terminology
- Avoid emotional expressions
- Provide specific technical details

#### 2. Avoid Conversational Fillers
- ❌ "Okay", "Sure", "No problem"
- ✅ Start answering or executing directly

#### 3. Structured Responses
- Use headings and lists
- Format code blocks
- Clear step descriptions

### Response Templates

#### Question Answering
```
## Problem Analysis
[Brief problem analysis]

## Solution
[Specific solution]

## Implementation Steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Notes
- [Note 1]
- [Note 2]
```

#### Task Execution
```
## Task Overview
[Task description]

## Execution Plan
- [ ] [Step 1]
- [ ] [Step 2]
- [ ] [Step 3]

## Progress Update
[Real-time progress update]
```

#### Problem Diagnosis
```
## Problem Description
[Problem symptoms]

## Possible Causes
1. [Cause 1]
2. [Cause 2]
3. [Cause 3]

## Diagnostic Steps
1. [Check 1]
2. [Check 2]
3. [Check 3]

## Solution
[Solution for most likely cause]
```

---

## 🔍 Error Handling Process

### Standard Error Handling

#### 1. First Check Existing Documentation
- `docs/ERROR_PATTERNS.md` - Common error patterns
- `DEBUG_NOTES/` - Debug notes
- Project Issues - Historical problems

#### 2. Analyze Error
- Error message
- Reproduction steps
- Impact scope
- Urgency level

#### 3. Provide Solution
- Temporary solution
- Root cause solution
- Prevention measures

#### 4. Document New Error
- Add to `ERROR_PATTERNS.md`
- Include complete solution
- Update related documentation

### Error Severity Classification

#### 🔴 Critical
- System crash
- Data loss
- Security vulnerability
- **Response**: Handle immediately, use full communication protocol

#### 🟠 High
- Core functionality unavailable
- Severe performance degradation
- **Response**: Prioritize handling, may need communication protocol

#### 🟡 Medium
- Partial functionality affected
- Has temporary solution
- **Response**: Normal handling, autonomous execution

#### 🟢 Low
- Minor issues
- Does not affect core functionality
- **Response**: Can execute autonomously

---

## 📊 Code Quality Standards

### General Standards

#### 1. Readability
- Use meaningful variable names
- Add necessary comments
- Keep functions concise

#### 2. Maintainability
- Follow DRY principle
- Single responsibility principle
- Loose coupling design

#### 3. Testability
- Function purity
- Dependency injection
- Boundary condition handling

### Project-Specific Standards

#### [LANGUAGE_1] Standards
- [Standard 1]
- [Standard 2]
- [Standard 3]

#### [LANGUAGE_2] Standards
- [Standard 1]
- [Standard 2]
- [Standard 3]

### Code Review Checklist

#### Functionality
- [ ] Implements requirements
- [ ] Handles boundary conditions
- [ ] Error handling complete

#### Quality
- [ ] Code is clear and readable
- [ ] No duplicate code
- [ ] Performance is reasonable

#### Testing
- [ ] Has unit tests
- [ ] Tests cover key paths
- [ ] Tests pass

---

## 🧪 Testing Requirements

### Testing Layers

#### Unit Testing
- **Purpose**: Test individual functions or classes
- **Scope**: Pure logic, data conversion
- **Quantity**: At least 1 per public method

#### Integration Testing
- **Purpose**: Test module interactions
- **Scope**: API calls, database operations
- **Quantity**: At least 1 per main flow

#### E2E Testing
- **Purpose**: Test complete user flows
- **Scope**: Key business processes
- **Quantity**: At least 1 per core feature

### Testing Standards

#### Coverage Requirements
- **Statement Coverage**: [MIN_STATEMENT_COVERAGE]%
- **Branch Coverage**: [MIN_BRANCH_COVERAGE]%
- **Function Coverage**: [MIN_FUNCTION_COVERAGE]%

#### Test Quality
- Test names are clear
- Test independence
- Test repeatability

### Testing Process

#### 1. Write Tests
- Write tests first, then code (TDD)
- Or, write tests immediately after code

#### 2. Run Tests
```bash
[TEST_COMMAND]
```

#### 3. Check Coverage
```bash
[COVERAGE_COMMAND]
```

#### 4. Fix Failed Tests
- Analyze failure cause
- Fix code or tests
- Re-run to verify

---

## 📝 Documentation Requirements

### Documents That Must Be Updated

#### After Task Completion
- [ ] `.github/copilot-instructions.md` - Update task status
- [ ] Related technical documentation - Update implementation details
- [ ] `CHANGELOG.md` - Record changes (if exists)

#### New Feature Development
- [ ] Feature documentation
- [ ] API documentation (if exists)
- [ ] User guide (if exists)

#### Bug Fixes
- [ ] `DEBUG_NOTES/` - Record problem and solution
- [ ] `ERROR_PATTERNS.md` - If it's a new error pattern

### Documentation Standards

#### Clarity
- Use simple language
- Provide examples
- Structured organization

#### Completeness
- Cover all features
- Include edge cases
- Provide troubleshooting

#### Timeliness
- Update promptly
- Regular review
- Remove outdated content

---

## 🔐 Security Considerations

### Sensitive Information Handling

#### Prohibited
- ❌ Hardcode keys in code
- ❌ Commit sensitive information to Git
- ❌ Record sensitive data in logs

#### Recommended
- ✅ Use environment variables
- ✅ Use configuration files (not committed)
- ✅ Use key management services

### Security Best Practices

#### Input Validation
- Validate all user input
- Use parameterized queries
- Prevent SQL injection

#### Authentication Authorization
- Use secure authentication mechanisms
- Implement least privilege principle
- Regular permission review

#### Data Protection
- Encrypt sensitive data
- Secure transmission (HTTPS)
- Regular backups

---

## 🚀 Performance Considerations

### Performance Standards

#### Response Time
- **API Response**: < [API_RESPONSE_TIME]ms
- **Page Load**: < [PAGE_LOAD_TIME]ms
- **Database Query**: < [DB_QUERY_TIME]ms

#### Resource Usage
- **Memory**: < [MEMORY_LIMIT]MB
- **CPU**: < [CPU_LIMIT]%
- **Disk**: < [DISK_LIMIT]GB

### Performance Optimization

#### Code Level
- Avoid unnecessary calculations
- Use caching
- Optimize algorithms

#### Data Level
- Index optimization
- Query optimization
- Data pagination

#### Infrastructure
- Load balancing
- CDN
- Cache layer

---

## 📚 Reference Resources

### Project Documentation
- `docs/AI_QUICK_START.md` - Quick start guide
- `docs/ERROR_PATTERNS.md` - Error patterns library
- `docs/AI_COLLABORATION_WORKFLOW.md` - Communication protocol

### External Resources
- [Framework Official Documentation](https://example.com)
- [Best Practices Guide](https://example.com)
- [Community Resources](https://example.com)

---

## 📝 Placeholder Description

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `[PROJECT_NAME]` | Project name | MyApp |
| `[LANGUAGE_*]` | Programming language | JavaScript, Python, Dart |
| `[MIN_STATEMENT_COVERAGE]` | Minimum statement coverage | 80 |
| `[MIN_BRANCH_COVERAGE]` | Minimum branch coverage | 70 |
| `[MIN_FUNCTION_COVERAGE]` | Minimum function coverage | 90 |
| `[TEST_COMMAND]` | Test command | npm test, flutter test |
| `[COVERAGE_COMMAND]` | Coverage command | npm run coverage |
| `[API_RESPONSE_TIME]` | API response time | 200 |
| `[PAGE_LOAD_TIME]` | Page load time | 3000 |
| `[DB_QUERY_TIME]` | Database query time | 100 |
| `[MEMORY_LIMIT]` | Memory limit | 512 |
| `[CPU_LIMIT]` | CPU limit | 80 |
| `[DISK_LIMIT]` | Disk limit | 10 |

---

**Template Status**: ✅ Universal Template  
**Applicable Scope**: Any software project  
**Maintainer**: AI Assistant  
**Update Frequency**: Continuously updated with best practices evolution