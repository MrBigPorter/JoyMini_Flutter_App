
---

# Bug Fix Communication Template

> **Important**: All bug fixes can use this template to simplify communication. This is part of the AI Collaboration Development Specification.

## 📋 Template Usage Instructions

### Use Cases:
* Obvious functional error fixes.
* UI display issue fixes.
* Performance issue fixes.
* Compatibility issue fixes.

### Usage Workflow:
1.  **Copy Template**: Copy this template content into the communication.
2.  **Fill in Content**: Fill in each section according to the actual situation.
3.  **User Confirmation**: Start the fix after obtaining user confirmation.
4.  **Record Results**: Record the fix process and results.

### Notes:
* This template is suitable for relatively simple bug fixes.
* Complex bug fixes should use the "Important Code Modification Template".
* User confirmation must be obtained before starting the fix.

---

## 🔍 Bug Fix Communication

### Basic Bug Information
* **Bug Type**: [Please select: Functional Error / UI Issue / Performance Issue / Compatibility Issue].
* **Involved Files**: [List the involved files].
* **Severity**: [Please select: High / Medium / Low].
* **Priority**: [Please select: High / Medium / Low].
* **Communication Time**: `YYYY-MM-DD HH:MM`.
* **Bug ID**: `[If applicable]`.

---

## Phase 1: Problem Analysis (User Confirmation Required ✅)

### 1.1 Bug Description
[Detail the bug description:]
* What is the specific manifestation of the bug?
* Under what circumstances does it occur?
* What are the steps to reproduce?

### 1.2 Impact Analysis
[Analyze the impact of the bug:]
* Which functions are affected?
* How many users are affected?
* What is the extent of the impact on user experience?

### 1.3 Root Cause
[Analyze the root cause of the bug:]
* What is the preliminary judgment of the cause?
* Are there relevant error logs?
* Is it related to a specific environment?

### 1.4 Fix Goals
[Clarify the fix goals:]
* What is the primary fix goal?
* What is the expected effect after the fix?
* What are the success criteria?

### 1.5 User Confirmation
* [ ] User understands the bug description.
* [ ] User confirms the impact analysis.
* [ ] User approves the fix goals.
* [ ] User agrees to start the fix.

**User Confirmation Record**:
```
[Record user confirmation feedback]
```

---

## Phase 2: Fix Plan (User Confirmation Required ✅)

### 2.1 Fix Plan
[Describe the fix plan:]
* How do you plan to fix it?
* What are the specific steps for the fix?
* Why choose this plan?

### 2.2 Test Plan
[Develop a test plan:]
* How to test the effect of the fix?
* Which scenarios need to be tested?
* How to verify the fix was successful?

### 2.3 Risk Assessment
[Assess the fix risks:]
* What are the potential risks brought by the fix?
* How to avoid introducing new problems?
* What is the rollback plan?

### 2.4 User Confirmation
* [ ] User understands the fix plan.
* [ ] User confirms the test plan.
* [ ] User approves the risk assessment.
* [ ] User agrees to implement the fix.

**User Confirmation Record**:
```
[Record user confirmation feedback]
```

---

## Phase 3: Fix Implementation

### 3.1 Pre-Implementation Check
[Checks that must be completed before implementation:]
* [ ] Obtained user confirmation.
* [ ] Reviewed `docs/FLUTTER_COMMANDS_CHEATSHEET.md`.
* [ ] Test environment is ready.
* [ ] Detailed fix steps have been developed.

### 3.2 Fix Process Log
[Record the fix process:]

#### Step 1: [Step Description]
**Operation**: [Specific operation]
**Purpose**: [Purpose of operation]
**Result**: [Result of operation]
**Issue**: [Issues encountered]

#### Step 2: [Step Description]
**Operation**: [Specific operation]
**Purpose**: [Purpose of operation]
**Result**: [Result of operation]
**Issue**: [Issues encountered]

### 3.3 Command Execution Log
[Record all executed commands:]

#### Command 1: [Command Name]
**Command**: `[Complete command]`
**Purpose**: [Purpose of execution]
**Expected**: [Expected result]
**Actual**: [Actual result]

#### Command 2: [Command Name]
**Command**: `[Complete command]`
**Purpose**: [Purpose of execution]
**Expected**: [Expected result]
**Actual**: [Actual result]

---

## Phase 4: Test Verification

### 4.1 Test Results
[Record test results:]

#### Test Scenario 1: [Scenario Description]
**Test Steps**: [Test steps]
**Expected Result**: [Expected result]
**Actual Result**: [Actual result]
**Pass Status**: [✅Pass / ❌Fail]

#### Test Scenario 2: [Scenario Description]
**Test Steps**: [Test steps]
**Expected Result**: [Expected result]
**Actual Result**: [Actual result]
**Pass Status**: [✅Pass / ❌Fail]

### 4.2 Regression Testing
[Perform regression testing:]
* [ ] Are related functions working properly?
* [ ] Were new problems introduced?
* [ ] Is performance affected?

### 4.3 Verification Summary
[Summarize verification results:]
* **Fix Effect**: [Whether the fix was successful]
* **Test Coverage**: [Whether the testing was sufficient]
* **Quality Assessment**: [Assessment of fix quality]

---

## Phase 5: Completion Summary

### 5.1 Fix Results
[Summarize fix results:]
* **Actual Fix Content**: [What was actually fixed]
* **Difference from Plan**: [Difference from the plan]
* **Issues Encountered**: [Issues encountered during the fix process]

### 5.2 Effect Verification
[Verify fix effect:]
* **Functional Verification**: [Whether the function is normal]
* **Performance Verification**: [Whether performance is normal]
* **Compatibility Verification**: [Whether compatibility is normal]

### 5.3 Lessons Learned
[Summarize fix experience:]
* **Successes**: [Which practices were successful]
* **Improvement Points**: [Areas for improvement]
* **Suggestions**: [Suggestions for similar bug fixes]

### 5.4 Document Updates
[Record documents needing updates:]
* [ ] Update relevant technical documents.
* [ ] Record bug fix experience.
* [ ] Update test cases.

### 5.5 User Acceptance
**Final user acceptance confirmation required**

* [ ] User viewed fix results.
* [ ] User verified fix effect.
* [ ] User approved fix quality.
* [ ] **User confirms acceptance is complete**.

**Acceptance Record**:
```
[Record user acceptance feedback]
```

---

## 📊 Fix Record Summary

### Fix Timeline
* **Start Time**: `YYYY-MM-DD HH:MM`.
* **Problem Analysis Confirmed**: `YYYY-MM-DD HH:MM`.
* **Fix Plan Confirmed**: `YYYY-MM-DD HH:MM`.
* **Fix Completion Time**: `YYYY-MM-DD HH:MM`.
* **Test Completion Time**: `YYYY-MM-DD HH:MM`.
* **Acceptance Time**: `YYYY-MM-DD HH:MM`.

### Fix Efficiency Metrics
* **Total Fix Time**: [Calculate total time].
* **Analysis Time**: [Problem analysis time].
* **Fix Time**: [Actual fix time].
* **Test Time**: [Test verification time].

### Quality Assessment
* **Fix Integrity**: [Assess if fix is complete].
* **Test Sufficiency**: [Assess if testing was sufficient].
* **User Satisfaction**: [Assess user satisfaction].

---

**Template Version**: v1.0.0  
**Creation Date**: 2026-03-26  
**Last Updated**: 2026-03-26  
**Usage Status**: ✅ Active

