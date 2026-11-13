# CHANGELOG — interface-lens

## 2.0.0 — 2026-11-13

De cinco skills a dos, ambas visibles al modelo. En cien días de uso medido, las tres
skills de solo-slash nunca se invocaron y las dos visibles se usaron solas.

- **Nuevo:** `references/slop.md` y el detector `scripts/slop-scan.mjs` (27 indicadores
  mecánicos, veredicto por densidad).
- **`/glow-up`:** suma el pase de restar slop antes del visual y mide el detector
  antes/después; el pase funcional ahora recorre los siete lugares reales de `ab-pairs.md`.
- **`/ui-judge`:** rehecha. Sin puntaje por familia; slop + uso + dark patterns solo si
  la pantalla pide un compromiso. Visible al modelo, para que la cargue el revisor.
<!-- acta -->
- **Retiradas**: `/dark-pattern-scan` (su contenido vive en `/ui-judge`),
  `/ab-variant` (pedía infraestructura de A/B; `ab-pairs.md` queda de referencia) y
  `/ux-design`.
<!-- /acta -->
