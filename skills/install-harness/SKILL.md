---
name: install-harness
description: Copia la estructura del harness SDD (AGENTS.md, docs/, agentes, specs, hooks) a un repo existente, sin tocar src/ ni el código del proyecto.
disable-model-invocation: true
allowed-tools: [Read, Write, Edit, Glob, Bash]
---

# Instalar harness en un repo existente

Este skill scaffoldea el harness SDD (el mismo contenido del template
`frontend-harness-sdd`) dentro del repo donde se invoca, pensado para
proyectos que **ya existen** (a diferencia del GitHub Template Repository,
que es para arrancar proyectos nuevos desde cero).

## Precondición

Verificá que el directorio actual sea la raíz de un repo (existe `.git`).
Si no lo es, parás y se lo decís al humano — no escribas nada.

## Raíz del plugin (fuente de los archivos)

Usá `${CLAUDE_PLUGIN_ROOT}` si está disponible en este contexto — es la
variable oficial para que un script/skill de un plugin resuelva su propio
directorio de instalación. Si no está disponible dentro del cuerpo de un
`SKILL.md` (no confirmado contra la doc oficial, que solo la documenta
para hooks y comandos), usá como fallback la ruta relativa a este mismo
archivo: `skills/install-harness/SKILL.md` → la raíz del plugin es `../../`.

## Qué copiar tal cual (archivos normales)

Copiá estos archivos y carpetas, preservando su contenido, al directorio
actual (el repo destino):

- `AGENTS.md`
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
- `.claude/hooks/post-tool-use-test.sh`
- `.claude/hooks/stop-check.sh`
- `.claude/hooks/pre-tool-use-guard.sh`

**No copiés**: `README.md` (el repo destino ya tiene el suyo propio),
`.claude-plugin/`, `skills/`, `.harness-source-repo` — esos son del plugin
en sí, no del harness que se instala.

## `CLAUDE.md` y `.claude/settings.json` — casos especiales

Estos dos NUNCA se copian tal cual. La mayoría de los repos existentes ya
tienen alguno de los dos, y la regla de "nunca sobrescribir" haría que el
harness quede instalado a medias (sin rol de `leader`, sin hooks) sin que
nadie lo note. Tratalos así:

### `CLAUDE.md`

El `CLAUDE.md` de este plugin tiene una sección "Paso 0 — Bootstrap del
template" que es específica del repo fuente (detecta `.claude-plugin/`
para distinguir template vs. repo fuente) — **no la copies nunca**, es
texto muerto en el repo destino porque ahí `.claude-plugin/` no va a
existir jamás. Usá solo el contenido desde el heading `## Rol obligatorio:
leader` en adelante.

- Si el repo destino **no tiene** `CLAUDE.md`: creálo con ese contenido
  (desde `## Rol obligatorio: leader` en adelante), con su propio heading
  `# Instrucciones para Claude` arriba.
- Si el repo destino **ya tiene** `CLAUDE.md`: mostrale ese contenido al
  humano y preguntale si querés agregarlo como una sección nueva al final
  del archivo existente (ej. bajo un heading `## Harness SDD`). Solo
  escribí si confirma. Si no confirma, anotalo para el resumen final.

### `.claude/settings.json`

- Si el repo destino **no tiene** `.claude/settings.json`: copiá el de
  este plugin tal cual.
- Si el repo destino **ya tiene** `.claude/settings.json`: mostrale al
  humano un merge propuesto — las entradas de `hooks.PreToolUse`,
  `hooks.PostToolUse` y `hooks.Stop` de este plugin **agregadas** a los
  arrays existentes (no reemplazando lo que ya haya), y las entradas de
  `permissions.allow` de este plugin unidas (sin duplicar) a las
  existentes. Solo escribí si confirma. Si no confirma, anotalo para el
  resumen final.

## Protocolo

1. Confirmá la precondición (`.git` existe).
2. Para cada archivo de "Qué copiar tal cual": si **ya existe** en el
   repo destino, NO lo sobrescribas — anotalo como "ya existía, se dejó
   intacto". Si no existe, copialo (creando las carpetas intermedias que
   hagan falta).
3. Resolvé `CLAUDE.md` y `.claude/settings.json` según sus casos
   especiales de arriba.
4. Después de copiar, corré `chmod +x init.sh .claude/hooks/*.sh` en el
   repo destino, y sugerile al humano correr
   `git update-index --chmod=+x init.sh .claude/hooks/*.sh` si el repo
   está versionado — `Write` no preserva el bit de ejecución.
5. Al terminar, mostrale al humano un resumen de tres listas: qué se
   copió, qué se dejó intacto por ya existir, y **si `CLAUDE.md` y/o
   `.claude/settings.json` quedaron sin instalar** porque el humano no
   confirmó el merge — en ese caso decí explícitamente que el harness
   quedó incompleto (sin rol de `leader` forzado y/o sin hooks) y por qué.
6. Recordale los próximos pasos manuales (no los hagas vos solo sin que te
   lo pidan):
   - Completar "Módulos de este proyecto" y borrar la sección de stack
     (Next.js o Vite) que no aplique en `docs/architecture.md`.
   - Reemplazar `project`/`description` y adaptar o borrar la feature de
     ejemplo en `feature-list.json`.
   - Correr `./init.sh` para validar el estado del entorno.

## Reglas duras

- ❌ Nunca sobrescribas un archivo que ya existe en el repo destino sin
  confirmación explícita (ver casos especiales de `CLAUDE.md`/
  `settings.json`).
- ❌ Nunca copies `README.md`, `.claude-plugin/`, `skills/` ni
  `.harness-source-repo`.
- ❌ Nunca copies la sección "Paso 0" de `CLAUDE.md` al repo destino.
- ❌ Nunca toques `src/`/código de aplicación ni nada fuera de la lista
  de arriba.
- ✅ Si `CLAUDE.md` o `settings.json` quedaron sin instalar por falta de
  confirmación, decilo explícitamente en el resumen final — nunca lo
  omitas en silencio.
