# Session lifecycle — Chat vs Code vs Cowork

> Project Zomboid mod · working agreement for solo dev + Claude

---

## The golden rules

- **Always open and close every session in Chat**
- **Every ZeD coding session routes through the zed-orchestrator first**
- **Open Code only when the task is clearly defined**
- **Return to Chat when stuck or going in circles**
- **Cowork is for file/asset work only — never mix with active Lua sessions**

---

## Orchestrator — mandatory entry point for all ZeD coding sessions

The `zed-orchestrator` skill is the session conductor. Every ZeD coding session starts here before any code is written. It enforces the pipeline:

```
Boot → Brainstorm → Plan → Execute → Review → Close
```

**Boot:** Orchestrator reads NEXT_SESSION_HANDOFF.md FIRST (compact boot context), then
PROJECT_STATE.md, PZAPI-KNOWLEDGE-BANK.md, and TOOLTIP_SPEC.md from the gaming PC via MCP.
Reports current version, last session, build layer, and next target.
Also loads the ZeD-UI design notebook via Claude in Chrome extension:
https://notebooklm.google.com/notebook/59f4a511-ecc6-4a05-a49f-c2583e6f93be/preview

**Chrome extension:** Claude Code has access to Google Chrome via the "Claude in Chrome" MCP
extension. Use it to navigate to and read NotebookLM, web references, and other browser-based
resources during session prep and research phases.

**Brainstorm gate:** Clarifying questions before any code. Auto-flags ISInventoryPage traps,
gamepad requirements, split-screen concerns.

**Plan gate:** Task decomposition with file paths, skill routing, and done-criteria per task.
You approve the plan before a line of code is written. This is the design-in-chat moment.

**Execute:** Routes each task to the right specialist:
- Lua/ISUI/PZAPI → zed-modding
- Java/Kahlua2 → zed-java-backend
- Language patterns → zed-lua-java
- Architecture decisions → zed-project-bible

**Review gate:** 12-point ZeD checklist. Nothing ships with a failing item.

**Close:** Structured handoff packet to zed-session-docs, which runs full closeout.

> Prompt to boot orchestrator: "Let's start a ZeD session."

---

## Session start → always open Chat first


1. Open the Pro project in Claude Chat
2. Say "Let's start a ZeD session" — orchestrator boots, reads living docs, reports state
3. Orchestrator asks clarifying questions and produces a plan
4. Approve the plan, then execute

> Legacy prompt (still works): *"Let's start our session. Show me the current mod roadmap and suggest what to tackle today."*

---

## Routing: what kind of task is it?

### Fuzzy / needs design → **stay in Chat**

Use Chat when the task isn't fully resolved yet.

- Mechanics design and balancing
- UI/UX decisions and component specs
- Lua architecture planning
- API research
- Lore and narrative writing
- Roadmap prioritisation

**When it's ready:** write a clear spec in Chat (orchestrator plan gate handles this), then hand off to Code.

---

### Clear coding task → **go to Claude Code**

Use Code when you know exactly what to build.

- Lua file creation and editing
- Multi-file refactors
- Component implementation
- ISPanel / organism work
- In-game test → debug loop
- Git commits

**Trigger to open Code:** *"I'm heading to Claude Code now. Here's the task spec and relevant context: [paste spec]"*

---

### File / asset work → **open Cowork**

Use Cowork for non-code file operations.

- Sprite and tile renaming / batching
- Folder restructuring
- Generating doc stubs and outlines
- Asset inventory lists
- Bulk find-replace across files

**When it's ready:** files land in the right place, then pick up in Code or Chat.

---

## Mid-session: the switch gate

> **Are you hitting a wall in Code?**
> Confused · unclear · going in circles for more than ~15 min

| Situation | Action |
|---|---|
| Logic is unclear or design is unresolved | Return to Chat — re-spec before continuing |
| Bug with a clear cause | Stay in Code — debug it |
| Unsure which API or class to use | Return to Chat — research first |
| In-game behaviour wrong but code looks right | Stay in Code — add logging, test again |

**Re-spec prompt:** *"I'm stuck in Code on [X]. Here's what I have so far. Help me think through what's wrong with the approach."*

---

## Done signal

Before closing a task, check:

- [ ] Feature works correctly in-game
- [ ] No regressions in existing functionality
- [ ] Controller / gamepad tested if UI component
- [ ] Code committed in Claude Code
- [ ] Orchestrator review gate passed

If any box is unchecked → back to Code to fix.

---

## Session wrap-up → always end in Chat

1. Return to Chat
2. Tell orchestrator "that's a wrap" or say "Custodian"
3. Orchestrator produces handoff packet, hands to zed-session-docs
4. Session-docs runs full closeout: version bump, PROJECT_STATE.md update, NEXT_SESSION_HANDOFF.md written

> Prompt to use: *"That's a wrap."* or *"Custodian."*

---

## Full flow at a glance

```
Session start
    │
    ▼
Open Chat — say "Let's start a ZeD session"
    │
    ▼
zed-orchestrator boots: reads living docs, reports state
    │
    ▼
Brainstorm gate: clarifying questions
    │
    ▼
Plan gate: task decomposition — approve before coding
    │
    ├─── Fuzzy / needs more design ──► Stay in Chat (spec, research)
    │                                        │
    │                                        │ spec ready
    │                                        ▼
    ├─── Clear code task ───────────► Claude Code (write, edit, debug, commit)
    │                                        │
    │                                        │ hitting a wall?
    │                                        ├── Yes ──► back to Chat to re-spec
    │                                        │
    │                                        │ task working in-game?
    │                                        ├── No ───► keep debugging in Code
    │                                        │
    └─── File / asset work ─────────► Cowork (rename, batch, organise)
                                             │
                                             │ files ready
                                             ▼
                                       Claude Code or Chat
    │
    ▼
Review gate: 12-point ZeD checklist
    │
    ▼
Wrap up: "That's a wrap" → orchestrator → session-docs → closeout
    │
    ├─── More tasks today? ─── Yes ──► back to routing
    │
    └─── No → session end
```

---

*Last updated: April 9, 2026 (Session 73 — documentation audit, NEXT_SESSION_HANDOFF.md added to boot protocol)*
