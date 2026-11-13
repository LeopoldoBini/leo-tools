#!/usr/bin/env node
// slop-scan — pasada mecánica de AI slop visual sobre código de interfaz.
//
//   node slop-scan.mjs <archivo|carpeta>... [--json]   escanea
//   node slop-scan.mjs --reglas                        lista los indicadores
//
// Las reglas de acá son la única fuente de los indicadores mecánicos; los de juicio
// viven en references/slop.md. Un indicador suelto no delata nada: lo que se mide es
// cuántos indicadores DISTINTOS aparecen juntos. Corre con node o bun, sin dependencias.

import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, extname, relative } from "node:path";

const EXTENSIONES = new Set([".tsx", ".jsx", ".ts", ".js", ".html", ".css", ".scss", ".vue", ".svelte", ".astro", ".mdx"]);
const IGNORAR = new Set(["node_modules", "dist", "build", ".git", ".next", ".svelte-kit", "coverage", ".turbo"]);

// minimo: cuántas apariciones en un mismo archivo hacen falta para que cuente.
// Lo que es tic por presencia lleva 1; lo que es tic por abuso, más.
export const REGLAS = [
  // Tipografía
  { id: "tracking-negativo", grupo: "tipografía", minimo: 1, que: "letter-spacing negativo en títulos", re: /\btracking-(?:tight|tighter|\[-[^\]]+\])|letter-spacing:\s*-/g },
  { id: "instrument-serif", grupo: "tipografía", minimo: 1, que: "Instrument Serif, la serif de moda de la IA", re: /Instrument[ _-]?Serif/gi },
  { id: "serif-italica", grupo: "tipografía", minimo: 1, que: "titular en serif itálica", re: /\bfont-serif\b[^"'`\n]*\bitalic\b|\bitalic\b[^"'`\n]*\bfont-serif\b/g },
  { id: "italicas", grupo: "tipografía", minimo: 3, que: "palabras en itálica para dar énfasis, de a muchas", re: /<em\b|<i>|\bitalic\b/g },
  { id: "monoespaciada", grupo: "tipografía", minimo: 4, que: "monoespaciada fuera del código", re: /\bfont-mono\b/g },
  { id: "fuente-inter", grupo: "tipografía", minimo: 1, que: "Inter para todo, la fuente por defecto de la IA", re: /font-family:[^;]*\bInter\b|["'`]Inter["'`]|\bfont-inter\b/g },
  { id: "eyebrow", grupo: "tipografía", minimo: 1, que: "eyebrow: textito en mayúsculas espaciadas encima del título", re: /\buppercase\b[^"'`\n]*\btracking-(?:wide|wider|widest)\b|\btracking-(?:wide|wider|widest)\b[^"'`\n]*\buppercase\b/g },
  { id: "mayusculas", grupo: "tipografía", minimo: 3, que: "subtítulos y labels en mayúsculas sostenidas", re: /\buppercase\b|text-transform:\s*uppercase/g },
  { id: "punto-en-titulo", grupo: "tipografía", minimo: 1, que: "punto final en un título", re: /<h[1-3]\b[^>]*>[^<{]*[\p{L}\d]\.\s*<\/h[1-3]>/gu },
  // Componentes
  { id: "pills", grupo: "componentes", minimo: 3, que: "tags y pills por todos lados", re: /<Badge\b|\brounded-full\b[^"'`\n]*\bpx-[1-3]\b/g },
  { id: "numeracion", grupo: "componentes", minimo: 1, que: "secciones numeradas tipo «01 —»", re: />\s*0\d\s*[—–\/.·]|["'`]0\d\s*[—–\/·]/g },
  { id: "breadcrumb-codigo", grupo: "componentes", minimo: 1, que: "rutas tipo ~/proyecto/seccion como decoración", re: />\s*~\/[\w-]+|>\s*\$\s+[\w-]+\s/g },
  { id: "squircle", grupo: "componentes", minimo: 1, que: "squircles (esquinas superelipse)", re: /squircle|superellipse|corner-shape/gi },
  { id: "emoji-icono", grupo: "componentes", minimo: 1, que: "emojis usados como iconos", re: /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu },
  { id: "valores-arbitrarios", grupo: "componentes", minimo: 3, que: "medidas sueltas fuera de la escala (p-[13px])", re: /\b(?:p|px|py|pt|pb|pl|pr|m|mx|my|mt|mb|ml|mr|gap|w|h|text|rounded)-\[\d+(?:\.\d+)?px\]/g },
  { id: "radios", grupo: "componentes", minimo: 4, que: "radios de borde inconsistentes", re: /\brounded(?:-(?:none|sm|md|lg|xl|2xl|3xl|full|\[[^\]]+\]))?\b(?!-[trbl])/g, distintos: true },
  // Estructura
  { id: "borde-y-sombra", grupo: "estructura", minimo: 1, que: "borde y sombra en el mismo elemento", re: /className=["'`][^"'`]*\bborder\b[^"'`]*\bshadow(?:-\w+)?\b|className=["'`][^"'`]*\bshadow(?:-\w+)?\b[^"'`]*\bborder\b/g },
  { id: "bordes", grupo: "estructura", minimo: 8, que: "contenedores con borde para todo", re: /(?<![-\w])border(?:-[trblxy])?\b(?![-:])/g },
  { id: "divisores", grupo: "estructura", minimo: 4, que: "divisores de más", re: /<hr\b|<Separator\b|\bdivide-[xy]\b/g },
  { id: "centrado-largo", grupo: "estructura", minimo: 2, que: "párrafos centrados", re: /<p\b[^>]*\btext-center\b/g },
  // Color y fondo
  { id: "gradiente", grupo: "color", minimo: 1, que: "fondos con gradiente", re: /\bbg-(?:gradient|linear|radial|conic)-|(?:linear|radial|conic)-gradient\(/g },
  { id: "violeta-fucsia", grupo: "color", minimo: 1, que: "gradiente violeta→fucsia/azul sin marca que lo pida", re: /\bfrom-(?:purple|violet|indigo|fuchsia)-\d+[^"'`\n]*\bto-(?:pink|fuchsia|purple|blue|violet)-\d+/g },
  { id: "texto-gradiente", grupo: "color", minimo: 1, que: "texto con gradiente", re: /\bbg-clip-text\b/g },
  { id: "opacidades", grupo: "color", minimo: 6, que: "muchos tonos y opacidades del mismo color", re: /\b(?:bg|text|border|ring|from|to)-[a-z]+(?:-\d{2,3})?\/\d{1,3}\b/g, distintos: true },
  { id: "blob-difuso", grupo: "color", minimo: 1, que: "manchas de color difuminadas de fondo", re: /\bblur-(?:2xl|3xl|\[\d{2,}px\])/g },
  { id: "fondo-crema", grupo: "color", minimo: 1, que: "fondo crema o pergamino, el slop que reemplazó al violeta", re: /\bbg-(?:amber|orange|yellow|stone)-50\b|#(?:faf7f2|f5f0e8|fdf6e3|faf3e0|f5f1e8|fbf8f1|f7f3ea)\b/gi },
  { id: "dithering", grupo: "color", minimo: 1, que: "dithering o imágenes ASCII", re: /dither|[░▒▓█]{3,}|[╔╗╚╝═║]{3,}/gi },
];

// components/ui es el kit vendorizado (shadcn y similares): es el sistema del proyecto,
// no una decisión de diseño de la vista, así que no se juzga.
const esKit = (ruta) => /(?:^|\/)components\/ui$/.test(ruta);

function archivos(ruta, salida = []) {
  if (esKit(ruta)) return salida;
  const st = statSync(ruta);
  if (st.isFile()) {
    if (EXTENSIONES.has(extname(ruta))) salida.push(ruta);
    return salida;
  }
  for (const nombre of readdirSync(ruta)) {
    if (IGNORAR.has(nombre)) continue;
    archivos(join(ruta, nombre), salida);
  }
  return salida;
}

function mostrar(archivo, base) {
  const rel = relative(base, archivo);
  return rel.startsWith("..") ? archivo : rel;
}

function lineaDe(texto, indice) {
  return texto.slice(0, indice).split("\n").length;
}

// Escanea rutas y devuelve el informe. Es la interfaz que usan la CLI y los tests.
export function escanear(rutas, base = process.cwd()) {
  const hallazgos = {};
  for (const archivo of rutas.flatMap((r) => archivos(r))) {
    const texto = readFileSync(archivo, "utf8");
    for (const regla of REGLAS) {
      const matches = [...texto.matchAll(regla.re)];
      const peso = regla.distintos ? new Set(matches.map((m) => m[0])).size : matches.length;
      if (peso < regla.minimo) continue;
      const h = (hallazgos[regla.id] ??= { id: regla.id, grupo: regla.grupo, que: regla.que, veces: 0, lugares: [] });
      h.veces += matches.length;
      for (const m of matches.slice(0, 3)) h.lugares.push(`${mostrar(archivo, base)}:${lineaDe(texto, m.index)}`);
    }
  }
  const lista = Object.values(hallazgos);
  const n = lista.length;
  const veredicto = n <= 2 ? "limpio" : n <= 5 ? "sospechoso" : "slop";
  return { indicadores: n, de: REGLAS.length, veredicto, hallazgos: lista };
}

function imprimir(informe) {
  console.log(`slop-scan: ${informe.indicadores} de ${informe.de} indicadores → ${informe.veredicto}`);
  for (const h of informe.hallazgos) {
    console.log(`  [${h.grupo}] ${h.id} ×${h.veces} — ${h.que}`);
    for (const l of h.lugares.slice(0, 3)) console.log(`      ${l}`);
  }
}

const esCli = process.argv[1] && import.meta.url.endsWith(process.argv[1].split("/").pop());
if (esCli) {
  const args = process.argv.slice(2);
  if (args.includes("--reglas")) {
    for (const r of REGLAS) console.log(`${r.grupo}\t${r.id}\t${r.que}${r.minimo > 1 ? ` (desde ${r.minimo} en un archivo)` : ""}`);
    process.exit(0);
  }
  const rutas = args.filter((a) => !a.startsWith("--"));
  if (rutas.length === 0) {
    console.error("uso: slop-scan.mjs <archivo|carpeta>... [--json] · --reglas");
    process.exit(2);
  }
  const informe = escanear(rutas);
  if (args.includes("--json")) console.log(JSON.stringify(informe, null, 2));
  else imprimir(informe);
}
