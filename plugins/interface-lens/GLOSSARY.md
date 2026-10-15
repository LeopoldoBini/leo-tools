# GLOSSARY.md — lenguaje compartido de interface-lens

Glosario canónico del dominio. Las cinco skills razonan con este modelo mental; los
términos de acá son los únicos nombres válidos para estos conceptos.

`/glow-up` es la excepción parcial: **aplica** en vez de juzgar, así que usa estos
términos para decidir qué edita, pero no los reporta. Sus reglas de ejecución están en
`references/craft.md`.

## El bucle (estructura temporal)

Los 37 principios del catálogo **no son una lista: son un bucle** que se recarga solo.
Ordena *cuándo* actúa cada principio.

```
        ┌──────────────────── ↺ recarga ────────────────────┐
        │                                                    │
   DISPARADOR ──→ ACCIÓN ──→ RECOMPENSA ──→ INVERSIÓN ───────┘
   (A)           (B·E)       (C)            (D)
   Fogg          Fitts       recompensa     rachas
   Zeigarnik     Hick        variable       goal-gradient
   push          Doherty     dopamina       identidad

   Familia E (claridad/legibilidad) sostiene TODO el bucle.
   Familia F (ética) decide su DIRECCIÓN.
   Familia G (decisión) opera en el instante del tap, entre DISPARADOR y ACCIÓN:
   es la que decide si el bucle arranca alguna vez.
```

## El eje ético (dirección)

Ordena *hacia dónde* apunta cada mecánica. El mismo motor puede **servir** al usuario
o **capturarlo**.

```
   ético ────────────── persuasivo ────────────── oscuro
   (alinea con           (empuja al                (captura contra
    el usuario)           producto)                 la voluntad)
      🟢                     🟡                        🔴
```

## Términos canónicos

| Término | Definición | No confundir con |
|---|---|---|
| **Bucle** | disparador→acción→recompensa→inversión (Fogg/Eyal). La unidad de análisis de un flujo. | "funnel" (embudo de conversión, mide al negocio; el bucle mide al hábito) |
| **Familia A–G** | Las 7 familias del catálogo: A disparadores, B acción/fricción, C recompensa, D inversión, E claridad, F ética, G decisión. | — |
| **La pregunta** | Lo que un elemento de la pantalla le hace resolver al usuario, en primera persona de él ("¿vale 19 $ al mes?"). Unidad de análisis de la familia G. | el copy del elemento (el texto es el medio; la pregunta es lo que produce en la cabeza) |
| **El canje** | Reemplazar una pregunta difícil por una fácil que produce la misma decisión. | bajar el precio o agregar oferta (eso cambia la oferta, no la pregunta) |
| **El par** | A y B comparables: misma oferta, mismo precio, mismos datos, misma foto; la presentación es la única variable. | rediseño (cambia varias cosas a la vez, no se puede atribuir el resultado) |
| **Delta** | Un cambio entre A y B: un elemento, un principio, una pregunta que se vuelve más fácil. | mejora cosmética (un delta que no mueve ninguna pregunta se descarta) |
| **Delta reversible** | Delta que convierte por explotar un sesgo y se da vuelta en dark pattern con un dato falso: precio tachado, badge comparativo, urgencia, encuadre de pérdida. Tabla en `ab-pairs.md`. | dark pattern ya confirmado (el reversible pasa el gate y entra; el confirmado sale) |
| **Eje ético** | ético → persuasivo → oscuro. Atributo de cada *uso* de un principio, no del principio en sí. | "bueno/malo": la técnica es neutral, el uso no |
| **Prueba del arrepentimiento** | ¿El usuario agradecería este empujón si supiera exactamente cómo funciona? (Eyal). El filtro que decide los casos 🟡/🔴. | consentimiento formal (aceptar TOS no aprueba la prueba) |
| **Nudge** | Facilita la decisión que le conviene al usuario. | **Sludge**: fricción que estorba la salida o la decisión pro-usuario |
| **Fricción estratégica** | Fricción añadida a propósito donde protege al usuario (confirmar antes de borrar, revisar antes de pagar). | sludge (la dirección lo distingue: ¿a quién protege la fricción?) |
| **Time-well-spent** | Norte de diseño: tarea cumplida bien + usuario se va mejor. | "engagement"/"tiempo en app" como métrica de éxito |
| **Asimetría de fricción** | Pasos para entrar vs. pasos para salir de un compromiso. Test maestro de `dark-patterns.md`. | — |
| **Dark pattern** | Mecánica que falla la prueba del arrepentimiento Y está en la taxonomía de `dark-patterns.md`. | mal diseño sin intención (eso es un hallazgo de usabilidad, no un dark pattern) |

## Escalas compartidas (usadas por las 3 skills)

- **Severidad de hallazgo:** `bloqueante` (dark pattern confirmado o tarea imposible) · `alta` (fricción/confusión que hace fallar la tarea a una parte de los usuarios) · `media` (fricción notable, tarea completable) · `baja` (pulido).
- **Confianza:** `alta` (evidencia directa en el input) · `media` (inferencia razonable) · `baja` (hipótesis, requiere verificar con el input completo o con usuarios).
- **Veredicto ético por mecánica:** 🟢 pasa la prueba del arrepentimiento · 🟡 pasa con condiciones (declararlas) · 🔴 falla.
