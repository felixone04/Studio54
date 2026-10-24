<?php
// Base comune a tutte le pagine del sito: dati, indirizzi e piccoli aiuti.
//
// Oggi i contenuti arrivano da data/contenuti.json. Quando ci sarà il
// database su Hostinger basterà cambiare dati() perché li legga da lì: le
// pagine non cambiano.

declare(strict_types=1);

date_default_timezone_set('Europe/Rome');

/** Vero quando il sito viene esportato in pagine HTML statiche (anteprima su GitHub Pages). */
define('STATICO', getenv('STATICO') === '1');

/** Tutti i contenuti del sito. */
function dati(): array
{
    static $d = null;
    if ($d === null) {
        $raw = file_get_contents(__DIR__ . '/../data/contenuti.json');
        $d = json_decode($raw === false ? '{}' : $raw, true) ?: [];
    }
    return $d;
}

function contenuti(): array
{
    return dati()['content'] ?? [];
}

/** Testo sicuro da mettere nell'HTML. */
function e(?string $s): string
{
    return htmlspecialchars((string) $s, ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

/** Valore di un parametro dell'indirizzo (?id=...), anche nell'esportazione statica. */
function param(string $nome): string
{
    if (STATICO) {
        return (string) getenv(strtoupper($nome));
    }
    return isset($_GET[$nome]) ? (string) $_GET[$nome] : '';
}

/**
 * Indirizzo di una pagina. Con PHP: lavoro.php?id=x; nell'anteprima
 * statica: lavoro-x.html.
 */
function url(string $pagina, string $id = ''): string
{
    if (STATICO) {
        if ($pagina === 'index') {
            return 'index.html';
        }
        return $pagina . ($id !== '' ? '-' . rawurlencode($id) : '') . '.html';
    }
    $chiave = $pagina === 'riservata' ? 'sez' : 'id';
    return $pagina . '.php' . ($id !== '' ? '?' . $chiave . '=' . rawurlencode($id) : '');
}

/** Le foto di Unsplash si chiedono alla larghezza che serve. */
function foto(string $u, int $w): string
{
    if (strpos($u, 'images.unsplash.com') === false) {
        return $u;
    }
    if (preg_match('/[?&]w=\d+/', $u)) {
        return (string) preg_replace('/([?&])w=\d+/', '${1}w=' . $w, $u);
    }
    return $u . (strpos($u, '?') === false ? '?' : '&') . 'w=' . $w;
}

/** Attributi src e srcset per una foto, con le larghezze più utili. */
function foto_attr(string $u, string $sizes = '100vw'): string
{
    if (strpos($u, 'images.unsplash.com') === false) {
        return 'src="' . e($u) . '"';
    }
    $set = [];
    foreach ([480, 800, 1200, 1600, 2200] as $w) {
        $set[] = e(foto($u, $w)) . ' ' . $w . 'w';
    }
    return 'src="' . e(foto($u, 1200)) . '" srcset="' . implode(', ', $set) . '" sizes="' . e($sizes) . '"';
}

/**
 * Indirizzo di un file di assets/ con la sua "impronta": quando il file
 * cambia cambia anche l'indirizzo, così il browser non usa la copia vecchia.
 */
function risorsa(string $percorso): string
{
    $file = __DIR__ . '/../' . $percorso;
    return $percorso . (is_file($file) ? '?v=' . substr(md5_file($file), 0, 10) : '');
}

function due(int $n): string
{
    return str_pad((string) $n, 2, '0', STR_PAD_LEFT);
}

function maiuscolo(string $s): string
{
    return mb_strtoupper($s, 'UTF-8');
}

/** Solo i lavori visibili sul sito. */
function lavori_pubblicati(): array
{
    return array_values(array_filter(dati()['works'] ?? [], fn($w) => $w['published'] ?? true));
}

/** Foto del carosello: quelle con la stella, altrimenti tutte. */
function foto_apertura(): array
{
    $g = dati()['gallery'] ?? [];
    $h = array_values(array_filter($g, fn($p) => $p['inHero'] ?? true));
    return $h ?: $g;
}

function copertina(array $w): string
{
    $c = trim($w['cover'] ?? '');
    return $c !== '' ? $c : ($w['photos'][0]['url'] ?? '');
}

function servizio(string $id): ?array
{
    foreach (dati()['services'] ?? [] as $s) {
        if ($s['id'] === $id) {
            return $s;
        }
    }
    return null;
}

/** Riga di informazioni unite da un punto. */
function unisci(array $parti, string $sep = ' · '): string
{
    return implode($sep, array_filter(array_map('trim', $parti), fn($p) => $p !== ''));
}

const MESI = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio',
    'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'];

/** Data in italiano, es. "12 giugno 2027". */
function data_it(?string $iso, bool $breve = false): string
{
    if (!$iso) {
        return '';
    }
    $t = strtotime($iso);
    if ($t === false) {
        return '';
    }
    $m = MESI[(int) date('n', $t) - 1];
    return date('j', $t) . ' ' . ($breve ? mb_substr($m, 0, 3) : $m) . ' ' . date('Y', $t);
}
