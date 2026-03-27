---

# Important Code Change Communication Template

> **Important**: All significant code changes must use this template for communication. This is a core part of the AI Collaboration Development Specification.

## 📋 Template Usage Instructions

### Use Cases:
* Architecture-level design changes.
* Core business logic modifications (Payment, Orders, User Data).
* Major performance optimizations.
* Security-related modifications.
* Third-party service integrations.
* Significant code refactoring.

### Usage Workflow:
1.  **Copy Template**: Copy this template content into the communication.
2.  **Fill in Content**: Fill in each section based on the actual situation.
3.  **User Confirmation**: Wait for user confirmation after completing each phase.
4.  **Record Confirmation**: Record the user's confirmation and feedback.

### Notes:
* Each phase must be completed in order.
* Explicit user confirmation is required before proceeding to the next phase.
* All communication and confirmation results must be recorded.

---

## 🔍 Important Code Change Communication

### Basic Modification Information
* **Modification Type**: [Select: Architecture / Core Business / Performance / Security / Third-party Integration / Major Refactoring].
* **Involved Files**: [List the primary files involved].
* **Estimated Workload**: [Estimate time required, e.g., 2-4 hours].
* **Priority**: [Select: High / Medium / Low].
* **Communication Time**: `YYYY-MM-DD HH:MM`.
* **Communication ID**: `[Auto-generated or manually filled]`.

---

## Phase 1: Problem Statement (User Confirmation Required ✅)

### 1.1 Problem Description
[Detail the current problem, including:]
* What is the specific manifestation of the problem?
* When did this problem appear?
* Under what circumstances does this problem occur?

### 1.2 Impact Scope
[Describe the scope of the problem's impact:]
* Which functional modules are affected?
* How many users are affected?
* What is the specific impact on the business?

### 1.3 Supporting Data
[Provide data or evidence supporting the problem:]
* Are there error logs?
* Is there performance monitoring data?
* Is there user feedback?
* Are there test reports?

### 1.4 Modification Goals
[Clarify the goals to be achieved through the modification:]
* What is the primary goal?
* What are the secondary goals?
* What are the success criteria?

### 1.5 User Confirmation
* [ ] User understands the problem description.
* [ ] User confirms the impact scope.
* [ ] User approves the modification goals.
* [ ] User agrees to proceed to the next phase.

**User Confirmation Record**:
```
[Record user confirmation feedback, e.g.:
- User confirms understanding of the problem
- User agrees with the modification goals
- User requests additions: ...]
```

---

## Phase 2: Solution Design (User Confirmation Required ✅)

### 2.1 Technical Solution
[Describe the planned technical solution:]
* What is the overall architectural design?
* What are the core technology selections?
* Why was this solution chosen?

### 2.2 Implementation Logic
[Describe specific implementation methods:]
* What are the main implementation steps?
* What are the key technical points?
* How will implementation quality be guaranteed?

### 2.3 Alternative Options
[Provide alternative options for the user to choose from:]
* Option A: [Description of Option A]
  * Pros: [List pros]
  * Cons: [List cons]
  * Recommendation: [High / Medium / Low]
* Option B: [Description of Option B]
  * Pros: [List pros]
  * Cons: [List cons]
  * Recommendation: [High / Medium / Low]

### 2.4 Implementation Plan
[Develop a detailed implementation plan:]
* Stage 1: [Describe the first stage of work]
* Stage 2: [Describe the second stage of work]
* Stage 3: [Describe the third stage of work]
* Schedule: [Estimate time for each stage]

### 2.5 User Confirmation
* [ ] User understands the technical solution.
* [ ] User confirms the implementation logic.
* [ ] User has chosen an implementation option.
* [ ] User agrees to proceed to the next phase.

**User Confirmation Record**:
```
[Record user confirmation feedback, e.g.:
- User chooses Option A
- User requests adjustments to the implementation plan
- User confirms the schedule]
```

---

## Phase 3: Risk Assessment (User Confirmation Required ✅)

### 3.1 Technical Risks
[Identify potential technical risks:]
* Risk 1: [Describe risk]
  * Probability: [High / Medium / Low]
  * Impact: [High / Medium / Low]
  * Mitigation: [Describe mitigation measure]
* Risk 2: [Describe risk]
  * Probability: [High / Medium / Low]
  * Impact: [High / Medium / Low]
  * Mitigation: [Describe mitigation measure]

### 3.2 Compatibility Risks
[Assess the impact on other modules:]
* Impacted Module 1: [Describe impact]
* Impacted Module 2: [Describe impact]
* Compatibility Test Plan: [Describe test plan]

### 3.3 Performance Risks
[Assess the impact on performance:]
* Expected Performance Impact: [Describe impact]
* Performance Test Plan: [Describe test plan]
* Performance Monitoring Plan: [Describe monitoring plan]

### 3.4 Rollback Plan
[Develop a rollback plan for issues:]
* Rollback Conditions: [Under what circumstances is a rollback necessary]
* Rollback Steps: [Detailed rollback steps]
* Rollback Verification: [How to verify a successful rollback]

### 3.5 User Confirmation
* [ ] User understands technical risks.
* [ ] User confirms compatibility risks.
* [ ] User approves the rollback plan.
* [ ] User agrees to proceed to the next phase.

**User Confirmation Record**:
```
[Record user confirmation feedback, e.g.:
- User approves the risk assessment
- User requests enhanced performance monitoring
- User confirms the rollback plan]
```

---

## Phase 4: Implementation Authorization (Explicit Consent Required ✅)

### 4.1 Final Solution Summary
[Summarize confirmation results from all phases:]
* Problem Statement: [Summarize problem]
* Technical Solution: [Summarize solution]
* Risk Assessment: [Summarize risks]
* Implementation Plan: [Summarize plan]

### 4.2 Success Criteria
[Clarify how to determine if the modification was successful:]
* Functional Criteria: [Functional success criteria]
* Performance Criteria: [Performance success criteria]
* Quality Criteria: [Quality success criteria]

### 4.3 Communication Plan
[Develop a communication plan for the implementation process:]
* Reporting Frequency: [e.g., Report every 30 minutes]
* Reporting Content: [What the report needs to include]
* Emergency Communication: [Communication method for emergencies]

### 4.4 Implementation Authorization
**Important**: Requires the user's explicit "Consent to Implement" confirmation

* [ ] User understands the final solution.
* [ ] User confirms success criteria.
* [ ] User agrees to the communication plan.
* [ ] **User explicitly agrees to start implementation**.

### 4.5 Authorization Record
```
**Authorization Information**:
- Authorization Time: YYYY-MM-DD HH:MM
- Authorizer: [User Name/ID]
- Authorization Conditions: [Any additional conditions]
- Authorization Validity: [If applicable]

**User Explicit Consent Statement**:
[Record the user's explicit consent statement, e.g.:
"I agree to start implementation according to the above plan"
"Agree to start implementation, please proceed as planned"
"Authorize start of implementation, communicate promptly if there are issues"]
```

---

## Phase 5: Implementation Phase

### 5.1 Pre-Implementation Check
[Checks that must be completed before implementation:]
* [ ] Completed user confirmation for all phases.
* [ ] Reviewed `docs/FLUTTER_COMMANDS_CHEATSHEET.md`.
* [ ] Development environment is ready.
* [ ] Detailed implementation steps have been developed.

### 5.2 Implementation Progress Report
[Report progress regularly according to the communication plan]

#### Report Time: `YYYY-MM-DD HH:MM`
**Current Progress**: [Describe current progress]
**Completed Work**: [List completed work]
**Issues Encountered**: [Describe issues encountered and solutions]
**Next Steps**: [Describe the next steps]
**Estimated Completion Time**: [Update ETA]

### 5.3 Command Execution Log
[Record all executed commands]

#### Command 1: [Command Name]
**Command**: `[Complete command]`
**Purpose**: [Purpose of execution]
**Expected**: [Expected result]
**Actual**: [Actual result]
**Issue**: [Encountered problems and solutions]

---

## Phase 6: Completion Summary

### 6.1 Implementation Results
[Summarize implementation results:]
* **Actually Completed Work**: [List work actually completed]
* **Difference from Plan**: [Describe the difference from the plan]
* **Issues Encountered**: [Summarize issues encountered during implementation]

### 6.2 Effect Verification
[Verify modification effect:]
* **Functional Verification**: [Whether the function works as expected]
* **Performance Verification**: [Whether performance meets expectations]
* **Compatibility Verification**: [Whether other modules are affected]

### 6.3 Lessons Learned
[Summarize implementation experience:]
* **Successes**: [Which practices were successful]
* **Improvement Points**: [Areas for improvement]
* **Suggestions**: [Suggestions for similar modifications]

### 6.4 Document Updates
[Record documents needing updates:]
* [ ] Update `.github/copilot-instructions.md`.
* [ ] Update relevant technical documents.
* [ ] Update Command Cheatsheet.
* [ ] Record this implementation experience.

### 6.5 User Acceptance
**Final user acceptance confirmation required**

* [ ] User viewed implementation results.
* [ ] User verified modification effect.
* [ ] User approved implementation quality.
* [ ] **User confirms acceptance is complete**.

**Acceptance Record**:
```
[Record user acceptance feedback, e.g.:
"Acceptance passed, modification effect meets expectations"
"Confirmed complete, thank you for the work"
"Acceptance complete, this task can be closed"]
```

---

## 📊 Communication Record Summary

### Communication Timeline
* **Start Time**: `YYYY-MM-DD HH:MM`.
* **Problem Statement Confirmed**: `YYYY-MM-DD HH:MM`.
* **Solution Design Confirmed**: `YYYY-MM-DD HH:MM`.
* **Risk Assessment Confirmed**: `YYYY-MM-DD HH:MM`.
* **Implementation Authorization Time**: `YYYY-MM-DD HH:MM`.
* **Completion Time**: `YYYY-MM-DD HH:MM`.
* **Acceptance Time**: `YYYY-MM-DD HH:MM`.

---

**Template Version**: v1.0.0  
**Creation Date**: 2026-03-26  
**Last Updated**: 2026-03-26  
**Usage Status**: ✅ Active

