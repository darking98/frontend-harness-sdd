# Harness SDD — template

> Template reusable de harness multi-agente para proyectos TypeScript
> (React + Vite o Next.js). Aplica los principios de **Harness Engineering**:
> el repositorio ES el sistema, no solo el código que contiene.

## Cómo está organizado el arnés

| Pilar | Manifestación en este repo |
| --- | --- |
| **1. El repositorio ES el sistema** | `AGENTS.md`, `init.sh`, `feature-list.json`, `specs/`, `progress/`, `docs/` |
| **2. Orquestación multi-agente** | `.claude/agents/leader.md`, `spec-author.md`, `implementer.md`, `reviewer.md` |
| **3. Spec Driven Development** | `docs/specs.md`, EARS notation, puerta de aprobación humana en `spec_ready` |
| **4. Supervisión y mejora** | `CHECKPOINTS.md`, hooks en `.claude/settings.json` |

## Instalarlo como plugin en un repo existente

```
/plugin install frontend-harness-sdd --marketplace darking98/frontend-harness-sdd
```

(Requiere Claude Code 2.1.275 o posterior; funciona en un solo paso aunque
todavía no hayas agregado el marketplace.) Para el camino de proyecto
nuevo desde cero, ver "Al forkear este template" más abajo.

## Para empezar

```bash
./init.sh
```

Si todo está verde, abre `AGENTS.md` y sigue desde ahí.

> Hasta que este template no tenga un `package.json` real de un proyecto
> Vite/Next.js inicializado, `init.sh` no va a terminar completamente
> verde (le falta `node_modules` y un script `test`) — es esperable en un
> template sin app todavía, no un error.

## Al forkear este template a un proyecto real

1. Inicializar el proyecto TS elegido (Vite o Next.js) con su propio
   `package.json` — este harness todavía no cubre backend/NestJS.
2. Completar "Módulos de este proyecto" en `docs/architecture.md` y borrar
   la sección de stack (Next.js o Vite) que no aplique.
3. Reemplazar `project`/`description` en `feature-list.json`.
4. Adaptar o borrar la feature de ejemplo (`#1 input-with-validation`)
   según si aplica a tu proyecto.

## Probarlo vos mismo con Claude Code

Si abrís Claude Code en la raíz, ya estás dentro del arnés: `CLAUDE.md`
fuerza al modelo a actuar como `leader` (orquesta, no edita código) y
`docs/specs.md` impone el flujo Spec Driven Development.

Receta rápida:

1. `./init.sh` — debe terminar verde (ver nota sobre `package.json` arriba).
2. `feature-list.json` ya trae una feature de ejemplo en `pending` con
   `"sdd": true` (`#1 input-with-validation`).
3. Lanza Claude Code en la raíz del repo: `claude`.
4. Pídele: **«implementa la siguiente feature pendiente»**.

Lo que ocurre, en dos fases:

**Fase 1 — Spec.** El `leader` lanza un `spec-author` que escribe
`specs/<feature>/{requirements.md, design.md, tasks.md}` y deja la feature
en `spec_ready`. Luego **para y te pide aprobación**.

Vos leés los tres archivos en tu editor:

- `requirements.md` — qué debe hacer la feature, en EARS estricto.
- `design.md` — decisiones técnicas antes de escribir código.
- `tasks.md` — checklist de pasos discretos a ejecutar.

Cuando estés conforme, dices al chat «aprobado» (o pides cambios).

**Fase 2 — Código.** El `leader` transiciona la feature a `in_progress` y
lanza `implementer` (sigue las tasks una a una marcándolas `[x]`) y
después `reviewer` (verifica trazabilidad `R<n>` ↔ test y todas las tasks
completas).

Dónde queda la traza de cada subagente:

| Archivo | Quién lo escribe | Qué contiene |
| --- | --- | --- |
| `specs/<feature>/requirements.md` | spec-author | EARS requirements numeradas `R1`, `R2`, ... |
| `specs/<feature>/design.md` | spec-author | Decisiones técnicas + alternativa descartada |
| `specs/<feature>/tasks.md` | spec-author | Checklist; el implementer la va marcando `[x]` |
| `progress/current.md` | leader | Plan vivo de la sesión |
| `progress/impl-<feature>.md` | implementer | Archivos tocados + mapa `R<n> → test` + output de los tests |
| `progress/review-<feature>.md` | reviewer | Checklist contra `docs/`, `specs/<feature>/` y `CHECKPOINTS.md` |
| `feature-list.json` | leader/implementer | `pending` → `spec_ready` → `in_progress` → `done` |
| `progress/history.md` | leader | Resumen append-only al cerrar la sesión |

Abre `specs/` y `progress/` en tu editor mientras Claude trabaja: cada
informe aparece en cuanto el subagente termina. Esa es la regla
anti-teléfono-descompuesto en acción — el contenido no circula por chat,
vive en disco y queda versionado.

## Estructura

```
.
├── AGENTS.md              # Mapa para agentes (divulgación progresiva)
├── CHECKPOINTS.md         # Criterios de "estado final correcto"
├── CLAUDE.md              # Fuerza el rol de leader al arrancar
├── feature-list.json      # Alcance: una feature a la vez
├── init.sh                # Verificación e inicialización
├── specs/<feature>/       # Spec por feature (Kiro-style)
│   ├── requirements.md    # EARS notation
│   ├── design.md          # Decisiones técnicas
│   └── tasks.md           # Checklist de implementación
├── progress/
│   ├── current.md         # Sesión activa (estado vivo)
│   └── history.md         # Bitácora append-only
├── docs/
│   ├── architecture.md    # Macro-estructura: módulos, capas, data flow
│   ├── conventions.md     # Naming, estilos, composición de componentes
│   ├── specs.md           # Proceso SDD: EARS, 3 archivos, aprobación humana
│   └── verification.md    # Cómo demostrar que funciona
└── .claude/
    ├── agents/            # leader, spec-author, implementer, reviewer
    └── settings.json      # Hooks que automatizan la verificación
```

El código de aplicación (`src/`, `app/`, `modules/`, etc. según el stack)
aparece una vez que se forkea el template a un proyecto real — los tests
van co-ubicados ahí, no en una carpeta `tests/` aparte.

## Aprendizajes que ilustra este template

- **Divulgación progresiva** en `AGENTS.md`: el agente no recibe todas las
  reglas de golpe, recibe un mapa para buscarlas bajo demanda.
- **Una feature a la vez** validado por `init.sh` (rechaza más de un
  `in_progress` en `feature-list.json`).
- **Spec Driven Development** estilo Kiro: requirements (EARS) → design →
  tasks → code, con una puerta de aprobación humana antes de tocar código.
- **Estado en disco**, no en chat: `specs/`, `progress/current.md` y
  `history.md` sobreviven a reinicios y context windows reventadas.
- **Verificación ejecutable**: `init.sh` corre los tests reales y valida
  la presencia de specs para toda feature SDD.
- **Trazabilidad obligatoria**: cada `R<n>` se mapea a un test concreto;
  el reviewer rechaza si falta.
- **Patrón Leader-Spec_author-Implementer-Reviewer**: el leader no
  implementa, el spec-author no codifica, el implementer no se
  autoaprueba, el reviewer no edita código.
- **Anti teléfono-descompuesto**: los subagentes escriben sus resultados
  en archivos y solo devuelven una referencia ligera.
