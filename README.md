# OpenCode Windows Setup

One-command setup for OpenCode on Windows with 30+ MCP servers, swarm multi-agent coordination, session search, and power-pack slash commands.

## What You Get

### Plugins
- **Swarm** (`/swarm`) — Break tasks into parallel subtasks, spawn agents, file-locking, git-backed tracking
- **Power-pack** (`/code-review`, `/feature-dev`, etc.) — 11 structured slash commands for common workflows
- **Browser** — In-session browser automation

### Slash Commands
`/code-review`, `/feature-dev`, `/security-review`, `/code-architect`, `/code-explorer`, `/frontend-design`, `/mcp-builder`, `/skill-creator`, `/agents-md-improver`, `/agents-md-revise`, `/code-reviewer`

### Agents
`@archaeologist`, `@explore`, `@refactorer`, `@reviewer`, `@swarm-planner`, `@swarm-worker`, `@swarm-researcher`

### MCP Servers (30+)
playwright, puppeteer, git, github, filesystem, fetch, web-search, memory, sequential-thinking, sqlite, postgres, redis, security-audit, lighthouse, a11y, cypress, storybook, tailwindcss, stylelint, core-web-vitals, paperplain, google-trends, wikipedia, browser-mcp, next-devtools, chrome-devtools, opencode-docs, npm-package-docs, context7, humanizer

### LSP Support
TypeScript, Python, Go, Rust, C/C++, Java, YAML, JSON, SQL, Markdown, CSS, HTML, Dockerfile, Bash, TOML, GraphQL, Tailwind, Terraform, PowerShell

### CLI Tools
- `swarm` — Multi-agent coordination (v0.63.2)
- `cass` — Cross-agent session search (v0.6.19)

## Prerequisites

- Windows 10+ (64-bit)
- [Node.js 18+](https://nodejs.org/) or [Bun](https://bun.sh/docs/installation#windows)
- [PowerShell 7+](https://github.com/PowerShell/PowerShell/releases)
- OpenCode CLI (`npm install -g opencode-ai` or `scoop install opencode`)

## Quick Install

```powershell
# Clone the repo
git clone https://github.com/YOUR_USERNAME/opencode-windows-setup.git
cd opencode-windows-setup

# Run setup
powershell -ExecutionPolicy Bypass -File setup.ps1
```

### Options

```powershell
# Skip backup of existing config
setup.ps1 -SkipBackup

# Skip swarm plugin install
setup.ps1 -SkipSwarm

# Skip CASS install
setup.ps1 -SkipCass

# Overwrite without asking
setup.ps1 -Force
```

## Manual Install

If you prefer to set things up manually:

1. Copy files to `%USERPROFILE%\.config\opencode\`
2. Run `npm install` or `bun install` in that directory
3. `npm install -g opencode-swarm-plugin`
4. `swarm setup`
5. Install CASS using the [install script](https://github.com/Dicklesworthstone/coding_agent_session_search)
6. Restart your terminal

## Default Model

Configured to use OpenCode's free-tier model (`opencode/big-pickle`). No API key needed.

## Optional

- **Ollama** — Download from [ollama.com](https://ollama.com/download/windows), then `ollama pull mxbai-embed-large` (enables semantic memory for swarm)
- **UBS** — `curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/ultimate_bug_scanner/main/install.sh | bash -s -- --easy-mode` (pre-commit bug scanning)

## File Structure

```
opencode-windows-setup/
├── config/
│   ├── opencode.jsonc       # Main config (models, MCP, LSP, agents, plugins)
│   └── package.json         # Node dependencies
├── commands/                # Power-pack slash commands (*.md)
├── agent/                   # Agent definitions (*.md)
├── plugin/                  # Plugin files (swarm.ts)
├── scripts/                 # Utility scripts
├── setup.ps1                # One-command installer
└── README.md
```

## Troubleshooting

**Compaction stuck/hanging?** The `plugin/swarm.ts` registers an `experimental.session.compacting` hook that injects ~9KB of swarm coordination context during compaction. This breaks compaction with `opencode/big-pickle` (free tier — upstream issues #27758, #26220, #30443). Fix: open `plugin/swarm.ts`, find the `"experimental.session.compacting"` handler, and replace it with a no-op:

```typescript
"experimental.session.compacting": async (
  _input: { sessionID: string },
  _output: CompactionOutput,
): Promise<void> => {
  // no-op — avoid injecting swarm context during compaction
},
```

Alternatively, disable auto-compaction in `config/opencode.jsonc`:
```jsonc
"compaction": {
  "auto": false,
  "prune": true,
  "reserved": 80000
}
```

**Plugin not loading?** Run `opencode --pure` to check if a plugin is causing issues, then run `opencode debug info` to see loaded plugins.

**Model not found?** Run `opencode models` to list available models, then update `model` in `config/opencode.jsonc`.

**Permission errors on npm install?** Run PowerShell as Administrator, or use `bun install` instead.

## Updating

```powershell
git pull
powershell -ExecutionPolicy Bypass -File setup.ps1
```