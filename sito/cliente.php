<?php
// L'area di un cliente: il suo evento, l'album da sfogliare, i documenti e i
// link caricati dallo studio dal gestionale. Ogni cliente vede solo la sua.
require __DIR__ . '/inc/app.php';
require __DIR__ . '/inc/clienti.php';

if (STATICO) {
    // Anteprima: una pagina per ogni cliente d'esempio (cliente-<id>.html).
    $cl = cliente_da_id(param('id'));
    $esci = url('area-clienti');
} else {
    sessione();
    $cl = cliente_collegato();
    if (!$cl) {
        header('Location: ' . url('area-clienti'));
        exit;
    }
    $esci = url('area-clienti') . '?esci=1';
}
if (!$cl) {
    exit('Cliente non trovato.');
}

$pagina = '';
$titolo = 'La vostra area';
$noindex = true;
$classe_body = 'pagina-clienti';
$nome = trim(explode(' ', $cl['name'])[0] ?? '');
$album = $cl['album'] ?? [];
$documenti = array_values(array_filter($cl['files'] ?? [], fn($f) => !($f['isLink'] ?? false)));
$link = array_values(array_filter($cl['files'] ?? [], fn($f) => $f['isLink'] ?? false));
$foto_album = array_map(fn($p) => ['src' => foto($p['url'], 1400), 'grande' => foto($p['url'], 2200), 'didascalia' => $p['caption'] ?? ''], $album);

require __DIR__ . '/inc/testa.php';
?>

<div class="contenitore cliente">
  <div class="cliente-testa">
    <div>
      <p class="etichetta entra"><span class="trattino"></span>LA VOSTRA AREA</p>
      <h1 class="titolo-grande entra">CIAO <?= e(maiuscolo($nome)) ?></h1>
      <p class="sottotitolo entra"><?= e($cl['eventTitle'] ?? '') ?><?php if (!empty($cl['eventDate']) || !empty($cl['location'])): ?><br><span><?= e(unisci([$cl['eventDate'] ?? '', $cl['location'] ?? ''])) ?></span><?php endif; ?></p>
    </div>
    <a class="link etichetta tenue" href="<?= e($esci) ?>">ESCI &rarr;</a>
  </div>
  <?php if (!empty($cl['welcome'])): ?><p class="cliente-benvenuto rivela"><?= e($cl['welcome']) ?></p><?php endif; ?>

  <?php if ($album): ?>
  <section class="cliente-album rivela">
    <div class="cliente-sezione-testa">
      <h2><span class="num-oro">01</span>IL VOSTRO ALBUM</h2>
      <span class="contatore"><?= due(count($album)) ?> FOTO</span>
    </div>
    <div class="album" data-album data-foto="<?= e(json_encode($foto_album)) ?>"
         data-titolo="<?= e(maiuscolo($cl['eventTitle'] ?? '')) ?>" data-data="<?= e($cl['eventDate'] ?? '') ?>">
      <div class="album-libro"></div>
      <div class="album-comandi">
        <button type="button" class="tondo" data-pagina="-1" aria-label="Pagina precedente">&#8249;</button>
        <span class="contatore album-conto"></span>
        <button type="button" class="tondo" data-pagina="1" aria-label="Pagina successiva">&#8250;</button>
      </div>
      <p class="album-aiuto">Sfogliatelo con le frecce o toccando le pagine · <button type="button" class="link album-grande">Guarda le foto a schermo intero</button></p>
    </div>
  </section>
  <?php endif; ?>

  <div class="cliente-file">
    <?php if ($documenti): ?>
    <section class="rivela">
      <div class="cliente-sezione-testa"><h2><span class="num-oro">02</span>DOCUMENTI</h2></div>
      <?php foreach ($documenti as $f): ?>
        <a class="file" href="<?= e($f['url']) ?>" target="_blank" rel="noopener" download>
          <span class="file-icona pdf">PDF</span>
          <span class="file-testo"><strong><?= e($f['name']) ?></strong><?php if (!empty($f['note'])): ?><small><?= e($f['note']) ?></small><?php endif; ?></span>
          <span class="file-azione">SCARICA</span>
        </a>
      <?php endforeach; ?>
    </section>
    <?php endif; ?>
    <?php if ($link): ?>
    <section class="rivela">
      <div class="cliente-sezione-testa"><h2><span class="num-oro"><?= $documenti ? '03' : '02' ?></span>LINK</h2></div>
      <?php foreach ($link as $f): ?>
        <a class="file" href="<?= e($f['url']) ?>" target="_blank" rel="noopener">
          <span class="file-icona link-ico">&#8599;</span>
          <span class="file-testo"><strong><?= e($f['name']) ?></strong><?php if (!empty($f['note'])): ?><small><?= e($f['note']) ?></small><?php endif; ?></span>
          <span class="file-azione">APRI</span>
        </a>
      <?php endforeach; ?>
    </section>
    <?php endif; ?>
  </div>

  <section class="cliente-password rivela">
    <details>
      <summary>Cambia la password</summary>
      <form data-cambia-password novalidate>
        <div class="coppia">
          <div class="campo"><input id="p-nuova" type="password" autocomplete="new-password" minlength="8" placeholder=" "><label for="p-nuova">Nuova password (min. 8 caratteri)</label></div>
          <div class="campo"><input id="p-ripeti" type="password" autocomplete="new-password" placeholder=" "><label for="p-ripeti">Ripeti la password</label></div>
        </div>
        <p class="errore errore-password"></p>
        <button type="submit" class="pillola">SALVA <i>&rarr;</i></button>
      </form>
    </details>
  </section>
</div>

<?php require __DIR__ . '/inc/piede.php'; ?>
