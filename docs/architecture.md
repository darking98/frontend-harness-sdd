# Arquitectura — Qué significa "hacer un buen trabajo"

> Este documento define el estándar de calidad. Los agentes revisores
> evalúan código contra este archivo. Si no está aquí, no es un requisito.
>
> Este harness es un template reusable: lo que sigue queda con placeholders
> (`<dominio>`) hasta que se clone a un proyecto real. Al forkear:
> 1. Completar "Módulos de este proyecto" con los dominios reales.
> 2. Borrar la sección de stack (Next.js o Vite) que no aplique a ese proyecto.
>
> Para naming, estilos y composición de componentes (`ui/` vs `components/`,
> formularios, datos hardcodeados) ver `docs/conventions.md` — este archivo
> es solo la macro-estructura: dónde vive cada cosa y por qué.

## Módulos de este proyecto

<Completar con los dominios de negocio reales una vez decididos, ej.
`expenses`, `auth`. Hasta entonces, no inventar dominios de ejemplo.>

## Principios

1. **Arquitectura por módulos, no por capa técnica.** `src/modules/<dominio>/`
   agrupa todo lo de un dominio de negocio (componentes, hooks, capa de
   datos, tipos, config) junto. No hay variante "plana" para apps chicas:
   incluso una app de un solo dominio arranca con un módulo dentro de
   `modules/`.
2. **Un componente/hook/util usado por un solo módulo vive adentro de ese
   módulo.** Se promueve a nivel de app (`components/`, `hooks/`, `lib/`)
   recién cuando lo necesita un segundo módulo — no antes. Un primitivo
   genuinamente reusable desde el día uno (ej. un input con validación,
   útil para cualquier form de cualquier dominio) nace directo a nivel de
   app, no dentro de un módulo a la espera de "promoción".
3. **Validación en los bordes.** Todo input de usuario (form, Server
   Action, llamada a servicio/API) se valida con un schema (zod u otro)
   antes de tocar datos — aunque el form ya valide client-side.
4. **No introducir dependencias ni capas nuevas** (state manager global,
   ORM, librería de UI nueva) sin una razón concreta documentada en
   `feature-list.json`.

## Estructura — Next.js (App Router)

| Carpeta | Contenido |
| --- | --- |
| `app/` | Rutas. `page.tsx` es un Server Component que hace el fetching y renderiza directo el "container" del módulo. No existe `screens/` aparte. |
| `modules/<dominio>/` | Todo lo del dominio — ver desglose abajo. |
| `components/`, `hooks/` (nivel de app) | Lo que reutiliza **más de un módulo**, incluyendo primitivos reusables desde el inicio (ver principio 2). |
| `lib/` | Infraestructura transversal: cliente de DB (si no hay backend separado), helpers HTTP, env vars, formateo. |
| `schemas/` | Schemas de validación (zod u otro) compartidos entre módulos. |

Dentro de cada `modules/<dominio>/`: `components/` (incluye el container
que `page.tsx` renderiza), `ui/`, `hooks/` (estado de cliente, no
fetching), `actions/` (Server Actions, una por mutación), `queries.ts`
(lecturas awaited desde `page.tsx`), `config/`, `helper/`, `types/`.

**Data fetching**: lecturas vía `await` a `queries.ts` desde `page.tsx`.
Escrituras siempre vía Server Action en `actions/`, invocada preferentemente
con `<form action={accion}>`. Toda Server Action valida su input con schema
antes de tocar datos, y llama `revalidatePath`/`revalidateTag` al terminar —
el cliente nunca refetchea a mano.

```
usuario → app/<ruta>/page.tsx (Server Component)
            │
            ├─ await modules/<dominio>/queries.ts  (lectura)
            │        └─→ DB / backend
            │
            └─→ modules/<dominio>/components/<dominio>-container.tsx
                     │
                     └─ <form action={...}> → modules/<dominio>/actions/<accion>.ts
                              │                     ("use server")
                              ├─ valida con schema (zod)
                              └─→ DB / backend → revalidatePath/Tag
```

`"use client"` solo en la hoja más chica posible del árbol, nunca en
`page.tsx` ni en un layout salvo estrictamente necesario.

## Estructura — React + Vite (SPA)

Sin Server Components ni Server Actions: no hay frontera server/client, así
que el fetching vive en `hooks/` del módulo (vía `services/`), igual que en
una app mobile.

| Carpeta | Contenido |
| --- | --- |
| `app/` o `routes/` | Rutas del router elegido (ej. react-router). Cada ruta renderiza el container del módulo correspondiente — queda como glue, sin lógica propia. |
| `modules/<dominio>/` | Todo lo del dominio — ver desglose abajo. |
| `components/`, `hooks/` (nivel de app) | Lo que reutiliza **más de un módulo**, incluyendo primitivos reusables desde el inicio (ver principio 2). |
| `lib/` | Cliente HTTP/API, config, helpers puros. |

Dentro de cada `modules/<dominio>/`: `components/` (incluye el container),
`ui/`, `hooks/` (estado **y** fetching de datos del dominio), `services/`
(llamadas a la API — se llama `services/`, no `actions/`, porque "Server
Action" no existe fuera de Next.js), `config/`, `helper/`, `types/`.

```
usuario → app/<ruta> (route del router)
            │
            └─→ modules/<dominio>/components/<dominio>-container.tsx
                     │
                     ├─ modules/<dominio>/hooks/use-<dominio>.ts (lectura)
                     │        └─→ modules/<dominio>/services/<dominio>-service.ts
                     │                 └─→ backend API
                     │
                     └─ form (react-hook-form) → valida con schema (zod)
                              └─→ modules/<dominio>/services/<accion>-service.ts
                                       └─→ backend API
```

## Ejemplo — primitivo reusable vs. específico de dominio

`ui/input.tsx` (nivel de app) es la primitiva visual pura. `components/forms/input-with-validation.tsx` (nivel de app, **no** dentro de
`modules/<dominio>/`) la envuelve con `useController` de react-hook-form —
vive a nivel de app porque cualquier módulo con formularios lo va a
necesitar, no hace falta esperar un segundo consumidor real para
"promoverlo". Un componente que sí es específico de un dominio (ej. una
card de resultado de búsqueda con el formato propio de `<dominio>`) se
queda dentro de `modules/<dominio>/ui/cards/` hasta que otro módulo
necesite exactamente ese mismo formato.

## Qué NO hacer

- No fetchear datos dentro de `app/`/`routes/` en Vite — ahí no hay
  frontera server/client como en Next; el container llama directo a los
  hooks del módulo.
- No poner `"use client"` en `page.tsx` ni en un layout de Next salvo
  estrictamente necesario — mantener el árbol como Server Components el
  mayor tiempo posible.
- No crear una carpeta `screens/` separada — el componente que la ruta
  renderiza vive en `modules/<dominio>/components/`.
- No agregar un sistema de estado global ni config nuevo sin documentarlo
  primero en `feature-list.json`.
