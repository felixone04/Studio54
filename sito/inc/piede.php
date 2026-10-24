<?php
// Fine di ogni pagina pubblica: footer con i contatti e gli script.
$c = contenuti();
$k = $c['contacts'] ?? [];
$tel = preg_replace('/[^0-9+]/', '', $k['phone'] ?? '');
$wa = preg_replace('/[^0-9]/', '', $k['whatsapp'] ?? '');
?>
  </main>

  <footer class="piede">
    <div class="piede-colonne">
      <div>
        <h3>SCRIVICI</h3>
        <?php if (!empty($k['email'])): ?><a class="link" href="mailto:<?= e($k['email']) ?>"><?= e($k['email']) ?></a><?php endif; ?>
        <?php if (!empty($k['phone'])): ?><a class="link" href="tel:<?= e($tel) ?>"><?= e($k['phone']) ?></a><?php endif; ?>
        <?php if ($wa !== ''): ?><a class="link" href="https://wa.me/<?= e($wa) ?>" target="_blank" rel="noopener">WhatsApp</a><?php endif; ?>
      </div>
      <div>
        <h3>STUDIO</h3>
        <?php if (!empty($k['address'])): ?>
          <a class="link" href="https://www.google.com/maps/search/?api=1&amp;query=<?= e(rawurlencode($k['address'])) ?>" target="_blank" rel="noopener"><?= e($k['address']) ?></a>
        <?php endif; ?>
        <?php if (!empty($k['hours'])): ?><p><?= e($k['hours']) ?></p><?php endif; ?>
      </div>
      <div>
        <h3>SOCIAL</h3>
        <?php if (!empty($k['instagram'])): ?><a class="link" href="<?= e($k['instagram']) ?>" target="_blank" rel="noopener">Instagram</a><?php endif; ?>
        <?php if (!empty($k['facebook'])): ?><a class="link" href="<?= e($k['facebook']) ?>" target="_blank" rel="noopener">Facebook</a><?php endif; ?>
      </div>
      <div>
        <h3>ESPLORA</h3>
        <a class="link" href="<?= e(url('index')) ?>">Home</a>
        <a class="link" href="<?= e(url('lavori')) ?>">Lavori</a>
        <a class="link" href="<?= e(url('biografia')) ?>">Biografia</a>
        <a class="link" href="<?= e(url('preventivo')) ?>">Preventivo</a>
      </div>
    </div>
    <img class="piede-logo" src="assets/img/logo.png" alt="<?= e($c['studioName'] ?? 'Studio 54') ?>">
    <div class="piede-fondo">
      <span>&copy; <?= date('Y') ?> <?= e($c['studioName'] ?? '') ?><?= !empty($k['vat']) ? '  ·  ' . e($k['vat']) : '' ?></span>
      <span class="piede-link">
        <a class="link" href="app/studio54.apk" download>Scarica l'app Android</a>
        <span class="punto"></span>
        <a class="link" href="<?= e(url('riservata')) ?>">Area riservata</a>
      </span>
    </div>
  </footer>

  <div class="lightbox" id="lightbox" hidden aria-modal="true" role="dialog" aria-label="Foto a schermo intero">
    <button class="lb-chiudi" type="button" aria-label="Chiudi">&times;</button>
    <button class="lb-freccia lb-prec" type="button" aria-label="Foto precedente">&#8249;</button>
    <figure><img alt=""></figure>
    <button class="lb-freccia lb-succ" type="button" aria-label="Foto successiva">&#8250;</button>
    <div class="lb-testo">
      <div><p class="lb-titolo"></p><p class="lb-meta"></p></div>
      <span class="lb-conto"></span>
    </div>
  </div>

  <script src="assets/js/sito.js?v=1"></script>
</body>
</html>
