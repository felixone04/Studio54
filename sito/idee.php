<?php
// Pagina di prova (non collegata dal menu): nuove proposte di sezioni per la
// home, da scegliere con il cliente. Quelle scelte andranno in index.php e
// questa pagina, con idee.css e idee.js, verrà tolta.
require __DIR__ . '/inc/app.php';

$pagina = '';
$titolo = 'Proposte per la home';
$noindex = true;
$css_extra = ['assets/css/idee.css'];
$js_extra = ['assets/js/idee.js'];
$u = fn(string $id) => 'https://images.unsplash.com/photo-' . $id . '?auto=format&fit=crop&w=1800&q=80';

// 1 · Fisarmonica
$strisce = [
    ['Matrimoni', '1537633552985-df8429e8048b', 'matrimonio'],
    ['Ritratti', '1531746020798-e6953c6e8e04', ''],
    ['Battesimi', '1515488042361-ee00e0ddd4e4', 'cerimonia'],
    ['Feste', '1530103862676-de8c9debad1d', 'evento'],
    ['Eventi', '1470229722913-7c0e2dbbafd3', 'evento'],
];
// 2 · Messa a fuoco
$fuoco = [
    ['Matrimoni', '1519741497674-611481863552'],
    ['Ritratti', '1544005313-94ddf0286df2'],
    ['Cerimonie', '1469371670807-013ccf25f16a'],
    ['Feste', '1492684223066-81342ee5ff30'],
];
// 3 · Stampe sul tavolo: [foto, sinistra %, alto %, rotazione, larghezza]
$stampe = [
    ['1465495976277-4387d4b0b4c6', 6, 10, -7, 26],
    ['1583939003579-730e3918a45a', 30, 4, 4, 18],
    ['1511285560929-80b456fea0bc', 47, 16, -3, 28],
    ['1544005313-94ddf0286df2', 74, 6, 6, 18],
    ['1515488042361-ee00e0ddd4e4', 14, 52, 5, 24],
    ['1470229722913-7c0e2dbbafd3', 40, 56, -5, 26],
    ['1516589178581-6cd7833ae3b2', 68, 50, -8, 17],
];
// 5 · Album: coppie di pagine
$album = [
    ['1583939003579-730e3918a45a', '1460978812857-470ed1c77af0'],
    ['1511795409834-ef04bbd61622', '1522673607200-164d1b6ce486'],
    ['1516589178581-6cd7833ae3b2', '1519741497674-611481863552'],
];

require __DIR__ . '/inc/testa.php';
?>

<div class="contenitore proposte-testa">
  <p class="etichetta entra"><span class="trattino"></span>PROPOSTE PER LA HOME</p>
  <h1 class="titolo-grande entra">NUOVE IDEE</h1>
  <p class="sottotitolo entra">Cinque sezioni diverse da mettere sotto il carosello. Toccale e provale: sono tutte interattive.</p>
</div>

<!-- ============================================================ IDEA 1 -->
<p class="proposta"><b>Idea 1</b> · Fisarmonica <span>Passa sopra (o tocca) una striscia: si apre la foto con il tipo di servizio</span></p>
<section class="sezione fisarmonica">
  <div class="fisa">
    <?php foreach ($strisce as $k => [$nome, $id, $filtro]): ?>
      <a class="fisa-striscia<?= $k === 0 ? ' aperta' : '' ?>" href="<?= e(url('lavori') . ($filtro !== '' ? '?evento=' . $filtro : '')) ?>">
        <img <?= foto_attr($u($id), '60vw') ?> alt="" loading="lazy">
        <span class="fisa-num"><?= due($k + 1) ?></span>
        <span class="fisa-nome"><?= e(maiuscolo($nome)) ?></span>
      </a>
    <?php endforeach; ?>
  </div>
</section>

<!-- ============================================================ IDEA 2 -->
<p class="proposta"><b>Idea 2</b> · Messa a fuoco <span>Scorri: ogni foto passa da sfocata a nitida, come con l'obiettivo</span></p>
<section class="fuoco" data-fuoco style="--n: <?= count($fuoco) ?>">
  <div class="fuoco-schermo">
    <?php foreach ($fuoco as $k => [$nome, $id]): ?>
      <figure class="fuoco-foto" data-k="<?= $k ?>">
        <img <?= foto_attr($u($id)) ?> alt="" loading="lazy">
        <figcaption><span class="num-oro"><?= due($k + 1) ?> / <?= due(count($fuoco)) ?></span><strong><?= e(maiuscolo($nome)) ?></strong></figcaption>
      </figure>
    <?php endforeach; ?>
    <span class="fuoco-mirino" aria-hidden="true"><i></i><i></i><i></i><i></i><b></b></span>
  </div>
</section>

<!-- ============================================================ IDEA 3 -->
<p class="proposta"><b>Idea 3</b> · Stampe sul tavolo <span>Passaci sopra per raddrizzarle, trascinale per spostarle</span></p>
<section class="tavolo" data-tavolo>
  <p class="tavolo-scritta">SPOSTA LE STAMPE</p>
  <?php foreach ($stampe as $k => [$id, $x, $y, $r, $w]): ?>
    <figure class="stampa" style="left: <?= $x ?>%; top: <?= $y ?>%; --r: <?= $r ?>deg; --w: <?= $w ?>%; z-index: <?= $k + 1 ?>">
      <img src="<?= e(foto($u($id), 900)) ?>" alt="" draggable="false" loading="lazy">
    </figure>
  <?php endforeach; ?>
</section>

<!-- ============================================================ IDEA 4 -->
<p class="proposta"><b>Idea 4</b> · Prima e dopo <span>Trascina la linea: a sinistra lo scatto, a destra la foto finita dallo studio</span></p>
<section class="sezione prima-dopo">
  <div class="pd" data-prima-dopo>
    <img class="pd-dopo" <?= foto_attr($u('1465495976277-4387d4b0b4c6')) ?> alt="La foto finita" draggable="false">
    <div class="pd-prima"><img <?= foto_attr($u('1465495976277-4387d4b0b4c6')) ?> alt="Lo scatto originale" draggable="false"></div>
    <span class="pd-etichetta sinistra">LO SCATTO</span>
    <span class="pd-etichetta destra">LA FOTO FINITA</span>
    <span class="pd-linea" role="slider" tabindex="0" aria-label="Confronto prima e dopo" aria-valuemin="0" aria-valuemax="100" aria-valuenow="50"><i></i></span>
  </div>
</section>

<!-- ============================================================ IDEA 5 -->
<p class="proposta"><b>Idea 5</b> · Album da sfogliare <span>Tocca le frecce o le pagine per sfogliarlo</span></p>
<section class="sezione album-sez">
  <div class="album" data-album>
    <div class="album-libro">
      <div class="pagina-fissa sinistra"><div class="copertina-dentro"><img src="assets/img/mark.png" alt=""><p>GIULIA &amp; MARCO</p><small>Giugno 2024</small></div></div>
      <?php foreach ($album as $k => [$a, $b]): ?>
        <div class="foglio" style="z-index: <?= count($album) - $k ?>">
          <div class="faccia fronte"><img src="<?= e(foto($u($a), 1000)) ?>" alt="" loading="lazy"></div>
          <div class="faccia retro"><img src="<?= e(foto($u($b), 1000)) ?>" alt="" loading="lazy"></div>
        </div>
      <?php endforeach; ?>
      <div class="pagina-fissa destra"><div class="copertina-dentro"><p>FINE</p><small>Album fine art, cucito a mano</small></div></div>
    </div>
    <div class="album-comandi">
      <button type="button" class="tondo" data-pagina="-1" aria-label="Pagina precedente">&#8249;</button>
      <span class="contatore album-conto"></span>
      <button type="button" class="tondo" data-pagina="1" aria-label="Pagina successiva">&#8250;</button>
    </div>
  </div>
</section>

<?php require __DIR__ . '/inc/piede.php'; ?>
