#!/usr/bin/env bash
# Abre una sesión de Claude en otro repo y devuelve una dirección con la que hablarle.
#
# El nombre que ve `ListAgents` NO se elige: sale de la carpeta + 2 caracteres al azar, y colisiona
# de verdad (medido: dos sesiones vivas llamadas `app-saltacompra-a4`). Por eso acá se fija el id de
# sesión ANTES de crear y después se pregunta qué nombre le tocó a ESE id — sin adivinar cuál de las
# sesiones nuevas es la nuestra.
set -euo pipefail

ROOTS_DEFAULT="$HOME/Proyectos $HOME/cuenta-norte"
COLOR_SPAWN="Indigo"   # color reservado: "esta ventana la abrió otra sesión, no Leo"
MODO="cmux"
HOST=""
RC_NOMBRE=""
REPORTAR_A=""
REPO=""
TITULO=""
BRIEF=""
MODEL=""
DRY=0
WORKTREE=0
FORZAR_VENTANA=0

uso() {
  cat <<'EOF'
uso: spawn.sh --repo <ruta-o-fragmento> [opciones]

  --repo <r>       Carpeta donde abrirla (`.` = acá), o un fragmento a buscar entre los repos git.
                   Cualquier carpeta sirve: el contexto de trabajo no siempre es un repo.
  --host <h>       Abrirla en otra máquina de la flota (un host de ~/.ssh/config, p. ej. `devbox`).
                   El repo se resuelve ALLÁ, contra el disco de esa máquina.
  --brief <t>      Lo que se le pide a la sesión nueva. Sin esto arranca ociosa.
  --brief-file <f> Lee el brief de un archivo — el traspaso de /handoff entra derecho acá.
  --model <m>      Modelo de la sesión (fable, opus, sonnet…). Se fija al nacer: desde adentro
                   la sesión no puede cambiárselo (/model sólo existe tipeado por el usuario).
  --remote-control [n]  Registra la sesión en la cuenta con ese nombre, y ahí `SendMessage` la
                   alcanza aunque haya nacido en otra máquina. Con --host va puesto siempre.
  --reportar-a <d> Dirección de retorno a la que la sesión nueva manda el resultado al terminar
                   (`bridge:session_…`, la del enlace de esta sesión). El aviso automático de
                   "ya está" no cruza máquinas: lo manda ella o no llega ninguno.
  --worktree       Árbol de trabajo propio del mismo repo, para que no se pisen dos sesiones.
  --ventana        Ventana propia aunque ya haya una abierta en ese repo.
  --titulo <t>     Título de la ventana de cmux. Default: nombre de la carpeta. No aplica a pestañas.
  --bg             Sesión de fondo (sin pestaña). Leo no la ve ni la puede tomar.
  --dry-run        Muestra lo que haría y sale.

Dónde aparece: si ya hay una ventana de cmux abierta en ese repo, entra como PESTAÑA ahí — al lado
de la que la pidió. Si no hay ninguna, abre ventana propia, marcada con color y con quién la abrió.

Sin cmux pero con tmux (la flota), abre una VENTANA en la mesa de tmux de ese repo — la que Leo ya
espeja desde la Mac. Sin mesa para ese repo, crea una. La ventana es siempre nueva: no se escribe
sobre una que ya existe.

Con --host este mismo script viaja por ssh y corre del otro lado, así la versión del plugin que
haya instalada allá no importa. La sesión remota NO se ve con ListAgents ni recibe SendMessage: se
le habla por `ssh <host> tmux send-keys -t <window_id>`.

Busca repos en $SPAWN_ROOTS (default: ~/Proyectos ~/cuenta-norte).
Los worktrees viven en $SPAWN_WORKTREES (default: ~/.spawn-worktrees), fuera del repo.
Salida: bloques `clave: valor`. Sale 2 si el fragmento es ambiguo, listando los candidatos.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)   REPO="${2:-}"; shift 2 ;;
    --host)   HOST="${2:-}"; shift 2 ;;
    --remote-control) RC_NOMBRE="${2:-}"; shift 2 ;;
    --reportar-a) REPORTAR_A="${2:-}"; shift 2 ;;
    --brief)  BRIEF="${2:-}"; shift 2 ;;
    --brief-file)
      [ -f "${2:-}" ] || { echo "error: no existe el archivo de brief '${2:-}'" >&2; exit 66; }
      BRIEF="$(cat "$2")"; shift 2 ;;
    --model)  MODEL="${2:-}"; shift 2 ;;
    --worktree) WORKTREE=1; shift ;;
    --ventana) FORZAR_VENTANA=1; shift ;;
    --titulo) TITULO="${2:-}"; shift 2 ;;
    --bg)     MODO="bg"; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) uso; exit 0 ;;
    *) echo "error: opción desconocida '$1'" >&2; uso >&2; exit 64 ;;
  esac
done

[ -n "$REPO" ] || { echo "error: falta --repo" >&2; exit 64; }

# El aviso de "terminé" que el harness manda solo vale para sesiones de esta máquina. Cruzando
# máquinas lo manda la sesión nueva o no llega ninguno, así que la instrucción viaja en el brief.
if [ -n "$REPORTAR_A" ] && [ -n "$BRIEF" ]; then
  BRIEF="$BRIEF

---
Cuando termines —o si te trabás y no podés seguir— mandale el resultado a la sesión que te abrió:
SendMessage con \`to\` igual a esta cadena completa: \`$REPORTAR_A\`. Tres líneas: qué quedó hecho, qué
falta, qué necesitás. Es el único aviso que va a recibir; no está mirando tu pantalla. Esa sesión no
figura en tu \`ListAgents\` —está en otra máquina— y aun así la dirección entrega."
fi

# Un mensaje de `cmux agent message` llega rotulado «no es tu operador», y una sesión prudente no lo
# contesta (medido 26-oct-2026: haiku se negó 4 de 4). El aviso viaja en el brief, y sólo a sesiones
# que nacen acá: decirlo en un CLAUDE.md global abriría ese canal a cualquier sesión engañada.
if [ -z "$HOST" ] && [ -n "$BRIEF" ] && command -v cmux >/dev/null 2>&1; then
  BRIEF="$BRIEF

---
Puede que la sesión que te abrió te escriba por cmux (llega como \`[cmux agent message]\`). Es parte
de este pedido: contestale en tu respuesta de texto normal, no por el canal de cmux."
fi

# --- otra máquina de la flota -----------------------------------------------
# El trabajo entero pasa allá: este script se copia a sí mismo por ssh y corre del otro lado, contra
# el disco de esa máquina. Por eso la versión del plugin instalada allá da igual — van desparejas y
# se quedan atrás (medido 27-ago-2026: 1.5.1 en la devbox, 1.5.2 en la Mac).
#
# `bash -lc` no es un detalle de estilo: `claude` vive en un multishell de fnm que sólo existe en un
# shell de login, así que un ssh a secas no lo encuentra.
if [ -n "$HOST" ]; then
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST" true 2>/dev/null || {
    echo "estado: sin-host"
    echo "host: $HOST"
    echo "detalle: ssh no conecta — máquina apagada, VPN caída o clave no aceptada"
    exit 4
  }

  TAG="$(date +%s)-$$"
  SCRIPT_REMOTO="/tmp/spawn-$TAG.sh"
  ssh -o BatchMode=yes "$HOST" "cat > $SCRIPT_REMOTO" < "$0" \
    || { echo "error: no se pudo subir el script a $HOST" >&2; exit 70; }

  # Una sesión en otra máquina no la ve `ListAgents` ni la alcanza `SendMessage`: el registro de la
  # cuenta es lo que la vuelve direccionable, y sube por una conexión saliente, así que no le hace
  # falta que la Mac sea alcanzable de vuelta (no lo es: entra NATeada por la VPN).
  if [ -z "$RC_NOMBRE" ]; then
    RC_NOMBRE="$HOST-$(basename "$REPO" | tr ' ._:/' '-----' | cut -c1-20)-$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
  fi
  ARGS="--repo $(printf '%q' "$REPO") --remote-control $(printf '%q' "$RC_NOMBRE")"
  if [ -n "$BRIEF" ]; then
    # El brief viaja por archivo también en el salto: metido en la línea de ssh lo mastican dos
    # shells seguidos (el local y el remoto) y los acentos y comillas no sobreviven.
    BRIEF_REMOTO="/tmp/spawn-brief-$TAG.md"
    printf '%s' "$BRIEF" | ssh -o BatchMode=yes "$HOST" "cat > $BRIEF_REMOTO" \
      || { echo "error: no se pudo subir el brief a $HOST" >&2; exit 70; }
    ARGS="$ARGS --brief-file $BRIEF_REMOTO"
  fi
  [ -n "$MODEL" ] && ARGS="$ARGS --model $(printf '%q' "$MODEL")"
  [ -n "$TITULO" ] && ARGS="$ARGS --titulo $(printf '%q' "$TITULO")"
  [ "$WORKTREE" -eq 1 ] && ARGS="$ARGS --worktree"
  [ "$FORZAR_VENTANA" -eq 1 ] && ARGS="$ARGS --ventana"
  [ "$MODO" = "bg" ] && ARGS="$ARGS --bg"
  [ "$DRY" -eq 1 ] && ARGS="$ARGS --dry-run"

  set +e
  SALIDA_REMOTA="$(ssh -o BatchMode=yes "$HOST" "bash -lc $(printf '%q' "bash $SCRIPT_REMOTO $ARGS")" 2>&1)"
  RC=$?
  set -e
  ssh -o BatchMode=yes "$HOST" "rm -f $SCRIPT_REMOTO" >/dev/null 2>&1 || true

  echo "host: $HOST"
  # El nombre que le tocó del otro lado es local a esa máquina y no direcciona nada desde acá; la
  # dirección buena es el nombre con que se registró en la cuenta.
  printf '%s\n' "$SALIDA_REMOTA" | sed '/^nombre_repetido:/d; s/^nombre:/nombre_alla:/'
  echo "nombre: $RC_NOMBRE"
  DIR_REMOTA="$(printf '%s\n' "$SALIDA_REMOTA" | sed -n 's/^direccion_tmux: //p')"
  if [ -n "$DIR_REMOTA" ] && [ "$DIR_REMOTA" != "—" ]; then
    echo "leerle: ssh $HOST 'tmux capture-pane -p -t $DIR_REMOTA'"
    echo "hablarle_por_tmux: ssh $HOST 'tmux send-keys -t $DIR_REMOTA \"texto\" Enter'"
  fi
  # La bitácora es la única prueba de que el brief entró, y vive en el disco de la otra máquina.
  SID_REMOTO="$(printf '%s\n' "$SALIDA_REMOTA" | sed -n 's/^session_id: //p')"
  [ -n "$SID_REMOTO" ] && \
    echo "verificar: ssh $HOST 'grep -rc \"Unknown command\" ~/.claude/projects --include=$SID_REMOTO.jsonl'"
  exit $RC
fi

# --- resolver el destino ----------------------------------------------------
# Una ruta existente se toma tal cual, tenga .git o no: el contexto adecuado para trabajar es a veces
# una carpeta del paraguas, no un repo. Sin ruta, el sistema de archivos ES el registro y los repos se
# descubren buscando .git, así no hay una lista a mano que se pudra. Ante duda se sale con 2 y se
# listan los candidatos — nunca se elige por el usuario.
if [ -d "$REPO" ]; then
  DESTINO="$(cd "$REPO" && pwd)"
else
  CANDIDATOS=""
  for root in ${SPAWN_ROOTS:-$ROOTS_DEFAULT}; do
    [ -d "$root" ] || continue
    while IFS= read -r g; do
      d="${g%/.git}"
      case "$(basename "$d" | tr '[:upper:]' '[:lower:]')" in
        *"$(echo "$REPO" | tr '[:upper:]' '[:lower:]')"*) CANDIDATOS="$CANDIDATOS$d"$'\n' ;;
      esac
    done < <(find "$root" -maxdepth 7 -name .git -type d 2>/dev/null)
  done
  CANDIDATOS="$(printf '%s' "$CANDIDATOS" | sed '/^$/d')"
  N=$(printf '%s' "$CANDIDATOS" | grep -c . || true)
  if [ "$N" -eq 0 ]; then
    echo "estado: sin-coincidencias"
    echo "buscado: $REPO"
    exit 2
  elif [ "$N" -gt 1 ]; then
    echo "estado: ambiguo"
    echo "buscado: $REPO"
    echo "candidatos:"
    printf '%s\n' "$CANDIDATOS" | sed 's/^/  - /'
    exit 2
  fi
  DESTINO="$CANDIDATOS"
fi

[ -n "$TITULO" ] || TITULO="$(basename "$DESTINO")"

# --- árbol propio -----------------------------------------------------------
# Dos sesiones sobre el mismo árbol se pisan sin avisar: una hace checkout mientras la otra edita, y
# el index de git queda trabado. El worktree vive FUERA del repo para no ensuciar lo que ya está.
RAMA=""
WTDIR=""
if [ "$WORKTREE" -eq 1 ]; then
  git -C "$DESTINO" rev-parse --git-dir >/dev/null 2>&1 \
    || { echo "error: --worktree necesita un repo git; '$DESTINO' no lo es" >&2; exit 64; }
  RAMA="spawn/$(basename "$DESTINO")-$(date +%H%M%S)"
  WTDIR="${SPAWN_WORKTREES:-$HOME/.spawn-worktrees}/$(basename "$RAMA")"
  if [ "$DRY" -eq 0 ]; then
    mkdir -p "$(dirname "$WTDIR")"
    git -C "$DESTINO" worktree add -b "$RAMA" "$WTDIR" >/dev/null 2>&1 \
      || { echo "error: no se pudo crear el worktree en $WTDIR" >&2; exit 70; }
  fi
  DESTINO="$WTDIR"
  TITULO="$TITULO (árbol propio)"
  FORZAR_VENTANA=1   # un árbol aparte es trabajo aparte: merece su ventana
fi
UUID="$(python3 -c 'import uuid;print(uuid.uuid4())')"

# El brief viaja por archivo, no incrustado en la línea de comando: así comillas, saltos de línea y
# acentos llegan intactos en vez de romper el quoting del shell que cmux ejecuta.
#
# Arranca como el alias `cc` de Leo — sin preguntar permisos. Se escribe la bandera y no el alias
# porque el comando lo corre un shell no interactivo, donde los alias no existen. Efecto de fondo:
# también saltea el "¿confiás en esta carpeta?" que dejaba sesiones trabadas en repos nuevos.
CLAUDE_BIN="claude --dangerously-skip-permissions"
[ -n "$MODEL" ] && CLAUDE_BIN="$CLAUDE_BIN --model $MODEL"
[ -n "$RC_NOMBRE" ] && CLAUDE_BIN="$CLAUDE_BIN --remote-control \"$RC_NOMBRE\""
BRIEFFILE=""
CMD="$CLAUDE_BIN --session-id $UUID"
if [ -n "$BRIEF" ]; then
  BRIEFFILE="$(mktemp "${TMPDIR:-/tmp}/spawn-brief.XXXXXX")"
  printf '%s' "$BRIEF" > "$BRIEFFILE"
  CMD="$CLAUDE_BIN --session-id $UUID \"\$(cat $BRIEFFILE)\""
fi

# --- dónde ponerla: pestaña en una ventana que ya existe, o ventana nueva -----
# Abrir una ventana por sesión llena la barra de duplicados del mismo repo (medido: dos ventanas en
# `radar` a la vez). Si ya hay una abierta ahí, la sesión nueva entra como pestaña: aparece al lado
# de la que la pidió y el origen se lee solo, sin marca. Se prefiere la ventana de quien llama; si no
# es esa, la de actividad más reciente. Sin ninguna, ventana propia — y ahí sí hace falta marcarla.
WSTAB=""; GRUPO=""; ORIGEN=""
# La Mac tiene cmux y es la interfaz; la flota no lo tiene ni le sirve. Ahí el análogo de la ventana
# es la mesa de tmux del repo, que ya se espeja desde la Mac: una ventana nueva adentro aparece en la
# pantalla de Leo sin ningún puente extra.
if [ "$MODO" = "cmux" ] && ! command -v cmux >/dev/null 2>&1 && command -v tmux >/dev/null 2>&1; then
  MODO="tmux"
fi
if [ "$MODO" = "cmux" ] && command -v cmux >/dev/null 2>&1; then
  INFO="$(python3 - "$DESTINO" "${CMUX_WORKSPACE_ID:-}" <<'PY' 2>/dev/null || true
import json, os, subprocess, sys

dest, caller = sys.argv[1], sys.argv[2]

def cmux_json(*args):
    try:
        r = subprocess.run(["cmux", *args, "--json"], capture_output=True, text=True, timeout=10)
        return json.loads(r.stdout)
    except Exception:
        return {}

def toplevel(path):
    if not os.path.isdir(path):
        return None
    r = subprocess.run(["git", "-C", path, "rev-parse", "--show-toplevel"],
                       capture_output=True, text=True)
    return r.stdout.strip() or None

wss = cmux_json("workspace", "list").get("workspaces", [])
dest_top = toplevel(dest)

# Coincidencia exacta primero; si no hay, misma raíz de repo — abrir en el paraguas del mismo repo
# sigue siendo el mismo contexto de trabajo.
cands = [w for w in wss if (w.get("current_directory") or "").rstrip("/") == dest.rstrip("/")]
if not cands and dest_top:
    cands = [w for w in wss if toplevel(w.get("current_directory") or "") == dest_top]

elegido = next((w for w in cands if w.get("id") == caller), None)
if elegido is None and cands:
    elegido = sorted(cands, key=lambda w: w.get("latest_submitted_at") or "")[-1]

# El grupo y el título de quien llama sólo sirven si termina abriéndose ventana nueva.
mio = next((w for w in wss if w.get("id") == caller), None)
grupo = ""
if mio:
    for g in cmux_json("workspace-group", "list").get("groups", []):
        if mio.get("ref") in g.get("member_workspace_refs", []):
            grupo = g.get("ref", "")
            break

print("ws_tab=" + (elegido.get("ref", "") if elegido else ""))
print("grupo=" + grupo)
print("origen=" + (mio.get("custom_title") or os.path.basename(mio.get("current_directory") or "") if mio else ""))
PY
)"
  WSTAB="$(printf '%s\n' "$INFO" | sed -n 's/^ws_tab=//p')"
  GRUPO="$(printf '%s\n' "$INFO" | sed -n 's/^grupo=//p')"
  ORIGEN="$(printf '%s\n' "$INFO" | sed -n 's/^origen=//p')"
fi
MESA=""
if [ "$MODO" = "tmux" ]; then
  # La mesa del repo se reconoce por dónde está parada: coincidencia exacta primero, y si no, misma
  # raíz de repo — una mesa abierta en un subdirectorio sigue siendo el mismo contexto de trabajo.
  DEST_TOP="$(git -C "$DESTINO" rev-parse --show-toplevel 2>/dev/null || true)"
  while IFS=' ' read -r sname spath; do
    [ -n "$sname" ] || continue
    if [ "${spath%/}" = "${DESTINO%/}" ]; then MESA="$sname"; break; fi
    if [ -n "$DEST_TOP" ] && [ "$(git -C "$spath" rev-parse --show-toplevel 2>/dev/null || true)" = "$DEST_TOP" ]; then
      [ -n "$MESA" ] || MESA="$sname"
    fi
  done < <(tmux list-panes -a -F '#{session_name} #{pane_current_path}' 2>/dev/null || true)
fi
[ "$FORZAR_VENTANA" -eq 1 ] && WSTAB=""
[ "$FORZAR_VENTANA" -eq 1 ] && MESA=""
[ -n "$WSTAB" ] && MODO="tab"

if [ "$DRY" -eq 1 ]; then
  echo "estado: dry-run"
  echo "repo: $DESTINO"
  [ -n "$RAMA" ] && echo "rama: $RAMA"
  echo "modo: $MODO"
  [ -n "$WSTAB" ] && echo "ventana_destino: $WSTAB"
  if [ "$MODO" = "tmux" ]; then
    echo "sustrato: tmux (sin cmux en esta máquina)"
    echo "mesa_destino: ${MESA:-— (mesa nueva)}"
  fi
  [ -n "$GRUPO" ] && echo "grupo: $GRUPO"
  echo "titulo: $TITULO"
  echo "session_id: $UUID"
  echo "comando: $CMD"
  [ -n "$BRIEFFILE" ] && rm -f "$BRIEFFILE"
  exit 0
fi

# La primera sesión en una carpeta que Claude nunca abrió levanta el diálogo de confianza —«Is this a
# project you created or one you trust?»— y el brief se queda afuera. Lo levanta incluso con
# --dangerously-skip-permissions (medido 29-ago-2026 en la devbox, sobre ~/cuenta-norte, y
# 16-sep-2026 en una ventana de cmux sobre ~/Proyectos/SC/infra/datacenter). Vale para los tres
# sustratos con pantalla: antes sólo lo contestaba tmux, y la ventana de cmux quedaba parada
# esperando a que Leo fuera a apretar Enter.
#
# La opción marcada al abrir es «No, exit»: un Enter a ciegas MATA la sesión. Por eso se navega
# hasta que la flecha esté sobre «Yes, I trust this folder» y recién ahí se confirma, y sólo si
# ese diálogo está en pantalla. Confiar es coherente con cómo nace la sesión: la carpeta la
# eligió quien la abrió, y ya arranca sin preguntar permisos.
leer_pantalla() {
  case "$MODO" in
    tmux) tmux capture-pane -p -t "$WS" 2>/dev/null ;;
    tab)  cmux read-screen --surface "$SURF" 2>/dev/null ;;
    cmux) cmux read-screen --workspace "$WS" 2>/dev/null ;;
  esac
  return 0
}
apretar() {  # $1: down | enter
  case "$MODO" in
    tmux) [ "$1" = down ] && tmux send-keys -t "$WS" Down 2>/dev/null; [ "$1" = enter ] && tmux send-keys -t "$WS" Enter 2>/dev/null ;;
    tab)  cmux send-key --surface "$SURF" "$1" >/dev/null 2>&1 ;;
    cmux) cmux send-key --workspace "$WS" "$1" >/dev/null 2>&1 ;;
  esac
  return 0
}
contestar_confianza() {
  local PANTALLA
  for _ in $(seq 1 24); do
    PANTALLA="$(leer_pantalla)"
    if printf '%s' "$PANTALLA" | grep -q 'trust this folder'; then
      for _ in $(seq 1 4); do
        printf '%s' "$PANTALLA" | grep -q '❯.*trust this folder' && break
        apretar down
        sleep 0.4
        PANTALLA="$(leer_pantalla)"
      done
      printf '%s' "$PANTALLA" | grep -q '❯.*trust this folder' && apretar enter
      return 0
    fi
    printf '%s' "$PANTALLA" | grep -qE 'for shortcuts|bypass permissions' && return 0
    sleep 0.5
  done
  return 0
}

WS=""; SURF=""
case "$MODO" in
  tab)
    # Una pestaña nace fría: sin proceso hasta que recibe algo (medido). El Enter la despierta, y el
    # comando recién se manda con el prompt vivo — si no, el shell se come los primeros caracteres.
    SALIDA="$(cmux new-surface --type terminal --workspace "$WSTAB" --working-directory "$DESTINO" --focus false 2>&1)"
    SURF="$(printf '%s' "$SALIDA" | grep -oE 'surface:[0-9]+' | head -1)"
    [ -n "$SURF" ] || { echo "error: cmux no devolvió una referencia de pestaña" >&2; printf '%s\n' "$SALIDA" >&2; exit 70; }
    WS="$WSTAB"
    cmux send --surface "$SURF" "\n" >/dev/null 2>&1 || true
    for _ in $(seq 1 20); do
      [ -n "$(cmux read-screen --surface "$SURF" 2>/dev/null | tr -d '[:space:]')" ] && break
      sleep 0.5
    done
    sleep 1
    cmux send --surface "$SURF" "$CMD\n" >/dev/null 2>&1 \
      || { echo "error: no se pudo escribir en la pestaña $SURF" >&2; exit 70; }
    ;;
  cmux)
    command -v cmux >/dev/null 2>&1 || { echo "error: no está el cli de cmux; usá --bg" >&2; exit 69; }
    if [ -n "$GRUPO" ]; then
      SALIDA="$(cmux workspace create --name "$TITULO" --cwd "$DESTINO" --command "$CMD" --focus false --group "$GRUPO" 2>&1)"
    else
      SALIDA="$(cmux workspace create --name "$TITULO" --cwd "$DESTINO" --command "$CMD" --focus false 2>&1)"
    fi
    WS="$(printf '%s' "$SALIDA" | grep -oE 'workspace:[0-9]+' | head -1)"
    [ -n "$WS" ] || { echo "error: cmux no devolvió una referencia de workspace" >&2; printf '%s\n' "$SALIDA" >&2; exit 70; }
    # Color y descripción son la marca de origen: cmux no las pisa, a diferencia del título, que la
    # sesión reescribe sola con lo que está haciendo.
    cmux workspace-action --workspace "$WS" --action set-color --color "$COLOR_SPAWN" >/dev/null 2>&1 || true
    cmux workspace-action --workspace "$WS" --action set-description \
      --description "↩ abierta desde ${ORIGEN:-otra sesión} · $(date +'%d/%m %H:%M')" >/dev/null 2>&1 || true
    ;;
  tmux)
    # Una mesa de tmux puede tener trabajo vivo adentro, así que acá NUNCA se escribe sobre una
    # ventana que ya existe: la sesión nueva nace en la suya. El comando va puesto al crearla — no
    # hay prompt frío que despertar, que es donde send-keys se come los primeros caracteres.
    # La dirección que se devuelve es el window_id (`@N`), no `mesa:índice`: los índices se
    # RENUMERAN cuando se cierra otra ventana de la mesa, y una dirección guardada pasa a apuntar a
    # la sesión del vecino (medido 26-ago-2026: un monitor terminó leyendo la pantalla equivocada).
    # El window_id no se recicla mientras la ventana viva.
    VENTANA="↩ $TITULO"
    if [ -n "$MESA" ]; then
      WS="$(tmux new-window -P -F '#{window_id}' -t "$MESA:" -c "$DESTINO" -n "$VENTANA" "$CMD" 2>&1)" \
        || { echo "error: no se pudo abrir la ventana en la mesa '$MESA'" >&2; exit 70; }
    else
      # tmux no admite '.' ni ':' en el nombre de una mesa: los usa para direccionar ventana y panel.
      MESA="$(printf '%s' "$TITULO" | tr ' .:' '---' | cut -c1-24)"
      tmux has-session -t "=$MESA" 2>/dev/null \
        && { echo "error: ya existe una mesa llamada '$MESA' que no está en ese repo" >&2; exit 70; }
      tmux new-session -d -s "$MESA" -c "$DESTINO" -n "$VENTANA" "$CMD" 2>/dev/null \
        || { echo "error: no se pudo crear la mesa '$MESA'" >&2; exit 70; }
      WS="$(tmux list-windows -t "=$MESA" -F '#{window_id}' 2>/dev/null | head -1)"
    fi
    ;;
  bg)
    ( cd "$DESTINO" && $CLAUDE_BIN --bg --session-id "$UUID" "${BRIEF:-hola}" >/dev/null 2>&1 & )
    ;;
esac
[ "$MODO" = "bg" ] || contestar_confianza

# --- resolver qué nombre le tocó a NUESTRO id -------------------------------
NOMBRE=""
for _ in $(seq 1 15); do
  NOMBRE="$(claude agents --json 2>/dev/null | python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for s in d:
    if s.get("sessionId")==sys.argv[1]:
        print(s.get("name",""))
' "$UUID" || true)"
  [ -n "$NOMBRE" ] && break
  sleep 1
done

# Un nombre repetido entre sesiones vivas no se puede usar como dirección: SendMessage sólo direcciona
# por nombre, así que ahí la vía buena es la referencia de cmux.
REPETIDO="$(claude agents --json 2>/dev/null | python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
n=sys.argv[1]
print("si" if n and sum(1 for s in d if s.get("name")==n)>1 else "no")
' "$NOMBRE" || echo "no")"

# La dirección de cmux es la pestaña cuando hay pestaña: leer por ventana devuelve la pestaña
# seleccionada, que casi nunca es la nuestra.
DIR_CMUX="${SURF:-$WS}"

if [ -z "$NOMBRE" ]; then
  # La causa medida y frecuente: en un repo que Claude nunca abrió, la sesión se traba en la pregunta
  # "¿confiás en esta carpeta?" y nunca se registra. Mostrar la pantalla convierte un guión mudo en
  # un diagnóstico.
  echo "estado: trabada"
  echo "repo: $DESTINO"
  echo "modo: $MODO"
  echo "session_id: $UUID"
  [ "$MODO" = "tmux" ] && echo "mesa: ${MESA:-—}"
  echo "ventana: ${WS:-—}"
  [ -n "$SURF" ] && echo "pestaña: $SURF"
  if [ "$MODO" = "tmux" ] && [ -n "$WS" ]; then
    echo "pantalla:"
    tmux capture-pane -p -t "$WS" 2>/dev/null | sed '/^[[:space:]]*$/d' | tail -12 | sed 's/^/  /'
  elif [ -n "$DIR_CMUX" ]; then
    echo "pantalla:"
    if [ -n "$SURF" ]; then
      cmux read-screen --surface "$SURF" 2>/dev/null | sed '/^[[:space:]]*$/d' | tail -12 | sed 's/^/  /'
    else
      cmux read-screen --workspace "$WS" 2>/dev/null | sed '/^[[:space:]]*$/d' | tail -12 | sed 's/^/  /'
    fi
  fi
  [ -n "$BRIEFFILE" ] && echo "brief_tmp: $BRIEFFILE"
  exit 3
fi

echo "estado: creada"
echo "repo: $DESTINO"
[ -n "$RAMA" ] && echo "rama: $RAMA"
echo "modo: $MODO"
echo "session_id: $UUID"
[ -n "$SURF" ] && echo "pestaña: $SURF"
if [ "$MODO" = "tmux" ]; then
  # Se le escribe con `tmux send-keys -t <ref> "texto" Enter` y se le lee con `tmux capture-pane -p -t <ref>`.
  echo "mesa: ${MESA:-—}"
  echo "direccion_tmux: ${WS:-—}"
else
  echo "workspace: ${WS:-—}"
  echo "direccion_cmux: ${DIR_CMUX:-—}"
  # Para conversar: el mensaje por stdin, vuelve con la respuesta. La pantalla sólo destraba diálogos.
  [ -n "$DIR_CMUX" ] && echo "hablarle: $(cd "$(dirname "$0")" && pwd)/hablarle.sh $DIR_CMUX < mensaje"
fi
echo "nombre: $NOMBRE"
echo "nombre_repetido: $REPETIDO"
[ -n "$BRIEFFILE" ] && echo "brief_tmp: $BRIEFFILE"
exit 0
