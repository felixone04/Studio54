<?php
$app = dati()['appointments'] ?? [];
usort($app, fn($a, $b) => strcmp($a['start'], $b['start']));
?>
<div class="testa-pagina">
  <div>
    <h1>Calendario</h1>
    <p>Appuntamenti e servizi, sincronizzati con Google Calendar.</p>
  </div>
  <div class="testa-azioni">
    <button type="button" class="bottone bordo" data-demo><i class="ico ico-sincro"></i>Collega Google Calendar</button>
    <button type="button" class="bottone pieno" data-finestra="appuntamento"><i class="ico ico-piu"></i>Nuovo appuntamento</button>
  </div>
</div>

<div class="due-colonne larga-sinistra">
  <section class="scheda" data-calendario='<?= e(json_encode($app)) ?>'>
    <div class="cal-testa">
      <button type="button" class="ico-bottone" data-mese="-1" aria-label="Mese precedente"><i class="ico ico-sinistra"></i></button>
      <h2 class="cal-mese"></h2>
      <button type="button" class="ico-bottone" data-mese="1" aria-label="Mese successivo"><i class="ico ico-destra"></i></button>
    </div>
    <div class="cal-giorni"><span>Lun</span><span>Mar</span><span>Mer</span><span>Gio</span><span>Ven</span><span>Sab</span><span>Dom</span></div>
    <div class="cal-griglia"></div>
  </section>
  <section class="scheda">
    <div class="scheda-testa"><h2>Agenda</h2></div>
    <?php foreach ($app as $a): $t = strtotime($a['start']); ?>
      <div class="riga">
        <span class="giorno"><b><?= date('j', $t) ?></b><small><?= e(mb_strtoupper(mb_substr(MESI[(int) date('n', $t) - 1], 0, 3))) ?></small></span>
        <span class="riga-testo"><strong><?= e($a['title']) ?></strong><small><?= e(unisci([($a['allDay'] ?? false) ? 'Tutto il giorno' : date('H:i', $t) . '–' . date('H:i', strtotime($a['end'])), $a['location'] ?? ''])) ?></small></span>
        <button type="button" class="ico-bottone" data-finestra="appuntamento" data-chi="<?= e($a['title']) ?>" aria-label="Modifica"><i class="ico ico-matita"></i></button>
      </div>
    <?php endforeach; ?>
  </section>
</div>
