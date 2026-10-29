#!/usr/bin/env bash
# Stop — dispara al final de CADA respuesta del asistente, no solo al
# cerrar la sesión (así lo documenta Claude Code). Para no correr init.sh
# en cada turno conversacional, solo verifica si hay cambios de código
# (tocados o nuevos sin trackear) desde el último chequeo. Evita loops
# chequeando stop_hook_active.
set -u

INPUT=$(cat)
STOP_ACTIVE=$(printf '%s' "$INPUT" | node -e '
let d="";
process.stdin.on("data", c => d += c);
process.stdin.on("end", () => {
  try {
    const j = JSON.parse(d);
    process.stdout.write(j.stop_hook_active ? "1" : "0");
  } catch (e) { process.stdout.write("0"); }
});
' 2>/dev/null)

if [ "$STOP_ACTIVE" = "1" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

HAS_CHANGES=0
if ! git diff --quiet -- '*.ts' '*.tsx' '*.js' '*.jsx' 2>/dev/null; then HAS_CHANGES=1; fi
if ! git diff --cached --quiet -- '*.ts' '*.tsx' '*.js' '*.jsx' 2>/dev/null; then HAS_CHANGES=1; fi
if [ -n "$(git ls-files --others --exclude-standard -- '*.ts' '*.tsx' '*.js' '*.jsx' 2>/dev/null)" ]; then HAS_CHANGES=1; fi

if [ "$HAS_CHANGES" = "0" ]; then
  exit 0
fi

LOG="$CLAUDE_PROJECT_DIR/.claude/init-check.log"
if ./init.sh > "$LOG" 2>&1; then
  rm -f "$LOG"
  exit 0
else
  tail -20 "$LOG" >&2
  exit 2
fi
