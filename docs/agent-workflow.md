# Boss's Agent Workflow

## Org Chart

```
Boss
└── Claude Code (Team Leader)
    ├── Doer (Planning, Test Design, Implementation, Testing)
    └── Reviewer (Plan Review, Test Review, Code Review)
```

## The Two-Agent System

This workflow uses **two specialized agents** that leverage context continuity:

**Doer** – Handles execution (planning → test design → implementation → testing)
- Creates the plan (context filled with planning knowledge)
- Designs test cases (already knows plan intimately)
- Implements the code (already knows plan + tests intimately)
- Runs tests to verify (already knows plan + tests + code intimately)

**Reviewer** – Handles quality assurance (plan review → test review → code review)
- Reviews the plan (context filled with plan knowledge)
- Reviews test coverage (already knows plan intimately)
- Reviews the code (already knows plan + tests intimately, can verify adherence)

**Why This Works**: Each agent maintains their context window across multiple phases, eliminating the need to re-read and re-understand work between handoffs.

## Phase 1: Planning & Preparation

### Step 1: Create Operation Folder & Planning Document
- Claude Code creates operation subfolder in `/docs/working/`
- Example: `/docs/working/{operation-name}/`
- Create main planning file: `/docs/working/{operation}/plan.md`
- This is where agents will create, review, and handover all work products

### Step 2: Deep Discussion & Analysis
- Claude Code and Boss discuss feature requirements
- Analyze every angle, consider edge cases, make bulletproof
- Go into great depth until all ambiguity is removed

### Step 3: Rough Estimate for Chunking
- Claude Code analyzes the requirement
- Get just enough sense of the work to estimate chunks
- Example: "I think this can be done in 5 chunks: database migration, backend API, frontend changes, edge functions, testing"
- This is a ROUGH estimate – Doer will refine during planning
- **Wait for Boss feedback and authorization before proceeding**

### Step 4: Update Project Documentation with Current Operation
- Claude Code adds current operation to project's working documentation
- Include: operation name, branch, operation folder path, main plan path, objective, status, chunk count
- This helps agents understand what's currently being worked on

### Step 5: Boss Authorization
- Boss reviews discussion and rough estimate
- Boss gives go-ahead to start implementation

## Phase 2: Branch Management

### Step 6: Branch Management
- Claude Code analyzes current branch situation
- Informs Boss of branch status
- Creates fresh new branch for feature work
- Branch naming: descriptive of feature (e.g., `feature/user-authentication`)

### Step 7: Project Ready
- Fresh branch created
- Ready to start implementation

## Phase 3: Chunk Breakdown

### Step 8: Break Plan Into Chunks
- Claude Code breaks implementation plan into logical chunks
- **More chunks = better** (8, 10, 12... as many as makes sense)
- **Smaller chunks get better ratings more often** – break work into focused, atomic tasks
- Each chunk should be independently testable
- Chunks should follow logical sequence (database → backend → frontend)
- Write chunk breakdown to `/docs/working/{operation}/chunks.md`

## Phase 4: Agent Deployment

### Step 9: Brief the Agents
- Claude Code briefs both agents on the operation
- Instructs agents to read:
  - **PRIORITY #1**: Entire codebase – READ THE ACTUAL CODE, not just documentation
  - All documentation in `/docs/`
  - **Especially** the operation folder `/docs/working/{operation}/`
  - **Especially** the main plan and chunk breakdown files
- **CRITICAL REMINDER TO ALL AGENTS – NO HARDCODING**:
  - ❌ NO hardcoded LLM models
  - ❌ NO hardcoded system prompts
  - ❌ NO hardcoded API endpoints
  - ❌ NO hardcoded credentials or tokens
  - ❌ NO hardcoded configuration values
  - ✅ Always use dynamic values from variables/parameters/configuration
- **SEPARATION OF CONCERNS – PRAGMATIC, NOT DOGMATIC**:
  - ✅ Apply just enough to keep code clean and minimize technical debt
  - ✅ Each module should have clear, well-defined responsibilities
  - ✅ Separate business logic from presentation where it makes sense
  - ❌ Don't over-abstract or create excessive layers
  - ❌ Don't sacrifice simplicity for architectural purity
  - Balance: Maintainable code > Perfect architecture

## Phase 5: Chunk Implementation Loop (Test-Driven Development)

For each chunk (starting with Chunk 1):

### Step 10: Doer – Create Detailed Plan with Test Cases
- Claude Code summons **Doer**
- Task: "Plan Chunk N implementation with comprehensive test cases – read actual codebase files that will be modified"
- **CRITICAL – READ ACTUAL CODEBASE**: Doer must read the ACTUAL code files that will be modified, not just rely on documentation or assumptions
- **CRITICAL – NO HARDCODING**: Doer must NOT propose hardcoded values in the plan
- **TEST-FIRST PLANNING**: Doer must define test cases that will validate the chunk:
  - Unit tests for individual functions/methods
  - Integration tests for component interactions
  - Edge case tests
  - Error condition tests
- Doer writes plan in operation folder
- Example: `/docs/working/{operation}/chunk-1-plan.md`
- Plan must include:
  - What will be built
  - Test cases that define success
  - Implementation approach
  - Files to be modified
- **Context Advantage**: Doer now has deep understanding of requirements, codebase structure, test requirements, and implementation approach in their context window

### Step 11: Reviewer – Review Plan and Test Coverage
- Claude Code summons **Reviewer**
- Task: "Review `/docs/working/{operation}/chunk-1-plan.md`, verify test coverage is comprehensive, give rating and constructive feedback"
- **CRITICAL – READ ACTUAL CODEBASE**: Reviewer must read the ACTUAL code files that will be modified
- **CRITICAL – NO HARDCODING**: Reviewer must verify the plan does NOT introduce hardcoded values
- Reviewer evaluates:
  - Clarity
  - Completeness
  - Test coverage (are all paths tested?)
  - Alignment with Boss's requirements
  - Technical soundness
  - No hardcoded values
  - Based on actual codebase, not assumptions
- **Pragmatic Quality Gate**: Rating of **8/10 or higher** to proceed
- Reviewer writes review to `/docs/working/{operation}/chunk-1-plan-review.md`
- **Context Advantage**: Reviewer now has deep understanding of the plan and test requirements in their context window

### Step 12: Plan Iteration Loop
- **If rating < 8/10**:
  - Doer reads review feedback
  - Doer revises plan
  - Reviewer reviews again
  - Repeat until ≥8/10
  - **Context Advantage**: Both agents maintain full context through iteration
- **If rating ≥ 8/10**: Proceed to Step 13

### Step 13: Doer – Write Tests First
- Claude Code summons **Doer** (same agent who created the plan)
- Task: "Write the test code for the plan you created in `/docs/working/{operation}/chunk-1-plan.md`"
- **Context Advantage**: Doer already has the plan and test requirements in their context window
- **CRITICAL – READ ACTUAL CODEBASE**: Doer must read the ACTUAL code files to understand testing patterns and structure
- **TDD Approach**:
  - Write test code first
  - Tests should fail initially (nothing implemented yet)
  - Tests define the contract/interface
  - Tests cover happy path, edge cases, and error conditions
- Doer documents what tests were created

### Step 14: Reviewer – Review Tests
- Claude Code summons **Reviewer** (same agent who reviewed the plan)
- Task: "Review the test code against the plan you approved in `/docs/working/{operation}/chunk-1-plan.md`"
- **Context Advantage**: Reviewer already has the plan and test requirements in their context window
- **CRITICAL – READ ACTUAL TEST CODE**: Reviewer must read the ACTUAL test files
- Reviewer evaluates:
  - Tests match approved plan
  - Test coverage is comprehensive
  - Tests are well-structured
  - Tests will actually validate the requirements
  - No hardcoded values in tests
- **Pragmatic Quality Gate**: Rating of **8/10 or higher** to proceed
- Reviewer writes review to `/docs/working/{operation}/chunk-1-test-review.md`

### Step 15: Test Review Loop
- **If rating < 8/10**:
  - Doer reads review feedback
  - Doer fixes test issues
  - Reviewer reviews again
  - Repeat until ≥8/10
- **If rating ≥ 8/10**: Proceed to Step 16

### Step 16: Doer – Implement Code to Pass Tests
- Claude Code summons **Doer** (same agent who wrote the tests)
- Task: "Implement the code to make your tests pass"
- **Context Advantage**: Doer already has plan + tests in their context window – knows exactly what needs to be built
- **CRITICAL – READ ACTUAL CODEBASE**: Doer must read the ACTUAL code files being modified
- **CRITICAL – NO HARDCODING**: Doer must NOT write hardcoded values
- **TDD Approach**:
  - Run tests first (verify they fail)
  - Implement code to make tests pass
  - Refactor if needed
  - All tests must pass
- Doer documents what was changed

### Step 17: Reviewer – Review Code
- Claude Code summons **Reviewer** (same agent who reviewed plan and tests)
- Task: "Review the code implementation against the plan and tests you approved"
- **Context Advantage**: Reviewer already has plan + tests in their context window – knows exactly what was promised
- **CRITICAL – READ ACTUAL CODE**: Reviewer must read the ACTUAL modified code files
- **CRITICAL – NO HARDCODING**: Reviewer must verify the code does NOT contain hardcoded values
- **CRITICAL – AUDIT ALL FILES**: Check every modified file for hardcoded strings, even in unexpected places
- Reviewer evaluates:
  - Code matches approved plan
  - Tests pass
  - Code quality
  - Security
  - Architecture alignment
  - Pragmatic separation of concerns (clear responsibilities, minimal technical debt)
  - No additions beyond requirements
  - No hardcoded values anywhere
  - Based on actual code files
- **Pragmatic Quality Gate**: Rating of **8/10 or higher, AND all tests pass** to proceed
- Reviewer writes review to `/docs/working/{operation}/chunk-1-code-review.md`

### Step 18: Code Review Loop
- **If rating < 8/10 OR tests fail**:
  - Doer reads review feedback
  - Doer fixes issues
  - Reviewer reviews again
  - Repeat until ≥8/10 AND tests pass
  - **Context Advantage**: Both agents maintain full context through iteration
- **If rating ≥ 8/10 AND tests pass**: Proceed to Step 19

### Step 19: Doer – Run Full Test Suite
- Claude Code summons **Doer** (same agent who implemented the code)
- Task: "Run full test suite to ensure no regressions"
- **Context Advantage**: Doer already has plan + tests + implementation in their context window
- Doer verifies:
  - All new tests pass
  - All existing tests still pass (no regressions)
  - Build succeeds
  - No compilation/runtime errors
- Doer documents test results

### Step 20: Commit Changes
- Claude Code commits the chunk changes to git
- Commit message format: "Chunk X: [brief description]"
- Example: "Chunk 1: Database Schema – Add user authentication tables"
- Include co-author line: `Co-Authored-By: Claude <noreply@anthropic.com>`

### Step 21: Boss Checkpoint Review (Every Chunk)
- After EVERY chunk, Claude Code notifies Boss
- Boss does quick checkpoint review:
  - Test the implemented chunk
  - Verify direction is correct
  - Provide course corrections if needed
- If changes needed, create mini-chunks for adjustments
- Prevents any drift from Boss's vision

### Step 22: Chunk Complete
- Chunk N marked complete
- **Immediately start Chunk N+1** without waiting for Boss permission
- **Context Advantage**: Doer carries forward understanding from previous chunks
- Repeat Steps 10-21 for each chunk

## Phase 6: Integration Testing

### Step 23: Doer – Run Integration Tests
- Claude Code summons **Doer**
- Task: "Run integration tests across all chunks"
- Tests verify:
  - All chunks work together correctly
  - No conflicts between chunks
  - End-to-end workflows function
  - Performance is acceptable
- Doer documents integration test results

### Step 24: Fix Integration Issues
- If integration tests reveal issues:
  - Doer creates fix plan
  - Reviewer reviews fix plan
  - Doer implements fixes
  - Reviewer reviews fixes
  - Rerun integration tests
- Repeat until all integration tests pass

## Phase 7: Completion & Handoff

### Step 25: All Chunks Complete
- Claude Code declares to Boss: "Everything is ready for your human testing"

### Step 26: Provide Clear Test Instructions
- Claude Code tells Boss in clear steps:
  - What to test
  - How to test it
  - What success looks like
  - What edge cases to verify
  - How to run automated tests

Example test steps:
```
1. Run automated test suite: `npm test`
2. Verify all tests pass
3. Manual testing steps:
   a. [Specific action to test]
   b. [Expected result]
   c. [Edge case to verify]
4. Check logs for errors
5. Verify no regressions in existing features
```

## Quality Gates (Enforced at Each Step)

- **Planning**: Reviewer must give ≥8/10
- **Tests**: Reviewer must give ≥8/10
- **Code**: Reviewer must give ≥8/10 AND all tests must pass
- **Integration**: All integration tests must pass
- **No scope creep**: Agents cannot add features beyond Boss requirements
- **No hardcoding**: Agents must never hardcode values

## Success Criteria

✅ All chunks implemented
✅ All quality gates passed (≥8/10)
✅ All tests passing (unit, integration, regression)
✅ Boss checkpoint reviews passed
✅ Boss final testing complete
✅ Feature works as specified
✅ No regressions in existing functionality
✅ No hardcoded values anywhere

## Why Two Agents Work Better

### Context Continuity
**Old Multi-Agent System**:
- Planner creates plan → context window full of planning knowledge
- **NEW Coder agent** → starts fresh, must READ the plan.md file
- **NEW Code Reviewer agent** → starts fresh, must READ plan + code
- **NEW Tester agent** → starts fresh, must READ everything

**This Two-Agent System**:
- **Doer** creates plan → context window full of planning knowledge
- **Reviewer** reviews plan → context window full of plan knowledge
- **Doer** writes tests → **ALREADY KNOWS PLAN INTIMATELY**
- **Reviewer** reviews tests → **ALREADY KNOWS PLAN INTIMATELY**
- **Doer** implements code → **ALREADY KNOWS PLAN + TESTS INTIMATELY**
- **Reviewer** reviews code → **ALREADY KNOWS PLAN + TESTS INTIMATELY**
- **Doer** runs tests → **ALREADY KNOWS EVERYTHING INTIMATELY**

### Efficiency Gains
- ✅ Fewer context switches
- ✅ Fewer agent invocations
- ✅ No re-reading of plans/code between phases
- ✅ Deeper understanding through context persistence
- ✅ Faster iteration cycles
- ✅ Better quality through intimate knowledge
- ✅ Tests define success objectively (no subjective 10/10 debates)

### Specialization
- **Doer** = Expert in execution (planning → test design → coding → testing)
- **Reviewer** = Expert in quality (verifying completeness, correctness, test coverage, adherence)

## Test-Driven Development Benefits

### Objective Quality Gates
- Tests pass = code works
- No subjective "is this good enough?" debates
- Clear definition of done

### Early Architecture Validation
- Writing tests first forces thinking through interfaces
- Catches design problems in planning, not implementation
- Prevents over-engineering

### Built-in Regression Prevention
- Every chunk adds to test suite
- Future changes can't break existing functionality
- Confidence to refactor

### Learning Feedback Loop
- Boss finds bug? Add test case
- Next chunks inherit improved test coverage
- Workflow gets smarter over time

### Reviewer Focus Shift
- From "is this code beautiful?" (subjective)
- To "are tests comprehensive?" and "does code pass them?" (objective)
- Much faster, less bikeshedding

## Notes

- **Agents work sequentially on chunks** – complete Chunk 1 before Chunk 2
- **No parallel work** – prevents conflicts and maintains quality
- **Boss involved at: start (planning), checkpoints (every chunk), end (testing)** – agents handle implementation
- **Claude Code orchestrates** – summons agents, enforces quality gates, manages workflow
- **Context is king** – reusing agents preserves knowledge and accelerates work
- **Tests are first-class citizens** – written before code, define success, prevent regressions
- **Pragmatic quality** – 8/10 + passing tests is shippable, perfect is the enemy of done
- **Each chunk is a git commit** – easy rollback if needed
- **No hardcoding ever** – enforced at every review step# Boss's Agent Workflow

## Org Chart

```
Boss
└── Claude Code (Team Leader)
    ├── Doer (Planning, Test Design, Implementation, Testing)
    └── Reviewer (Plan Review, Test Review, Code Review)
```

## The Two-Agent System

This workflow uses **two specialized agents** that leverage context continuity:

**Doer** – Handles execution (planning → test design → implementation → testing)
- Creates the plan (context filled with planning knowledge)
- Designs test cases (already knows plan intimately)
- Implements the code (already knows plan + tests intimately)
- Runs tests to verify (already knows plan + tests + code intimately)

**Reviewer** – Handles quality assurance (plan review → test review → code review)
- Reviews the plan (context filled with plan knowledge)
- Reviews test coverage (already knows plan intimately)
- Reviews the code (already knows plan + tests intimately, can verify adherence)

**Why This Works**: Each agent maintains their context window across multiple phases, eliminating the need to re-read and re-understand work between handoffs.

## Phase 1: Planning & Preparation

### Step 1: Create Operation Folder & Planning Document
- Claude Code creates operation subfolder in `/docs/working/`
- Example: `/docs/working/{operation-name}/`
- Create main planning file: `/docs/working/{operation}/plan.md`
- This is where agents will create, review, and handover all work products

### Step 2: Deep Discussion & Analysis
- Claude Code and Boss discuss feature requirements
- Analyze every angle, consider edge cases, make bulletproof
- Go into great depth until all ambiguity is removed

### Step 3: Rough Estimate for Chunking
- Claude Code analyzes the requirement
- Get just enough sense of the work to estimate chunks
- Example: "I think this can be done in 5 chunks: database migration, backend API, frontend changes, edge functions, testing"
- This is a ROUGH estimate – Doer will refine during planning
- **Wait for Boss feedback and authorization before proceeding**

### Step 4: Update Project Documentation with Current Operation
- Claude Code adds current operation to project's working documentation
- Include: operation name, branch, operation folder path, main plan path, objective, status, chunk count
- This helps agents understand what's currently being worked on

### Step 5: Boss Authorization
- Boss reviews discussion and rough estimate
- Boss gives go-ahead to start implementation

## Phase 2: Branch Management

### Step 6: Branch Management
- Claude Code analyzes current branch situation
- Informs Boss of branch status
- Creates fresh new branch for feature work
- Branch naming: descriptive of feature (e.g., `feature/user-authentication`)

### Step 7: Project Ready
- Fresh branch created
- Ready to start implementation

## Phase 3: Chunk Breakdown

### Step 8: Break Plan Into Chunks
- Claude Code breaks implementation plan into logical chunks
- **More chunks = better** (8, 10, 12... as many as makes sense)
- **Smaller chunks get better ratings more often** – break work into focused, atomic tasks
- Each chunk should be independently testable
- Chunks should follow logical sequence (database → backend → frontend)
- Write chunk breakdown to `/docs/working/{operation}/chunks.md`

## Phase 4: Agent Deployment

### Step 9: Brief the Agents
- Claude Code briefs both agents on the operation
- Instructs agents to read:
  - **PRIORITY #1**: Entire codebase – READ THE ACTUAL CODE, not just documentation
  - All documentation in `/docs/`
  - **Especially** the operation folder `/docs/working/{operation}/`
  - **Especially** the main plan and chunk breakdown files
- **CRITICAL REMINDER TO ALL AGENTS – NO HARDCODING**:
  - ❌ NO hardcoded LLM models
  - ❌ NO hardcoded system prompts
  - ❌ NO hardcoded API endpoints
  - ❌ NO hardcoded credentials or tokens
  - ❌ NO hardcoded configuration values
  - ✅ Always use dynamic values from variables/parameters/configuration
- **SEPARATION OF CONCERNS – PRAGMATIC, NOT DOGMATIC**:
  - ✅ Apply just enough to keep code clean and minimize technical debt
  - ✅ Each module should have clear, well-defined responsibilities
  - ✅ Separate business logic from presentation where it makes sense
  - ❌ Don't over-abstract or create excessive layers
  - ❌ Don't sacrifice simplicity for architectural purity
  - Balance: Maintainable code > Perfect architecture

## Phase 5: Chunk Implementation Loop (Test-Driven Development)

For each chunk (starting with Chunk 1):

### Step 10: Doer – Create Detailed Plan with Test Cases
- Claude Code summons **Doer**
- Task: "Plan Chunk N implementation with comprehensive test cases – read actual codebase files that will be modified"
- **CRITICAL – READ ACTUAL CODEBASE**: Doer must read the ACTUAL code files that will be modified, not just rely on documentation or assumptions
- **CRITICAL – NO HARDCODING**: Doer must NOT propose hardcoded values in the plan
- **TEST-FIRST PLANNING**: Doer must define test cases that will validate the chunk:
  - Unit tests for individual functions/methods
  - Integration tests for component interactions
  - Edge case tests
  - Error condition tests
- Doer writes plan in operation folder
- Example: `/docs/working/{operation}/chunk-1-plan.md`
- Plan must include:
  - What will be built
  - Test cases that define success
  - Implementation approach
  - Files to be modified
- **Context Advantage**: Doer now has deep understanding of requirements, codebase structure, test requirements, and implementation approach in their context window

### Step 11: Reviewer – Review Plan and Test Coverage
- Claude Code summons **Reviewer**
- Task: "Review `/docs/working/{operation}/chunk-1-plan.md`, verify test coverage is comprehensive, give rating and constructive feedback"
- **CRITICAL – READ ACTUAL CODEBASE**: Reviewer must read the ACTUAL code files that will be modified
- **CRITICAL – NO HARDCODING**: Reviewer must verify the plan does NOT introduce hardcoded values
- Reviewer evaluates:
  - Clarity
  - Completeness
  - Test coverage (are all paths tested?)
  - Alignment with Boss's requirements
  - Technical soundness
  - No hardcoded values
  - Based on actual codebase, not assumptions
- **Pragmatic Quality Gate**: Rating of **8/10 or higher** to proceed
- Reviewer writes review to `/docs/working/{operation}/chunk-1-plan-review.md`
- **Context Advantage**: Reviewer now has deep understanding of the plan and test requirements in their context window

### Step 12: Plan Iteration Loop
- **If rating < 8/10**:
  - Doer reads review feedback
  - Doer revises plan
  - Reviewer reviews again
  - Repeat until ≥8/10
  - **Context Advantage**: Both agents maintain full context through iteration
- **If rating ≥ 8/10**: Proceed to Step 13

### Step 13: Doer – Write Tests First
- Claude Code summons **Doer** (same agent who created the plan)
- Task: "Write the test code for the plan you created in `/docs/working/{operation}/chunk-1-plan.md`"
- **Context Advantage**: Doer already has the plan and test requirements in their context window
- **CRITICAL – READ ACTUAL CODEBASE**: Doer must read the ACTUAL code files to understand testing patterns and structure
- **TDD Approach**:
  - Write test code first
  - Tests should fail initially (nothing implemented yet)
  - Tests define the contract/interface
  - Tests cover happy path, edge cases, and error conditions
- Doer documents what tests were created

### Step 14: Reviewer – Review Tests
- Claude Code summons **Reviewer** (same agent who reviewed the plan)
- Task: "Review the test code against the plan you approved in `/docs/working/{operation}/chunk-1-plan.md`"
- **Context Advantage**: Reviewer already has the plan and test requirements in their context window
- **CRITICAL – READ ACTUAL TEST CODE**: Reviewer must read the ACTUAL test files
- Reviewer evaluates:
  - Tests match approved plan
  - Test coverage is comprehensive
  - Tests are well-structured
  - Tests will actually validate the requirements
  - No hardcoded values in tests
- **Pragmatic Quality Gate**: Rating of **8/10 or higher** to proceed
- Reviewer writes review to `/docs/working/{operation}/chunk-1-test-review.md`

### Step 15: Test Review Loop
- **If rating < 8/10**:
  - Doer reads review feedback
  - Doer fixes test issues
  - Reviewer reviews again
  - Repeat until ≥8/10
- **If rating ≥ 8/10**: Proceed to Step 16

### Step 16: Doer – Implement Code to Pass Tests
- Claude Code summons **Doer** (same agent who wrote the tests)
- Task: "Implement the code to make your tests pass"
- **Context Advantage**: Doer already has plan + tests in their context window – knows exactly what needs to be built
- **CRITICAL – READ ACTUAL CODEBASE**: Doer must read the ACTUAL code files being modified
- **CRITICAL – NO HARDCODING**: Doer must NOT write hardcoded values
- **TDD Approach**:
  - Run tests first (verify they fail)
  - Implement code to make tests pass
  - Refactor if needed
  - All tests must pass
- Doer documents what was changed

### Step 17: Reviewer – Review Code
- Claude Code summons **Reviewer** (same agent who reviewed plan and tests)
- Task: "Review the code implementation against the plan and tests you approved"
- **Context Advantage**: Reviewer already has plan + tests in their context window – knows exactly what was promised
- **CRITICAL – READ ACTUAL CODE**: Reviewer must read the ACTUAL modified code files
- **CRITICAL – NO HARDCODING**: Reviewer must verify the code does NOT contain hardcoded values
- **CRITICAL – AUDIT ALL FILES**: Check every modified file for hardcoded strings, even in unexpected places
- Reviewer evaluates:
  - Code matches approved plan
  - Tests pass
  - Code quality
  - Security
  - Architecture alignment
  - Pragmatic separation of concerns (clear responsibilities, minimal technical debt)
  - No additions beyond requirements
  - No hardcoded values anywhere
  - Based on actual code files
- **Pragmatic Quality Gate**: Rating of **8/10 or higher, AND all tests pass** to proceed
- Reviewer writes review to `/docs/working/{operation}/chunk-1-code-review.md`

### Step 18: Code Review Loop
- **If rating < 8/10 OR tests fail**:
  - Doer reads review feedback
  - Doer fixes issues
  - Reviewer reviews again
  - Repeat until ≥8/10 AND tests pass
  - **Context Advantage**: Both agents maintain full context through iteration
- **If rating ≥ 8/10 AND tests pass**: Proceed to Step 19

### Step 19: Doer – Run Full Test Suite
- Claude Code summons **Doer** (same agent who implemented the code)
- Task: "Run full test suite to ensure no regressions"
- **Context Advantage**: Doer already has plan + tests + implementation in their context window
- Doer verifies:
  - All new tests pass
  - All existing tests still pass (no regressions)
  - Build succeeds
  - No compilation/runtime errors
- Doer documents test results

### Step 20: Commit Changes
- Claude Code commits the chunk changes to git
- Commit message format: "Chunk X: [brief description]"
- Example: "Chunk 1: Database Schema – Add user authentication tables"
- Include co-author line: `Co-Authored-By: Claude <noreply@anthropic.com>`

### Step 21: Boss Checkpoint Review (Every Chunk)
- After EVERY chunk, Claude Code notifies Boss
- Boss does quick checkpoint review:
  - Test the implemented chunk
  - Verify direction is correct
  - Provide course corrections if needed
- If changes needed, create mini-chunks for adjustments
- Prevents any drift from Boss's vision

### Step 22: Chunk Complete
- Chunk N marked complete
- **Immediately start Chunk N+1** without waiting for Boss permission
- **Context Advantage**: Doer carries forward understanding from previous chunks
- Repeat Steps 10-21 for each chunk

## Phase 6: Integration Testing

### Step 23: Doer – Run Integration Tests
- Claude Code summons **Doer**
- Task: "Run integration tests across all chunks"
- Tests verify:
  - All chunks work together correctly
  - No conflicts between chunks
  - End-to-end workflows function
  - Performance is acceptable
- Doer documents integration test results

### Step 24: Fix Integration Issues
- If integration tests reveal issues:
  - Doer creates fix plan
  - Reviewer reviews fix plan
  - Doer implements fixes
  - Reviewer reviews fixes
  - Rerun integration tests
- Repeat until all integration tests pass

## Phase 7: Completion & Handoff

### Step 25: All Chunks Complete
- Claude Code declares to Boss: "Everything is ready for your human testing"

### Step 26: Provide Clear Test Instructions
- Claude Code tells Boss in clear steps:
  - What to test
  - How to test it
  - What success looks like
  - What edge cases to verify
  - How to run automated tests

Example test steps:
```
1. Run automated test suite: `npm test`
2. Verify all tests pass
3. Manual testing steps:
   a. [Specific action to test]
   b. [Expected result]
   c. [Edge case to verify]
4. Check logs for errors
5. Verify no regressions in existing features
```

## Quality Gates (Enforced at Each Step)

- **Planning**: Reviewer must give ≥8/10
- **Tests**: Reviewer must give ≥8/10
- **Code**: Reviewer must give ≥8/10 AND all tests must pass
- **Integration**: All integration tests must pass
- **No scope creep**: Agents cannot add features beyond Boss requirements
- **No hardcoding**: Agents must never hardcode values

## Success Criteria

✅ All chunks implemented
✅ All quality gates passed (≥8/10)
✅ All tests passing (unit, integration, regression)
✅ Boss checkpoint reviews passed
✅ Boss final testing complete
✅ Feature works as specified
✅ No regressions in existing functionality
✅ No hardcoded values anywhere

## Why Two Agents Work Better

### Context Continuity
**Old Multi-Agent System**:
- Planner creates plan → context window full of planning knowledge
- **NEW Coder agent** → starts fresh, must READ the plan.md file
- **NEW Code Reviewer agent** → starts fresh, must READ plan + code
- **NEW Tester agent** → starts fresh, must READ everything

**This Two-Agent System**:
- **Doer** creates plan → context window full of planning knowledge
- **Reviewer** reviews plan → context window full of plan knowledge
- **Doer** writes tests → **ALREADY KNOWS PLAN INTIMATELY**
- **Reviewer** reviews tests → **ALREADY KNOWS PLAN INTIMATELY**
- **Doer** implements code → **ALREADY KNOWS PLAN + TESTS INTIMATELY**
- **Reviewer** reviews code → **ALREADY KNOWS PLAN + TESTS INTIMATELY**
- **Doer** runs tests → **ALREADY KNOWS EVERYTHING INTIMATELY**

### Efficiency Gains
- ✅ Fewer context switches
- ✅ Fewer agent invocations
- ✅ No re-reading of plans/code between phases
- ✅ Deeper understanding through context persistence
- ✅ Faster iteration cycles
- ✅ Better quality through intimate knowledge
- ✅ Tests define success objectively (no subjective 10/10 debates)

### Specialization
- **Doer** = Expert in execution (planning → test design → coding → testing)
- **Reviewer** = Expert in quality (verifying completeness, correctness, test coverage, adherence)

## Test-Driven Development Benefits

### Objective Quality Gates
- Tests pass = code works
- No subjective "is this good enough?" debates
- Clear definition of done

### Early Architecture Validation
- Writing tests first forces thinking through interfaces
- Catches design problems in planning, not implementation
- Prevents over-engineering

### Built-in Regression Prevention
- Every chunk adds to test suite
- Future changes can't break existing functionality
- Confidence to refactor

### Learning Feedback Loop
- Boss finds bug? Add test case
- Next chunks inherit improved test coverage
- Workflow gets smarter over time

### Reviewer Focus Shift
- From "is this code beautiful?" (subjective)
- To "are tests comprehensive?" and "does code pass them?" (objective)
- Much faster, less bikeshedding

## Notes

- **Agents work sequentially on chunks** – complete Chunk 1 before Chunk 2
- **No parallel work** – prevents conflicts and maintains quality
- **Boss involved at: start (planning), checkpoints (every chunk), end (testing)** – agents handle implementation
- **Claude Code orchestrates** – summons agents, enforces quality gates, manages workflow
- **Context is king** – reusing agents preserves knowledge and accelerates work
- **Tests are first-class citizens** – written before code, define success, prevent regressions
- **Pragmatic quality** – 8/10 + passing tests is shippable, perfect is the enemy of done
- **Each chunk is a git commit** – easy rollback if needed
- **No hardcoding ever** – enforced at every review step# Boss's Agent Workflow

## Org Chart

```
Boss
└── Claude Code (Team Leader)
    ├── Doer (Planning, Test Design, Implementation, Testing)
    └── Reviewer (Plan Review, Test Review, Code Review)
```

## The Two-Agent System

This workflow uses **two specialized agents** that leverage context continuity:

**Doer** – Handles execution (planning → test design → implementation → testing)
- Creates the plan (context filled with planning knowledge)
- Designs test cases (already knows plan intimately)
- Implements the code (already knows plan + tests intimately)
- Runs tests to verify (already knows plan + tests + code intimately)

**Reviewer** – Handles quality assurance (plan review → test review → code review)
- Reviews the plan (context filled with plan knowledge)
- Reviews test coverage (already knows plan intimately)
- Reviews the code (already knows plan + tests intimately, can verify adherence)

**Why This Works**: Each agent maintains their context window across multiple phases, eliminating the need to re-read and re-understand work between handoffs.

## Phase 1: Planning & Preparation

### Step 1: Create Operation Folder & Planning Document
- Claude Code creates operation subfolder in `/docs/working/`
- Example: `/docs/working/{operation-name}/`
- Create main planning file: `/docs/working/{operation}/plan.md`
- This is where agents will create, review, and handover all work products

### Step 2: Deep Discussion & Analysis
- Claude Code and Boss discuss feature requirements
- Analyze every angle, consider edge cases, make bulletproof
- Go into great depth until all ambiguity is removed

### Step 3: Rough Estimate for Chunking
- Claude Code analyzes the requirement
- Get just enough sense of the work to estimate chunks
- Example: "I think this can be done in 5 chunks: database migration, backend API, frontend changes, edge functions, testing"
- This is a ROUGH estimate – Doer will refine during planning
- **Wait for Boss feedback and authorization before proceeding**

### Step 4: Update Project Documentation with Current Operation
- Claude Code adds current operation to project's working documentation
- Include: operation name, branch, operation folder path, main plan path, objective, status, chunk count
- This helps agents understand what's currently being worked on

### Step 5: Boss Authorization
- Boss reviews discussion and rough estimate
- Boss gives go-ahead to start implementation

## Phase 2: Branch Management

### Step 6: Branch Management
- Claude Code analyzes current branch situation
- Informs Boss of branch status
- Creates fresh new branch for feature work
- Branch naming: descriptive of feature (e.g., `feature/user-authentication`)

### Step 7: Project Ready
- Fresh branch created
- Ready to start implementation

## Phase 3: Chunk Breakdown

### Step 8: Break Plan Into Chunks
- Claude Code breaks implementation plan into logical chunks
- **More chunks = better** (8, 10, 12... as many as makes sense)
- **Smaller chunks get better ratings more often** – break work into focused, atomic tasks
- Each chunk should be independently testable
- Chunks should follow logical sequence (database → backend → frontend)
- Write chunk breakdown to `/docs/working/{operation}/chunks.md`

## Phase 4: Agent Deployment

### Step 9: Brief the Agents
- Claude Code briefs both agents on the operation
- Instructs agents to read:
  - **PRIORITY #1**: Entire codebase – READ THE ACTUAL CODE, not just documentation
  - All documentation in `/docs/`
  - **Especially** the operation folder `/docs/working/{operation}/`
  - **Especially** the main plan and chunk breakdown files
- **CRITICAL REMINDER TO ALL AGENTS – NO HARDCODING**:
  - ❌ NO hardcoded LLM models
  - ❌ NO hardcoded system prompts
  - ❌ NO hardcoded API endpoints
  - ❌ NO hardcoded credentials or tokens
  - ❌ NO hardcoded configuration values
  - ✅ Always use dynamic values from variables/parameters/configuration
- **SEPARATION OF CONCERNS – PRAGMATIC, NOT DOGMATIC**:
  - ✅ Apply just enough to keep code clean and minimize technical debt
  - ✅ Each module should have clear, well-defined responsibilities
  - ✅ Separate business logic from presentation where it makes sense
  - ❌ Don't over-abstract or create excessive layers
  - ❌ Don't sacrifice simplicity for architectural purity
  - Balance: Maintainable code > Perfect architecture

## Phase 5: Chunk Implementation Loop (Test-Driven Development)

For each chunk (starting with Chunk 1):

### Step 10: Doer – Create Detailed Plan with Test Cases
- Claude Code summons **Doer**
- Task: "Plan Chunk N implementation with comprehensive test cases – read actual codebase files that will be modified"
- **CRITICAL – READ ACTUAL CODEBASE**: Doer must read the ACTUAL code files that will be modified, not just rely on documentation or assumptions
- **CRITICAL – NO HARDCODING**: Doer must NOT propose hardcoded values in the plan
- **TEST-FIRST PLANNING**: Doer must define test cases that will validate the chunk:
  - Unit tests for individual functions/methods
  - Integration tests for component interactions
  - Edge case tests
  - Error condition tests
- Doer writes plan in operation folder
- Example: `/docs/working/{operation}/chunk-1-plan.md`
- Plan must include:
  - What will be built
  - Test cases that define success
  - Implementation approach
  - Files to be modified
- **Context Advantage**: Doer now has deep understanding of requirements, codebase structure, test requirements, and implementation approach in their context window

### Step 11: Reviewer – Review Plan and Test Coverage
- Claude Code summons **Reviewer**
- Task: "Review `/docs/working/{operation}/chunk-1-plan.md`, verify test coverage is comprehensive, give rating and constructive feedback"
- **CRITICAL – READ ACTUAL CODEBASE**: Reviewer must read the ACTUAL code files that will be modified
- **CRITICAL – NO HARDCODING**: Reviewer must verify the plan does NOT introduce hardcoded values
- Reviewer evaluates:
  - Clarity
  - Completeness
  - Test coverage (are all paths tested?)
  - Alignment with Boss's requirements
  - Technical soundness
  - No hardcoded values
  - Based on actual codebase, not assumptions
- **Pragmatic Quality Gate**: Rating of **8/10 or higher** to proceed
- Reviewer writes review to `/docs/working/{operation}/chunk-1-plan-review.md`
- **Context Advantage**: Reviewer now has deep understanding of the plan and test requirements in their context window

### Step 12: Plan Iteration Loop
- **If rating < 8/10**:
  - Doer reads review feedback
  - Doer revises plan
  - Reviewer reviews again
  - Repeat until ≥8/10
  - **Context Advantage**: Both agents maintain full context through iteration
- **If rating ≥ 8/10**: Proceed to Step 13

### Step 13: Doer – Write Tests First
- Claude Code summons **Doer** (same agent who created the plan)
- Task: "Write the test code for the plan you created in `/docs/working/{operation}/chunk-1-plan.md`"
- **Context Advantage**: Doer already has the plan and test requirements in their context window
- **CRITICAL – READ ACTUAL CODEBASE**: Doer must read the ACTUAL code files to understand testing patterns and structure
- **TDD Approach**:
  - Write test code first
  - Tests should fail initially (nothing implemented yet)
  - Tests define the contract/interface
  - Tests cover happy path, edge cases, and error conditions
- Doer documents what tests were created

### Step 14: Reviewer – Review Tests
- Claude Code summons **Reviewer** (same agent who reviewed the plan)
- Task: "Review the test code against the plan you approved in `/docs/working/{operation}/chunk-1-plan.md`"
- **Context Advantage**: Reviewer already has the plan and test requirements in their context window
- **CRITICAL – READ ACTUAL TEST CODE**: Reviewer must read the ACTUAL test files
- Reviewer evaluates:
  - Tests match approved plan
  - Test coverage is comprehensive
  - Tests are well-structured
  - Tests will actually validate the requirements
  - No hardcoded values in tests
- **Pragmatic Quality Gate**: Rating of **8/10 or higher** to proceed
- Reviewer writes review to `/docs/working/{operation}/chunk-1-test-review.md`

### Step 15: Test Review Loop
- **If rating < 8/10**:
  - Doer reads review feedback
  - Doer fixes test issues
  - Reviewer reviews again
  - Repeat until ≥8/10
- **If rating ≥ 8/10**: Proceed to Step 16

### Step 16: Doer – Implement Code to Pass Tests
- Claude Code summons **Doer** (same agent who wrote the tests)
- Task: "Implement the code to make your tests pass"
- **Context Advantage**: Doer already has plan + tests in their context window – knows exactly what needs to be built
- **CRITICAL – READ ACTUAL CODEBASE**: Doer must read the ACTUAL code files being modified
- **CRITICAL – NO HARDCODING**: Doer must NOT write hardcoded values
- **TDD Approach**:
  - Run tests first (verify they fail)
  - Implement code to make tests pass
  - Refactor if needed
  - All tests must pass
- Doer documents what was changed

### Step 17: Reviewer – Review Code
- Claude Code summons **Reviewer** (same agent who reviewed plan and tests)
- Task: "Review the code implementation against the plan and tests you approved"
- **Context Advantage**: Reviewer already has plan + tests in their context window – knows exactly what was promised
- **CRITICAL – READ ACTUAL CODE**: Reviewer must read the ACTUAL modified code files
- **CRITICAL – NO HARDCODING**: Reviewer must verify the code does NOT contain hardcoded values
- **CRITICAL – AUDIT ALL FILES**: Check every modified file for hardcoded strings, even in unexpected places
- Reviewer evaluates:
  - Code matches approved plan
  - Tests pass
  - Code quality
  - Security
  - Architecture alignment
  - Pragmatic separation of concerns (clear responsibilities, minimal technical debt)
  - No additions beyond requirements
  - No hardcoded values anywhere
  - Based on actual code files
- **Pragmatic Quality Gate**: Rating of **8/10 or higher, AND all tests pass** to proceed
- Reviewer writes review to `/docs/working/{operation}/chunk-1-code-review.md`

### Step 18: Code Review Loop
- **If rating < 8/10 OR tests fail**:
  - Doer reads review feedback
  - Doer fixes issues
  - Reviewer reviews again
  - Repeat until ≥8/10 AND tests pass
  - **Context Advantage**: Both agents maintain full context through iteration
- **If rating ≥ 8/10 AND tests pass**: Proceed to Step 19

### Step 19: Doer – Run Full Test Suite
- Claude Code summons **Doer** (same agent who implemented the code)
- Task: "Run full test suite to ensure no regressions"
- **Context Advantage**: Doer already has plan + tests + implementation in their context window
- Doer verifies:
  - All new tests pass
  - All existing tests still pass (no regressions)
  - Build succeeds
  - No compilation/runtime errors
- Doer documents test results

### Step 20: Commit Changes
- Claude Code commits the chunk changes to git
- Commit message format: "Chunk X: [brief description]"
- Example: "Chunk 1: Database Schema – Add user authentication tables"
- Include co-author line: `Co-Authored-By: Claude <noreply@anthropic.com>`

### Step 21: Boss Checkpoint Review (Every Chunk)
- After EVERY chunk, Claude Code notifies Boss
- Boss does quick checkpoint review:
  - Test the implemented chunk
  - Verify direction is correct
  - Provide course corrections if needed
- If changes needed, create mini-chunks for adjustments
- Prevents any drift from Boss's vision

### Step 22: Chunk Complete
- Chunk N marked complete
- **Immediately start Chunk N+1** without waiting for Boss permission
- **Context Advantage**: Doer carries forward understanding from previous chunks
- Repeat Steps 10-21 for each chunk

## Phase 6: Integration Testing

### Step 23: Doer – Run Integration Tests
- Claude Code summons **Doer**
- Task: "Run integration tests across all chunks"
- Tests verify:
  - All chunks work together correctly
  - No conflicts between chunks
  - End-to-end workflows function
  - Performance is acceptable
- Doer documents integration test results

### Step 24: Fix Integration Issues
- If integration tests reveal issues:
  - Doer creates fix plan
  - Reviewer reviews fix plan
  - Doer implements fixes
  - Reviewer reviews fixes
  - Rerun integration tests
- Repeat until all integration tests pass

## Phase 7: Completion & Handoff

### Step 25: All Chunks Complete
- Claude Code declares to Boss: "Everything is ready for your human testing"

### Step 26: Provide Clear Test Instructions
- Claude Code tells Boss in clear steps:
  - What to test
  - How to test it
  - What success looks like
  - What edge cases to verify
  - How to run automated tests

Example test steps:
```
1. Run automated test suite: `npm test`
2. Verify all tests pass
3. Manual testing steps:
   a. [Specific action to test]
   b. [Expected result]
   c. [Edge case to verify]
4. Check logs for errors
5. Verify no regressions in existing features
```

## Quality Gates (Enforced at Each Step)

- **Planning**: Reviewer must give ≥8/10
- **Tests**: Reviewer must give ≥8/10
- **Code**: Reviewer must give ≥8/10 AND all tests must pass
- **Integration**: All integration tests must pass
- **No scope creep**: Agents cannot add features beyond Boss requirements
- **No hardcoding**: Agents must never hardcode values

## Success Criteria

✅ All chunks implemented
✅ All quality gates passed (≥8/10)
✅ All tests passing (unit, integration, regression)
✅ Boss checkpoint reviews passed
✅ Boss final testing complete
✅ Feature works as specified
✅ No regressions in existing functionality
✅ No hardcoded values anywhere

## Why Two Agents Work Better

### Context Continuity
**Old Multi-Agent System**:
- Planner creates plan → context window full of planning knowledge
- **NEW Coder agent** → starts fresh, must READ the plan.md file
- **NEW Code Reviewer agent** → starts fresh, must READ plan + code
- **NEW Tester agent** → starts fresh, must READ everything

**This Two-Agent System**:
- **Doer** creates plan → context window full of planning knowledge
- **Reviewer** reviews plan → context window full of plan knowledge
- **Doer** writes tests → **ALREADY KNOWS PLAN INTIMATELY**
- **Reviewer** reviews tests → **ALREADY KNOWS PLAN INTIMATELY**
- **Doer** implements code → **ALREADY KNOWS PLAN + TESTS INTIMATELY**
- **Reviewer** reviews code → **ALREADY KNOWS PLAN + TESTS INTIMATELY**
- **Doer** runs tests → **ALREADY KNOWS EVERYTHING INTIMATELY**

### Efficiency Gains
- ✅ Fewer context switches
- ✅ Fewer agent invocations
- ✅ No re-reading of plans/code between phases
- ✅ Deeper understanding through context persistence
- ✅ Faster iteration cycles
- ✅ Better quality through intimate knowledge
- ✅ Tests define success objectively (no subjective 10/10 debates)

### Specialization
- **Doer** = Expert in execution (planning → test design → coding → testing)
- **Reviewer** = Expert in quality (verifying completeness, correctness, test coverage, adherence)

## Test-Driven Development Benefits

### Objective Quality Gates
- Tests pass = code works
- No subjective "is this good enough?" debates
- Clear definition of done

### Early Architecture Validation
- Writing tests first forces thinking through interfaces
- Catches design problems in planning, not implementation
- Prevents over-engineering

### Built-in Regression Prevention
- Every chunk adds to test suite
- Future changes can't break existing functionality
- Confidence to refactor

### Learning Feedback Loop
- Boss finds bug? Add test case
- Next chunks inherit improved test coverage
- Workflow gets smarter over time

### Reviewer Focus Shift
- From "is this code beautiful?" (subjective)
- To "are tests comprehensive?" and "does code pass them?" (objective)
- Much faster, less bikeshedding

## Notes

- **Agents work sequentially on chunks** – complete Chunk 1 before Chunk 2
- **No parallel work** – prevents conflicts and maintains quality
- **Boss involved at: start (planning), checkpoints (every chunk), end (testing)** – agents handle implementation
- **Claude Code orchestrates** – summons agents, enforces quality gates, manages workflow
- **Context is king** – reusing agents preserves knowledge and accelerates work
- **Tests are first-class citizens** – written before code, define success, prevent regressions
- **Pragmatic quality** – 8/10 + passing tests is shippable, perfect is the enemy of done
- **Each chunk is a git commit** – easy rollback if needed
- **No hardcoding ever** – enforced at every review step