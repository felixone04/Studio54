<?php
require __DIR__ . '/inc/app.php';

$pagina = 'lavori';
$titolo = 'Lavori';
require __DIR__ . '/inc/testa.php';
?>

<!-- I filtri subito sotto la barra, poi tutti i lavori (disegnati da sito.js). -->
<div class="contenitore lavori-pagina" data-lavori></div>

<?php require __DIR__ . '/inc/piede.php'; ?>
