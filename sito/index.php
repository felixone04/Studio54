<?php
require __DIR__ . '/inc/app.php';

$pagina = 'index';
$titolo = '';
$classe_body = 'pagina-home';
$c = contenuti();
$apertura = foto_apertura();
$galleria = dati()['gallery'] ?? [];
$frase = trim(str_replace("\n", ' ', $c['heroTitle'] ?? ''));
$righe = array_values(array_filter(array_map('trim', explode("\n", $c['manifestoTitle'] ?? ''))));

require __DIR__ . '/inc/testa.php';
?>

<!-- Apertura: carosello delle sole foto orizzontali, racchiuse dagli angoli
     del mirino. In orizzontale a tutto schermo; in verticale la foto al
     centro con la descrizione sotto. -->
<section class="apertura" data-carosello data-intervallo="4000" aria-roledescription="carosello" aria-label="Foto in evidenza">
  <?php if ($frase !== ''): ?><p class="apertura-frase-v"><?= e(maiuscolo($frase)) ?></p><?php endif; ?>
  <div class="apertura-scena">
    <div class="apertura-foto">
      <?php foreach ($apertura as $i => $p): ?>
        <figure class="diapo<?= $i === 0 ? ' attiva' : '' ?>"
                data-titolo="<?= e($p['title'] ?? '') ?>"
                data-didascalia="<?= e($p['caption'] ?? '') ?>"
                data-meta="<?= e(maiuscolo(unisci([$p['category'] ?? '', $p['location'] ?? '', $p['year'] ?? '']))) ?>">
          <img <?= foto_attr($p['url'] ?? '') ?> alt="<?= e($p['title'] ?? '') ?>" <?= $i > 1 ? 'loading="lazy"' : '' ?>>
        </figure>
      <?php endforeach; ?>
    </div>
    <div class="apertura-velo"></div>
    <span class="mirino" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
    <div class="apertura-barra">
      <div class="apertura-riga">
        <div class="apertura-testo">
          <p class="ap-titolo"></p>
          <p class="ap-meta"></p>
        </div>
        <span class="ap-conto"></span>
        <button class="tondo chiaro ap-prec" type="button" aria-label="Foto precedente">&#8249;</button>
        <button class="tondo chiaro ap-succ" type="button" aria-label="Foto successiva">&#8250;</button>
      </div>
      <div class="avanzamento"></div>
      <?php if ($frase !== ''): ?><p class="apertura-frase"><?= e(maiuscolo($frase)) ?></p><?php endif; ?>
    </div>
  </div>
  <div class="apertura-descrizione">
    <p class="ap-numero"></p>
    <p class="ap-titolo"></p>
    <p class="ap-didascalia"></p>
    <p class="ap-meta"></p>
  </div>
  <div class="apertura-comandi">
    <div class="avanzamento"></div>
    <div class="apertura-comandi-riga">
      <button class="tondo ap-prec" type="button" aria-label="Foto precedente">&#8249;</button>
      <span class="ap-conto"></span>
      <button class="tondo ap-succ" type="button" aria-label="Foto successiva">&#8250;</button>
    </div>
  </div>
</section>

<?php if ($righe): ?>
<section class="sezione manifesto">
  <img class="manifesto-segno" src="assets/img/mark.png" alt="">
  <p class="etichetta"><span class="num">(01)</span><span class="trattino"></span>MANIFESTO</p>
  <p class="manifesto-testo rivela">
    <?php foreach ($righe as $i => $r): ?>
      <span class="<?= $i % 2 ? 'corsivo' : '' ?>"><?= e($r) ?></span>
    <?php endforeach; ?>
  </p>
  <span class="linea-corta"></span>
</section>
<?php endif; ?>

<?php if ($galleria): ?>
<section class="sezione mostra" data-galleria>
  <div class="titolo-sezione">
    <div>
      <p class="etichetta"><span class="num">(02)</span><span class="trattino"></span><?= e(maiuscolo($c['galleryKicker'] ?? '')) ?></p>
      <h2 class="rivela"><?= e($c['galleryTitle'] ?? '') ?></h2>
    </div>
    <span class="etichetta tenue"><?= count($galleria) ?> SCATTI</span>
  </div>
  <div class="mostra-colonne">
    <?php
    $forme = ['4/5', '3/4', '1/1', '4/5', '2/3', '5/4'];
    foreach ($galleria as $i => $p):
        $meta = unisci([$p['category'] ?? '', $p['location'] ?? '', $p['year'] ?? '']);
    ?>
      <figure class="quadro rivela" style="--forma: <?= $forme[$i % count($forme)] ?>"
              data-foto="<?= e(foto($p['url'] ?? '', 2200)) ?>"
              data-titolo="<?= e($p['title'] ?? '') ?>"
              data-meta="<?= e(maiuscolo($meta)) ?>"
              tabindex="0" role="button" aria-label="<?= e($p['title'] ?? '') ?>">
        <div class="quadro-foto mira">
          <img <?= foto_attr($p['url'] ?? '', '(max-width: 1023px) 50vw, 33vw') ?> alt="" loading="lazy">
          <span class="terzi"></span>
          <span class="mirino piccolo" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
        </div>
        <figcaption>
          <span class="num"><?= due($i + 1) ?></span>
          <span>
            <strong><?= e($p['title'] ?? '') ?></strong>
            <?php if ($meta !== ''): ?><small><?= e(maiuscolo($meta)) ?></small><?php endif; ?>
          </span>
        </figcaption>
      </figure>
    <?php endforeach; ?>
  </div>
</section>
<?php endif; ?>

<?php require __DIR__ . '/inc/piede.php'; ?>
