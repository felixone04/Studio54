<?php
// Base comune a tutte le pagine del sito: dati, indirizzi e piccoli aiuti.
//
// Le pagine PHP preparano la struttura (barra, menu, footer) e consegnano i
// dati al browser; foto, lavori e modulo li disegna assets/js/sito.js. Oggi
// i dati arrivano da data/*.json; con il database su Cloudflare basterà
// cambiare dati() e dati_gestionale() perché li chiedano all'API.

declare(strict_types=1);

date_default_timezone_set('Europe/Rome');

/** Vero quando il sito viene esportato in pagine HTML statiche (anteprima su GitHub Pages). */
define('STATICO', getenv('STATICO') === '1');

function leggi_json(string $nome): array
{
    $raw = @file_get_contents(__DIR__ . '/../data/' . $nome);
    return json_decode($raw === false ? '{}' : $raw, true) ?: [];
}

/** I dati pubblici: testi, caroselli, lavori e modulo preventivo. */
function dati(): array
{
    static $d = null;
    return $d ??= leggi_json('contenuti.json');
}

/** I dati del solo gestionale: richieste, calendario, clienti, accesso. */
function dati_gestionale(): array
{
    static $d = null;
    return $d ??= leggi_json('gestionale.json');
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

/** Indirizzo di una pagina: lavori.php con PHP, lavori.html nell'anteprima statica. */
function url(string $pagina): string
{
    return $pagina . (STATICO ? '.html' : '.php');
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

/** Dati consegnati al browser dentro la pagina, letti da assets/js/dati.js. */
function dati_pagina(string $id, array $dati): string
{
    $json = json_encode($dati, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG | JSON_HEX_AMP);
    return '<script type="application/json" id="' . e($id) . '">' . $json . '</script>';
}

function maiuscolo(string $s): string
{
    return mb_strtoupper($s, 'UTF-8');
}
