<?php
$cat = [];
foreach (dati()['services'] ?? [] as $s) $cat[$s['category'] ?? 'Servizi'][] = $s;
?>
<div class="testa-pagina">
  <div>
    <h1>Servizi e prodotti</h1>
    <p>Le voci tra cui il cliente sceglie nel preventivo. Il prezzo è facoltativo e resta solo interno.</p>
  </div>
  <div class="testa-azioni"><button type="button" class="bottone pieno" data-finestra="servizio"><i class="ico ico-piu"></i>Nuovo servizio</button></div>
</div>

<?php foreach ($cat as $nome => $lista): ?>
  <section class="scheda senza-margine">
    <div class="scheda-testa"><h2><?= e($nome) ?></h2><span class="tenue piccolo"><?= count($lista) ?> voci</span></div>
    <?php foreach ($lista as $s): ?>
      <div class="riga">
        <i class="ico ico-trascina tenue"></i>
        <span class="miniatura"><img src="<?= e(foto($s['image'] ?? '', 200)) ?>" alt="" loading="lazy"></span>
        <span class="riga-testo"><strong><?= e($s['name']) ?></strong><small><?= e($s['description'] ?? '') ?></small></span>
        <span class="prezzo"><?= isset($s['internalPrice']) ? '€ ' . number_format((float) $s['internalPrice'], 0, ',', '.') : '—' ?></span>
        <label class="interruttore" title="Visibile sul sito"><input type="checkbox" <?= ($s['active'] ?? true) ? 'checked' : '' ?> data-demo><span></span></label>
        <button type="button" class="ico-bottone" data-finestra="servizio" data-chi="<?= e($s['name']) ?>" aria-label="Modifica"><i class="ico ico-matita"></i></button>
      </div>
    <?php endforeach; ?>
  </section>
<?php endforeach; ?>
