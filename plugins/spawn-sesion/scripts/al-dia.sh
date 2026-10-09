#!/usr/bin/env bash
# ¿El repo de esta carpeta está al día con GitHub? Mira el repo que contiene la carpeta y, si ese
# repo vive anidado dentro de otro (un paraguas), también el paraguas.
#
# Uso: al-dia.sh [--para-viajar] [carpeta]      (carpeta por defecto: la actual)
#
#   sin flag       parte con semáforo por repo — verde / amarillo / rojo — y una acción por cada
#                  no-verde. Sale siempre 0. Fuera de un repo no imprime nada.
#   --para-viajar  además exige que no quede nada sin commitear ni sin subir, en repo y paraguas:
#                  sale 1 listando qué impide que el trabajo viaje a otra máquina.
#
# Solo lee. El fetch actualiza las referencias de origin y no toca el árbol; pull, commit y push
# nunca. El fetch tiene tope de 8 s: si falla o no llega, se dice, no se inventa estado.

TOPE_FETCH=8
modo=parte
dir=.
for a in "$@"; do
  case "$a" in
    --para-viajar) modo=viajar ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) dir=$a ;;
  esac
done

export GIT_TERMINAL_PROMPT=0

raiz() { git -C "$1" rev-parse --show-toplevel 2>/dev/null; }
corta() { case "$1" in "$HOME"/*) echo "~${1#"$HOME"}" ;; *) echo "$1" ;; esac; }

repo=$(raiz "$dir")
[ -n "$repo" ] || exit 0
repos=("$repo")
paraguas=$(raiz "$(dirname "$repo")")
[ -n "$paraguas" ] && repos+=("$paraguas")

# Remoto a consultar: el del upstream de la rama, si no origin, si no el primero que haya.
remoto_de() {
  local r=$1 rama rem
  rama=$(git -C "$r" symbolic-ref -q --short HEAD)
  [ -n "$rama" ] && rem=$(git -C "$r" config "branch.$rama.remote")
  if [ -z "$rem" ]; then
    if git -C "$r" remote | grep -qx origin; then rem=origin; else rem=$(git -C "$r" remote | head -1); fi
  fi
  echo "$rem"
}

# Fetch en paralelo, uno por repo, cada uno con su vigía que lo mata al tope (macOS no trae
# `timeout`). Sin terminal ni ssh interactivo: una pregunta colgaría el arranque de la sesión.
pids=(); vigias=()
for i in "${!repos[@]}"; do
  r=${repos[$i]}
  rem=$(remoto_de "$r")
  if [ -z "$rem" ]; then pids[i]=-; continue; fi
  (
    if [ -z "${GIT_SSH_COMMAND:-}" ] && [ -z "$(git -C "$r" config core.sshCommand)" ]; then
      export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=5"
    fi
    exec git -C "$r" fetch --quiet --no-tags "$rem"
  ) </dev/null >/dev/null 2>&1 &
  pids[i]=$!
  ( sleep "$TOPE_FETCH"; kill "${pids[i]}" ) </dev/null >/dev/null 2>&1 &
  vigias[i]=$!
  disown "${vigias[i]}" 2>/dev/null   # que su muerte no deje aviso de job en la salida
done
fetch_ok=()
for i in "${!repos[@]}"; do
  if [ "${pids[i]}" = - ]; then fetch_ok[i]=-; continue; fi
  if { wait "${pids[i]}"; } 2>/dev/null; then fetch_ok[i]=si; else fetch_ok[i]=no; fi
  kill "${vigias[i]}" 2>/dev/null
done

peor=0          # 0 verde, 1 amarillo, 2 rojo
parte=""        # líneas del parte
bloqueos=""     # lo que impide viajar
resumen_verde=""

# Evalúa un repo: agrega su bloque al parte, sube `peor` y anota bloqueos.
evaluar() {
  local r=$1 rol=$2 fok=$3
  local rama sucios stashes remotos up="" ahead=0 behind=0 color=0 items="" etiqueta
  rama=$(git -C "$r" symbolic-ref -q --short HEAD)
  sucios=$(git --no-optional-locks -C "$r" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  stashes=$(git -C "$r" stash list 2>/dev/null | wc -l | tr -d ' ')
  remotos=$(git -C "$r" remote)
  etiqueta="$rol $(corta "$r") [${rama:-HEAD suelto}]"

  sube() { [ "$1" -gt "$color" ] && color=$1; }
  item() { items="$items
    - $1"; }

  if [ -z "$remotos" ]; then
    sube 2; item "sin remoto: lo que se haga acá no sale de esta máquina → avisarle al usuario"
  elif git -C "$r" rev-parse -q --verify HEAD >/dev/null; then
    [ -n "$rama" ] && up=$(git -C "$r" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    if [ -n "$up" ]; then
      read -r ahead behind <<EOF
$(git -C "$r" rev-list --left-right --count "HEAD...$up")
EOF
    else
      ahead=$(git -C "$r" rev-list --count HEAD --not --remotes)
    fi
  fi

  if [ -z "$rama" ]; then
    sube 2; item "HEAD suelto (detached), fuera de toda rama → frenar y preguntarle al usuario en qué rama trabajar"
  elif [ -n "$remotos" ] && [ -z "$up" ]; then
    sube 1; item "la rama no tiene upstream → \`git push -u $(remoto_de "$r") $rama\` para que viaje"
  fi
  if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
    sube 2; item "divergido: $ahead propios sin subir y $behind de $up sin traer → frenar y preguntarle al usuario"
  elif [ "$behind" -gt 0 ] && [ "$sucios" -eq 0 ]; then
    sube 2; item "atrasado $behind y limpio → \`git pull --ff-only\` antes de trabajar"
  elif [ "$behind" -gt 0 ]; then
    sube 2; item "atrasado $behind con cambios sin commitear → frenar y preguntarle al usuario antes de traer"
  elif [ "$ahead" -gt 0 ]; then
    sube 1; item "commits sin subir: $ahead → \`git push\` cuando corresponda"
  fi
  if [ "$sucios" -gt 0 ]; then
    sube 1; item "cambios sin commitear en $sucios archivos → saber de quién son antes de pisarlos"
  fi
  if [ "$stashes" -gt 0 ]; then
    sube 1; item "stashes guardados: $stashes → \`git stash list\`: puede haber trabajo pendiente ahí"
  fi
  if [ "$fok" = no ]; then
    sube 1; item "no pude consultar GitHub (el fetch falló o tardó más de ${TOPE_FETCH} s): lo de origin puede estar viejo"
  fi

  # Lo que impide que el trabajo viaje: cambios locales o commits que el remoto no tiene.
  [ "$sucios" -gt 0 ] && bloqueos="$bloqueos
  - $(corta "$r"): cambios sin commitear en $sucios archivos"
  [ -n "$remotos" ] && [ "$ahead" -gt 0 ] && bloqueos="$bloqueos
  - $(corta "$r"): commits sin subir: $ahead"

  [ "$color" -gt "$peor" ] && peor=$color
  local nombres=(verde amarillo rojo)
  parte="$parte
  $etiqueta: ${nombres[$color]}$items"
  [ "$color" -eq 0 ] && resumen_verde="$resumen_verde${resumen_verde:+ y }$rol $(basename "$r") [$rama]"
}

for i in "${!repos[@]}"; do
  if [ "$i" -eq 0 ]; then rol=repo; else rol=paraguas; fi
  evaluar "${repos[$i]}" "$rol" "${fetch_ok[i]}"
done

nombres=(verde amarillo rojo)
if [ "$peor" -eq 0 ]; then
  echo "al-dia: verde — $resumen_verde al día con GitHub."
else
  echo "al-dia: ${nombres[$peor]} (git de esta carpeta frente a GitHub)$parte"
  if [ "$modo" = parte ]; then
    echo "Qué hacer: con rojo, frenar y contárselo al usuario antes de tocar nada — salvo \"atrasado y limpio\", que se resuelve haciendo primero el \`git pull --ff-only\`. Amarillo: tenerlo presente."
  fi
fi

if [ "$modo" = viajar ]; then
  if [ -n "$bloqueos" ]; then
    echo "para-viajar: NO — esto no llegaría a la otra máquina:$bloqueos"
    exit 1
  fi
  echo "para-viajar: ok — todo lo commiteado está subido y no hay cambios sueltos."
fi
exit 0
