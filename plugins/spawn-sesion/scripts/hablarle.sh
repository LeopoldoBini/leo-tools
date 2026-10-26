#!/usr/bin/env bash
# Le habla a otra sesión de Claude abierta en cmux, en esta Mac, y devuelve su respuesta.
#
# La pantalla no sirve para esto, en ninguna de las dos puntas (medido 24-oct-2026): `cmux send` +
# `send-key enter` dejaron un mensaje largo pegado como "[Pasted text #1]" sin enviar, con OK en los
# dos comandos; y esperar la respuesta comparando `read-screen` no vio que la otra ya había contestado.
# Por eso acá el mensaje viaja por `cmux agent message` —entra por los hooks de Claude, sin tipear— y
# la respuesta se lee de la bitácora de la otra sesión, que es donde queda escrita de verdad.
#
# Depende de un archivo interno de cmux sin documentar (~/.cmuxterm/claude-hook-sessions.json): es lo
# único que dice qué sesión corre HOY en esa pestaña —el id de arranque cambia con /clear— y cuándo
# terminó su turno. Se lee a la defensiva: si no tiene la forma esperada, se falla en voz alta (70).
set -euo pipefail

uso() {
  cat <<'EOF'
uso: hablarle.sh <destino> [--plazo <t>] < mensaje

  <destino>     La sesión: `surface:N` (pestaña) o `workspace:N` (ventana; cmux elige su agente).
  --plazo <t>   Cuánto esperar la respuesta: `30m`, `90s`, o minutos a secas. Default: 30m.
  El mensaje entra por stdin (cualquier largo, multilínea).

Espera la confirmación de entrega y después el fin del turno de la otra sesión, y recién ahí
imprime en stdout su respuesta completa, leída de su bitácora. El avance va a stderr.
Dos mensajes a la vez a la misma sesión comparten turno: cada uno vuelve con el texto de los dos.

Sale con:
  0   respondió; la respuesta está en stdout
  2   uso incorrecto o mensaje vacío
  3   no entregado: el destino no existe, no tiene Claude, no acepta mensajes, o cmux no lo entregó
  4   entregado, pero la sesión no terminó su turno dentro del plazo
  70  el registro de cmux no tiene la forma esperada (cambió su formato interno)
EOF
}

case "${1:-}" in -h|--help|"") uso; [ -n "${1:-}" ] && exit 0; exit 2 ;; esac
command -v cmux >/dev/null 2>&1 || { echo "error: no está el cli de cmux" >&2; exit 3; }

# El programa va en una variable para que stdin quede libre para el mensaje.
read -r -d '' PY <<'PYEOF' || true
import json, os, re, subprocess, sys, time

REGISTRO = os.path.expanduser("~/.cmuxterm/claude-hook-sessions.json")
PLAZO_ENTREGA = 60          # s: lo que tarda en entrar a una sesión ociosa es ~1,5 s (medido)
SONDEO = 3                  # s entre lecturas de archivos

def avance(msg): print(msg, file=sys.stderr, flush=True)
def fallar(cod, msg): avance("error: " + msg); sys.exit(cod)

def leer_plazo(t):
    m = re.fullmatch(r"(\d+(?:\.\d+)?)([sm]?)", t)
    if not m: fallar(2, f"plazo inválido: {t} (usá 30m, 90s o minutos)")
    n = float(m.group(1))
    return n if m.group(2) == "s" else n * 60

args = sys.argv[1:]
destino, plazo = None, 30 * 60
while args:
    a = args.pop(0)
    if a == "--plazo" and args: plazo = leer_plazo(args.pop(0))
    elif destino is None and not a.startswith("-"): destino = a
    else: fallar(2, f"argumento de más o desconocido: {a}")
if not destino: fallar(2, "falta el destino")
mensaje = sys.stdin.read()
if not mensaje.strip(): fallar(2, "el mensaje (stdin) está vacío")

def cmux(*a, entrada=None):
    r = subprocess.run(["cmux", *a], input=entrada, capture_output=True, text=True)
    return r.returncode, r.stdout, (r.stderr or r.stdout).strip()

def cmux_json(*a, entrada=None):
    rc, out, err = cmux(*a, entrada=entrada)
    if rc != 0: return None, err
    try: return json.loads(out), None
    except ValueError: return None, f"cmux no devolvió JSON: {out[:200]}"

# --- 1. ¿Hay una sesión de Claude ahí que acepte mensajes? -------------------------------------
estado, err = cmux_json("agent", "messages", "status", destino, "--json")
if estado is None: fallar(3, f"{destino}: {err}")
surface = estado.get("id")
if estado.get("scope") != "surface" or not surface:
    fallar(3, f"{destino} no resuelve a una pestaña con agente (cmux dijo: {json.dumps(estado)})")
if not (estado.get("receiving") and estado.get("messages_enabled", True)):
    fallar(3, f"{destino} tiene los mensajes apagados (`cmux agent messages on {destino}` los prende)")

def registro():
    """Sesión de Claude que corre HOY en la pestaña, según cmux. Falla en voz alta si cambió la forma."""
    try:
        with open(REGISTRO) as f: d = json.load(f)
    except FileNotFoundError: fallar(70, f"no está {REGISTRO}: ¿cmux cambió dónde guarda las sesiones?")
    except ValueError:
        return None  # escritura a medias de cmux; se relee en el próximo sondeo
    if not isinstance(d, dict) or not isinstance(d.get("activeSessionsBySurface"), dict) \
            or not isinstance(d.get("sessions"), dict):
        fallar(70, f"{REGISTRO} no tiene activeSessionsBySurface/sessions: cambió el formato interno de cmux")
    activa = d["activeSessionsBySurface"].get(surface)
    if not activa: return {}
    sid = activa.get("sessionId") if isinstance(activa, dict) else None
    s = d["sessions"].get(sid) if sid else None
    if not isinstance(s, dict) or "agentLifecycle" not in s:
        fallar(70, f"la sesión {sid} de {destino} no tiene agentLifecycle en el registro de cmux: cambió el formato")
    s = dict(s, sessionId=sid)
    if not s.get("transcriptPath") and s.get("cwd"):
        s["transcriptPath"] = os.path.expanduser("~/.claude/projects/" +
            re.sub(r"[/.]", "-", s["cwd"]) + f"/{sid}.jsonl")
    return s

def vivo(pid):
    try: os.kill(int(pid), 0); return True
    except PermissionError: return True
    except (ValueError, TypeError, ProcessLookupError): return False

s = registro()
if s is None: time.sleep(1); s = registro() or {}
if not s: fallar(3, f"{destino} no tiene una sesión de Claude registrada en cmux")
if s.get("pid") and not vivo(s["pid"]):
    fallar(3, f"{destino}: el Claude que cmux tiene registrado (pid {s['pid']}) ya no corre")

# --- 2. Mandar ------------------------------------------------------------------------------
# La nota final evita que conteste por el canal: esa respuesta despertaría a quien manda, y además
# no quedaría como texto en su bitácora, que es de donde se lee.
nota = ("\n\n(Respondé en texto, en tu turno: tu respuesta le llega sola a quien te escribió. "
        "No hace falta `cmux agent message --reply-to`.)")
cuerpo = mensaje.rstrip("\n") + nota

def ya_en_cola(desde):
    inbox, _ = cmux_json("agent", "inbox", "--surface", surface, "--json", "--limit", "50")
    for m in (inbox or {}).get("messages", []):
        # La bandeja de una pestaña lista lo que recibió Y lo que mandó: se filtra por destinatario.
        if m.get("recipient_surface_id") == surface and m.get("body") == cuerpo \
                and (m.get("created_at") or 0) >= desde: return m
    return None

# Pasados ~3,7 KB el socket de cmux corta a veces ("Socket closed before reply"), de 1 a 4 veces
# de cada 6, sin que el mensaje entre a la cola (medido 26-oct-2026, cmux 0.65.2). Se reintenta,
# pero antes se mira la cola: si el corte fue sólo en la respuesta, reenviar lo duplicaría.
# Mandarlo en un archivo no sirve: la otra sesión no abre lo que le pide leer un tercero (medido).
desde, enviado = time.time() - 1, None
for intento in range(10):
    enviado, err = cmux_json("agent", "message", surface, "--json", "-", entrada=cuerpo)
    if enviado and enviado.get("id"): break
    enviado = ya_en_cola(desde)
    if enviado or "Socket closed" not in (err or ""): break
    time.sleep(0.5)
if not enviado or not enviado.get("id"): fallar(3, f"cmux no aceptó el mensaje: {err}")
if intento: avance(f"cmux cortó el socket {intento} vez/veces; entró al reintento")
mid = enviado["id"]
if enviado.get("recipient_has_agent") is False:
    fallar(3, f"cmux dice que {destino} no tiene agente (mensaje {mid} quedó {enviado.get('state')})")
avance(f"mandado: {mid} → {destino}")

# --- 3. Confirmar la entrega ----------------------------------------------------------------
def mi_mensaje():
    inbox, _ = cmux_json("agent", "inbox", "--surface", surface, "--json", "--limit", "200")
    for m in (inbox or {}).get("messages", []):
        if m.get("id") == mid: return m
    return None

inicio = time.time()
while True:
    m = mi_mensaje() or {}
    st = m.get("state")
    if st in ("delivered", "read"): break
    if st == "failed": fallar(3, f"cmux no lo entregó: {m.get('failure_reason') or 'sin motivo'} (mensaje {mid})")
    # Una sesión ocupada lo lee recién en su próximo paso: mientras siga trabajando, la cola es normal.
    ocupada = (registro() or {}).get("agentLifecycle") == "running"
    tope = plazo if ocupada else PLAZO_ENTREGA
    if time.time() - inicio > tope:
        fallar(3, f"sin entregar a los {int(time.time() - inicio)} s (estado: {st or 'desconocido'}). "
                  f"Si sigue en cola puede entrar más tarde: no lo reenvíes a ciegas (mensaje {mid})")
    time.sleep(1 if time.time() - inicio < 10 else SONDEO)
avance(f"entregado: {m.get('delivered_via') or st}")

# --- 4. Esperar el fin del turno y leer la respuesta de la bitácora --------------------------
def leer_bitacora(ruta):
    """(entró, terminó, textos): si el mensaje ya está en la bitácora, si su turno cerró y el texto."""
    try:
        with open(ruta) as f: lineas = f.readlines()
    except OSError: return False, False, []
    entro, termino, textos = False, False, []
    for l in lineas:
        if not entro:
            # Ancla: el registro con que el mensaje entra a la charla (no la cola ni el pedido a la API).
            if mid in l:
                try: e = json.loads(l)
                except ValueError: continue
                entro = e.get("type") in ("user", "attachment")
            continue
        try: e = json.loads(l)
        except ValueError: continue
        if e.get("isSidechain"): continue
        if e.get("type") == "system" and e.get("subtype") == "turn_duration":
            termino = True
        elif e.get("type") == "assistant":
            for b in (e.get("message") or {}).get("content") or []:
                if isinstance(b, dict) and b.get("type") == "text" and b.get("text", "").strip():
                    textos.append(b["text"].strip())
    return entro, termino, textos

ruta, ultimo = None, ""
while True:
    s = registro() or {}
    # Se busca en la bitácora de la sesión ACTUAL hasta encontrar el mensaje: si alguien hizo /clear,
    # cmux ya apunta a la nueva. Una vez encontrado, esa es la conversación que contesta.
    if ruta is None and s.get("transcriptPath") and leer_bitacora(s["transcriptPath"])[0]:
        ruta = s["transcriptPath"]; sid = s.get("sessionId")
        avance(f"leyendo: {ruta}")
    if ruta:
        _, termino, textos = leer_bitacora(ruta)
        estado_reg = s.get("agentLifecycle") if s.get("sessionId") == sid else "otra-sesion"
        # Fin de turno real = la bitácora cierra el turno Y cmux la ve parada. Con trabajo de fondo
        # pendiente el turno cerró, pero la respuesta de verdad llega cuando ese trabajo vuelve.
        if termino and estado_reg not in ("running", "backgroundWorkPending"):
            if not textos: avance("aviso: terminó el turno sin escribir texto")
            print("\n\n".join(textos))
            sys.exit(0)
        ultimo = estado_reg
    if time.time() - inicio > plazo:
        fallar(4, f"entregado, pero sin fin de turno a los {int(time.time() - inicio)} s "
                  f"(estado: {ultimo or 'el mensaje todavía no aparece en su bitácora'}; mensaje {mid})")
    time.sleep(SONDEO)
PYEOF
exec python3 -c "$PY" "$@"
