<?php
// Fine di ogni pagina pubblica: footer (disegnato da sito.js con i contatti),
// foto a schermo intero, dati e script.
?>
  </main>

  <footer class="piede" data-piede></footer>

  <div class="visore" id="visore" hidden aria-modal="true" role="dialog" aria-label="Foto a schermo intero">
    <figure><img alt=""></figure>
    <button class="tondo visore-chiudi" type="button" aria-label="Chiudi"><svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6 6 18"/></svg></button>
    <button class="tondo visore-prec" type="button" aria-label="Foto precedente"><svg viewBox="0 0 24 24"><path d="m14.5 6-6 6 6 6"/></svg></button>
    <button class="tondo visore-succ" type="button" aria-label="Foto successiva"><svg viewBox="0 0 24 24"><path d="m9.5 6 6 6-6 6"/></svg></button>
  </div>

  <?= dati_pagina('s54-dati', dati()) ?>
  <script src="<?= e(risorsa('assets/js/dati.js')) ?>"></script>
  <script src="<?= e(risorsa('assets/js/sito.js')) ?>"></script>
</body>
</html>
