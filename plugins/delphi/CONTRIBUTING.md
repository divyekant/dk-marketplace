# Contributing to Delphi

Thanks for your interest in contributing! Delphi is a skill for coding agents that generates and executes comprehensive test scenarios.

## How to Contribute

### Reporting Issues

- Open an issue describing the problem or suggestion
- Include the agent you're using (Claude Code, Codex, Cursor, etc.)
- Include sample output if reporting a generation quality issue

### Improving the Skill

The core of Delphi is `skills/delphi/skill.md`. Changes to this file directly affect how agents generate and execute guided cases.

1. Fork the repo
2. Create a branch (`git checkout -b improve-coverage-matrix`)
3. Make your changes
4. Test by invoking the skill in a Claude Code session against a real project
5. Open a PR describing what you changed and why

### Adding Examples

Good reference examples help agents produce better output. Add to `examples/` following the guided case format in the skill.

### What Makes a Good Contribution

- **Coverage matrix improvements** — new dimensions or better descriptions of what to generate
- **Better prompting** — clearer instructions that produce more consistent output
- **Format improvements** — changes to the guided case template that make cases more useful
- **Surface-specific guidance** — better instructions for API, CLI, or background testing
- **Bug fixes** — if Delphi produces incorrect or malformed output, fix the instructions

### What to Avoid

- Adding external dependencies (Delphi is a single skill file by design)
- Changing the guided case format without backward compatibility consideration
- Adding features that only work with one specific agent

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
