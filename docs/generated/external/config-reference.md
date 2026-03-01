---
type: config-reference
audience: external
status: draft
generated: 2026-02-28
source-tier: direct
hermes-version: 1.0.0
---

# Configuration Reference

## Configuration File

Hermes uses a disk-based state file for tracking generation state:
```
docs/generated/.hermes.md
```

This file is automatically created and managed by Hermes. You do not need to edit it manually, but understanding its structure is useful for debugging and advanced usage.

## Environment Variables

Hermes does not use environment variables. All configuration is implicit through natural language invocations and the state file.

## Options

### State File (.hermes.md)

The state file tracks generation configuration, discovered features, and per-audience progress.

#### `source-tier`
- **Type:** string (enum)
- **Default:** auto-detected
- **Required:** No (auto-populated)
- **Description:** The input quality tier used for generation. Determined automatically based on what is available.
- **Valid values:** `carto`, `direct`, `context`
- **Example:**
  ```markdown
  - Source tier: direct
  ```
- **Notes:** Cannot be set manually. Hermes checks for Carto index first, then falls back to direct codebase reading.

#### `context-files`
- **Type:** string list
- **Default:** auto-discovered
- **Required:** No
- **Description:** Additional context files used during generation. Auto-discovered from standard locations, or specified by the user in the invocation.
- **Example:**
  ```markdown
  - Context files: [VISION.md, hermes-design.md, .apollo.yaml]
  ```
- **Notes:** To add context files, specify them in your invocation: "Generate docs, also use my-file.md"

#### `hermes-version`
- **Type:** string (semver)
- **Default:** current version
- **Required:** No (auto-populated)
- **Description:** The version of Hermes that performed the generation. Useful for tracking when docs need regeneration after a Hermes upgrade.
- **Example:**
  ```markdown
  - Hermes version: 1.0.0
  ```

### Feature Table

#### `features`
- **Type:** markdown table
- **Default:** populated by feature discovery
- **Required:** No (auto-populated)
- **Description:** Lists all discovered features with their component count and generation status.
- **Example:**
  ```markdown
  | Feature | Components | Status |
  |---------|-----------|--------|
  | multi-audience-generation | 1 file | complete |
  | mode-system | 1 file | pending |
  ```
- **Notes:** Status values: `pending` (not started), `in-progress` (interrupted), `complete` (done)

### Generation Progress

#### `audience-status`
- **Type:** per-audience string
- **Default:** `pending`
- **Required:** No (auto-populated)
- **Description:** Tracks generation progress for each audience independently. Enables resume on interrupted runs.
- **Example:**
  ```markdown
  - Internal: complete
  - External: in-progress
  - Marketing: pending
  ```
- **Notes:** `in-progress` means generation was interrupted for that audience. Hermes will regenerate the entire audience on resume.

#### `last-generated`
- **Type:** ISO 8601 timestamp
- **Default:** `never`
- **Required:** No (auto-populated)
- **Description:** When the last complete generation occurred. Used by Update mode to determine the delta window.
- **Example:**
  ```markdown
  - Last generated: 2026-02-28T14:30:00Z
  ```
- **Notes:** Only updated when all audiences complete. Partial runs do not update this timestamp.

### Document Frontmatter

Every generated document includes YAML frontmatter with these fields:

#### `id`
- **Type:** string
- **Description:** Unique identifier for the document within its type (e.g., `fh-001`, `feat-002`, `fb-003`)

#### `type`
- **Type:** string
- **Description:** Document type (e.g., `feature-handoff`, `changelog`, `feature-brief`)

#### `audience`
- **Type:** string
- **Description:** Target audience: `internal`, `external`, or `marketing`

#### `topic`
- **Type:** string
- **Description:** The feature or topic this document covers

#### `status`
- **Type:** string
- **Default:** `draft`
- **Description:** Document lifecycle status. All generated docs start as `draft`.

#### `generated`
- **Type:** date (YYYY-MM-DD)
- **Description:** When this document was generated

#### `source-tier`
- **Type:** string
- **Description:** Input tier used: `carto`, `direct`, or `context`

#### `hermes-version`
- **Type:** string
- **Description:** Hermes version that generated this document
