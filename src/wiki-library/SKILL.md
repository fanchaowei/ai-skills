---
name: wiki-library
description: "Compile articles, documents, or notes into a structured wiki knowledge base, and preserve links to authoritative AI module docs instead of duplicating their details. Use when the user asks to create or update a wiki/library, ingest content, compile a knowledge base, add material to a wiki, or invokes /wiki-library. Supports single or batch ingest. Triggers: wiki, library, ingest, knowledge base, compile, digest, index, catalog."
---

# Wiki Library — Knowledge Base Compiler

Compile any text content (articles, documents, notes) into structured wiki pages with cross-references, building a searchable, interconnected knowledge network.

IRON LAW: One wiki page = one knowledge entity. Never cram multiple concepts into one page.

## Wiki Directory Structure

Wiki defaults to `wiki/` under the current project root. User may specify a different path.

```
wiki/
├── index.md              # Full table of contents
├── log.md                # Append-only operation log
├── concepts/             # Core concept pages
├── products/             # Product/tool entity pages
├── patterns/             # Engineering patterns & design decisions
└── comparisons/          # Cross-topic comparison pages
```

## Workflow

### 1. Confirm Input

Accept user-specified content source:
- Pasted text directly
- File path(s) (md, txt, pdf, etc.)
- Directory path (batch processing)

If user doesn't specify a wiki path, use `wiki/`. Create the directory if it doesn't exist.

When an input file is under an owner's `claudedocs/` directory and its YAML frontmatter contains `doc_type: ai-module-spec`, treat it as an authoritative AI module document. Both conditions are required. Other sources continue through the original workflow unchanged.

### 2. Check Existing Wiki

Read `wiki/index.md` (if exists) to understand existing pages and avoid duplicates.

### 3. Extract Knowledge Entities

Extract from content:
- **Concepts** (`concepts/`): Abstract ideas, terminology, theories
- **Products** (`products/`): Specific products, tools, services
- **Patterns** (`patterns/`): Engineering patterns, design decisions, methodologies
- **Comparisons** (`comparisons/`): Cross-product or cross-approach analysis

Extraction threshold: An entity deserves its own page only if it would be referenced by other pages.

For authoritative AI module documents, apply the same entity categories and extraction threshold, but do not turn module-internal details into duplicate Wiki content. If a candidate only restates one module document and does not deserve its own entity page, link the source document from the relevant index or existing page. If multiple module documents support an independently useful concept, product, pattern, or comparison, create that entity under the existing categories.

### 4. Create or Update Pages

Each entity maps to one wiki page.

→ Load [references/page-templates.md](references/page-templates.md) for page templates.

Rules:
- If page already exists → **update** it, append new information, don't overwrite existing content
- Keep the one-line definition stable unless the new content provides a clearly better one
- Prioritize updating "Sources" and "Related Pages" sections

When an entity is backed by an authoritative AI module document, keep only the minimum definition, cross-entity context, reading guidance, Related Pages, and source links needed by the Wiki. Do not copy detailed APIs, full feature/file/symbol lists, verification evidence, or risk matrices already maintained by the module document. A thin page still uses its existing concept, product, pattern, or comparison template and directory.

### 5. Update Cross-References

Check all existing wiki pages. If new content involves concepts referenced in other pages:
- Update their Related Pages list
- Update their Sources list
- Supplement new information in their detail sections

For authoritative AI module documents, use a relative Markdown link in Sources, resolved from the current Wiki page, so readers can open the source document. A stable heading anchor may be used near a key synthesized conclusion, but do not invent anchors or cite every sentence.

### 6. Update index.md

Add new page entries to `wiki/index.md`, organized by category.

### 7. Append to log.md

Append to `wiki/log.md`:

```markdown
## YYYY-MM-DD: Ingest <source title>

**Source**: <file path or "user input">
**New pages**: list newly created pages
**Updated pages**: list modified pages
**New cross-references**: list newly established links
```

### 8. Report Results

Tell user: what pages were created, what pages were updated, what new cross-references were established.

## File Naming

- All lowercase, hyphen-separated: `agent-loop.md`, `kv-cache.md`
- Name by entity, not by number

## Cross-Reference Format

- Use `[[category/page-name]]` double-link format (Obsidian-compatible), e.g. `[[concepts/agent-loop]]`, `[[products/claude-code]]`
- Always include the category prefix to avoid ambiguity across directories
- List all related pages at the bottom of each page
- Link authoritative AI module documents with a Markdown path relative to the current Wiki page, for example `[ManagePageNavigation](../../apps/config-manage-system/claudedocs/modules/ManagePageNavigation.md)`.
- Use a heading anchor only when the source heading is stable; source links are required for these module documents, sentence-by-sentence citations are not.

## Guidelines

- Never create duplicate pages — always check wiki/ first
- Don't extract trivial entities — if a concept appears once and won't be referenced elsewhere, skip it
- For batch processing: extract all entities first, then create pages and update references in one pass to avoid inconsistent intermediate states
- Always update index.md and log.md after every ingest
