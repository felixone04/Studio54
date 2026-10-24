<?php
require __DIR__ . '/inc/app.php';

$pagina = 'lavori';
$lavori = lavori_pubblicati();
$id = param('id');
$i = null;
foreach ($lavori as $k => $w) {
    if ($w['id'] === $id) {
        $i = $k;
    }
}
$w = $i === null ? null : $lavori[$i];
$succ = ($w && count($lavori) > 1) ? $lavori[($i + 1) % count($lavori)] : null;
$titolo = $w['title'] ?? 'Lavoro';
if (!$w && !STATICO) {
    http_response_code(404);
}

require __DIR__ . '/inc/testa.php';
?>

<?php if (!$w): ?>
  <div class="contenitore lavoro-assente">
    <p>Questo lavoro non è più in mostra.</p>
    <a class="link etichetta" href="<?= e(url('lavori')) ?>">&larr; TUTTI I LAVORI</a>
  </div>
<?php else:
    $info = unisci([$w['category'] ?? '', $w['setting'] ?? '', $w['seasonLabel'] ?? '', $w['location'] ?? '', $w['date'] ?? ''], '  ·  ');
?>
  <div class="contenitore dettaglio-testa">
    <a class="link etichetta tenue" href="<?= e(url('lavori')) ?>">&larr; TUTTI I LAVORI</a>
    <h1 class="entra"><?= e(maiuscolo($w['title'])) ?></h1>
    <?php if ($info !== ''): ?><p class="etichetta tenue entra"><?= e(maiuscolo($info)) ?></p><?php endif; ?>
  </div>

  <?php if (!empty($w['photos'])): ?>
  <!-- Solo foto: la prima orizzontale grande, poi un collage che alterna
       verticali e orizzontali senza tagliarle (composto da sito.js). -->
  <div class="contenitore collage" data-collage data-titolo="<?= e($w['title']) ?>"
       data-meta="<?= e(maiuscolo(unisci([$w['category'] ?? '', $w['location'] ?? '', $w['date'] ?? '']))) ?>">
    <?php foreach ($w['photos'] as $p): ?>
      <figure class="tavola" data-foto="<?= e(foto($p['url'], 2200)) ?>" data-didascalia="<?= e($p['caption'] ?? '') ?>"
              tabindex="0" role="button" aria-label="<?= e(($p['caption'] ?? '') ?: $w['title']) ?>">
        <div class="tavola-foto mira">
          <img <?= foto_attr($p['url'], '(max-width: 599px) 100vw, 60vw') ?> alt="<?= e($p['caption'] ?? '') ?>">
          <span class="mirino piccolo" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
        </div>
        <figcaption><span class="num-oro">TAV. <span class="n"></span></span><?php if (!empty($p['caption'])): ?><em><?= e($p['caption']) ?></em><?php endif; ?></figcaption>
      </figure>
    <?php endforeach; ?>
  </div>
  <?php endif; ?>

  <div class="contenitore dettaglio-fondo">
    <?php if ($succ): ?>
      <a class="successivo" href="<?= e(url('lavoro', $succ['id'])) ?>">
        <span class="successivo-foto mira"><img <?= foto_attr(copertina($succ), '150px') ?> alt="" loading="lazy"><span class="mirino piccolo" aria-hidden="true"><i></i><i></i><i></i><i></i></span></span>
        <span class="successivo-testo"><small>LAVORO SUCCESSIVO</small><strong><?= e(maiuscolo($succ['title'])) ?></strong></span>
        <span class="successivo-freccia" aria-hidden="true">&rarr;</span>
      </a>
    <?php endif; ?>
    <a class="link etichetta tenue" href="<?= e(url('lavori')) ?>">&larr; TUTTI I LAVORI</a>
  </div>
<?php endif; ?>

<?php require __DIR__ . '/inc/piede.php'; ?>
