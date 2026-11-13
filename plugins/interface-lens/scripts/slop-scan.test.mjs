// Corre con: node --test  (o bun test) desde esta carpeta.
import { test } from "node:test";
import assert from "node:assert/strict";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { escanear } from "./slop-scan.mjs";

const fx = (n) => join(dirname(fileURLToPath(import.meta.url)), "fixtures", n);
const ids = (informe) => informe.hallazgos.map((h) => h.id).sort();

test("un hero típico de IA junta muchos indicadores y da slop", () => {
  const informe = escanear([fx("slop.tsx")]);
  // Escritos a mano mirando el fixture, no derivados del código.
  for (const id of ["gradiente", "violeta-fucsia", "blob-difuso", "eyebrow", "numeracion", "serif-italica",
    "tracking-negativo", "italicas", "pills", "borde-y-sombra", "opacidades", "emoji-icono"]) {
    assert.ok(ids(informe).includes(id), `falta ${id}`);
  }
  assert.equal(informe.veredicto, "slop");
});

test("una vista sobria de gestión sale limpia", () => {
  const informe = escanear([fx("limpio.tsx")]);
  assert.deepEqual(ids(informe), []);
  assert.equal(informe.veredicto, "limpio");
});

test("cada hallazgo apunta a archivo:línea real", () => {
  const h = escanear([fx("slop.tsx")]).hallazgos.find((x) => x.id === "numeracion");
  assert.match(h.lugares[0], /slop\.tsx:5$/);
});
