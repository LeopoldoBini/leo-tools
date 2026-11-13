# interface-lens

Mejorar y juzgar interfaces restando el AI slop, con psicología UX **más la brújula que
las listas de heurísticas no traen**: un eje ético (ético → persuasivo → oscuro) y la
prueba del arrepentimiento de Nir Eyal.

## La idea en una línea

La IA genera interfaces con los mismos tics (gradientes, eyebrows, pills, bordes en todo,
texto que se repite) y con la psicología del enganche apuntada a capturar en vez de
servir. Este plugin resta lo primero y vigila lo segundo, en dos skills que el agente
carga solo cuando está haciendo o revisando UI.

## Skills

| Skill | Verbo | Qué hace |
|---|---|---|
| `/glow-up` | **Aplicar** | Edita la vista: resta el slop, aplica las diez reglas de craft y el pase funcional, y verifica con screenshot y detector antes/después. |
| `/ui-judge` | **Juzgar** | Solo lee: slop, uso y terminación, y —si la pantalla pide un compromiso— dark patterns con asimetría de fricción. Hallazgos con `archivo:línea`. |

Las dos son visibles al modelo: una skill que depende de que alguien se acuerde de
invocarla no se usa. Ninguna orquesta.

## El detector

`scripts/slop-scan.mjs` mide el slop mecánico sobre el código: cuántos indicadores
distintos aparecen juntos, con `archivo:línea`. Corre con node o bun, sin dependencias;
`--reglas` lista lo que mira. Tests: `node --test` en `scripts/`.

```bash
node scripts/slop-scan.mjs <carpeta-de-la-vista> [--json]
```

## Estructura

```
interface-lens/
  GLOSSARY.md                ← lenguaje compartido: bucle, eje ético, escalas, el par
  references/
    slop.md                  ← AI slop: cómo correr el detector, indicadores de juicio, cómo se resta
    craft.md                 ← cómo se ve una UI terminada: las diez reglas de ejecución
    ab-pairs.md              ← la pregunta, el canje, los siete lugares de un delta
    dark-patterns.md         ← taxonomía operativa con señales de código por patrón
    principles.md            ← catálogo de 37 principios (familias A–G), nombres canónicos
  scripts/
    slop-scan.mjs            ← detector mecánico (+ test y fixtures)
  skills/
    glow-up/  ui-judge/
```

## Principios de diseño del plugin

- **Evidencia o nada:** ningún hallazgo sin elemento concreto, cita o `archivo:línea`. El prompting genérico contra heurísticas ronda 50–75% de precisión; el anclaje a evidencia es lo que lo sube.
- **Flujos, no pantallas:** los dark patterns más graves (roach motel, forced continuity) solo emergen en la interacción — por eso el scan rastrea rutas de entrada/salida en el código.
- **Honestidad sobre límites:** cada auditoría declara qué NO pudo evaluarse desde el input recibido.
- **Norte time-well-spent:** tarea cumplida bien, no tiempo en app.
- **Restar antes que sumar:** el modelo tiende a agregar; casi toda mejora real de una UI generada empieza por sacar.

## Vecinos

`ui-ux-pro-max` (marketplace de terceros) **genera un sistema visual desde cero**:
paletas, tipografías y estilo para un proyecto que todavía no tiene ninguno. `craft.md`
va al revés: **adopta el sistema que el proyecto ya tiene** y lo ejecuta bien. Si
arrancás de cero, el primero; si tenés una app andando, `/glow-up`.

## Origen

Destilado de dos videos de uxpeak del acervo — *"The UX Psychology Behind Apps People
Can't Stop Using"* (`2TlIg3VokY8`, familias A–F) y *"Top 3 UX/UI Redesigns"*
(`zr37ibqXl1U`, familia G y el método del par) —, cruzado con BJ Fogg (B=MAP), Nir Eyal
(*Hooked*), [Laws of UX](https://lawsofux.com/) (Jon Yablonski), Kahneman & Tversky y
Cialdini, más la capa ética (taxonomía de dark patterns, prueba del arrepentimiento,
time-well-spent). Las citas por familia están en `references/`.
