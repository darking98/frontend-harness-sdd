#!/usr/bin/env bash
# PostToolUse (Edit|Write) — corre tests solo si se tocó código.
# Exit 0 no le llega el stdout al modelo (solo al debug log); exit 2 sí le
# manda stderr como feedback. Por eso: éxito = exit 0 silencioso,
# fallo = volcar el resumen a stderr y salir con 2.
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

if [ -f pnpm-lock.yaml ]; then PM=pnpm
elif [ -f yarn.lock ]; then PM=yarn
else PM=npm
fi

OUTPUT=$("$PM" test 2>&1)
CODE=$?

if [ $CODE -ne 0 ]; then
  echo "$OUTPUT" | tail -20 >&2
  exit 2
fi

exit 0
