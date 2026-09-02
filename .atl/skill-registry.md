# Skill Registry — DMC_ProyectFinal_JulioLozano

**Generated**: 2026-09-02

Index of non-SDD skills discoverable for this project. Sub-agents load the exact `SKILL.md`
path listed here; this file is an index, not a summary of skill content.

Project-level skill dirs (`.claude/skills/` and `.agents/skills/`) contain the same three
symlinked skills; `.claude/skills/` entries are listed as authoritative (project-level over
user-level, per dedup rule).

## Skills Index

| Name | Trigger (from description) | Path | Scope |
|---|---|---|---|
| generar-prd | Generate/draft/create a PRD or define product requirements for a new project or feature | `.claude/skills/generar-prd/SKILL.md` | project |
| generar-tech-design | Generate/draft/create a Technical Design Document, system architecture, or ADRs (MADR), interviewing the user decision by decision from the PRD | `.claude/skills/generar-tech-design/SKILL.md` | project |
| generar-backlog | Break down/decompose a PRD + Technical Design Document into an ordered backlog of implementable specs, each ready to start one SDD cycle | `.claude/skills/generar-backlog/SKILL.md` | project |

No user-level skill directories (`~/.claude/skills/`, etc.) were scanned for entries outside the
`sdd-*`/`_shared` families, per registry rules (those are excluded from this index).

## Convention files

None of `agents.md`, `AGENTS.md`, project-level `CLAUDE.md`, `.cursorrules`, `GEMINI.md`, or
`copilot-instructions.md` were found at the project root.
