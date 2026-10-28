<?php
// Il gestionale dello studio, da computer: un'unica pagina che modifica sito
// e app insieme (lavori, preventivo, biografia, contatti), solo il sito
// (carosello orizzontale) o solo l'app (carosello verticale, area clienti).
//
// Per ora, senza database, le modifiche restano nel browser in cui si fanno
// e il sito le mostra subito in quel browser. Con Cloudflare il salvataggio
// passerà dall'API (vedi assets/js/dati.js) e arriverà a tutti, app compresa.
require __DIR__ . '/inc/app.php';
$c = contenuti();
?><!DOCTYPE html>
<html lang="it" data-ext="<?= STATICO ? 'html' : 'php' ?>">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex">
  <title>Gestionale · <?= e($c['studioName'] ?? 'Studio 54') ?></title>
  <meta name="theme-color" content="#FFFFFF">
  <link rel="icon" type="image/png" href="assets/img/favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Josefin+Sans:ital,wght@0,300;0,400;0,600;1,300&family=Jost:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="<?= e(risorsa('assets/css/riservata.css')) ?>">
</head>
<body>
  <div id="app"></div>
  <div class="finestra" id="finestra" hidden role="dialog" aria-modal="true" aria-labelledby="finestra-titolo">
    <div class="finestra-box">
      <h2 class="finestra-titolo" id="finestra-titolo"></h2>
      <div class="finestra-corpo"></div>
      <div class="finestra-azioni"></div>
    </div>
  </div>
  <div class="avviso-breve" id="avviso-breve" hidden role="status"></div>

  <?= dati_pagina('s54-dati', dati()) ?>
  <?= dati_pagina('s54-gestionale', dati_gestionale()) ?>
  <script src="<?= e(risorsa('assets/js/dati.js')) ?>"></script>
  <script src="<?= e(risorsa('assets/js/riservata.js')) ?>"></script>
</body>
</html>
