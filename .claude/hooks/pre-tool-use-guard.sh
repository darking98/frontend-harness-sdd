#!/usr/bin/env bash
# PreToolUse (Edit|Write) — bloquea escrituras en código de aplicación si
# no hay ninguna feature "in_progress" en feature-list.json.
#
# Límite conocido: un hook no puede distinguir QUIÉN está llamando a la
# tool (leader actuando como sesión principal vs. un implementer real
# despachado como subagente) — ve la misma tool call en ambos casos. Esto
# evita escribir código sin ninguna feature activa, pero NO evita que el
# leader implemente él mismo mientras una feature sí está in_progress.
set -u

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | node -e '
let d="";
process.stdin.on("data", c => d += c);
process.stdin.on("end", () => {
  try {
    const j = JSON.parse(d);
    process.stdout.write((j.tool_input && j.tool_input.file_path) || "");
  } catch (e) {}
});
' 2>/dev/null)

case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac

cd "$CLAUDE_PROJECT_DIR" || exit 0

HAS_IN_PROGRESS=$(node -e '
try {
  const d = JSON.parse(require("fs").readFileSync("feature-list.json", "utf8"));
  console.log(d.features.some(f => f.status === "in_progress") ? "1" : "0");
} catch (e) { console.log("1"); }
' 2>/dev/null)

if [ "$HAS_IN_PROGRESS" = "0" ]; then
  echo "No hay ninguna feature en 'in_progress' en feature-list.json. No se puede editar código de aplicación sin una feature activa (ver AGENTS.md)." >&2
  exit 2
fi

exit 0
