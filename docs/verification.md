# Verificación — Cómo demostrar que el trabajo funciona

> Regla de oro: **el agente no dice "funciona", lo demuestra**.
> Toda feature termina con evidencia ejecutable, no con afirmaciones.

## Niveles de verificación

### Nivel 1 — Tests unitarios (obligatorio)

Todo componente/hook/función pública en `src/modules/<dominio>/` (o a nivel
de app) tiene al menos un test co-ubicado (`<nombre>.test.tsx` /
`<nombre>.test.ts`, junto al archivo que prueba, no en una carpeta `tests/`
separada) que:

1. Cubre el camino feliz.
2. Cubre al menos un camino de error si la función/componente puede fallar
   o rechazar un input inválido.

Comando (detecta el package manager como `init.sh`):
```bash
"$PM" test
```

### Nivel 2 — Test de integración de UI (obligatorio para features con interacción)

Renderizar el componente real con `@testing-library/react` y simular la
interacción con `userEvent` (click, type) en vez de invocar handlers
directamente. Para formularios, montar un `useForm`/`FormProvider` real —
nunca mockear react-hook-form ni la librería de validación.

```tsx
render(<InputWithValidationHarness />);
await userEvent.type(screen.getByLabelText("Email"), "no-es-un-email");
await userEvent.click(screen.getByRole("button", { name: /enviar/i }));
expect(screen.getByText(/formato de email inválido/i)).toBeInTheDocument();
```

### Nivel 3 — Smoke test manual (opcional pero recomendado)

Antes de cerrar la sesión, levantar el dev server (`"$PM" run dev`) y probar
a mano el flujo end-to-end de la feature en el navegador.

### Nivel 4 — Trazabilidad de requirements (obligatorio para features con `"sdd": true`)

Cada `R<n>` de `specs/<name>/requirements.md` debe poder mapearse a al
menos un test concreto. El reviewer rechaza si falta cobertura.

El implementer documenta el mapa en `progress/impl-<name>.md`:

```markdown
## Trazabilidad
- R1 → `input reflects typed value` (input-with-validation.test.tsx)
- R2 → `blocks submit and shows error when empty` (input-with-validation.test.tsx)
```

## Anti-patrones (no hacer)

- ❌ "Agregué el componente, debería funcionar." → falta test ejecutable.
- ❌ Test que solo verifica que el componente renderiza sin crashear
  (`expect(container).toBeTruthy()`). → tiene que comprobar comportamiento
  concreto (texto visible, estado del form, llamada al service).
- ❌ Mock de react-hook-form o de cualquier librería de forms/validación. →
  montar `useForm`/`FormProvider` real y disparar la validación de verdad.
- ❌ Snapshot test como única verificación de un componente. → un snapshot
  detecta cambios, no verifica comportamiento; sirve como complemento, no
  como el único test.
- ❌ Marcar la feature como `done` sin pasar `./init.sh`.

## Verificación final antes de cerrar

```bash
./init.sh           # debe terminar con [OK] Entorno listo
```

Si `./init.sh` está rojo, **no** marques nada como `done`. Anota el bloqueo
en `progress/current.md` con estado `blocked` en `feature-list.json`.
