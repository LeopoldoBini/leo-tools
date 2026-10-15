---
name: ab-variant
description: Par A|B de una pantalla de decisión — nombra la pregunta que le hace al usuario, la canjea por una más fácil y deriva deltas mínimos, cada uno con su principio declarado, su gate ético y su implementación.
disable-model-invocation: true
---

# /ab-variant — la misma pantalla, la pregunta fácil

Tomás una pantalla de decisión (paywall, checkout, onboarding, ficha de producto,
selector de opciones) y devolvés **el par**: A como está, B con la pregunta canjeada.

Tu valor no es rediseñar más lindo. Es que cada cambio entre A y B sea un **delta**
atribuible: un elemento, un principio, una pregunta que se volvió más fácil. Un
rediseño entero no enseña nada porque no se puede atribuir el resultado.

## Paso 0 — Cargar la base de conocimiento

Leé, en este orden, ANTES de mirar el input:

1. `${CLAUDE_PLUGIN_ROOT}/references/ab-pairs.md` — la pregunta, el canje, los siete lugares del delta, los cuatro deltas reversibles. Es el método.
2. `${CLAUDE_PLUGIN_ROOT}/references/principles.md` — familia **G** completa; A–F para nombrar deltas que caen fuera de conversión.
3. `${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md` — eje ético, prueba del arrepentimiento, escalas.

`dark-patterns.md` se lee solo si el Paso 4 marca un delta del lado rojo.

## Paso 1 — Fijar A y su tarea

A es lo que existe hoy: screenshot, URL, mockup descrito o código de la vista. Si el
input es código, leé los archivos y reconstruí qué ve el usuario.

Necesitás dos cosas antes de seguir, y si falta alguna preguntala en **una** pregunta:

- **La tarea del usuario final** — qué vino a lograr, en sus términos.
- **La decisión que la pantalla le pide** — el tap que la pantalla existe para conseguir.

Cerrás el paso con el **inventario de A**: la lista de sus elementos visibles (título,
imagen, cifras, campos, control principal, control de descarte, lo que hay bajo el
botón), y al lado de cada uno **la pregunta que le hace al usuario**, escrita en primera
persona del usuario. Todo elemento del inventario tiene su pregunta escrita; el que no
la tenga es un elemento que no entendiste todavía, no uno que no pregunta nada.

## Paso 2 — Nombrar la pregunta dominante y canjearla

De todas las preguntas del inventario, una es la que decide: la que el usuario tiene que
resolver para tocar el botón. Escribila, y escribí al lado su canje.

```
Pregunta de A: "¿Vale 19 $ al mes?"
Pregunta de B: "¿Puedo probarlo gratis?"
```

**Gate del canje** — la pregunta de B pasa si cumple las tres:

1. Es más fácil de responder (menos cálculo, menos incertidumbre, menos riesgo percibido).
2. Contestarla afirmativamente **produce la misma decisión** que la pantalla necesita.
3. Se responde con lo que ya hay o con un dato verdadero — no con una promesa nueva.

Si falla la 2, es una evasión: volvé y buscá otro canje. Si falla la 3, el canje exige
cambiar el producto, no la pantalla — decilo así y ofrecé `/ux-design` para eso.

## Paso 3 — Derivar los deltas

Recorré **los siete lugares** de `ab-pairs.md` (copy del control, la cifra, el ancla, la
imagen, el momento del total, la objeción sin responder, el punto de partida) y por cada
uno decidí si hay delta. Formato de cada delta:

> **N. \<elemento\>** — A: `<lo que dice/hace hoy>` → B: `<lo que dice/hace>`
> [Familia·Principio] · mueve: `<qué pregunta se volvió más fácil>`

Reglas que hacen al par un par:

- **Un delta toca un elemento y solo uno.** Dos cambios en el mismo elemento se fusionan en uno o se parte el par en dos.
- **Todo delta mueve una de las siete preguntas.** El que no la mueve es cosmético: se descarta, no se documenta.
- **Los invariantes se declaran**: misma oferta, mismo precio, mismos datos, misma foto. Un delta que cambia la oferta sale del par y se reporta aparte como cambio de producto.
- Entre 3 y 7 deltas. Menos de 3 y no hay par que valga la pena; más de 7 y estás rediseñando — quedate con los que más mueven la pregunta dominante y decí cuáles dejaste afuera.

## Paso 4 — Gate ético, delta por delta

Cada delta que toque precio tachado, badge comparativo, urgencia/escasez o encuadre de
pérdida pasa por la tabla de **deltas reversibles** de `ab-pairs.md`:

1. Nombrá el dato del que depende y de dónde sale (backend real, dato histórico, nada).
2. Aplicá la **prueba del arrepentimiento**: sabiendo lo que vos sabés, ¿elegiría igual?
3. Veredicto 🟢 / 🟡 (con la condición escrita) / 🔴.

Un 🔴 sale de B **reemplazado por su versión honesta** — el stock real en vez del
inventado, el referente nombrado en el badge, la pérdida que efectivamente ocurre.
Nombrá el patrón de `dark-patterns.md` que estabas a punto de shippear: ese es el
hallazgo más valioso del par.

## Paso 5 — Entregable

En el chat; NADA de artifacts salvo pedido explícito.

```
## La pregunta
A: "…"  →  B: "…"   (una línea de por qué la de B es más fácil)

## El par, pantalla contra pantalla
Dos bloques paralelos, elemento por elemento, en el mismo orden de lectura.
Si el input fue visual, describí B con el detalle suficiente para dibujarla.

## Deltas
Tabla numerada: elemento · A → B · [Familia·Principio] · pregunta que mueve.

## Invariantes
Qué NO cambió (oferta, precio, datos, foto). Sin esta línea no es un par.

## Gate ético
Un renglón por delta reversible: dato, origen, veredicto 🟢/🟡/🔴, condición.
"Ningún delta reversible" también se declara.

## Implementación
Solo si el input fue código: el diff o los archivos de B, con cada cambio
trazable a su número de delta.

## Cómo se testea
La hipótesis en una línea, la métrica que la mide y qué resultado la refuta.
```

## Honestidad del par

El par es una **hipótesis lista para testear**, no un resultado. No afirmes que B
convierte más: afirmá qué pregunta se volvió más fácil y qué hay que medir para saberlo.
Cuando el pedido llegue con la métrica del negocio por delante, mantené el norte
time-well-spent — un canje que sube el tap y baja la satisfacción del usuario es un
delta que hay que reportar como tal, no un triunfo.

Cerrá ofreciendo (sin ejecutarlo) auditar B con `/ui-judge`, o `/dark-pattern-scan` si
el gate del Paso 4 dejó algún 🟡 sobre un flujo de suscripción o checkout.
