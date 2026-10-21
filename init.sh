#!/usr/bin/env bash
# init.sh — Verificación e inicialización del entorno
#
# Este script lo ejecuta el agente al COMENZAR una sesión y antes de
# declarar cualquier tarea como `done`. Si falla, la sesión no debe avanzar.
#
# Salida esperada: códigos de salida claros y bloques marcados con [OK]/[FAIL].

set -u
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$1"; }

EXIT_CODE=0

echo "── 1. Verificando entorno ─────────────────────────────"

# Node disponible
if ! command -v node >/dev/null 2>&1; then
  fail "node no está instalado"
  exit 1
fi
ok "node -> $(node --version)"

# Versión mínima 18 (requerida por Next.js 14+ / Nest 10+ / Vite 5+)
NODE_VERSION_OK=$(node -e 'console.log(Number(process.versions.node.split(".")[0]) >= 18 ? 1 : 0)')
if [ "$NODE_VERSION_OK" != "1" ]; then
  fail "Se requiere Node >= 18"
  exit 1
fi
ok "Versión de Node compatible"

# Detectar package manager por lockfile
if [ -f "pnpm-lock.yaml" ]; then
  PM="pnpm"
elif [ -f "yarn.lock" ]; then
  PM="yarn"
elif [ -f "package-lock.json" ]; then
  PM="npm"
else
  warn "No se encontró lockfile (pnpm-lock.yaml / yarn.lock / package-lock.json). Asumiendo npm."
  PM="npm"
fi

if ! command -v "$PM" >/dev/null 2>&1; then
  fail "Package manager detectado ($PM) no está instalado"
  EXIT_CODE=1
else
  ok "Package manager -> $PM"
fi

if [ ! -d "node_modules" ]; then
  fail "node_modules no existe. Corre '$PM install' antes de continuar."
  EXIT_CODE=1
else
  ok "node_modules presente"
fi

echo ""
echo "── 2. Verificando archivos base del arnés ──────────────"

for f in AGENTS.md feature-list.json progress/current.md docs/architecture.md docs/conventions.md docs/verification.md CHECKPOINTS.md; do
  if [ ! -f "$f" ]; then
    fail "Falta archivo base: $f"
    EXIT_CODE=1
  else
    ok "Existe $f"
  fi
done

echo ""
echo "── 3. Validando feature-list.json y specs ─────────────"

node <<'JS'
const fs = require("fs");
const path = require("path");

try {
  const data = JSON.parse(fs.readFileSync("feature-list.json", "utf8"));
  const valid = new Set(["pending", "spec_ready", "in_progress", "done", "blocked"]);
  const inProgress = data.features.filter((f) => f.status === "in_progress");

  if (inProgress.length > 1) {
    console.log(`[FAIL]  Hay ${inProgress.length} features en in_progress (máximo 1)`);
    process.exit(1);
  }

  const requiresSpec = new Set(["spec_ready", "in_progress", "done"]);
  const specErrors = [];

  for (const f of data.features) {
    if (!valid.has(f.status)) {
      console.log(`[FAIL]  Estado inválido en feature ${f.id}: ${f.status}`);
      process.exit(1);
    }
    if (f.sdd && requiresSpec.has(f.status)) {
      const specDir = path.join("specs", f.name);
      for (const fname of ["requirements.md", "design.md", "tasks.md"]) {
        if (!fs.existsSync(path.join(specDir, fname))) {
          specErrors.push(
            `feature ${f.id} (${f.name}) en ${f.status} sin ${specDir}/${fname}`
          );
        }
      }
    }
  }

  if (specErrors.length > 0) {
    for (const e of specErrors) console.log(`[FAIL]  ${e}`);
    process.exit(1);
  }

  console.log(`[OK]    feature-list.json válido (${data.features.length} features)`);
  console.log("[OK]    Specs presentes para features sdd con estado no-pending");
} catch (e) {
  console.log(`[FAIL]  feature-list.json o specs inválidos: ${e.message}`);
  process.exit(1);
}
JS

if [ $? -ne 0 ]; then EXIT_CODE=1; fi

echo ""
echo "── 4. Ejecutando tests ─────────────────────────────────"

HAS_TEST_SCRIPT=$(node -e 'try { const p = require("./package.json"); console.log(p.scripts && p.scripts.test ? 1 : 0); } catch { console.log(0); }')

if [ "$HAS_TEST_SCRIPT" = "1" ]; then
  if "$PM" test 2>&1; then
    ok "Todos los tests pasan"
  else
    fail "Hay tests rotos"
    EXIT_CODE=1
  fi
else
  warn "No hay script 'test' en package.json todavía"
fi

echo ""
echo "── 5. Resumen ──────────────────────────────────────────"

if [ $EXIT_CODE -eq 0 ]; then
  ok "Entorno listo. Puedes empezar a trabajar."
else
  fail "Entorno NO está listo. Resuelve los errores antes de avanzar."
fi

exit $EXIT_CODE
