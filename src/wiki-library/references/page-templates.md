# Wiki Page Templates

When an entity is already documented by an authoritative `claudedocs` file with `doc_type: ai-module-spec`, keep the matching template but fill it minimally. Preserve the entity definition, Wiki context, Related Pages, and Sources; link the module document with a relative Markdown link resolved from the current Wiki page instead of duplicating its detailed contracts, file lists, tests, or risks.

## Concept Page (concepts/)

```markdown
# Page Title

> One-line definition

## Key Points
(3-5 points, 1-2 sentences each)

## Details
(Expanded explanation, may include subsections)

## Context
(Which articles/documents it appears in, what role it plays)

## Related Pages
- [[related-concept]]

## Sources
- Article/Document X: specific reference point
```

## Product Page (products/)

```markdown
# Product Name

> One-line positioning

## Core Capabilities
(3-5 key features)

## Technical Highlights
(Architecture, implementation approach, etc.)

## Use Cases
(When to use it)

## Related Pages
- [[related-product]]
- [[related-concept]]

## Sources
- Article/Document X: specific reference point
```

## Pattern Page (patterns/)

```markdown
# Pattern Name

> One-line summary of what problem this pattern solves

## Problem Context
(When you need this pattern)

## Solution
(Core approach of the pattern)

## Trade-offs
(What you give up by using this pattern)

## Related Pages
- [[related-pattern]]
- [[related-concept]]

## Sources
- Article/Document X: specific reference point
```

## Comparison Page (comparisons/)

```markdown
# A vs B

> One-line summary of the core difference

## Comparison

| Dimension | A | B |
|-----------|---|---|
| ... | ... | ... |

## Strengths of Each

## Selection Guide
(When to choose A, when to choose B)

## Related Pages
- [[A]]
- [[B]]

## Sources
- Article/Document X: specific reference point
```
