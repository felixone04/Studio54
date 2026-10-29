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

# Indirizzi sconosciuti: si torna alla home. Un rimando e non una copia della
# home, perché da un indirizzo in una sottocartella (/Studio54/a/b) i percorsi
# relativi di stili, foto e menu non funzionerebbero.
cat > "$OUT/404.html" <<'HTML'
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<meta name="robots" content="noindex">
<title>Studio 54</title>
<script>
  // Su GitHub Pages il sito sta in /<nome del progetto>/, altrove nella radice.
  var parti = location.pathname.split('/');
  var base = /\.github\.io$/.test(location.hostname) && parti[1] ? '/' + parti[1] + '/' : '/';
  location.replace(base + 'index.html');
</script>
</head>
<body style="background:#fff"></body>
</html>
HTML
echo "  404.html"
echo "Fatto: $OUT"
