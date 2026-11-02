<?php
require __DIR__ . '/inc/app.php';

// Privacy e cookie: informativa, cookie e note legali, con i testi scritti
// nel gestionale (uguali nell'app). Li disegna sito.js.
$pagina = 'privacy';
$titolo = 'Privacy e cookie';
require __DIR__ . '/inc/testa.php';
?>

<div class="contenitore legale" data-legale></div>

<?php require __DIR__ . '/inc/piede.php'; ?>
