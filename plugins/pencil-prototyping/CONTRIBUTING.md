# Contributing to pencil-prototyping

Thanks for your interest in contributing!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/<you>/pencil-prototyping.git`
3. Create a feature branch: `git checkout -b feat/your-feature`
4. Make your changes
5. Test locally by symlinking: `ln -sf $(pwd) ~/.claude/skills/pencil-prototyping`
6. Commit with conventional style: `git commit -m "feat: add your feature"`
7. Push and open a PR

## Guidelines

- Follow conventional commit messages (`feat:`, `fix:`, `docs:`, `chore:`)
- Keep `SKILL.md` focused and concise
- Test the shell script on both ARM64 and x86_64 if possible
- Update README.md if adding user-facing features

## Reporting Issues

Open an issue with:
- Your macOS version and architecture
- Claude Code version
- Pencil.dev version (if installed)
- Steps to reproduce
