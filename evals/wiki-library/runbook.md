# wiki-library Eval Runbook

## Evaluation Status

All scenarios default to `not_run`. Change a result to `pass` or `fail` only after saving the real output and checking every assertion.

## Isolated Runs

1. Create an independent temporary project with an empty `wiki/` for each run.
2. Run the ordinary-source scenario once with the baseline `wiki-ingest` and once with `wiki-library`. Compare entity selection, categories, page templates, `index.md`, `log.md`, and double links.
3. Run each AI module scenario with the baseline as a control and `wiki-library` as the candidate. Preserve the complete output from every run.
4. Use a fresh agent or task for every run. Provide only the prompt, fixture, Skill, and isolated output path; do not reveal the success assertions or expected answer.
5. Follow the `skill-creator` review process to generate a viewer so the user can inspect real outputs before assertions are scored.
6. Record only `pass`, `fail`, or `not_run` for each scenario.

## Assertions

### Ordinary source regression

Confirm that baseline and candidate outputs are equivalent in knowledge entity selection, category placement, template structure, double links, `index.md`, and `log.md` behavior.

### Single authoritative module

Confirm that the candidate requires both the `claudedocs/` location and `doc_type: ai-module-spec`, links the source with a resolvable relative Markdown path, and does not reproduce detailed contracts, file lists, test evidence, or risks.

### Multi-module synthesis

Confirm that any independently useful synthesis remains in one of the original four categories, links both authoritative module documents, and introduces no new page type, Wiki directory, or log field.
