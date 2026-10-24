<div class="testa-pagina">
  <div>
    <h1>Galleria</h1>
    <p>La stella mette la foto nel carosello d'apertura (vanno solo le orizzontali).</p>
  </div>
  <div class="testa-azioni">
    <button type="button" class="bottone bordo" data-demo><i class="ico ico-carica"></i>Carica più foto</button>
    <button type="button" class="bottone pieno" data-finestra="foto"><i class="ico ico-piu"></i>Nuova foto</button>
  </div>
</div>

<div class="griglia-foto">
  <?php foreach (dati()['gallery'] ?? [] as $p): ?>
    <figure class="foto-scheda">
      <div class="foto-scheda-img"><img src="<?= e(foto($p['url'], 500)) ?>" alt="" loading="lazy">
        <button type="button" class="stella<?= ($p['inHero'] ?? true) ? ' accesa' : '' ?>" data-stella aria-label="Nel carosello d'apertura">&#9733;</button>
      </div>
      <figcaption>
        <strong><?= e($p['title']) ?></strong>
        <small><?= e(unisci([$p['category'] ?? '', $p['location'] ?? '', $p['year'] ?? ''])) ?></small>
        <button type="button" class="ico-bottone" data-finestra="foto" data-chi="<?= e($p['title']) ?>" aria-label="Modifica"><i class="ico ico-matita"></i></button>
      </figcaption>
    </figure>
  <?php endforeach; ?>
</div>
