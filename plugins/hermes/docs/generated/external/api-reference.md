---
type: api-reference
audience: external
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# API Reference

## Overview

Hermes does not expose a traditional HTTP API, REST endpoints, or programmatic library interface. It operates as a **Claude Code skill** — a markdown-based instruction set that Claude Code follows when invoked through natural language.

The "API" for Hermes is its invocation interface: natural language commands within a Claude Code session.

## Invocation Interface

### Generate (Full Project)

Generates documentation for all three audiences across the entire project.

**Invocations:**
```
"Generate docs for this project"
"Document this project"
"Generate documentation"
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| Project path | implicit | Yes | The current working directory in the Claude Code session |
| Context files | string list | No | Additional files to include: "also use competitive-analysis.md" |

**Output:** All 17 doc types written to `docs/generated/`

---

### Update (Delta)

Generates documentation only for features that changed since the last run.

**Invocations:**
```
"Update docs"
"Document what changed"
"Update docs since v1.0"
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| Since timestamp | auto-detected | No | Read from `.hermes.md`; or version tag if specified |

**Output:** Updated docs for changed features only

---

### Internal Only

Generates only internal documentation (CS/Support/Engineering).

**Invocations:**
```
"Generate internal docs"
"CS documentation"
"Support docs"
```

**Output:** Feature Handoffs, Use Cases, Troubleshooting Guides, Release Notes, FAQ, Glossary

---

### External Only

Generates only external documentation (developers/end users).

**Invocations:**
```
"Generate external docs"
"API docs"
"User documentation"
```

**Output:** Feature Docs, Getting Started, API Reference, Config Reference, Error Reference, Changelog, Migration Guide

---

### Marketing Only

Generates only marketing documentation (product marketing/sales).

**Invocations:**
```
"Generate marketing docs"
"Feature briefs"
"Product datasheet"
```

**Output:** Feature Briefs, Release Announcements, Product Datasheet, Sales One-Pagers

## Output Format

All output is markdown with YAML frontmatter. Every generated document includes:

```yaml
---
id: {document-id}
type: {document-type}
audience: {internal|external|marketing}
topic: {feature-or-topic-name}
status: draft
generated: {YYYY-MM-DD}
source-tier: {carto|direct|context}
hermes-version: 1.0.0
---
```

## Limitations

- No programmatic API — Hermes is invoked through natural language only
- No webhook or CI/CD trigger — manual invocation required (CI/CD hooks are planned for v2.0)
- No streaming output — docs are written to disk after generation completes for each audience
- No query interface — you cannot ask Hermes about previously generated docs; use the file system or Memories MCP
