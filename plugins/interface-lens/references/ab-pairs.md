# Pares A|B — el método de la pregunta

Cómo se opera la familia G del catálogo (`principles.md`). Los principios dicen *qué*
mueve la conducta; este archivo dice *cómo* se convierte una pantalla en dos y se
justifica cada cambio. Lo usa `/glow-up` en su pase funcional; `/ui-judge` lo lee cuando
audita una pantalla de decisión.

## La regla

> Cada elemento de la pantalla le está haciendo **una pregunta** al usuario. La pregunta
> que hacés determina si actúa o duda.

**La pregunta** es la unidad de análisis: no "este botón es chico" sino "este botón
pregunta *¿me comprometo?* cuando podría preguntar *¿empiezo?*".

**El canje** es la operación: reemplazar una pregunta difícil por una fácil que consigue
lo mismo. Calibración con tres pares reales:

| Pantalla | Pregunta difícil (A) | Pregunta fácil (B) |
|---|---|---|
| Paywall de suscripción | ¿Vale 19 $ al mes? | ¿Puedo probarlo gratis? |
| Selector de viaje | ¿Cuánto estoy dispuesto a arriesgar? | ¿Cuál quiero? |
| Ficha de alojamiento | ¿Completo este formulario? | ¿Me voy a este lugar? |

Un canje no baja el precio ni agrega oferta: **cambia lo que el usuario tiene que
resolver de cabeza para avanzar.** Si la pregunta fácil consigue algo distinto de lo que
el producto necesita, no es un canje — es una evasión.

## El par y su variable única

Un par es A y B **comparables**: misma oferta, mismo precio, mismos datos, misma foto.
La única variable es la presentación. Cada cambio entre A y B es un **delta**, y cada
delta toca un elemento y solo uno.

Dos deltas en el mismo elemento, o un delta que cambia la oferta, dejan de ser un par:
son un rediseño, y un rediseño no enseña nada porque no se puede atribuir el resultado.
Declarar los invariantes por escrito es lo que mantiene el par honesto.

## Los siete lugares donde vive un delta

Interrogatorio de la pantalla. Cada renglón es una pregunta al diseño, con el principio
de la familia G que la responde:

1. **El copy del control** — ¿implica compromiso o comienzo? *Subscribe* activa "pago
   recurrente, difícil de cancelar"; *Start* implica arranque. Y el posesivo importa:
   *my free trial* da propiedad antes del tap, *your* no.
2. **La cifra** — ¿hay algún rango, "desde" o promesa vaga que pueda ser un número
   exacto? [G·Rango = duda] [G·Especificidad = confianza]
3. **El ancla** — ¿qué número ve primero? Un precio aislado se juzga contra el
   presupuesto mensual; el mismo precio junto a un tachado real, o expresado como
   fracción de algo grande, casi no registra. [G·Anclaje]
4. **La imagen** — ¿muestra el producto o decora? Nadie se compromete con lo que no
   puede visualizar: una ilustración hermosa que no responde *qué estoy comprando*
   ocupa el lugar del contenido que sí lo haría.
5. **El momento del total** — ¿el número final está donde se decide, o en el paso
   siguiente? "Reservar · 445 € total" mata la ansiedad de costo oculto en el lugar
   exacto donde nace. [G·Sesgo de transparencia]
6. **La objeción sin responder** — ¿qué duda queda en la cabeza del usuario, y se
   contesta con una línea? ("cancelación gratis antes del 26 de marzo", "el día 5 te
   avisamos"). Anticipar la objeción n.º 1 en pantalla es más barato que perder el tap.
7. **El punto de partida** — ¿la pantalla arranca en cero? Campos vacíos, progreso en
   0%, nada del usuario todavía en el producto. La línea de largada la elegís vos.
   [G·Sesgo del default] [D·Goal-Gradient] [G·Efecto IKEA]

Un delta que no mueve ninguna de las siete preguntas es cosmético: se descarta.

## Los cuatro deltas reversibles

Estos cuatro convierten más justamente porque explotan el sesgo, y se dan vuelta hacia
el dark pattern con un solo dato falso. Cada uno pasa el gate antes de entrar a B:

| Delta | Entra a B si… | Es dark pattern si… |
|---|---|---|
| Precio tachado / descuento | ese precio se cobró de verdad | el tachado nunca existió |
| Badge comparativo ("más barato", "−31 %") | hay referente verificable y se puede nombrar | compara contra nada |
| Urgencia, contador, escasez | el dato sale del backend real | está hardcodeado o se resetea al recargar |
| Encuadre de pérdida ("perdés estos archivos") | la pérdida ocurre de verdad | la consecuencia está fabricada |

El corte: **el usuario, sabiendo lo que vos sabés, ¿seguiría eligiendo igual?** El aviso
del día 5 antes del cobro es el ejemplo del lado correcto — convierte más *por* ser
honesto. Cuando un delta cae del lado rojo, la salida es su versión honesta (mostrar el
stock real, poner el referente del badge), no borrarlo sin reemplazo. Taxonomía completa
y señales de código: `dark-patterns.md`.

## Cobertura y límites

- **Sesgo de funnel.** Todo esto es maquinaria pre-conversión: primera visita, paywall,
  onboarding, checkout. No dice nada sobre uso recurrente, navegación, densidad de
  información ni accesibilidad. Aplicado a una pantalla de trabajo diario, sobra.
- **Generador de hipótesis, no evidencia.** Las fuentes afirman ganadores sin publicar
  tasas ni tamaños de muestra. Un par es una hipótesis lista para testear; presentarlo
  como "B convierte más" sin test propio es inventar el dato.

## Fuentes

Destilados del acervo (rutas locales de la máquina de Leo):

- `productos/acervo/app/items/top-3-ux-ui-redesigns-that-make-you-design-like-a-pro/` —
  uxpeak, 2026-05-31: los tres pares, la regla de la pregunta, sesgo de transparencia,
  facilidad evaluativa. [Original](https://www.youtube.com/watch?v=zr37ibqXl1U)
- `productos/acervo/app/items/the-ux-psychology-behind-apps-people-can-t-stop-using/` —
  uxpeak, 2026-07-02: defaults, goal-gradient, reciprocidad, IKEA, aversión a la
  pérdida, contraste. [Original](https://www.youtube.com/watch?v=2TlIg3VokY8)
- Pantallas reales para calibrar el ojo: [Mobbin](https://mobbin.com/uxpeak).
