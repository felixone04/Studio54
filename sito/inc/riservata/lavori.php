<div class="testa-pagina">
  <div>
    <h1>Lavori</h1>
    <p>I servizi realizzati, con le foto. Trascina per riordinare.</p>
  </div>
  <div class="testa-azioni"><button type="button" class="bottone pieno" data-finestra="lavoro"><i class="ico ico-piu"></i>Nuovo lavoro</button></div>
</div>

<section class="scheda senza-margine">
  <?php foreach (dati()['works'] ?? [] as $w): ?>
    <div class="riga<?= ($w['published'] ?? true) ? '' : ' spenta' ?>">
      <i class="ico ico-trascina tenue"></i>
      <span class="miniatura larga"><img src="<?= e(foto(copertina($w), 300)) ?>" alt="" loading="lazy"></span>
      <span class="riga-testo">
        <strong><?= e($w['title']) ?></strong>
        <small><?= e(unisci([$w['category'] ?? '', $w['setting'] ?? '', $w['seasonLabel'] ?? '', $w['date'] ?? '', count($w['photos'] ?? []) . ' foto'])) ?></small>
      </span>
      <button type="button" class="ico-bottone" data-occhio aria-label="Visibile sul sito"><i class="ico ico-occhio"></i></button>
      <button type="button" class="ico-bottone" data-finestra="lavoro" data-chi="<?= e($w['title']) ?>" aria-label="Modifica"><i class="ico ico-matita"></i></button>
      <button type="button" class="ico-bottone" data-demo aria-label="Elimina"><i class="ico ico-cestino"></i></button>
    </div>
  <?php endforeach; ?>
</section>
