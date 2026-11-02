<?php
require __DIR__ . '/inc/app.php';

// Un lavoro: solo le sue foto, sparse e intere (lavoro.php?id=...).
$pagina = 'lavori';
$titolo = 'Lavoro';

// Con PHP il lavoro si conosce già qui: titolo della scheda e anteprima del
// link (WhatsApp, Facebook...) con la sua copertina e il suo nome.
$id = (string) ($_GET['id'] ?? '');
foreach ($id !== '' ? lavori_sito() : [] as $w) {
    if (($w['id'] ?? '') !== $id) continue;
    $titolo = (string) ($w['title'] ?? 'Lavoro');
    $luogo = trim(implode(' · ', array_filter([trim((string) ($w['location'] ?? '')), trim((string) ($w['category'] ?? ''))])));
    $anteprima = [
        'titolo' => $titolo . ($luogo !== '' ? ' · ' . $luogo : ''),
        'testo' => ($luogo !== '' ? $luogo . ' · ' : '') . (contenuti()['studioName'] ?? 'Studio 54'),
        'foto' => copertina($w),
    ];
    break;
}
require __DIR__ . '/inc/testa.php';
?>

<div class="contenitore collage" data-collage></div>

<?php require __DIR__ . '/inc/piede.php'; ?>
