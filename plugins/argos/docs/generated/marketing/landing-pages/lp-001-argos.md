# Argos Landing Page Copy

---

## Hero Section

### Headline
Your GitHub issues, handled -- before you even open the tab.

### Subheadline
Argos is a Claude Code plugin that watches your repos for new issues, investigates them against your local codebase, and takes action within boundaries you define.

### CTA
Get started with `/watch owner/repo`

---

## Problem Section

### Heading
Issue triage is eating your mornings.

### Body
New issues arrive overnight. You scan each one, check if it is a duplicate, trace through the codebase to understand the impact, then label it and assign it. Fifteen minutes per issue. Five issues a day. That is over an hour of context-switching before you write a line of code.

Server-side tools can auto-label, but they cannot read your codebase. They do not know which files are fragile, which bugs keep recurring, or what a fix looks like. The real investigation still falls on you.

---

## Features Section

### Heading
What Argos does while you are not looking.

### Feature 1: Zero-Cost Until It Matters
Argos polls your repos using bash and the GitHub CLI -- no LLM involved. Filtering happens in `jq`. Zero new issues? The cycle exits immediately with zero tokens consumed. At 5-minute intervals across 10 repos, that is 2,880 daily polls that cost nothing. The LLM only activates when an issue actually needs attention. No webhook server, no cloud function, no always-on infrastructure.

### Feature 2: Investigates Locally
Unlike server-side tools, Argos reads your actual codebase. It traces through files, identifies affected functions, checks for duplicates against resolution history, and builds a diagnosis -- the same work you would do, done before you arrive.

### Feature 3: Acts Within Your Rules
A YAML policy file defines three tiers: auto (execute immediately), approve (queue for your review), and deny (never). You control which actions are hands-free, which need a sign-off, and which are forbidden. Hard guardrails cap actions per hour, limit open PRs, and protect sensitive files.

### Feature 4: Learns Over Time
Argos uses Memories MCP to persist patterns across sessions. It remembers past resolutions, recognizes duplicate clusters, and learns codebase hotspots. Every week it watches, it gets more accurate.

### Feature 5: Stays Safe
Rate limits, protected file paths, maximum concurrent PRs, and dry-run mode ensure Argos operates within safe bounds. These guardrails are enforced at the system level -- they apply regardless of policy settings.

---

## How It Works

### Heading
One command. Full control.

### Step 1: Watch
Run `/watch owner/repo`. Argos walks you through a guided setup: which labels to monitor, which actions to automate, how you want to be notified.

### Step 2: Configure
Argos generates a YAML policy file. Review it, adjust the tiers, set your guardrails. Run a dry cycle to see what would happen without any actions being taken.

### Step 3: Let It Work
Argos begins polling. New issues get classified, labeled, and investigated. Actions in the auto tier execute immediately. Actions in the approve tier wait for your `/argos-approve` command. Everything is logged, everything is auditable.

### Step 4: Review
Run `/argos-status` anytime to see watched repos, queue depth, and recent actions. Run `/argos-approve` to review pending items. Adjust your policy as you build trust.

---

## Comparison Section

### Heading
Built different from server-side tools.

| | Argos | Webhook Bots | GitHub Actions | LLM Pollers |
|---|---|---|---|---|
| Idle cost | **Zero tokens** | Server uptime | Minutes consumed | Tokens every cycle |
| Infrastructure | None | Server + endpoint + TLS | GitHub runners | LLM API + scheduler |
| Local codebase access | Full | None | Checkout only | Depends |
| Inbound attack surface | None | Webhook endpoint | None | None |
| Proactive monitoring | Yes | Yes | Event-driven | Yes |
| Configurable autonomy tiers | Yes | No | No | No |
| Cross-session learning | Yes | No | No | No |

---

## Trust Section

### Heading
Your code never leaves your machine.

### Body
Argos runs entirely inside Claude Code. It polls via the GitHub CLI and investigates using your local files. No source code is sent to external services beyond your existing Claude Code configuration. Policy files are local YAML. State is local JSON. Memories stay in your Memories MCP instance. You have full visibility into every action Argos takes.

---

## CTA Section

### Heading
Stop triaging. Start building.

### Body
Install the Argos plugin, run `/watch owner/repo`, and let your issues handle themselves -- within the boundaries you set.

### Primary CTA
Get started with Argos

### Secondary Link
Read the design document for full technical details.
