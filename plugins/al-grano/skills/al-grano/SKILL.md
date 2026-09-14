---
name: al-grano
description: "Invocar antes de escribir el mensaje final de una tarea con varios pasos (archivos tocados, comandos corridos), y cuando el usuario pide la versión corta de lo último («hacemela corta», «resumime», «qué pasó»). Formato del parte."
model-invocable: solo reescribe lo que ya pasó en la conversación; no escribe archivos ni despacha nada
---

# al-grano

El **parte** es para alguien que lleva muchas cosas a la vez: lo lee en segundos, lo incorpora y
vuelve a lo suyo. Es corto para que den ganas de leerlo.

- **Reporte final de un trabajo con pasos:** el reporte sale directamente como parte.
- **Pedido de la versión corta de lo último:** el parte reescribe lo ya dicho, sin trabajo nuevo.
  Si al releer algo estaba mal o sin verificar, eso entra.

## Formato

Etiquetas en negrita al inicio de línea, en este orden; la que no tenga contenido se omite.

- **Ojo:** riesgo o algo roto que cambia lo que el usuario hace. Va primero.
- **Pasó:** una línea.
- **Quedó:** de una a tres líneas, una idea cada una.
- **Te toca:** decisión o acción del usuario. Lo que tiene que copiar o tipear, en bloque de código.

Techo: ocho líneas. Lo que no entra es **detalle**, y el detalle se da cuando el usuario lo pide.
Esa respuesta va completa; la siguiente vuelve al parte.

## Qué entra

Entra aunque pase el techo: un riesgo que cambia una decisión, una decisión del usuario (una línea
por opción, con su implicancia), una acción suya, un supuesto declarado como tal.

Todo lo demás es detalle: cómo se hizo, nombres técnicos, lo que salió bien sin consecuencia,
avisos menores.

Palabras de todos los días. Un concepto técnico nuevo va con analogía de una línea.

## Chequeo antes de mandar

- Se lee en veinte segundos.
- Con eso solo, el usuario sigue sin volver a preguntar.
- Cada línea resiste la pregunta «si la borro, ¿pierde algo que necesita hoy?». La que no, se borra.
