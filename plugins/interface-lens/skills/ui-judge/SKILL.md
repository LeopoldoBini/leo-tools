---
name: ui-judge
description: Audita una interfaz sin editarla (código, URL o screenshot) buscando AI slop, problemas de uso y, si pide un compromiso, dark patterns, con evidencia por hallazgo. Usar al revisar un diff que toca UI o cuando piden juzgar una pantalla.
---

<!-- model-invocable: solo lee y reporta; no edita, no crea issues ni despacha nada. Tiene que poder cargarla el revisor de un diff de UI sin que Leo la pida. -->

# /ui-judge — auditoría de interfaz

Juzgás una interfaz y devolvés hallazgos. **No editás**: si hay que arreglar, eso es
`/glow-up`. Tu valor es **anclar cada hallazgo a evidencia concreta** y decir lo que el
que la hizo no ve: el slop que metió sin darse cuenta y, si la pantalla pide un
compromiso, si manipula.

## Paso 0 — Cargar la rúbrica

1. `${CLAUDE_PLUGIN_ROOT}/references/slop.md` — siempre.
2. `${CLAUDE_PLUGIN_ROOT}/references/craft.md` — siempre: sus reglas son el criterio de uso y terminación.
3. `${CLAUDE_PLUGIN_ROOT}/GLOSSARY.md` — escalas de severidad y confianza, eje ético.
4. Solo si la pantalla pide una decisión o un compromiso (Paso 1): `references/ab-pairs.md` y `references/dark-patterns.md`.

## Paso 1 — Delimitar y clasificar

**Qué se audita.** Con un diff, la superficie es el código de UI tocado más los flujos que
ese código afecta. Si no, la vista o el flujo que te señalaron.

**Qué input hay, y qué no se puede ver desde ahí:**

| Input | Cómo | No evaluable desde ahí |
|---|---|---|
| Código | Read + detector | render real: composición, contraste efectivo |
| URL | Playwright: screenshots de los estados clave; sin browser, HTML + copy | sin browser: jerarquía visual, estética |
| Screenshot | visión | estados, flujos, código; el detector no corre |

Si hay código y la app se puede levantar, mirá también el render: la capa de juicio del
slop necesita verlo.

**Qué pide la pantalla.** Clasificala en una línea:

- **De trabajo** (gestión, listados, formularios internos, paneles): el uso recurrente manda.
- **De decisión** (paywall, checkout, pricing, onboarding, ficha de producto).
- **De compromiso** (alta o baja de suscripción, consentimiento, permisos, cancelación).

Las de decisión y compromiso suman el Paso 4.

## Paso 2 — Slop

1. Corré el detector sobre los archivos (`slop.md` dice cómo) y quedate con su veredicto
   y sus `archivo:línea`.
2. Recorré la tabla de juicio de `slop.md` sobre el render o el copy.
3. Descartá lo que es identidad del sistema del proyecto, y decilo.
4. Marcá todo lo **duplicado en pantalla**: el mismo dato, la misma idea o el mismo
   control dos veces. La duplicación de código, en cambio, es del revisor de código, no
   de acá.

## Paso 3 — Uso y terminación

Recorré `craft.md` como criterio: jerarquía con un solo primario, espaciado por grupos,
estados completos (vacío, error, loading, foco), contraste, toque y 360px. Cada regla
que falla con evidencia es un hallazgo; las que no se pueden ver desde el input van a
"No evaluable".

## Paso 4 — Decisión y compromiso (solo si aplica)

- **Pantalla de decisión:** nombrá **la pregunta** que le hace cada elemento clave al
  usuario y recorré los siete lugares de `ab-pairs.md`. El fix es el canje por la
  pregunta fácil.
- **Pantalla de compromiso:** trazá la ruta de **entrada** y la de **salida** en el
  código (pasos, canal) y medí la **asimetría de fricción**. Recorré la taxonomía de
  `dark-patterns.md` con sus señales de código: countdowns hardcodeados, stock aleatorio
  en el cliente, `checked` en opciones con costo, negativas que no se persisten,
  handlers que hacen más de lo que dice su label.
- A cada mecánica persuasiva, la **prueba del arrepentimiento**: 🟢 / 🟡 (con condición) / 🔴.
  Si un dark pattern confirmado choca con la regulación (sección regulatoria de
  `dark-patterns.md`), marcalo: es pasivo legal, no solo deuda de UX.

Distinguí **dark pattern** (falla la prueba y está en la taxonomía) de mal diseño sin
manipulación: lo segundo va al Paso 3.

## Regla de evidencia

Cada hallazgo lleva:

- **Qué** — indicador de `slop.md`, regla de `craft.md` o patrón de `dark-patterns.md`, por su nombre.
- **Evidencia** — `archivo:línea`, texto citado literal o posición en el screenshot. Prohibido un hallazgo cuyo sujeto sea "la interfaz".
- **Severidad · confianza** — escalas de `GLOSSARY.md`.
- **Fix** — instrucción implementable ("borrar el eyebrow de `Hero.tsx:12`"), no un principio.

Lo que no cumple, se descarta. Pocos hallazgos con evidencia valen más que muchos
genéricos.

## Paso 5 — Reporte

En el chat, nada de artifacts salvo pedido:

```
## Veredicto — <una línea>
Slop: <limpio | sospechoso | slop> (N indicadores; detector + juicio)
Dark patterns: PASA / FALLA   ← solo si hubo Paso 4. FALLA con ≥1 hallazgo
                                 bloqueante o alto de confianza alta.

## Hallazgos (por severidad)
1. <qué> — severidad · confianza
   Evidencia: …
   Fix: …

## Asimetría de fricción   ← solo pantallas de compromiso
Entrada vs. salida por compromiso: pasos y canal.

## No evaluable desde este input
Qué quedó afuera y cómo completarlo. Lo no mirado no está aprobado.

## Si hago solo tres cosas
```

Sin puntajes por familia. Cerrá ofreciendo, sin ejecutarlo, `/glow-up` para aplicar los
fixes visuales.
