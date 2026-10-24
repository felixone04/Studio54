<?php $c = contenuti(); $k = $c['contacts'] ?? []; ?>
<div class="testa-pagina">
  <div>
    <h1>Identità e contatti</h1>
    <p>Nome, colore, recapiti e opzioni del modulo preventivo.</p>
  </div>
</div>

<form class="moduli" data-demo-modulo>
  <section class="scheda pannello">
    <h2>Identità</h2>
    <div class="coppia">
      <label class="campo"><span>Nome dello studio</span><input value="<?= e($c['studioName'] ?? '') ?>"></label>
      <label class="campo"><span>Slogan</span><input value="<?= e($c['tagline'] ?? '') ?>"></label>
    </div>
    <p class="etichetta-campo">Colore di accento</p>
    <div class="colori">
      <?php foreach (['Sabbia' => '#B89B72', 'Argento' => '#C9C5BC', 'Oro' => '#D4A85A', 'Rosa cipria' => '#E2A7A0', 'Salvia' => '#93AB8C', 'Blu notte' => '#6E8CC8'] as $n => $col): ?>
        <button type="button" class="colore<?= $n === 'Sabbia' ? ' scelto' : '' ?>" style="--c: <?= $col ?>" title="<?= e($n) ?>" aria-label="<?= e($n) ?>"></button>
      <?php endforeach; ?>
    </div>
  </section>
  <section class="scheda pannello">
    <h2>Contatti</h2>
    <p class="tenue">Compaiono nel footer del sito. I campi vuoti non vengono mostrati.</p>
    <div class="coppia">
      <label class="campo"><span>Telefono</span><input value="<?= e($k['phone'] ?? '') ?>"></label>
      <label class="campo"><span>WhatsApp</span><input value="<?= e($k['whatsapp'] ?? '') ?>"></label>
    </div>
    <label class="campo"><span>Email</span><input value="<?= e($k['email'] ?? '') ?>"></label>
    <label class="campo"><span>Indirizzo</span><input value="<?= e($k['address'] ?? '') ?>"></label>
    <label class="campo"><span>Orari di apertura</span><input value="<?= e($k['hours'] ?? '') ?>"></label>
    <div class="coppia">
      <label class="campo"><span>Instagram (link)</span><input value="<?= e($k['instagram'] ?? '') ?>"></label>
      <label class="campo"><span>Facebook (link)</span><input value="<?= e($k['facebook'] ?? '') ?>"></label>
    </div>
    <label class="campo"><span>Partita IVA / dati legali</span><input value="<?= e($k['vat'] ?? '') ?>"></label>
  </section>
  <section class="scheda pannello">
    <h2>Tipi di festa nel preventivo</h2>
    <p class="tenue">Le voci del menu “Tipo di evento”. “Altro” permette al cliente di specificare.</p>
    <div class="chips modificabili">
      <?php foreach ($c['eventTypes'] ?? [] as $t): ?><span class="chip"><?= e($t) ?><button type="button" data-demo aria-label="Togli">&times;</button></span><?php endforeach; ?>
    </div>
    <div class="riga-aggiungi"><label class="campo"><span>Nuovo tipo di evento</span><input></label><button type="button" class="bottone bordo" data-demo><i class="ico ico-piu"></i>Aggiungi</button></div>
  </section>
  <div class="barra-salva" hidden><span>Modifiche non salvate</span><button type="button" class="bottone testo" data-annulla>Annulla</button><button type="button" class="bottone pieno" data-demo>Salva</button></div>
</form>
