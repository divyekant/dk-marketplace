# think-different

An on-demand Claude Code skill that shifts how Claude approaches problems. When the straight-line approach isn't working, invoke this skill to get Claude to think laterally.

## What It Does

When invoked, the skill:

1. **Diagnoses** what kind of stuck you're in (wrong problem, wrong assumptions, overcomplicated, tunnel vision, treating symptoms)
2. **Reframes** using the simplest applicable thinking framework (Occam's Razor governs — only escalate if needed)
3. **Presents** 2-3 alternative paths ranked with a recommendation

It draws from 15 established thinking frameworks including First Principles, Inversion, SCAMPER, 5 Whys, Premortem, and others — but you never see the machinery. You just get fresh angles.

## Install

```bash
git clone https://github.com/divyekant/think-different.git
cd think-different
./install.sh
```

Then restart Claude Code.

## Usage

Invoke it when you need a different angle:

- "Use the think-different skill"
- "Think different about this problem"
- "I'm stuck, help me reframe"
- `/think-different`

### When to use it

- You've hit a wall and the same approach keeps failing
- You want Claude to challenge its current framing
- You want creative alternatives before starting work
- The proposed solutions don't feel right

### When NOT to use it

- The obvious approach hasn't been tried yet
- You're debugging (use `systematic-debugging` instead)
- The problem is genuinely straightforward

## How It Works

**Governing principle: Occam's Razor.** Start with the simplest reframe. Only go deeper if it doesn't cut.

The skill diagnoses your blockage type, then selects from its internal framework toolkit:

| Stuck Type | Example Signal |
|---|---|
| Wrong problem | "Solution works but doesn't help" |
| Wrong assumptions | "Same wall from every angle" |
| Overcomplicated | "This feels too heavy" |
| Tunnel vision | "Only one approach considered" |
| Treating symptoms | "Fixes keep spawning new issues" |

Each stuck type maps to 3 ranked frameworks. The skill applies the top match first, escalates only if needed, never applies more than 3 per invocation.

## Research Basis

Built from 15 established thinking frameworks:

- Lateral Thinking (de Bono), First Principles (Aristotle/Musk), Inversion (Munger)
- TRIZ, Constraint-based Creativity, Oblique Strategies (Eno)
- 5 Whys (Toyota), Rubber Duck Debugging, Analogical Thinking
- SCAMPER, Premortem (Klein), Polya's Problem-Solving
- Hammock-Driven Development (Hickey), Chesterton's Fence, Cognitive Bias Awareness

## License

MIT
