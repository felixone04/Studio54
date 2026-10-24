<?php
// Pagina di prova (non collegata dal menu): le proposte di nuove sezioni
// per la home, da scegliere con il cliente. Quelle scelte andranno in
// index.php e questa pagina verrà tolta.
require __DIR__ . '/inc/app.php';

$pagina = '';
$titolo = 'Proposte per la home';
$noindex = true;
$u = fn(string $id) => 'https://images.unsplash.com/photo-' . $id . '?auto=format&fit=crop&w=1800&q=80';

// 1 · Mosaico dei tipi di servizio
$tipi = [
    ['Matrimoni', $u('1519741497674-611481863552'), 'matrimonio', 'grande'],
    ['Ritratti', $u('1531746020798-e6953c6e8e04'), '', 'alta'],
    ['Battesimi e comunioni', $u('1515488042361-ee00e0ddd4e4'), 'cerimonia', ''],
    ['Feste', $u('1530103862676-de8c9debad1d'), 'evento', ''],
    ['Eventi e aziende', $u('1470229722913-7c0e2dbbafd3'), 'evento', 'larga'],
];
// 2 · Pellicola
$rullino = [
    ['Matrimoni', '1465495976277-4387d4b0b4c6'], ['Cerimonie', '1469371670807-013ccf25f16a'],
    ['Ritratti', '1544005313-94ddf0286df2'], ['Feste', '1492684223066-81342ee5ff30'],
    ['Famiglie', '1515488042361-ee00e0ddd4e4'], ['Eventi', '1470229722913-7c0e2dbbafd3'],
    ['Dettagli', '1452587925148-ce544e77e70d'], ['Coppie', '1516589178581-6cd7833ae3b2'],
];
// 3 · Trittico
$giornata = [
    ['Prima', 'I preparativi, l\'attesa.', '1537633552985-df8429e8048b'],
    ['Durante', 'La promessa, gli sguardi.', '1583939003579-730e3918a45a'],
    ['Dopo', 'La festa, fino all\'ultimo ballo.', '1544005313-94ddf0286df2'],
];
$ultimi = array_slice(lavori_pubblicati(), 0, 3);

require __DIR__ . '/inc/testa.php';
?>

<div class="contenitore proposte-testa">
  <p class="etichetta entra"><span class="trattino"></span>PROPOSTE PER LA HOME</p>
  <h1 class="titolo-grande entra">SCEGLI LE SEZIONI</h1>
  <p class="sottotitolo entra">Cinque idee da mettere sotto il carosello, al posto delle "Opere". Puoi sceglierne una, alcune o tutte.</p>
</div>

<!-- ============================================================ IDEA 1 -->
<p class="proposta"><b>Idea 1</b> · Mosaico dei tipi di servizio <span>Toccando una foto si aprono i lavori di quel tipo</span></p>
<section class="sezione mosaico">
  <div class="mosaico-griglia">
    <?php foreach ($tipi as [$nome, $img, $filtro, $forma]): ?>
      <a class="tessera <?= e($forma) ?> rivela mira" href="<?= e(url('lavori') . ($filtro !== '' ? '?evento=' . $filtro : '')) ?>">
        <img <?= foto_attr($img, '(max-width: 899px) 100vw, 50vw') ?> alt="" loading="lazy">
        <span class="mirino" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
        <span class="tessera-testo"><strong><?= e(maiuscolo($nome)) ?></strong><small>GUARDA I LAVORI &rarr;</small></span>
      </a>
    <?php endforeach; ?>
  </div>
</section>

<!-- ============================================================ IDEA 2 -->
<p class="proposta"><b>Idea 2</b> · Pellicola che scorre <span>Scorre lenta da sola; passandoci sopra si ferma</span></p>
<section class="pellicola" aria-label="Rullino">
  <div class="pellicola-nastro">
    <?php for ($giro = 0; $giro < 2; $giro++): foreach ($rullino as $k => [$nome, $id]): ?>
      <figure class="fotogramma"<?= $giro ? ' aria-hidden="true"' : '' ?>>
        <img src="<?= e(foto($u($id), 700)) ?>" alt="" loading="lazy">
        <figcaption><span class="num-oro"><?= due($k + 1) ?>A</span><?= e(maiuscolo($nome)) ?></figcaption>
      </figure>
    <?php endforeach; endfor; ?>
  </div>
</section>

<!-- ============================================================ IDEA 3 -->
<p class="proposta"><b>Idea 3</b> · Trittico "una giornata" <span>Tre foto verticali, una parola ciascuna</span></p>
<section class="sezione trittico">
  <div class="trittico-griglia">
    <?php foreach ($giornata as $k => [$parola, $riga, $id]): ?>
      <figure class="trittico-foto rivela" style="transition-delay: <?= $k * 120 ?>ms">
        <div class="mira"><img <?= foto_attr($u($id), '(max-width: 719px) 100vw, 33vw') ?> alt="" loading="lazy"><span class="mirino piccolo" aria-hidden="true"><i></i><i></i><i></i><i></i></span></div>
        <figcaption><strong><?= e(maiuscolo($parola)) ?></strong><em><?= e($riga) ?></em></figcaption>
      </figure>
    <?php endforeach; ?>
  </div>
</section>

<!-- ============================================================ IDEA 4 -->
<p class="proposta"><b>Idea 4</b> · Ultimi lavori <span>Le copertine degli ultimi tre lavori</span></p>
<section class="sezione ultimi">
  <div class="titolo-sezione">
    <p class="etichetta"><span class="trattino"></span>ULTIMI LAVORI</p>
    <a class="link etichetta" href="<?= e(url('lavori')) ?>">TUTTI I LAVORI &rarr;</a>
  </div>
  <div class="ultimi-griglia">
    <?php foreach ($ultimi as $w): ?>
      <a class="ultimo rivela" href="<?= e(url('lavoro', $w['id'])) ?>">
        <span class="ultimo-foto mira"><img <?= foto_attr(copertina($w), '(max-width: 719px) 100vw, 33vw') ?> alt="" loading="lazy"><span class="mirino piccolo" aria-hidden="true"><i></i><i></i><i></i><i></i></span></span>
        <strong><?= e(maiuscolo($w['title'])) ?></strong>
        <small><?= e(unisci([$w['category'] ?? '', $w['location'] ?? ''])) ?></small>
      </a>
    <?php endforeach; ?>
  </div>
</section>

<!-- ============================================================ IDEA 5 -->
<p class="proposta"><b>Idea 5</b> · Invito finale al preventivo <span>Una grande foto e un solo pulsante</span></p>
<section class="invito">
  <img <?= foto_attr($u('1511285560929-80b456fea0bc')) ?> alt="" loading="lazy">
  <span class="mirino" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
  <div class="invito-testo">
    <p class="etichetta"><span class="trattino"></span>PREVENTIVO GRATUITO</p>
    <h2>RACCONTACI<br>IL TUO EVENTO</h2>
    <a class="pillola chiara" href="<?= e(url('preventivo')) ?>">RICHIEDI UN PREVENTIVO <i>&#8599;</i></a>
  </div>
</section>

<?php require __DIR__ . '/inc/piede.php'; ?>
