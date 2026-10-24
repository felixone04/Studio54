<?php
// Inizio di ogni pagina pubblica: <head>, logo d'apertura e barra in alto.
// Prima di includerla la pagina imposta $pagina (voce attiva) e $titolo.

$c = contenuti();
$nome = $c['studioName'] ?? 'Studio 54';
$titolo_pagina = isset($titolo) && $titolo !== '' ? $titolo . ' · ' . $nome : $nome . ' · ' . ($c['tagline'] ?? '');
$voci = [
    ['Home', 'index'],
    ['Lavori', 'lavori'],
    ['Biografia', 'biografia'],
    ['Preventivo', 'preventivo'],
];
?><!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= e($titolo_pagina) ?></title>
  <meta name="description" content="<?= e($nome) ?> · Fotografia di matrimoni ed eventi. Guarda i nostri lavori e richiedi un preventivo gratuito.">
  <meta name="theme-color" content="#FFFAF0">
  <link rel="icon" type="image/png" href="assets/img/favicon.png">
  <link rel="apple-touch-icon" href="assets/img/icon-192.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Josefin+Sans:ital,wght@0,300;0,400;0,600;1,300;1,400&family=Jost:wght@400;500;600&display=swap" rel="stylesheet">
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
<body class="<?= e($classe_body ?? '') ?>">
  <div id="intro" aria-hidden="true">
    <img src="assets/img/logo.png" alt="">
    <div class="intro-barra"><b></b></div>
  </div>

  <header class="barra" id="barra">
    <a class="barra-logo" href="<?= e(url('index')) ?>" aria-label="Home">
      <img src="assets/img/logo.png" alt="<?= e($nome) ?>">
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
      <button class="menu-chiudi" type="button" aria-label="Chiudi">&times;</button>
    </div>
    <nav class="menu-voci">
      <?php foreach ($voci as $i => [$t, $p]): ?>
        <a class="<?= $pagina === $p ? 'attivo' : '' ?>" href="<?= e(url($p)) ?>">
          <small><?= due($i + 1) ?></small><?= e(maiuscolo($t)) ?>
        </a>
      <?php endforeach; ?>
    </nav>
    <div class="menu-contatti">
      <?php if (!empty($c['contacts']['phone'])): ?>
        <a href="tel:<?= e(preg_replace('/[^0-9+]/', '', $c['contacts']['phone'])) ?>"><?= e($c['contacts']['phone']) ?></a>
      <?php endif; ?>
      <?php if (!empty($c['contacts']['email'])): ?>
        <a href="mailto:<?= e($c['contacts']['email']) ?>"><?= e($c['contacts']['email']) ?></a>
      <?php endif; ?>
    </div>
  </div>

  <main id="contenuto">
