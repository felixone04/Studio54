<?php
require __DIR__ . '/inc/app.php';

$pagina = 'biografia';
$titolo = 'Biografia';
$c = contenuti();
$paragrafi = array_values(array_filter(array_map('trim', preg_split('/\n\s*\n/', $c['bioStory'] ?? '') ?: [])));
$metodo = $c['timeline'] ?? [];

require __DIR__ . '/inc/testa.php';
?>

<section class="sezione bio">
  <div class="bio-griglia">
    <div class="bio-testo">
      <p class="etichetta entra"><span class="trattino"></span><?= e(maiuscolo(($c['tagline'] ?? '') ?: 'Chi siamo')) ?></p>
      <h1 class="titolo-grande entra"><?= e(maiuscolo($c['bioTitle'] ?? '')) ?></h1>
      <?php if (!empty($c['bioIntro'])): ?>
        <p class="sottotitolo grande entra"><?= nl2br(e($c['bioIntro'])) ?></p>
      <?php endif; ?>
      <?php if ($paragrafi): ?>
        <span class="linea-corta"></span>
        <?php foreach ($paragrafi as $i => $p): ?>
          <p class="rivela <?= $i === 0 ? 'bio-attacco' : 'bio-paragrafo' ?>"><?= e($p) ?></p>
        <?php endforeach; ?>
      <?php endif; ?>
    </div>
    <?php if (!empty($c['bioImage'])): ?>
      <div class="bio-foto rivela"><img <?= foto_attr($c['bioImage'], '(max-width: 1023px) 100vw, 45vw') ?> alt=""></div>
    <?php endif; ?>
  </div>
</section>

<?php if ($metodo): ?>
<section class="sezione metodo">
  <div class="contenitore-stretto">
    <p class="etichetta"><span class="trattino"></span>IL METODO</p>
    <div class="metodo-passi">
      <?php foreach ($metodo as $m): ?>
        <div class="passo rivela">
          <p class="passo-numero"><?= e($m['year'] ?? '') ?></p>
          <p class="passo-titolo"><?= e(maiuscolo($m['title'] ?? '')) ?></p>
          <?php if (!empty($m['text'])): ?><p class="passo-testo"><?= e($m['text']) ?></p><?php endif; ?>
        </div>
      <?php endforeach; ?>
    </div>
  </div>
</section>
<?php endif; ?>

<?php require __DIR__ . '/inc/piede.php'; ?>
