<div class="testa-pagina">
  <div>
    <h1>Pacchetti</h1>
    <p>Combinazioni pronte di servizi, da proporre con un link al preventivo.</p>
  </div>
  <div class="testa-azioni"><button type="button" class="bottone pieno" data-finestra="pacchetto"><i class="ico ico-piu"></i>Nuovo pacchetto</button></div>
</div>

<div class="griglia-schede">
  <?php foreach (dati()['packages'] ?? [] as $p): ?>
    <article class="scheda pacchetto">
      <div class="pacchetto-foto"><img src="<?= e(foto($p['image'] ?? '', 800)) ?>" alt="" loading="lazy"><?php if (!empty($p['featured'])): ?><span class="nastro">PIÙ SCELTO</span><?php endif; ?></div>
      <div class="pacchetto-testo">
        <h2><?= e($p['name']) ?></h2>
        <p class="tenue"><?= e($p['tagline'] ?? '') ?></p>
        <ul>
          <?php foreach ($p['serviceIds'] as $id): ?><li><?= e(servizio($id)['name'] ?? '') ?></li><?php endforeach; ?>
        </ul>
        <div class="pacchetto-azioni">
          <button type="button" class="bottone bordo" data-finestra="pacchetto" data-chi="<?= e($p['name']) ?>"><i class="ico ico-matita"></i>Modifica</button>
          <button type="button" class="bottone testo" data-copia="<?= e(url('preventivo') . '?p=' . rawurlencode($p['id'])) ?>"><i class="ico ico-link"></i>Copia link</button>
        </div>
      </div>
    </article>
  <?php endforeach; ?>
</div>
