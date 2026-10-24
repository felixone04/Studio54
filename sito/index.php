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

<?php if ($galleria):
    // Le stampe sparse sul tavolo: posizione (% sinistra, % alto), rotazione
    // e larghezza di ognuna. Le foto sono le prime della Galleria.
    $posti = [[5, 9, -7, 24], [29, 3, 4, 17], [46, 14, -3, 27], [74, 5, 6, 18], [13, 50, 5, 22], [39, 55, -5, 25], [67, 48, -8, 18]];
    $stampe = array_slice($galleria, 0, count($posti));
?>
<section class="tavolo" data-tavolo aria-label="Gli scatti">
  <div class="tavolo-testa">
    <p class="etichetta"><span class="num">(02)</span><span class="trattino"></span>GLI SCATTI</p>
    <p class="tavolo-aiuto">TOCCA PER GUARDARE · TRASCINA PER SPOSTARE</p>
  </div>
  <?php foreach ($stampe as $k => $p):
      [$x, $y, $r, $w] = $posti[$k];
      $meta = unisci([$p['category'] ?? '', $p['location'] ?? '', $p['year'] ?? '']);
  ?>
    <figure class="stampa" style="left: <?= $x ?>%; top: <?= $y ?>%; --r: <?= $r ?>deg; --w: <?= $w ?>%; z-index: <?= $k + 1 ?>"
            data-foto="<?= e(foto($p['url'] ?? '', 2200)) ?>" data-titolo="<?= e($p['title'] ?? '') ?>" data-meta="<?= e(maiuscolo($meta)) ?>"
            tabindex="0" role="button" aria-label="<?= e($p['title'] ?? '') ?>">
      <img src="<?= e(foto($p['url'] ?? '', 900)) ?>" alt="" draggable="false" loading="lazy">
    </figure>
  <?php endforeach; ?>
</section>
<?php endif; ?>

<?php require __DIR__ . '/inc/piede.php'; ?>
