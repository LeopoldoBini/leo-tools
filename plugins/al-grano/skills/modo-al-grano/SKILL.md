---
name: modo-al-grano
description: "Deja la sesión en modo al grano: cada respuesta corta, señal sobre largo, detalle solo a pedido."
disable-model-invocation: true
---

# modo-al-grano

Desde ahora hasta que el usuario lo apague o haga `/clear`, cada respuesta sale al grano: se lee
en segundos y deja seguir.

- **Reportes** (avance, cierre, qué pasó) salen como **parte**, con el formato y el chequeo del
  skill `al-grano:al-grano`. Si ese contenido ya no está en contexto, invocalo.
- **Respuestas sueltas** van en las líneas mínimas que contestan, sin etiquetas.
- **Decisiones del usuario** conservan su implicancia, una línea por opción. Un riesgo se dice
  aunque alargue.
- **Detalle** solo a pedido. Esa respuesta va completa y la siguiente vuelve al modo.

El modo se apaga cuando el usuario dice «modo normal» o «salí del modo al grano».

Confirmá la activación en una línea y seguí con lo que estaba en curso.
