# SR Design Gate Visual Companion

Use visuals only when they make a design decision easier to judge than prose.

## Use Visuals For

- admin UI layout, navigation, form, table, and interaction comparisons
- permission/menu flow maps
- lifecycle, state-machine, sequence, and data-flow diagrams
- architecture boundary diagrams
- before/after UI behavior that would be ambiguous in text

## Avoid Visuals For

- plain requirements questions
- backend-only API trade-offs
- schema field naming unless relationship shape matters
- text tables of pros and cons
- questions where the answer is a product rule, not a spatial or visual judgment

## Default Tools

Prefer the cheapest useful representation:

1. Mermaid in the conversation for state, sequence, flow, and architecture diagrams.
2. Browser skill with a temporary local HTML mockup for UI choices or clickable comparisons.
3. Screenshot review only when the user supplies or requests a visual artifact.

Keep temporary visual files outside the repo unless the user explicitly wants them committed.

## Consent Prompt

Before starting browser-based visual work, ask once:

```text
Some of this may be easier to judge visually. I can show diagrams or mockups in the browser as we go. Want to use that, or keep this text-only?
```

If the user declines, continue text-only.

## Per-Step Test

Before each visual step, ask internally:

```text
Would the user understand or decide this better by seeing it?
```

If the answer is no, keep the design gate in the conversation.
