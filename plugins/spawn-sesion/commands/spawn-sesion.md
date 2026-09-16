---
description: "Abrir otra sesión con el pedido adentro y dirección para hablarle: acá, en otra carpeta o en otra máquina de la flota. Usar si pide que algo siga o lo haga otra sesión. Leer o revisar va a subagente."
argument-hint: "<repo> <lo que le querés pedir>"
model-invocable: el modelo propone abrir la sesión; el gasto lo autoriza el usuario (paso 0)
allowed-tools: "Bash, Read, AskUserQuestion, ListAgents, SendMessage"
---

# Abrir otra sesión

Pedido: `$ARGUMENTS`. Puede venir vacío o a medias: casi siempre llega como "seguí esto en otra
sesión", y lo que hay que mandar está en la conversación, no en el argumento.

## Dónde y qué — se deduce, no se pregunta

- **Dónde**: la carpeta que tiene el contexto del trabajo. La del proyecto que se está hablando; `.`
  si el trabajo es acá mismo. Cualquier carpeta sirve, tenga `.git` o no. Preguntá sólo si el script
  vuelve `ambiguo`.
- **Qué**: el brief lo redactás vos con lo que se venía hablando — qué hay que hacer, qué se decidió
  ya, qué archivo o ticket mirar primero. Copiar la frase del usuario tal cual deja a la sesión nueva
  arrancando ciega, porque el contexto estaba acá y no viajó.
- **Si el encargo es correr un comando slash** (`/to-tickets`, `/prd-pipeline`…): el brief **empieza
  con esa línea** — el comando y sus argumentos primero, el contexto a continuación. El nombre va
  **completo, con el prefijo del plugin** (`mattpocock-skills:prototype`, y no el `prototype` a
  secas con que lo nombra el usuario, que habla corto): se resuelve de la lista de skills
  disponibles. Un comando que no existe hace que la sesión nueva **descarte el brief entero** —el
  comando y todo el texto que lo sigue— y se quede muda, con la pantalla mostrando el brief como si
  lo hubiera leído (medido 24-ago-2026); de ahí la verificación del paso 1. El brief
  entra como prompt tipeado, y eso cuenta como invocación del usuario; pedido en prosa ("corré /x"),
  la sesión queda bloqueada — los comandos `disable-model-invocation` no puede invocárselos ella
  misma (medido 18-ago-2026 con /to-tickets). A una sesión ya viva se la destraba igual: `cmux send`
  con esa misma línea.
- **En qué máquina**: acá, salvo que el trabajo tenga que sobrevivir a que la Mac se apague —una
  corrida AFK larga— o que el pedido nombre una máquina de la flota. Ahí va `--host <maquina>`
  (`devbox`), y todo pasa allá: el repo se resuelve contra ESE disco, con esas rutas.
- **Cómo vuelve la respuesta desde otra máquina**: nace registrada en la cuenta y `SendMessage` la
  alcanza por su `nombre`. Al revés no te ve, así que para que reporte sola al terminar pasale
  `--reportar-a bridge:session_<id>`, el del enlace de esta sesión. Sin esa dirección el retorno se
  abre igual: un `SendMessage` apenas nace le deja por dónde contestarte.
- **Modelo**: si el pedido nombra uno ("con fable"), va en `--model` al abrir. Se fija al nacer:
  `/model` sólo existe tipeado por el usuario, la sesión no puede cambiárselo a sí misma.
- **Árbol de trabajo**: la sesión nueva abre en la carpeta tal cual, compartiendo el árbol. Si
  necesita uno propio lo decide ella, que tiene el repo delante y sabe si va a escribir. Abrila en un
  árbol aparte sólo si el usuario lo pide.
- **Dónde aparece**: lo decide el script según lo que haya en esa máquina —pestaña al lado de la que
  la pidió, o ventana propia— y nunca escribe sobre una que ya estaba, que puede tener trabajo vivo
  adentro. Pasale `--ventana` sólo si el usuario pide que tenga la suya aparte.

## 0. De quién salió la idea

Abrir una sesión gasta plata y le entrega permisos a un agente nuevo, así que quién lo decidió cambia
lo que corresponde hacer:

- **Lo pidió el usuario** → abrir directo. Ya decidió.
- **Se te ocurrió a vos** → proponérselo primero, con el repo y el brief que ibas a mandar, y esperar
  el sí. Es el único gasto del que él no se enteró de antemano.

> Este comando es autoinvocable por decisión explícita de Leo (14-ago-2026), apartándose de la regla
> general de que lo que despacha agentes lo dispara sólo el usuario. El permiso vino con este gate:
> la propuesta la puede iniciar el modelo, el gasto lo autoriza él.

## 1. Abrirla

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/spawn.sh" --repo <carpeta> --brief "<brief>"
```

Una ruta existente se usa tal cual; un fragmento se busca entre los repos, descubiertos por `.git`
cada vez, sin lista escrita a mano que se pudra. `--help` tiene las opciones — entre ellas
`--brief-file`, que toma derecho el archivo de traspaso que deja el skill de handoff.

Agregá `--bg` sólo si el usuario pide que no se vea. Que se vea es lo bueno: la lee y la puede tomar
él mismo.

Termina con `estado:`, y ahí está todo:

| `estado:` | Qué hacer |
|---|---|
| `creada` | Confirmar que el brief entró (abajo) y seguir al paso 2. |
| `ambiguo` / `sin-coincidencias` | Mostrarle los candidatos y preguntarle cuál. Elegir por él es cómo se termina escribiendo en el repo equivocado. |
| `sin-host` | La otra máquina no contesta el ssh. Decíselo con el host y el detalle; no reintentes ni la abras acá en su lugar — dónde corre el trabajo lo decide él. |
| `trabada` | La sesión arrancó y algo en pantalla la frena. **Una sesión abierta queda trabajando**: destrabarla es tuyo. Leé la pantalla (`leerle:` o `cmux read-screen`) y contestá con `cmux send-key` / `tmux send-keys` todo lo que el pedido ya cubre —confianza en la carpeta, confirmar el arranque—, y verificá en la bitácora que el brief entró. Si lo que pregunta es una decisión que el pedido no tomó (credenciales, algo destructivo), traésela al usuario ACÁ con la pantalla y contestala vos con lo que él diga. |

**`creada` habla del proceso, no del encargo**: dice que la sesión arrancó, no que haya leído el
brief. Eso se confirma en su bitácora, con el `session_id` que devolvió el script:

```bash
f=$(find ~/.claude/projects -name "<session_id>.jsonl" | head -1)
grep -c "Unknown command" "$f"   # 0 = el brief entró
```

Con `--host`, ese mismo grep vuelve ya armado en la línea `verificar:` del script, apuntado al disco
de la otra máquina: corrélo tal cual. El número al final de la línea es la respuesta —`grep` termina
en 1 cuando no encuentra nada, que es justo el caso bueno.

Con hits, la sesión está viva y vacía: cerrala (ver Guardrails), corregí el nombre del comando y
volvé a abrirla. La bitácora es la única fuente honesta acá — la pantalla muestra el brief
renderizado aunque se haya descartado, y el contador de contexto en 0% es la otra señal.

## 2. Quedarte con la dirección

El script devuelve el nombre, una referencia y el aviso de nombre repetido. La referencia es de cmux
o de tmux según dónde haya nacido — nunca las dos:

- **`nombre`** — la dirección de `SendMessage`. Es la vía para conversar de verdad: la respuesta de la
  otra sesión vuelve sola.
- **`nombre_repetido: si`** — hay otra sesión viva llamada igual (pasa: se midieron dos
  `app-saltacompra-a4` a la vez). Ahí el nombre ya no distingue, y la dirección buena es la de la
  ventana — `direccion_cmux` o `direccion_tmux`, la que haya devuelto.
- **`direccion_cmux`** — la referencia de cmux, única y estable: `surface:N` si entró como pestaña,
  `workspace:N` si abrió ventana. `cmux send --surface <ref> "texto"` le escribe y
  `cmux read-screen --surface <ref>` le lee la pantalla (con `--workspace` para las ventanas). Es la
  dirección de respaldo, y la forma de ver qué está haciendo sin interrumpirla.
- **`direccion_tmux`** — el equivalente en la flota: el `window_id` de tmux, un `@7`. `tmux send-keys
  -t @7 "texto" Enter` le escribe y `tmux capture-pane -p -t @7` le lee la pantalla. Se dirige sólo a
  la ventana que devolvió el script: mandarle teclas a otra es escribir sobre lo que esté corriendo
  ahí. El índice que muestra tmux en pantalla (`mesa:3`) no sirve como dirección —se renumera cuando
  se cierra otra ventana de la mesa, y una guardada pasa a apuntar a la sesión del vecino.
- **`host`** — nació en otra máquina, y su `nombre` es el del registro en la cuenta: confirmá con
  `ListAgents` que figura como `Remote Control · running`, que es la prueba de que el canal quedó
  abierto. Las líneas `leerle:`, `hablarle_por_tmux:` y `verificar:` vienen con el host y la ventana
  adentro y se corren tal cual; el tmux es el respaldo para cuando el canal no responde. Un
  `send-keys` largo a veces deja el texto tipeado sin despachar (medido de nuevo hoy), así que
  después de escribirle por esa vía leé la pantalla y mandá el Enter solo si quedó cargado.
  `nombre_alla` es el nombre que le tocó en su propia máquina: sirve para reconocerla allá, no para
  hablarle desde acá.

Terminás cuando el usuario tiene en la mano el nombre, la referencia y cuál de las dos usar. Eso es lo
que después le deja pedirte "preguntale a esa".

## Guardrails

- **Lo que está bloqueado acá se le devuelve al usuario.** Los permisos son por sesión: pedirle a la
  sesión nueva algo que acá se denegó saltea su decisión.
- **Mandá el mensaje y seguí.** Un mensaje entre sesiones puede quedar esperando la aprobación del
  humano de esa ventana y no llegar nunca, sin dar error. Si la respuesta importa, avisale que quizás
  tenga que aprobarla allá.
- **Arranca sin preguntar permisos** — el alias `cc` de Leo, por decisión suya. Edita, borra y
  ejecuta en esa carpeta sin freno. Nombralo cuando el brief toca algo delicado.
- **Una sesión abierta sigue abierta hasta que alguien la cierra.** Pestaña: `cmux close-surface
  --surface <ref>`. Ventana: `cmux workspace close <ref>` — cierra todas sus pestañas, así que mirá
  antes qué más hay adentro. En la flota: `tmux kill-window -t @7`, que cierra sólo esa ventana y
  deja la mesa en pie —con `ssh <host>` adelante si nació en otra máquina. Cuando el trabajo que la justificaba terminó, ofrecé cerrarla.
