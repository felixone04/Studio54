<?php
// Inizio di ogni pagina pubblica: <head>, logo d'apertura e barra in alto.
// Prima di includerla la pagina imposta $pagina (voce attiva) e $titolo.

$c = contenuti();
$nome = $c['studioName'] ?? 'Studio 54';
$titolo_pagina = isset($titolo) && $titolo !== '' ? $titolo . ' · ' . $nome : $nome . ' · ' . ($c['tagline'] ?? '');
$descrizione = $nome . ' · Fotografia di matrimoni ed eventi. Guardate i nostri lavori e chiedeteci informazioni.';

// Anteprima del link quando lo si condivide (WhatsApp, Facebook, Telegram...):
// la pagina di un lavoro la prepara con copertina e nome (lavoro.php), le
// altre mostrano una foto del carosello. Solo foto con un indirizzo web:
// quelle caricate dentro i dati non si possono mostrare fuori dal sito.
$anteprima = ($anteprima ?? []) + ['titolo' => $titolo_pagina, 'testo' => $descrizione, 'foto' => ''];
if ($anteprima['foto'] === '') {
    foreach (array_merge(dati()['carouselSite'] ?? [], array_map(fn ($w) => ['url' => copertina($w)], lavori_sito())) as $f) {
        if (($f['active'] ?? true) !== false && preg_match('#^https?://#', (string) ($f['url'] ?? ''))) { $anteprima['foto'] = $f['url']; break; }
    }
}
$anteprima['foto'] = preg_match('#^https?://#', $anteprima['foto']) ? foto_larga($anteprima['foto'], 1200) : '';
$indirizzo = indirizzo_pagina();

$voci = [
    ['Home', 'index'],
    ['Lavori', 'lavori'],
    ['Biografia', 'biografia'],
    ['Preventivo', 'preventivo'],
];
?><!DOCTYPE html>
<html lang="it" data-ext="<?= STATICO ? 'html' : 'php' ?>">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= e($titolo_pagina) ?></title>
  <meta name="description" content="<?= e($descrizione) ?>">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="<?= e($nome) ?>">
  <meta property="og:locale" content="it_IT">
  <meta property="og:title" content="<?= e($anteprima['titolo']) ?>">
  <meta property="og:description" content="<?= e($anteprima['testo']) ?>">
  <?php if ($indirizzo !== ''): ?><meta property="og:url" content="<?= e($indirizzo) ?>">
  <?php endif; ?><?php if ($anteprima['foto'] !== ''): ?><meta property="og:image" content="<?= e($anteprima['foto']) ?>">
  <meta name="twitter:card" content="summary_large_image">
  <?php endif; ?><meta name="theme-color" content="#FFFFFF">
  <meta name="color-scheme" content="light only">
  <link rel="icon" type="image/png" href="assets/img/favicon.png">
  <link rel="apple-touch-icon" href="assets/img/icon-192.png">
  <link rel="preconnect" href="https://images.unsplash.com">
  <link rel="preload" href="assets/fonts/josefin-sans-latin.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="assets/fonts/jost-latin.woff2" as="font" type="font/woff2" crossorigin>
  <link rel="stylesheet" href="<?= e(risorsa('assets/css/caratteri.css')) ?>">
  <link rel="stylesheet" href="<?= e(risorsa('assets/css/sito.css')) ?>">
  <script>
    // Il logo d'apertura si vede entrando nel sito (o ricaricando la pagina);
    // passando da una pagina all'altra del sito no.
    try {
      var nav = (performance.getEntriesByType('navigation')[0] || {}).type;
      var dentro = document.referrer && new URL(document.referrer).origin === location.origin;
      if (dentro && nav !== 'reload') document.documentElement.classList.add('senza-intro');
    } catch (e) {}
  </script>
</head>
<body class="pagina-<?= e($pagina) ?>" data-pagina="<?= e($pagina) ?>">
  <div id="intro" aria-hidden="true">
    <img src="assets/img/logo.png" alt="">
    <div class="intro-barra"><b></b></div>
  </div>

  <header class="barra" id="barra">
    <a class="barra-logo" href="<?= e(url('index')) ?>" aria-label="Home">
      <img class="logo-scuro" src="assets/img/logo.png" alt="<?= e($nome) ?>">
      <!-- Sopra la foto d'apertura il logo è chiaro. -->
      <img class="logo-chiaro" src="assets/img/logo-chiaro.png" alt="" aria-hidden="true">
    </a>
    <nav class="barra-voci" aria-label="Menu principale">
      <?php foreach ($voci as [$t, $p]): ?>
        <a class="link<?= $pagina === $p ? ' attivo' : '' ?>" href="<?= e(url($p)) ?>"><?= e(maiuscolo($t)) ?></a>
      <?php endforeach; ?>
    </nav>
    <button class="barra-menu" type="button" aria-label="Menu" aria-expanded="false" aria-controls="menu">
      <span>MENU</span><i></i>
    </button>
  </header>

  <div class="menu" id="menu" hidden>
    <div class="menu-testa">
      <a class="barra-logo" href="<?= e(url('index')) ?>" aria-label="Home">
        <img src="assets/img/logo.png" alt="<?= e($nome) ?>">
      </a>
      <button class="menu-chiudi" type="button" aria-label="Chiudi"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18"/></svg></button>
    </div>
    <nav class="menu-voci">
      <?php foreach ($voci as $i => [$t, $p]): ?>
        <a class="<?= $pagina === $p ? 'attivo' : '' ?>" href="<?= e(url($p)) ?>">
          <small>0<?= $i + 1 ?></small><?= e(maiuscolo($t)) ?>
        </a>
      <?php endforeach; ?>
    </nav>
    <div class="menu-contatti" data-menu-contatti></div>
  </div>

  <main id="contenuto">
