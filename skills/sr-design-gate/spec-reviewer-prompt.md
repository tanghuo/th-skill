# SR Design Gate Spec Reviewer Prompt

Use this when a serious design needs a focused second pass before implementation planning.

Replace bracketed fields before dispatching or pasting.

```text
You are reviewing a design artifact before implementation planning.

Design artifact:
[DESIGN_FILE_OR_ARTIFACT]

Repo context:
[REPO_PATH_AND_RELEVANT_MODULES]

Risk focus:
[MONEY | PERMISSIONS | SCHEMA | PROTO | OPENAPI | FRONTEND_BACKEND_CONTRACT | LIFECYCLE | ASYNC_RECOVERY | EXTERNAL_PROVIDER | OTHER]

Review only for material issues that could cause wrong implementation, unsafe rollout, or likely rework.

Check:

1. Completeness
   - Are there missing requirements, source-of-truth definitions, rollout steps, validation steps, or ownership boundaries needed for planning?

2. Consistency
   - Do goals, non-goals, data model, contracts, write paths, read paths, and rollout guidance contradict each other?

3. Clarity
   - Could a reasonable implementer interpret any requirement in two incompatible ways?

4. Scope
   - Is P1 separate from P2/future work?
   - Is this focused enough for implementation planning, or should it be decomposed first?

5. Repo alignment
   - Does the design match current code/schema/proto/OpenAPI/docs facts supplied in the artifact?
   - If verification against the repo is required but not supplied, mark it as "needs verification" instead of assuming.

6. Validation
   - Are acceptance criteria and test/verification commands strong enough for the risk?

Output:

Status: Approved | Issues Found

Material Issues:
- [Severity] [Section or anchor]: [issue]
  Why it matters:
  Required fix:

Advisory Notes:
- [Non-blocking suggestion, if any]

Do not flag wording preferences, optional examples, or style issues unless they would change implementation behavior.
```
