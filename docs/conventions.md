# Convenciones de código

> Homogeneidad extrema. La IA predice mejor cuando el repositorio se parece
> a sí mismo en todas partes.
>
> Esto cubre naming, estilo y composición de componentes — el micro-nivel.
> Para dónde vive cada cosa (módulos, capas, data flow), ver
> `docs/architecture.md`.

## Estilo TypeScript

- **Modo:** `strict: true` en `tsconfig.json` (incluye `noImplicitAny`,
  `strictNullChecks`). Nada de `any` sin justificar con un comentario del
  por qué.
- **Formato:** Prettier + ESLint con la config del proyecto. Si no existe
  todavía, default: comillas simples, semicolons, 100 columnas.
- **Imports:** ordenados en tres bloques — externos (`react`, `next`,
  librerías), internos vía alias (`@/modules/...`), relativos del mismo
  módulo. Evitar `../../../` largo: usar el alias en cuanto cruza de
  carpeta de módulo.
- **Strings:** template literals para interpolación. Nada de concatenación
  con `+`.

## Nombres

| Tipo | Convención | Ejemplo |
|------|------------|---------|
| Archivos / carpetas | `kebab-case`, siempre | `input-with-validation.tsx` |
| Componentes (export) | `PascalCase` | `InputWithValidation` |
| Hooks | `camelCase`, prefijo `use` | `useExpenses` |
| Funciones / variables | `camelCase` | `loadExpenses` |
| Tipos / interfaces | `PascalCase` | `ExpenseDraft` |
| Constantes | `UPPER_SNAKE` | `DEFAULT_PAGE_SIZE` |

El nombre de archivo/carpeta nunca se traduce al idioma del producto
(un módulo de "Configuración" vive en `modules/settings/`, no
`modules/configuracion/`); el copy visible para el usuario sí sigue el
idioma del producto.

## Clases por sobre estilos inline

Siempre que se pueda, el styling va con clases (Tailwind u otro), no con
objetos de estilo inline. Excepción: valores dinámicos/animados que una
librería de animación necesita en tiempo real — ahí sí puede requerir
estilo inline porque las clases no reciben un valor animado.

## `ui/` y `components/` trabajan en par

`ui/` es la primitiva de diseño — puramente visual, sin lógica de negocio
ni de formularios. `components/` implementa un componente de `ui/`
sumándole lógica (ej. `ui/inputs/input.tsx` → `components/forms/input-with-validation.tsx`
con react-hook-form). Mismo principio en cualquier módulo o a nivel de app.

- **Nada suelto directo en `ui/` o `components/`**: todo componente va en
  una subcarpeta que agrupa por categoría (`components/forms/<nombre>.tsx`,
  no `components/<nombre>.tsx`). La subcarpeta admite más componentes
  relacionados a futuro sin reordenar nada.
- **Toda "card" de item de lista va en `ui/cards/`** del módulo que la usa
  (o en el `ui/cards/` de nivel de app si la reutiliza más de un módulo).
  La card recibe su propio tipo local mínimo (solo los campos que pinta),
  no el tipo completo de dominio.

## Un formulario siempre va en su propio componente

Un `<form>` (los campos + el submit) nunca vive inline dentro del
componente que decide dónde/cómo se muestra (un diálogo, un modal, una
página completa). Van separados: `<feature>-form.tsx` (los campos, el
`action`/`onSubmit`, nada de estado de apertura/cierre) y el componente que
lo monta (ej. `<feature>-dialog.tsx`) le pasa `action`/valores por
default/`onCancel` por props. El componente que monta el form no sabe qué
campos tiene; el form no sabe si lo muestra un diálogo, una página completa
o un panel lateral.

## Datos hardcodeados van en `config/`

Arrays de objetos, `Record`, listas de opciones: van en
`modules/<dominio>/config/` (o `config/` de nivel de app si son
transversales). Un archivo de `config/` puede consolidar varias constantes
relacionadas aunque hoy las consuma un solo componente. Config puramente
interna de un componente (no reutilizable ni "contenido", ej. los
parámetros de un spring de animación) se queda inline.

## Manejo de errores

Funciones que pueden fallar (`services/`, `actions/`, llamadas a API) lanzan
errores nombrados, nunca devuelven `null`/`undefined` en silencio:

```ts
export class ExpenseNotFoundError extends Error {}
```

La UI captura esos errores en el límite más cercano al usuario (estado de
error del form, boundary de la página) y muestra un mensaje legible — nunca
deja un stack trace visible ni se conforma con un `console.error` como
único manejo.

## Comentarios

Por defecto **no** se escriben. Solo se permiten cuando explican un *por qué*
no obvio (p. ej. workaround documentado, invariante sutil). Los nombres
deben hacer el resto.
