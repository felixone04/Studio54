<?php
require __DIR__ . '/inc/app.php';

$pagina = 'index';
$titolo = '';
require __DIR__ . '/inc/testa.php';
?>

<!-- Il carosello delle foto orizzontali (solo foto, frecce e dissolvenza) e
     i lavori in evidenza: li disegna sito.js con i dati del gestionale. -->
<section class="apertura" data-carosello data-intervallo="4000" aria-roledescription="carosello" aria-label="Foto"></section>

<section class="contenitore evidenza" data-evidenza aria-label="Lavori in evidenza"></section>

<?php require __DIR__ . '/inc/piede.php'; ?>
