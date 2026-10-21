---
name: install-harness
description: Copia la estructura del harness SDD (AGENTS.md, docs/, agentes, specs) a un repo existente, sin tocar src/ ni el código del proyecto.
disable-model-invocation: true
allowed-tools: [Read, Write, Glob, Bash]
---

# Instalar harness en un repo existente

Este skill scaffoldea el harness SDD (el mismo contenido del template
`frontend-harness-sdd`) dentro del repo donde se invoca, pensado para
proyectos que **ya existen** (a diferencia del GitHub Template Repository,
que es para arrancar proyectos nuevos desde cero).

## Precondición

Verificá que el directorio actual sea la raíz de un repo (existe `.git`).
Si no lo es, parás y se lo decís al humano — no escribas nada.

## Qué copiar

La fuente es la raíz de este mismo plugin (donde vive este `SKILL.md`, dos
niveles arriba: `skills/install-harness/SKILL.md` → la raíz del plugin es
`../../`). Copiá estos archivos y carpetas, preservando su contenido tal
cual, al directorio actual (el repo destino):

- `AGENTS.md`
- `CLAUDE.md`
- `CHECKPOINTS.md`
- `init.sh`
- `docs/architecture.md`
- `docs/conventions.md`
- `docs/specs.md`
- `docs/verification.md`
- `feature-list.json`
- `progress/current.md`
- `progress/history.md`
- `.claude/agents/leader.md`
- `.claude/agents/spec-author.md`
- `.claude/agents/implementer.md`
- `.claude/agents/reviewer.md`
- `.claude/settings.json`

**No copiés**: `README.md` (el repo destino ya tiene el suyo propio),
`.claude-plugin/`, `skills/`, `.harness-source-repo` — esos son del plugin
en sí, no del harness que se instala.

## Protocolo

1. Confirmá la precondición (`.git` existe).
2. Para cada archivo de la lista: si **ya existe** en el repo destino, NO
   lo sobrescribas — anotalo como "ya existía, se dejó intacto". Si no
   existe, copialo tal cual (creando las carpetas intermedias que hagan
   falta: `docs/`, `progress/`, `.claude/agents/`).
3. Al terminar, mostrale al humano un resumen de dos listas: qué se copió
   y qué se dejó intacto por ya existir.
4. Recordale los próximos pasos manuales (no los hagas vos solo sin que te
   lo pidan):
   - Completar "Módulos de este proyecto" y borrar la sección de stack
     (Next.js o Vite) que no aplique en `docs/architecture.md`.
   - Reemplazar `project`/`description` y adaptar o borrar la feature de
     ejemplo en `feature-list.json`.
   - Correr `./init.sh` para validar el estado del entorno.

## Reglas duras

- ❌ Nunca sobrescribas un archivo que ya existe en el repo destino.
- ❌ Nunca copies `README.md`, `.claude-plugin/`, `skills/` ni
  `.harness-source-repo`.
- ❌ Nunca toques `src/` ni nada fuera de la lista de arriba.
