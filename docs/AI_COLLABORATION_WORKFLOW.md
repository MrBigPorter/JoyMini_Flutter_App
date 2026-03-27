
---

# AI Collaboration Development Workflow

> **Important**: This workflow is effective as of **2026-03-26**. All AI-collaborative development activities must strictly adhere to these protocols.

## 📋 Overview

This workflow is designed to resolve core challenges in AI-collaborative development:
1. **Opaque Code Changes**: Ensuring users fully understand the purpose and implementation of every significant modification.
2. **Lack of Communication Protocols**: Establishing standardized communication and confirmation mechanisms.
3. **Unreliable Memory**: Guaranteeing specification adherence through documentation, checklists, and structured processes.
4. **Inconsistent Execution**: Building a systematic execution assurance mechanism.

## 🏗️ Workflow Diagram

```
User Request → AI Analysis → Determine Significance → 
    ↓ (Significant Change)            ↓ (Routine Change)
Initiate Communication Protocol     Direct Implementation
    ↓                                ↓
Problem Statement → User OK         Implementation Complete
    ↓                                ↓
Solution Design → User OK           Result Report
    ↓
Risk Assessment → User OK
    ↓
Implementation Authorization → User Explicit Consent
    ↓
Implementation → Progress Reports → Completion Summary
```

## 🔍 Detailed Phase Requirements

### Phase 1: Request Analysis

#### 1.1 Content Analysis
- Analyze the complexity and significance of the user request.
- Determine if a full communication protocol is required.
- Identify potential technical challenges and risks.

#### 1.2 Criteria for "Significant Changes"
**Modifications requiring a full communication protocol include**:
- ✅ Architecture-level design changes.
- ✅ Core business logic modifications (Payment, Orders, User Data).
- ✅ Major performance optimizations.
- ✅ Security-related modifications.
- ✅ Third-party service integrations.
- ✅ Significant code refactoring.

**Routine changes eligible for direct implementation**:
- 🔧 Bug fixes (obvious functional errors).
- 📝 Documentation updates (comments and doc refinements).
- 🎨 UI polishing (styling adjustments without functional impact).
- 🔄 Dependency updates (version upgrades and compatibility tweaks).

---

### Phase 2: Communication Protocol (Significant Changes)

#### 2.1 Problem Statement Phase
**Goal**: Ensure the user understands the background and necessity of the modification.
**Required Content**:
- **Problem Description**: What is the current issue?
- **Impact Scope**: Which functions or users are affected?
- **Data Support**: Supporting evidence (performance metrics, user feedback, or error logs).
- **Modification Goal**: What is the desired outcome?
  **Template**: Must use `docs/templates/IMPORTANT_CODE_CHANGE_TEMPLATE.md`.

#### 2.2 Solution Design Phase
**Goal**: Ensure the user understands the technical solution and implementation logic.
**Required Content**:
- **Technical Solution**: How will the problem be resolved?
- **Implementation Logic**: Specific methodology and steps.
- **Technology Selection**: Rationale for the chosen stack/approach.
- **Implementation Plan**: Detailed schedule and milestones.

#### 2.3 Risk Assessment Phase
**Goal**: Ensure the user understands potential risks and mitigation measures.
**Required Content**:
- **Technical Risks**: Potential technical hurdles.
- **Compatibility Risks**: Impact on other modules.
- **Performance Risks**: Impact on application speed/resources.
- **Rollback Plan**: Strategy to revert changes if issues arise.
- **Monitoring Plan**: How to track the effectiveness of the fix.

#### 2.4 Implementation Authorization Phase
**Goal**: Obtain explicit user authorization for implementation.
**Required Content**:
- **Final Solution Summary**: Consolidating confirmation results from all prior phases.
- **Execution Schedule**: Defined implementation timeline.
- **Communication Plan**: Schedule for updates during implementation.
- **Success Criteria**: How to judge if the modification was successful.

---

### Phase 3: Implementation Phase

#### 3.1 Pre-Implementation Checklist
- [ ] User confirmation obtained for all communication phases.
- [ ] Reviewed `docs/FLUTTER_COMMANDS_CHEATSHEET.md`.
- [ ] Development environment prepared.
- [ ] Detailed implementation steps defined.

#### 3.2 Implementation Requirements
- Execute according to the confirmed solution.
- Report progress at least every 30 minutes.
- Pause and communicate immediately if issues occur.
- Log all executed commands and operations.

#### 3.3 Progress Reporting
**Content**: Current progress, completed tasks, encountered issues/solutions, next steps, and updated ETA.
**Frequency**:
- Significant Changes: At least every 30 minutes.
- Routine Changes: Upon completion.

---

### Phase 4: Completion Phase

#### 4.1 Completion Summary
**Required Content**:
- **Results Summary**: Work actually completed.
- **Effect Verification**: How the results were validated.
- **Issue Log**: Problems encountered and their resolutions.
- **Lessons Learned**: Insights for future implementations.

#### 4.2 Documentation Updates
- [ ] Update task status in `.github/copilot-instructions.md`.
- [ ] Update relevant technical documentation.
- [ ] Record implementation experiences and "Lessons Learned."
- [ ] Update the Command Cheatsheet (if new commands were used).

---

## 📊 Quality Assurance Mechanisms

### Mandatory Checklists

#### Significant Change Checklist:
- [ ] 1. Does this fall under "Significant Changes"?
- [ ] 2. Problem Statement confirmed by user?
- [ ] 3. Solution Design confirmed by user?
- [ ] 4. Risk Assessment confirmed by user?
- [ ] 5. Explicit implementation authorization obtained?
- [ ] 6. All relevant docs reviewed?
- [ ] 7. Environment ready?
- [ ] 8. Detailed implementation plan finalized?

#### Command Execution Checklist:
- [ ] 1. Reviewed `docs/FLUTTER_COMMANDS_CHEATSHEET.md`?
- [ ] 2. Used project-specific commands (e.g., `make` commands)?
- [ ] 3. Verified environment (Dev/Test/Prod)?
- [ ] 4. Applied necessary parameters/flags?
- [ ] 5. Recorded purpose of the command?
- [ ] 6. Verified actual execution results?

---

## 📈 Effectiveness Evaluation

### Short-term (1-2 Weeks):
- ✅ Comprehensive communication for all significant code changes.
- ✅ Transparent user understanding of every modification's purpose.
- ✅ Standardized and reliable command execution.
- ✅ Reduced issues stemming from miscommunication.

### Long-term (3 Months):
- ✅ Established mature AI-collaborative development culture.
- ✅ Reusable workflows and templates.
- ✅ Continuous improvement mechanism.
- ✅ Adoption as a team-wide standard practice.

---

**Last Updated: 2026-03-26** **Effective Date: 2026-03-26** **Execution Status: ✅ ACTIVE**

