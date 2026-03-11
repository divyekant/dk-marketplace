# Installing Delphi for Codex

## Installation

1. Clone Delphi into your Codex workspace:

   ```bash
   git clone https://github.com/divyekant/delphi.git ~/.codex/delphi
   ```

2. Symlink the skill into Codex discovery:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/delphi/skills/delphi ~/.agents/skills/delphi
   ```

3. Restart Codex so it discovers the skill.

## Usage

Open Codex in a project directory and ask Delphi to generate or execute guided cases.

Examples:

```text
Generate guided cases for this project.
Generate guided cases for the auth flow.
Execute guided cases.
Run P0 guided cases.
```
