# leo-tools — Claude Code plugins de Leopoldo Bini

Utilidades **standalone**: cada plugin resuelve un problema por su cuenta y se instala suelto,
sin depender del resto del stack. Lo que solo tiene sentido junto con el pipeline AFK vive en
[`leo-stack`](https://github.com/LeopoldoBini/leo-stack), no acá.

## Plugins

| Plugin | Qué hace | Categoría |
|--------|----------|-----------|
| **[clickup](#clickup)** | Integración completa con la API de ClickUp vía curl (100+ endpoints), sin MCP | Productividad |
| **adr-sync** | Mantiene los ADR consistentes con el resto de la documentación del proyecto | Documentación |
| **qa-forge** | QA autónomo: plan de pruebas P0-P3 sobre el código, ejecución vía Playwright y reporte de bugs | Testing |
| **interface-lens** | Psicología UX con brújula ética: `/ui-judge`, `/ux-design`, `/dark-pattern-scan` | Diseño |
| **memory-flow** | `/revisar_memoria` — barrido batch de la memoria del proyecto, con graduaciones propuestas | Productividad |
| **yt-transcript** | `/yt-transcript` — transcript de YouTube a un archivo central, con resumen e índice | Productividad |
| **voice-checkpoint** | `/analizar` — checkpoint de comprensión para dictado por voz, antes de tocar nada | Productividad |
| **al-grano** | `/al-grano` rehace lo último como parte corto; `/modo-al-grano` deja la sesión así | Productividad |

Instalación: `/plugin install <plugin>@leo-tools`, o `/plugin > Discover`.

---

## ClickUp

Direct ClickUp API v2 integration for Claude Code. No MCP dependency — uses `curl` with automatic auth, retry, and rate limit handling.

### What it does

- **Full API access**: Tasks, comments, time tracking, docs, custom fields, checklists, dependencies, tags, goals, webhooks, and more (100+ endpoints)
- **Smart skill**: Claude learns the ClickUp API and uses it autonomously when you ask about tasks or projects
- **4 slash commands**: `/cu:search`, `/cu:task`, `/cu:spaces`, `/cu:status`
- **2 subagents**: `clickup-explorer` (bulk searches, workspace mapping) and `clickup-reporter` (analytics, time reports)
- **Per-project config**: Each project can define its own space, lists, and conventions via `.claude/clickup.local.md`
- **Helper scripts**: `cu-api.sh` (API wrapper), `cu-format.py` (JSON to tables), `cu-paginate.sh` (auto-pagination)

### Architecture

```
plugins/clickup/
├── .claude-plugin/plugin.json        # Plugin manifest
├── skills/clickup-api/
│   ├── SKILL.md                      # Main skill (Claude reads this first)
│   ├── references/                   # Endpoint docs (loaded on demand)
│   │   ├── endpoints-tasks.md        # Tasks CRUD, custom fields, bulk ops
│   │   ├── endpoints-hierarchy.md    # Teams > Spaces > Folders > Lists
│   │   ├── endpoints-advanced.md     # Comments, checklists, deps, tags
│   │   ├── endpoints-time.md         # Time tracking
│   │   ├── endpoints-docs.md         # Documents API
│   │   ├── endpoints-admin.md        # Members, views, goals, webhooks
│   │   ├── error-handling.md         # Rate limits, errors, retry
│   │   └── best-practices.md         # Patterns and conventions
│   └── scripts/
│       ├── cu-api.sh                 # Core API wrapper (auth + retry)
│       ├── cu-format.py              # JSON formatter (tables, cards, trees)
│       └── cu-paginate.sh            # Automatic pagination handler
├── commands/                         # Slash commands
│   ├── cu-search.md                  # /cu:search <term or ID>
│   ├── cu-task.md                    # /cu:task <ID>
│   ├── cu-spaces.md                  # /cu:spaces
│   └── cu-status.md                  # /cu:status
├── agents/                           # Subagents
│   ├── clickup-explorer.md           # Read-only bulk operations
│   └── clickup-reporter.md           # Analytics and reports
└── templates/
    └── clickup.local.md.template     # Per-project config template
```

### Requirements

- `curl`, `python3`, `bash` (standard macOS/Linux tools)
- ClickUp API personal token ([get one here](https://app.clickup.com/settings/apps))
- No pip packages needed — only Python stdlib

### Installation

```bash
/plugin install clickup@leo-tools
```

Or browse in `/plugin > Discover`.

### Setup

#### 1. Save your token

```bash
mkdir -p ~/.config/clickup
echo 'pk_YOUR_TOKEN_HERE' > ~/.config/clickup/token
chmod 600 ~/.config/clickup/token
```

#### 2. Set your Team ID

```bash
# Discover your Team ID:
curl -s -H "Authorization: $(cat ~/.config/clickup/token)" \
  https://api.clickup.com/api/v2/team | python3 -c "
import sys, json
for t in json.load(sys.stdin)['teams']:
    print(f\"  {t['name']}: {t['id']}\")"

# Save it:
echo 'CLICKUP_TEAM_ID=YOUR_TEAM_ID' > ~/.config/clickup/config.env
```

#### 3. (Optional) Per-project config

Copy the template and customize with your project's space/list IDs:

```bash
cp ~/.claude/plugins/marketplaces/leo-tools/plugins/clickup/templates/clickup.local.md.template \
   your-project/.claude/clickup.local.md
```

This file tells Claude which space, lists, and status workflows your project uses.

### Usage

Once installed, Claude uses the ClickUp API automatically when you ask about tasks or projects:

```
> show me overdue tasks in the implementation list
> create a task "Deploy hotfix" with high priority
> how much time did I track this week?
```

Or use slash commands directly:

| Command | Description |
|---------|-------------|
| `/cu:search deploy` | Search tasks by name |
| `/cu:search 86af443vq` | Fetch task by ID |
| `/cu:task 86af443vq` | Full task card with comments and time |
| `/cu:spaces` | Workspace tree (spaces > folders > lists) |
| `/cu:status` | Dashboard grouped by status |

### Token resolution

The plugin looks for your token in this order:

1. `~/.config/clickup/token` (recommended)
2. `$CLICKUP_API_KEY` environment variable
3. `~/.config/saltacompra/clickup.env` (legacy)

---

## Adding new plugins

1. Create `plugins/your-plugin/` with the [standard structure](https://code.claude.com/docs/en/plugins)
2. Add an entry to `.claude-plugin/marketplace.json`
3. Commit and push
4. On your machine: `cd ~/.claude/plugins/marketplaces/leo-tools && git pull`
