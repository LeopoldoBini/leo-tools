# Craft visual — cómo se ve una UI terminada

Reglas operativas de ejecución, no criterios de juicio: cada renglón se aplica editando
código. Lo usa `/glow-up`. Los porqués psicológicos están en `principles.md` (familias E
y B); acá está el **cómo**.

La diferencia entre una UI que parece demo y una que parece producto casi nunca es la
idea: es el ritmo del espaciado, los estados que faltan y los tres tamaños de fuente
sueltos. Este archivo es esa lista.

## 1. Adoptar el sistema, nunca imponerlo

Antes de tocar un color, sacá del proyecto lo que ya existe: tokens de Tailwind o CSS
custom properties, tema de shadcn, tipografías cargadas, radios y sombras en uso,
componentes que ya resuelven el patrón. **Un valor nuevo se agrega solo si no hay uno
que sirva**, y se agrega al sistema (token), no suelto en la clase.

Una vista embellecida con colores propios desentona con el resto de la app: se ve peor
que antes, aunque aislada se vea mejor.

## 2. Jerarquía — tres niveles y un solo primario

- Tres niveles de énfasis por vista: **primario** (la acción o el dato que importa), **secundario**, **terciario**. Un cuarto nivel no se percibe, solo ensucia.
- Un solo botón primario visible por pantalla. Lo demás baja a secundario, *ghost* o link.
- Jerarquía por **tamaño + peso + color**, en ese orden. El dato más importante es el más grande; si dos cosas compiten por la mirada, ninguna gana. [E·Von Restorff]
- El título de la vista no tiene por qué ser lo más grande: muchas veces el dato es el protagonista (el precio, el total, el nombre).

## 3. Espaciado — el arreglo más rentable

- Una sola escala, múltiplos de 4 (4·8·12·16·24·32·48·64). Nada de `13px` ni `mt-[7px]`.
- **Regla de proximidad:** el espacio *dentro* de un grupo siempre menor que el espacio *entre* grupos. Label pegado a su input; bloques separados. Cuando una UI se siente "desordenada" sin saber por qué, casi siempre es esto invertido. [E·Gestalt]
- El padding de un contenedor ≥ el mayor espacio interno; si no, el contenido parece apretado contra el borde.
- Alineá bordes y baselines: una columna imaginaria por la izquierda del contenido. Un desalineado de 2px se percibe sin poder nombrarlo.

## 4. Tipografía

- Escala geométrica de 5–6 pasos y nada más (ej. 12·14·16·20·24·32). Cada tamaño con su rol declarado.
- `line-height` inverso al tamaño: títulos 1.1–1.25, cuerpo 1.5–1.6. Un título con line-height de párrafo se ve flojo.
- Medida de lectura 45–75 caracteres (`max-w-prose` o `max-w-[65ch]`). Texto que cruza toda la pantalla no se lee.
- `font-variant-numeric: tabular-nums` en cifras que se comparan o cambian (precios, contadores, tablas): sin eso los números bailan.
- Un peso por rol (400 cuerpo, 500/600 títulos y labels). Cinco pesos distintos en una vista es ruido.
- Sin mayúsculas sostenidas en frases; solo en labels muy cortos y con `letter-spacing` positivo.

## 5. Color

- Tres capas: **superficie** (fondos), **contenido** (texto e iconos), **acento** (uno solo). El acento se reserva a la acción primaria y a lo seleccionado; si el acento está en seis lugares, no señala nada.
- Contraste: texto normal ≥ 4.5:1, texto ≥ 24px o bold ≥ 18px puede 3:1, bordes de control ≥ 3:1. El gris sobre gris claro es el defecto más común y el más fácil de arreglar.
- Semántica (éxito, alerta, error, info) **nunca solo por color**: siempre con icono o texto.
- Si hay modo oscuro, se resuelve con tokens, no con un segundo set de clases. Y en oscuro se bajan las saturaciones: el acento del modo claro suele vibrar.

## 6. Profundidad, bordes y radios

- Borde **o** sombra, no los dos en el mismo elemento.
- Una escala de sombras de 3 pasos, suaves y con la misma dirección de luz (siempre hacia abajo).
- Radio consistente por familia: mismo radio en botones e inputs; el radio del contenedor ≥ radio del hijo + padding, o el hijo se ve cortado.

## 7. Estados — donde se juega la diferencia

Todo elemento interactivo tiene los seis: **hover**, **focus-visible**, **active**,
**disabled**, **loading**, y su contraparte de datos: **vacío** y **error**.

- `focus-visible` con anillo propio y contraste ≥ 3:1 — nunca `outline: none` sin reemplazo.
- `cursor-pointer` en todo lo clickeable; `cursor-not-allowed` en lo deshabilitado.
- **Empty state con acción**, no una frase triste: qué es esto, y el botón que lo llena.
- **Skeleton con el layout final** — mismas alturas y anchos, así no hay salto cuando llegan los datos.
- Error con el mensaje al lado del campo que lo causó, en texto, redactado como se arregla ("falta el año") y no como falló ("input inválido").
- Toda acción tiene feedback en menos de 100ms, aunque sea el estado *loading*. [B·Doherty]

## 8. Movimiento

- 150–250ms, `ease-out` para entrar y `ease-in` para salir. Más de 300ms se siente lento.
- Solo `transform` y `opacity` (el resto reflowea). Nada de animar `height` sin necesidad.
- Respetar `prefers-reduced-motion`.
- Se anima lo que cambia de estado o de lugar; una animación decorativa que se repite molesta a la tercera vez.

## 9. Toque, densidad y responsive

- Objetivos ≥ 44×44px reales; separación ≥ 8px entre objetivos adyacentes. [B·Fitts]
- Acción primaria al alcance del pulgar en mobile; lo destructivo lejos de ella. [B·Thumb zone]
- Probar 360px de ancho antes que el desktop: lo que sobrevive ahí sobrevive en todas partes.
- Sin scroll horizontal, y el contenido no se corta al hacer zoom al 200%.

## 10. Detalles que separan producto de demo

Iconos SVG de un solo set (Lucide, Heroicons), nunca emojis como iconos · números
formateados con locale y unidad · fechas con día de la semana cuando importa · truncado
con `title` o tooltip · `aria-label` en todo botón que solo tiene icono · `alt` real en
imágenes de contenido · el copy sin jerga interna del sistema.

## Antipatrones

Las señales de UI generada al apuro —el AI slop— viven en `slop.md`, con su detector.

## La regla de construcción

Todo dato que la pantalla muestre **sale de datos reales del producto**. Si el dato no
existe todavía, el elemento no se pone (nada de contadores, stock, badges de descuento o
métricas de relleno). No es una regla de estilo: un número inventado se convierte en un
bug el día que alguien lo cree.
