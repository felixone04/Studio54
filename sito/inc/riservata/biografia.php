<?php $c = contenuti(); ?>
<div class="testa-pagina">
  <div>
    <h1>Biografia</h1>
    <p>La storia dello studio e il metodo di lavoro.</p>
  </div>
</div>

<form class="moduli" data-demo-modulo>
  <section class="scheda pannello">
    <h2>La storia</h2>
    <label class="campo"><span>Titolo della pagina</span><input value="<?= e($c['bioTitle'] ?? '') ?>"></label>
    <label class="campo"><span>Introduzione (frase in evidenza)</span><textarea rows="2"><?= e($c['bioIntro'] ?? '') ?></textarea></label>
    <label class="campo"><span>Racconto</span><textarea rows="7"><?= e($c['bioStory'] ?? '') ?></textarea></label>
    <p class="aiuto">Separa i paragrafi con una riga vuota.</p>
    <div class="campo-foto"><img src="<?= e(foto($c['bioImage'] ?? '', 600)) ?>" alt=""><button type="button" class="bottone bordo" data-demo><i class="ico ico-carica"></i>Cambia foto</button></div>
  </section>
  <section class="scheda pannello">
    <h2>Il metodo</h2>
    <p class="tenue">I passaggi del lavoro (numero, titolo, testo).</p>
    <?php foreach ($c['timeline'] ?? [] as $i => $m): ?>
      <div class="voce-elenco">
        <div class="voce-elenco-testa"><strong>Passaggio <?= $i + 1 ?></strong><span><button type="button" class="ico-bottone" data-demo aria-label="Su"><i class="ico ico-su"></i></button><button type="button" class="ico-bottone" data-demo aria-label="Giù"><i class="ico ico-giu"></i></button><button type="button" class="ico-bottone" data-demo aria-label="Elimina"><i class="ico ico-cestino"></i></button></span></div>
        <div class="coppia stretta-prima">
          <label class="campo"><span>Numero</span><input value="<?= e($m['year'] ?? '') ?>"></label>
          <label class="campo"><span>Titolo</span><input value="<?= e($m['title'] ?? '') ?>"></label>
        </div>
        <label class="campo"><span>Testo</span><input value="<?= e($m['text'] ?? '') ?>"></label>
      </div>
    <?php endforeach; ?>
    <button type="button" class="bottone bordo" data-demo><i class="ico ico-piu"></i>Aggiungi passaggio</button>
  </section>
  <div class="barra-salva" hidden><span>Modifiche non salvate</span><button type="button" class="bottone testo" data-annulla>Annulla</button><button type="button" class="bottone pieno" data-demo>Salva</button></div>
</form>
