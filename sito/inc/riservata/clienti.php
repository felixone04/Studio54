<?php
$clienti = dati()['clients'] ?? [];
$lavori = dati()['works'] ?? [];
?>
<div class="testa-pagina">
  <div>
    <h1>Clienti</h1>
    <p>Gli account dell'area clienti: dal sito nessuno può registrarsi, li crei solo tu.</p>
  </div>
  <div class="testa-azioni"><button type="button" class="bottone pieno" data-nuovo-cliente><i class="ico ico-piu"></i>Nuovo cliente</button></div>
</div>

<section class="scheda senza-margine">
  <?php foreach ($clienti as $cl):
      $doc = array_values(array_filter($cl['files'] ?? [], fn($f) => !($f['isLink'] ?? false)));
      $lnk = array_values(array_filter($cl['files'] ?? [], fn($f) => $f['isLink'] ?? false));
  ?>
    <details class="richiesta">
      <summary>
        <span class="iniziali"><?= e(mb_substr($cl['name'], 0, 1) . mb_substr(strstr($cl['name'], ' ') ?: '', 1, 1)) ?></span>
        <span class="riga-testo">
          <strong><?= e($cl['name']) ?> <span class="stato <?= ($cl['active'] ?? true) ? 'stato-confermata' : 'stato-archiviata' ?>"><?= ($cl['active'] ?? true) ? 'Attivo' : 'Sospeso' ?></span></strong>
          <small><?= e(unisci([$cl['email'], $cl['eventTitle'] ?? '', count($cl['album'] ?? []) . ' foto', count($cl['files'] ?? []) . ' file'])) ?></small>
        </span>
        <i class="ico ico-giu"></i>
      </summary>
      <div class="richiesta-corpo">
        <div class="azioni">
          <a class="bottone bordo" href="<?= e(url('cliente', $cl['id'])) ?>" target="_blank"><i class="ico ico-esterno"></i>Vedi la sua area</a>
          <button type="button" class="bottone bordo" data-nuova-password="<?= e($cl['name']) ?>" data-email="<?= e($cl['email']) ?>"><i class="ico ico-sincro"></i>Nuova password</button>
          <button type="button" class="bottone bordo" data-finestra="cliente" data-chi="<?= e($cl['name']) ?>"><i class="ico ico-matita"></i>Modifica dati</button>
        </div>

        <h3>Evento</h3>
        <p><?= e(unisci([$cl['eventTitle'] ?? '', $cl['eventDate'] ?? '', $cl['location'] ?? ''])) ?></p>

        <h3>Album da sfogliare (<?= count($cl['album'] ?? []) ?> foto)</h3>
        <div class="miniature-album">
          <?php foreach (array_slice($cl['album'] ?? [], 0, 8) as $p): ?><img src="<?= e(foto($p['url'], 200)) ?>" alt="" loading="lazy"><?php endforeach; ?>
        </div>
        <div class="azioni">
          <button type="button" class="bottone bordo" data-demo><i class="ico ico-carica"></i>Carica foto</button>
          <label class="campo stretto in-riga"><span>Prendi le foto da un lavoro</span>
            <select data-demo><option value="">Scegli…</option><?php foreach ($lavori as $w): ?><option><?= e($w['title']) ?></option><?php endforeach; ?></select>
          </label>
        </div>

        <h3>Documenti e link</h3>
        <?php foreach (array_merge($doc, $lnk) as $f): ?>
          <div class="riga file-riga">
            <span class="file-tipo"><?= ($f['isLink'] ?? false) ? 'LINK' : 'PDF' ?></span>
            <span class="riga-testo"><strong><?= e($f['name']) ?></strong><small><?= e($f['note'] ?? '') ?></small></span>
            <a class="ico-bottone" href="<?= e($f['url']) ?>" target="_blank" rel="noopener" aria-label="Apri"><i class="ico ico-esterno"></i></a>
            <button type="button" class="ico-bottone" data-demo aria-label="Togli"><i class="ico ico-cestino"></i></button>
          </div>
        <?php endforeach; ?>
        <div class="azioni" style="margin-top: 12px">
          <button type="button" class="bottone bordo" data-finestra="pdf" data-chi=""><i class="ico ico-carica"></i>Carica PDF</button>
          <button type="button" class="bottone bordo" data-finestra="link" data-chi=""><i class="ico ico-link"></i>Aggiungi link</button>
        </div>

        <div class="richiesta-fondo">
          <label class="interruttore-riga"><span class="interruttore"><input type="checkbox" <?= ($cl['active'] ?? true) ? 'checked' : '' ?> data-demo><span></span></span> Accesso attivo</label>
          <button type="button" class="bottone testo rosso" data-demo>Elimina cliente</button>
        </div>
      </div>
    </details>
  <?php endforeach; ?>
</section>

<!-- Dopo la creazione: la password generata e il messaggio da mandare. -->
<div class="finestra" id="credenziali" hidden role="dialog" aria-modal="true">
  <div class="finestra-box">
    <h2 class="finestra-titolo">Account creato</h2>
    <p class="tenue">Manda questi dati al cliente: la password non si potrà più rivedere (se la perde, ne generi una nuova).</p>
    <textarea class="messaggio-cliente" rows="8" readonly></textarea>
    <div class="finestra-azioni">
      <button type="button" class="bottone testo" data-chiudi-credenziali>Chiudi</button>
      <a class="bottone bordo" data-whatsapp target="_blank" rel="noopener"><i class="ico ico-chat"></i>WhatsApp</a>
      <a class="bottone bordo" data-email-cliente><i class="ico ico-busta"></i>Email</a>
      <button type="button" class="bottone pieno" data-copia-messaggio><i class="ico ico-link"></i>Copia</button>
    </div>
  </div>
</div>
