# Over-Implementation Review Mode

> Standalone mode for a diff or PR. It evaluates whether the change exceeds the
> minimal sufficient solution. It does not look for ordinary bugs and does not
> edit code unless the user explicitly asks for fixes.

```text
Execute an over-implementation review for the current diff or PR.

Scope:
- Review only non-generated code introduced or expanded by this change.
- Ignore vendor and generated code.
- Historical debt counts only when this change expands it.
- Do not classify naming style, small readability improvements, or local
  cleanup as over-implementation unless the change adds extra semantics,
  extension points, configuration, runtime paths, or test burden.

Step 1: Anchor the minimal sufficient solution.
- Real problem or requirement:
- Evidence, such as error text, requirement, test name, commit message, or
  changed path:
- Evidence coverage:
- Minimal sufficient change, or "cannot precisely anchor":

Step 2: Ask why each extra piece exists.
- What future or "just in case" scenario does it assume?
- Can that scenario happen in this system's real semantics and deployment?

Check categories:
- Speculative expansion: code for unproven fields, paths, callers, or scenarios.
- Excessive defense: impossible null/value/concurrency combinations, unrealistic
  numeric scale, or configurable knobs that can be constants.
- Excess abstraction: one-production-implementation interfaces outside real
  runtime boundaries such as storage, RPC, cache, third party, time, or random.
- Excess configuration: pseudo-config where environment values are identical.
- Excess testing: production seams or guards that exist only for tests.
- Excess comments: comments that restate obvious code instead of invariants or
  surprising tradeoffs.
- Excess mechanism: state machines, compensation frameworks, retry systems, or
  routing layers before weighing impact and reversibility.

Judgment discipline:
- Necessary defense is not over-implementation when the boundary is real:
  money, untrusted input, external systems, and true concurrency deserve guards.
- Multi-instance, multi-team, high-scale, or future-product assumptions need
  explicit evidence unless the changed path is already that boundary.
- Some forward compatibility is valid when it is an explicit contract or hard to
  retrofit later.

Output format:

## Minimal Sufficient Solution
- Real problem:
- Evidence:
- Evidence coverage:
- Minimal sufficient change:

## Findings
### N. [Remove / Simplify / Keep] Title
- Location: file:line
- Extra code:
- Assumed future or edge case:
- Whether it is realistic in this system:
- Minimal sufficient solution:
- Consequence and reversibility of removal/simplification:

## Conclusion
- Remove:
- Simplify:
- Keep:

If no clear over-implementation exists, output "No over-implementation found"
and list the minimal sufficient solution you compared against.
```
