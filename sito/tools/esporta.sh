#!/usr/bin/env bash
# Trasforma il sito PHP in pagine HTML statiche, per l'anteprima su GitHub
# Pages (che non esegue PHP). Su Hostinger il sito userà direttamente i .php.
#
# Uso:  bash sito/tools/esporta.sh <cartella di uscita>
# Si ferma al primo errore o avviso del PHP, così niente di rotto va online.
set -euo pipefail

OUT="$(realpath -m "${1:-_site}")"
cd "$(dirname "$0")/.."

rm -rf "$OUT"
mkdir -p "$OUT"
cp -r assets "$OUT/assets"
touch "$OUT/.nojekyll"

export STATICO=1
LOG="$(mktemp)"

pagina() { # pagina <file php> <file html>
  php -d display_errors=stderr -d error_reporting=E_ALL "$1" > "$OUT/$2" 2> "$LOG"
  if [ -s "$LOG" ]; then
    echo "Errore PHP in $1 -> $2:" >&2
    cat "$LOG" >&2
    exit 1
  fi
  echo "  $2"
}

# Le pagine disegnano i contenuti nel browser (assets/js/sito.js): un solo
# lavoro.html vale per tutti i lavori (lavoro.html?id=...).
echo "Pagine"
for p in index lavori lavoro biografia preventivo riservata; do pagina "$p.php" "$p.html"; done

# Indirizzi sconosciuti: la home.
cp "$OUT/index.html" "$OUT/404.html"
echo "Fatto: $OUT"
