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

echo "Pagine pubbliche"
for p in index lavori biografia preventivo; do pagina "$p.php" "$p.html"; done

echo "Lavori"
for id in $(php -r '$d = json_decode(file_get_contents("data/contenuti.json"), true);
  foreach ($d["works"] as $w) if ($w["published"] ?? true) echo $w["id"], "\n";'); do
  ID="$id" pagina lavoro.php "lavoro-$id.html"
done

echo "Area clienti"
pagina area-clienti.php area-clienti.html
for id in $(php -r '$d = json_decode(file_get_contents("data/contenuti.json"), true);
  foreach ($d["clients"] ?? [] as $c) echo $c["id"], "\n";'); do
  ID="$id" pagina cliente.php "cliente-$id.html"
done

echo "Area riservata (anteprima grafica)"
pagina riservata.php riservata.html
for s in panoramica richieste calendario clienti servizi pacchetti lavori galleria home biografia contatti impostazioni; do
  SEZ="$s" pagina riservata.php "riservata-$s.html"
done

# Indirizzi sconosciuti: la home.
cp "$OUT/index.html" "$OUT/404.html"
echo "Fatto: $OUT"
