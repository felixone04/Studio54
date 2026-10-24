<?php $c = contenuti(); ?>
<div class="testa-pagina">
  <div>
    <h1>Pagina Home</h1>
    <p>Le foto si gestiscono dalla Galleria.</p>
  </div>
</div>

<form class="moduli" data-demo-modulo>
  <section class="scheda pannello">
    <h2>Apertura</h2>
    <p class="tenue">La frase del carosello.</p>
    <label class="campo"><span>Frase</span><input value="<?= e($c['heroTitle'] ?? '') ?>"></label>
  </section>
  <section class="scheda pannello">
    <h2>Manifesto</h2>
    <p class="tenue">Una frase sola, al centro della pagina.</p>
    <label class="campo"><span>Frase</span><textarea rows="3"><?= e($c['manifestoTitle'] ?? '') ?></textarea></label>
    <p class="aiuto">Vai a capo per la seconda riga, che appare in corsivo.</p>
  </section>
  <section class="scheda pannello">
    <div class="scheda-testa"><h2>La mostra</h2><a class="bottone testo" href="<?= e(url('riservata', 'galleria')) ?>"><i class="ico ico-foto"></i>Gestisci le foto</a></div>
    <div class="coppia">
      <label class="campo"><span>Etichetta</span><input value="<?= e($c['galleryKicker'] ?? '') ?>"></label>
      <label class="campo"><span>Titolo</span><input value="<?= e($c['galleryTitle'] ?? '') ?>"></label>
    </div>
  </section>
  <section class="scheda pannello">
    <h2>Pagina preventivo</h2>
    <p class="tenue">La foto in apertura.</p>
    <div class="campo-foto"><img src="<?= e(foto($c['bannerImage'] ?? '', 800)) ?>" alt=""><button type="button" class="bottone bordo" data-demo><i class="ico ico-carica"></i>Cambia foto</button></div>
  </section>
  <div class="barra-salva" hidden><span>Modifiche non salvate</span><button type="button" class="bottone testo" data-annulla>Annulla</button><button type="button" class="bottone pieno" data-demo>Salva</button></div>
</form>
