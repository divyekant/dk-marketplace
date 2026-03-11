# Installing Hermes for Codex

## Installation

1. Clone Hermes into your Codex workspace:

   ```bash
   git clone https://github.com/divyekant/hermes.git ~/.codex/hermes
   ```

2. Symlink the Hermes skill into Codex discovery:

   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/hermes/skills/hermes ~/.agents/skills/hermes
   ```

3. Restart Codex so it discovers the skill.

## Usage

Open Codex in a project directory and ask Hermes to generate docs.

Examples:

```text
Generate docs for this project.
Generate internal docs.
Update docs for this project.
```

## Custom Templates

Project overrides still live in `.hermes/templates/`.

To start from the bundled default template:

```bash
mkdir -p .hermes/templates
cp ~/.agents/skills/hermes/templates/internal.md .hermes/templates/internal.md
```

Edit the copied file, then Hermes will use it automatically for that project.
