# AI slop visual — cómo se reconoce una interfaz hecha por IA sin criterio

Lo usan `/glow-up` (para restarlo) y `/ui-judge` (para señalarlo). El slop no es un error
suelto: es la **acumulación** de tics que el modelo repite porque se entrenó con las
mismas plantillas. Una itálica no delata nada; ocho de estos juntos, sí.

Dos capas, con dueño distinto:

| Capa | Quién la mide | Dónde vive |
|---|---|---|
| **Mecánica** | el detector, sobre el código | `scripts/slop-scan.mjs` — sus reglas son la única lista; `--reglas` las imprime |
| **De juicio** | el modelo, sobre un screenshot y el copy | la tabla de abajo |

## Correr el detector

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/slop-scan.mjs" <carpeta-o-archivos-de-la-vista>
```

Devuelve cuántos indicadores **distintos** aparecen y un veredicto: `limpio` (0–2),
`sospechoso` (3–5), `slop` (6 o más), con `archivo:línea` por hallazgo. `--json` para
leerlo desde otro paso. Ignora `components/ui` (el kit vendorizado es el sistema del
proyecto, no una decisión de la vista).

Leelo como insumo, no como sentencia:

- **Un hallazgo puede ser legítimo.** Si el sistema del proyecto usa labels en
  mayúsculas o una serif en títulos, es identidad, no slop. Lo que se resta es lo que
  ninguna marca pidió.
- **Pasar en limpio no prueba nada.** El detector no ve la composición. La capa de
  juicio es obligatoria igual.

## Indicadores de juicio

Se evalúan mirando el render (o leyendo el copy). Cada uno con su prueba:

| Indicador | Prueba |
|---|---|
| UI sobredetallada | ¿Hay decoración que no responde a ninguna tarea? Contá elementos que podrías borrar sin que nadie lo note. |
| Cards dentro de cards | ¿Un contenedor con borde o fondo vive adentro de otro igual? El anidado se resuelve con espacio, no con otra caja. |
| Diagramas sobredetallados | ¿El diagrama tiene más nodos o flechas que lo que el texto necesita explicar? |
| Texto verboso o redundante | ¿El mismo dato o la misma idea aparece dos veces en la pantalla (título que repite el label, subtítulo que parafrasea el título)? |
| Iconos decorativos | ¿Cada icono ayuda a reconocer algo, o está para llenar? Un icono por item de lista es casi siempre relleno. |
| Look de plantilla | Hero centrado + tres features en columnas + CTA con gradiente: ¿podría ser la landing de cualquier SaaS? |
| Gris lavado | Texto secundario tan claro que no pasa contraste, todo en el mismo gris. |
| Jerarquía plana o gritona | ¿Compiten dos cosas por la mirada, o un panel lateral llama más que el contenido? |
| Botones de tres colores | Más de un primario por pantalla, cada uno con su color. |
| Estilos fuera del sistema | Colores crudos (`bg-pink-500`) donde el proyecto tiene tokens; para Tailwind lo atrapa mejor `shadcn/lint` si está instalado. |
| Placeholder como label | El único nombre del campo desaparece al escribir. |
| Tamaños de fuente sueltos | Más de cinco o seis tamaños en la vista, sin rol cada uno. |
| Iconos de sets mezclados | Trazos, rellenos o grosores distintos conviviendo. |

## Cómo se resta

Para cada indicador encontrado, la salida es **sacar**, no cambiar un tic por otro:

- gradiente → superficie plana del sistema;
- eyebrow, numeración, breadcrumb decorativo → se borran; el título solo alcanza;
- pills y badges → quedan solo los que son un dato (estado, cantidad);
- bordes y divisores → espacio entre grupos (`craft.md` §3);
- opacidades sueltas → los tokens de color del sistema;
- itálicas de énfasis → peso, y solo donde hay un dato.

Cuidado con el péndulo: cambiar el look "startup violeta" por "serif sobre pergamino"
es otro slop. El objetivo es el sistema del proyecto bien ejecutado, no una estética
distinta.

## Fuentes

Destilados del acervo de Leo (`productos/acervo/app/items/`): `20-ai-design-slop-indicators`
(Charles Liu, la lista de 20), `impeccable-kills-ai-design-slop` (Inter, violeta→azul,
cards anidadas, fondo crema), `agents-sucked-at-ui-until-today` (bordes sin motivo,
radios, contraste lavado), `shadcn-just-fixed-tailwind-s-biggest-problem` (estilos fuera
del sistema, valores arbitrarios).
