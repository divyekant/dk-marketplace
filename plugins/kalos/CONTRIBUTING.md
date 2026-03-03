# Contributing to Kalos

Thanks for your interest in contributing!

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Make your changes
4. Commit using conventional commits (`feat:`, `fix:`, `chore:`, etc.)
5. Push and open a pull request

## Development

Kalos is a Claude Code skill project. The main logic lives in `skills/kalos/SKILL.md`.

### Testing

Hook scripts are tested with [bats](https://github.com/bats-core/bats-core):

```bash
bats test/
```

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
