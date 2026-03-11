# Marketing Document Templates

Templates for product marketing, sales, and content teams.

**Voice:** Confident, benefit-focused, concise. Product-centric ("Now you can...", "{Product} enables..."). Reader cares about outcomes, not mechanisms. Value over detail — every sentence should answer "so what?"

---

## Feature Brief (Keystone Document)

**File:** `docs/generated/marketing/feature-briefs/fb-{NNN}-{slug}.md`

This is the **keystone document** — other marketing docs derive from it.

~~~markdown
---
id: fb-{NNN}
type: feature-brief
audience: marketing
topic: {feature-name}
status: draft
generated: {date}
source-tier: {tier}
context-files: [{list}]
hermes-version: 1.0.1
---

# Feature Brief: {Feature Name}

## One-Liner
{Single sentence — what it is and why it matters. Usable as a tagline or email subject.}

## What It Is
{2-3 sentences in non-technical language. A product marketer should be able to read this and immediately understand the feature without any engineering background.}

## Who It's For
{Target personas or segments. Be specific:
- **Primary:** {who benefits most — role, company size, use case}
- **Secondary:** {who else benefits}}

## The Problem It Solves
{In the customer's language — what pain they feel today that this feature addresses. Frame as a story, not a spec:
"Teams currently have to manually X every time they Y, which takes Z hours and often leads to errors..."}

## Key Benefits
{3-5 benefits — outcome-focused, not feature-focused:
- **{Benefit headline}:** {1-sentence elaboration}
Repeat for each benefit.}

## How It Works (Simplified)
{Non-technical explanation. Enough for marketing to understand and explain, not enough to implement. Use analogies if helpful. 3-5 sentences max.}

## Competitive Context
{How this compares to alternatives — only populated if context files provide competitive info:
- **vs. {Competitor}:** {our advantage}
If no competitive context available, state: "Competitive positioning requires additional context — provide competitive analysis docs to populate this section."}

## Proof Points
{Metrics, benchmarks, or evidence of value. Only populated if available from context:
- {proof point}
If none available, state: "Proof points require usage data or customer feedback to populate."}

## Suggested Messaging
{2-3 ready-to-use messages for different contexts:
- **Announcement:** {for blog post, email, or social media}
- **Sales pitch:** {for sales conversations}
- **One-liner:** {for landing pages or feature lists}}
~~~

---

## Product Datasheet

**File:** `docs/generated/marketing/datasheet.md`

~~~markdown
---
id: ds-001
type: datasheet
audience: marketing
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# {Product Name} — Product Datasheet

## Overview
{2-3 sentence product description — what it is, who it's for, primary value proposition}

## Key Capabilities
{Bulleted list of major features, grouped by category if >10 items:
### {Category}
- {Capability}: {1-sentence description}}

## Technical Specifications
| Spec | Value |
|------|-------|
| Language/Runtime | {from package manifest} |
| Supported Platforms | {from code/config} |
| API Style | {REST/GraphQL/gRPC/CLI — from code} |
| Authentication | {auth methods — from code} |
| Data Storage | {database type — from config/code} |

## Dependencies
{Key runtime dependencies — not dev dependencies:
| Dependency | Version | Purpose |
|-----------|---------|---------|
| ... | ... | ... |}

## Integrations
{List of supported integrations, derived from code:
- **{Integration}:** {what it enables}}

## Deployment Options
{How it can be deployed:
- {option}: {brief description}}

## Security & Compliance
{Security features derived from code — auth methods, encryption, audit logging.
Compliance certs only if documented in context files.}

## System Requirements
{Minimum requirements from docs, config, or Dockerfile:
| Requirement | Minimum |
|------------|---------|
| ... | ... |}
~~~

---

## Release Announcement

**File:** `docs/generated/marketing/release-announcements/ra-v{version}.md`

~~~markdown
---
id: ra-v{version}
type: release-announcement
audience: marketing
version: {version}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# {Product Name} v{version}: {Headline}

## The Headline
{One compelling sentence — what's the most exciting thing in this release. Usable as email subject, social post, or blog title.}

## What's New
{For each notable feature/improvement — user-benefit language:

### {Feature Name}
{2-3 sentences: what it enables, who benefits, why it matters. No technical jargon.}

**Key benefit:** {single sentence — the "so what?"}
}

## Improvements
{Bulleted list of quality-of-life improvements — brief:
- {improvement}: {benefit}}

## Getting Started
{How to access the new features — upgrade instructions, links to docs:
- Existing users: {upgrade path}
- New users: {getting started link}}

## What's Next
{Brief preview of upcoming work — builds anticipation without committing:
"We're working on {X} and {Y} — stay tuned."}
~~~

---

## Sales One-Pager

**File:** `docs/generated/marketing/one-pagers/op-{NNN}-{slug}.md`

~~~markdown
---
id: op-{NNN}
type: one-pager
audience: marketing
topic: {feature-or-product}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# {Feature/Product Name}

## The Problem
{2-3 sentences describing the pain point — in the prospect's language}

## The Solution
{2-3 sentences describing how {product/feature} solves it — benefit-focused}

## Key Benefits
{3-4 benefits with proof points:
- **{Benefit}:** {supporting detail or metric}}

## How It Works
{Simplified 3-step explanation:
1. **{Step}** — {what happens}
2. **{Step}** — {what happens}
3. **{Step}** — {result}}

## Who It's For
{Target personas:
- **{Role}:** {why they care}
- **{Role}:** {why they care}}

## Get Started
{Clear CTA — what to do next}
~~~

**Generation rules for sales one-pager:**
1. Derive from the corresponding feature brief — distill to essentials
2. Must fit on one printed page (~400 words max)
3. Problem → Solution → Benefits → How → Who → CTA flow
4. Every sentence must pass the "so what?" test
5. No technical jargon — a VP should understand every word

---

## Blog Post

**File:** `docs/generated/marketing/blog-posts/bp-{NNN}-{slug}.md`

Long-form content piece (~800-1200 words). Derives from the feature brief but expands into a narrative. Suitable for company blog, Medium, Dev.to, or thought leadership.

~~~markdown
---
id: bp-{NNN}
type: blog-post
audience: marketing
topic: {feature-or-topic}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# {Compelling Headline}

{Hook paragraph — 2-3 sentences that name the pain point and make the reader nod. No product mention yet. Start with the reader's world, not yours.}

## The Problem

{3-4 paragraphs expanding on the pain. Use concrete scenarios:
- "You've just shipped a feature. Marketing finds out from the changelog three days later."
- "Your new hire spends their first week reading source code because no one documented the architecture."

Be specific and relatable. This section should make the reader feel understood.}

## A Better Way

{2-3 paragraphs introducing the solution concept — not the product yet, but the approach. What would ideal look like?

"What if every time you shipped code, the documentation wrote itself? Not generic API docs — actual audience-specific content that CS can use to answer tickets, marketing can use to write announcements, and users can follow to get started."}

## How {Product} Does This

{3-4 paragraphs explaining the product. Keep it accessible:
- What it does (1 paragraph)
- How it works at a high level (1-2 paragraphs, no implementation details)
- What makes it different (1 paragraph)

Use concrete examples from the codebase where possible.}

## Results

{1-2 paragraphs with proof points, metrics, or before/after comparisons. If no metrics are available from context, use structural benefits:
"A 10-feature codebase generates 70+ documents across three audiences in a single run."}

## Getting Started

{2-3 sentences with a clear CTA. Link to getting started docs, GitHub repo, or demo.}
~~~

**Generation rules for blog posts:**
1. Derive from feature brief — expand the problem/solution narrative
2. Target 800-1200 words — enough depth to be valuable, short enough to finish
3. Open with pain, not product. The reader should feel understood before you pitch.
4. One product mention in the headline is fine. Don't repeat the product name every paragraph.
5. Use concrete examples from the actual codebase, not hypothetical scenarios
6. End with a single, clear CTA — don't offer 5 different next steps

---

## Social Posts

**File:** `docs/generated/marketing/social/sp-{NNN}-{slug}.md`

Pack of platform-specific posts. One file per feature/topic, containing posts for multiple platforms.

~~~markdown
---
id: sp-{NNN}
type: social-posts
audience: marketing
topic: {feature-or-topic}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# Social Posts: {Feature/Topic Name}

## Twitter / X

### Launch Post
{1-2 sentences + CTA. Under 280 characters. Punchy, benefit-first.}

### Thread (3-5 tweets)
**1/** {Hook — the problem, phrased as a question or bold statement}
**2/** {The insight — why existing approaches fail}
**3/** {The solution — what {product/feature} does differently}
**4/** {Proof point — a concrete result or metric}
**5/** {CTA — link, try it, star the repo}

### One-Liner
{Single tweet. Under 140 characters. Quotable.}

## LinkedIn

### Announcement Post
{3-4 paragraphs. Professional but not corporate. Structure:
- Opening hook (1 sentence — the problem)
- Context (2-3 sentences — why this matters now)
- Solution (2-3 sentences — what you built and why)
- CTA (1 sentence — link or ask)

Include 3-5 relevant hashtags at the end.}

### Short Post
{1-2 paragraphs. Insight-driven — share a lesson learned or pattern observed while building this. End with a question to drive engagement.}

## Generic / Newsletter

### Blurb
{2-3 sentences suitable for a newsletter mention, product hunt description, or community post. Benefit-first, link at the end.}
~~~

**Generation rules for social posts:**
1. Derive from feature brief one-liner and suggested messaging
2. Twitter: under 280 chars per tweet. No hashtags on Twitter.
3. LinkedIn: professional tone, hashtags OK, longer format acceptable
4. Every post must be self-contained — reader shouldn't need context
5. Avoid superlatives ("revolutionary", "game-changing") — use specifics instead
6. Include the product/feature name in at least the launch post and CTA tweet

---

## Email Announcement

**File:** `docs/generated/marketing/emails/em-{NNN}-{slug}.md`

Launch or announcement email. Derives from release announcement but formatted for email delivery.

~~~markdown
---
id: em-{NNN}
type: email-announcement
audience: marketing
topic: {feature-or-release}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# Email: {Feature/Release Name}

## Meta
- **Subject Line:** {Under 60 chars. Benefit-first. No clickbait.}
- **Preview Text:** {Under 90 chars. Complements the subject — don't repeat it.}
- **Audience Segment:** {Who should receive this — all users, power users, trial users, etc.}

## Body

### Opening
{1-2 sentences. Name the outcome, not the feature:
"Starting today, your documentation writes itself." NOT "We're excited to announce Hermes v1.0."}

### What's New
{For each key feature/change — 2-3 bullet points:
- **{Benefit headline}** — {1 sentence explaining what changed and why it matters to THEM}}

### How to Get Started
{1-2 sentences with a clear action:
"[Try it now →](link)" or "Run `command` to get started."}

### Closing
{1 sentence. Warm but brief. No "please don't hesitate to reach out."}

## Footer Notes
- **Unsubscribe category:** {product-updates / release-notes / marketing}
- **Reply-to:** {team or person}
~~~

**Generation rules for email announcements:**
1. Derive from release announcement — restructure for inbox scanning
2. Subject line under 60 characters — test with "would I open this?"
3. Body should be scannable in 15 seconds — use bold, bullets, short paragraphs
4. ONE primary CTA. Secondary links are OK but one action should be obvious.
5. Don't open with "We're excited" or "We're thrilled" — open with the reader's benefit
6. Keep total body under 200 words — respect the inbox

---

## Landing Page Copy

**File:** `docs/generated/marketing/landing-pages/lp-{NNN}-{slug}.md`

Structured copy blocks for a product or feature landing page. Each section is a standalone block that can be assembled by a designer.

~~~markdown
---
id: lp-{NNN}
type: landing-page
audience: marketing
topic: {product-or-feature}
status: draft
generated: {date}
source-tier: {tier}
hermes-version: 1.0.1
---

# Landing Page: {Product/Feature Name}

## Hero Section
- **Headline:** {5-10 words. Benefit-first. What the reader gets.}
- **Subheadline:** {1-2 sentences expanding on the headline. Still benefit-focused.}
- **Primary CTA:** {Button text — action-oriented: "Get Started Free", "Try It Now", "View on GitHub"}
- **Secondary CTA:** {Optional link text: "See documentation", "Watch demo"}

## Problem Section
- **Section headline:** {Name the pain in their words}
- **Pain points:** {3-4 bullet points describing the current state — what's broken, slow, or frustrating}

## Solution Section
- **Section headline:** {How life changes with your product}
- **Value props:** {3-4 items, each with:}
  - **Icon/visual hint:** {emoji or icon suggestion}
  - **Headline:** {3-5 words}
  - **Description:** {1-2 sentences}

## How It Works
- **Section headline:** {e.g., "Three steps to better docs"}
- **Steps:**
  1. **{Step name}** — {1 sentence}
  2. **{Step name}** — {1 sentence}
  3. **{Step name}** — {1 sentence}

## Features Grid
{4-6 features, each with:
- **Title:** {feature name}
- **Description:** {1 sentence, benefit-focused}
- **Detail:** {1 sentence, how it works at a high level}}

## Social Proof
{If available from context:
- **Metric:** {e.g., "70+ docs generated per project"}
- **Quote:** {if customer testimonials exist in context}
- **Logos:** {if integration/partner logos are relevant}
If not available: "Social proof section requires customer data or usage metrics."}

## Final CTA
- **Headline:** {Restate the core benefit}
- **CTA Button:** {Same as hero primary CTA}
- **Supporting text:** {1 sentence — reduce friction: "Free and open source", "No credit card required"}
~~~

**Generation rules for landing pages:**
1. Derive from feature brief + datasheet — combine benefit messaging with specs
2. Every section is a standalone block — a designer should be able to rearrange them
3. Headlines are benefit-first, never feature-first ("Ship docs automatically" not "Automatic Documentation Generator")
4. Limit jargon — this page may be the first thing a prospect sees
5. Social proof section: only populate with verifiable data from context. Never fabricate metrics or quotes.
6. Two CTAs max — primary (action) and secondary (learn more)
