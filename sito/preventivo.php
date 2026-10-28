<?php
require __DIR__ . '/inc/app.php';

// Il modulo preventivo, tutto in una pagina: le parti accese dal gestionale
// (tipo di evento, data, luogo, richieste, contatti, messaggio). Lo disegna
// sito.js; con il database l'invio andrà all'API e la richiesta arriverà nel
// gestionale e nell'app.
$pagina = 'preventivo';
$titolo = 'Preventivo';
require __DIR__ . '/inc/testa.php';
?>

<div class="contenitore preventivo" data-preventivo></div>

<?php require __DIR__ . '/inc/piede.php'; ?>
