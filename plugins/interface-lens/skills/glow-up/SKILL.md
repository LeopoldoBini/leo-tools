---
name: glow-up
description: Deja una vista hermosa y más usable editando su código, restando el AI slop y verificando con screenshot antes/después. Usar al pulir, rediseñar o "dejar impecable" una pantalla existente, o al terminar una UI que generó un agente.
---

<!-- model-invocable: pulir una vista es trabajo de edición sobre código que ya existe, no orquestación: no crea issues, no despacha subagentes, no mergea. Tiene que poder cargarla el agente que está haciendo UI, sin que Leo se acuerde de pedirla. -->

# /glow-up — dejala hermosa y que funcione mejor

Te pasan una vista y la devolvés **mejorada y andando**. No auditás, no puntuás, no
listás lo que está mal: editás el código y mostrás el resultado.

Tres pases sobre la misma vista, en este orden: **restar** (sacar el slop), **el visual**
(que se vea terminada) y **el funcional** (que sea más fácil de usar y de decidir).
Restar va primero porque casi siempre es lo que más mejora y lo único que el modelo no
hace solo: tiende a agregar.

## Paso 0 — Cargar el cómo

1. `${CLAUDE_PLUGIN_ROOT}/references/slop.md` — qué se resta y con qué detector.
2. `${CLAUDE_PLUGIN_ROOT}/references/craft.md` — las diez reglas del pase visual.
3. `${CLAUDE_PLUGIN_ROOT}/references/ab-pairs.md`, sección **los siete lugares donde vive un delta** — el pase funcional.

`principles.md` solo si necesitás el nombre canónico de un principio. Nada más se lee.

## Paso 1 — Ubicar la vista y su sistema

Identificá los archivos que la componen (componente, estilos, tokens, datos que recibe).
Si el input es un screenshot o una URL sin código, pedí la ruta del componente: sin
código no hay glow-up, hay opinión.

Después extraé del proyecto, **antes de tocar nada**:

| Qué | Dónde mirar |
|---|---|
| Tokens de color, radios, sombras | `tailwind.config.*`, CSS custom properties, tema de shadcn |
| Escala tipográfica y fuentes cargadas | config de Tailwind, `@font-face`, `<link>` de fuentes, layout raíz |
| Componentes que ya resuelven el patrón | carpeta de UI del proyecto (`components/ui`, design system interno) |
| Cómo se ve el resto de la app | dos o tres vistas vecinas ya terminadas |

Cerrás el paso con la lista de tokens y componentes que vas a **reutilizar**. Un valor
nuevo entra solo si ninguno existente sirve, y entra como token del sistema.

## Paso 2 — Ver el antes

1. Levantá la app y sacá screenshot de la vista como está (el runner del proyecto, o
   Playwright si está disponible). Si no se puede levantar (falta backend, datos,
   credenciales), decilo en una línea y seguí desde el código, pero probá primero.
2. Corré el detector sobre los archivos de la vista y guardá su salida (`slop.md` dice
   cómo). Es el número del antes.

## Paso 3 — Restar

Con la salida del detector y la tabla de juicio de `slop.md` sobre el screenshot:

- Sacá cada indicador que ninguna marca pidió, con la receta de **cómo se resta**.
- Borrá lo duplicado en pantalla: el mismo dato o la misma idea dicha dos veces.
- Lo que el sistema del proyecto usa a propósito queda: es identidad, no slop.

El paso cierra cuando cada hallazgo del detector está **restado o justificado** en una
línea.

## Paso 4 — Pase visual

Aplicá `craft.md` en su orden, editando los archivos. Los cuatro que más mueven el
resultado, si hay que priorizar: **espaciado por grupos**, **jerarquía de tres niveles
con un solo primario**, **estados completos** y **contraste de texto**.

Cierra cuando las diez reglas están **aplicadas o descartadas con motivo**, recorridas
de una a diez. Nada de lo que agregues puede ser un indicador de `slop.md`.

## Paso 5 — Pase funcional

Recorré los siete lugares de `ab-pairs.md` sobre la vista —el copy del control, la
cifra, el ancla, la imagen, el momento del total, la objeción sin responder, el punto de
partida— y aplicá los que correspondan. En una pantalla de trabajo diario (sin decisión
de compra ni compromiso) suele quedar solo el copy del control y el punto de partida: no
fuerces el resto.

**Regla de construcción:** todo dato que muestres sale de datos reales del producto. Si
el dato no existe, el elemento no se pone.

## Paso 6 — Verificar corriendo

1. Screenshot del **después**, misma vista, mismo viewport, y otro a **360px** de ancho:
   sin scroll horizontal, sin nada cortado.
2. Detector otra vez: el número de indicadores **baja o se justifica**.
3. Recorrer con **teclado**: cada control alcanzable y con foco visible.
4. La app compila y la vista no perdió funcionalidad (handlers conectados, datos llegando).

Si el después no se ve mejor que el antes, no terminó: volvé al Paso 3. El screenshot
es el criterio, no tu descripción del cambio.

## Paso 7 — Entregar

Corto y sin diagnóstico:

```
## Antes / después
Los dos screenshots (o una línea si no se pudo levantar la app).
Slop: N → M indicadores.

## Qué cambió
Una línea por cambio, agrupada en "se restó", "se ve" y "se usa".
Cada línea nombra el elemento concreto, no el principio.

## Del sistema
Tokens y componentes reutilizados; valores nuevos que hubo que agregar, si hubo.

## Si querés seguir
Máximo tres cosas que quedaron afuera por alcance, en una línea cada una.
```

Sin score por familia ni sección de trade-offs. Si lo que se pide es juzgar sin editar,
eso es `/ui-judge`.
