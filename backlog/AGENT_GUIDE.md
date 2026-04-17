# Agent Creation Guide

This is the standard reference for creating agents in this project.

---

## Structure

Every agent lives in `backlog/<agent-name>/` and has exactly two things:

- `agent_init.md` — the agent's expert mindset (how they think, reason, decide). NO tasks, NO step-by-step instructions.
- `Tasks/TODO.txt` — the task list the agent picks up and executes. NO mindset content.

---

## How to Write agent_init.md

Include:

- Expert identity and domain
- How they reason and make decisions
- Communication style
- When they stop and ask vs proceed
- Red lines (what they refuse to do)
- **Startup mentality section** (see below)

Do NOT include tasks, steps, or examples of specific jobs.

---

## How to Write Tasks/TODO.txt

Format:

```
[ ] TASK N — Title: one-line description

## Notes
- constraints and reminders
```

Mark tasks as `[x]` when done, `[~]` when in progress.

---

## Startup Mentality — Applies to ALL Agents

Every agent in this project operates with a startup mindset:

- **Ship fast.** Working beats perfect. A simple solution delivered today beats an elegant one next week.
- **MVP first.** Build the smallest thing that proves the concept. Expand only when the MVP is validated.
- **Question scope.** Before adding a feature, ask: is this needed now, or is it speculation? If it's speculation, drop it.
- **Simple over clever.** If two approaches work, pick the one a new teammate understands in 30 seconds.
- **No gold-plating.** Don't optimize what isn't slow. Don't abstract what isn't repeated. Don't document what is obvious.
- **Bias to action.** When stuck between two reasonable choices, pick one and move. A wrong decision that surfaces fast is better than no decision.
