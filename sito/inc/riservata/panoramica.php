<?php
$q = dati()['quotes'] ?? [];
$app = dati()['appointments'] ?? [];
$stati = array_count_values(array_map(fn($x) => $x['status'] ?? 'nuova', $q));
usort($app, fn($a, $b) => strcmp($a['start'], $b['start']));
$lavori = lavori_pubblicati();
?>
<div class="testa-pagina">
  <div>
    <h1>Panoramica</h1>
    <p>Buongiorno! Ecco come va lo studio.</p>
  </div>
</div>

<div class="statistiche">
  <a class="stat" href="<?= e(url('riservata', 'richieste')) ?>"><b><?= $stati['nuova'] ?? 0 ?></b><span>Richieste nuove</span><i class="ico ico-busta"></i></a>
  <a class="stat" href="<?= e(url('riservata', 'richieste')) ?>"><b><?= $stati['contattata'] ?? 0 ?></b><span>Da confermare</span><i class="ico ico-telefono"></i></a>
  <a class="stat" href="<?= e(url('riservata', 'calendario')) ?>"><b><?= count($app) ?></b><span>Appuntamenti in arrivo</span><i class="ico ico-calendario"></i></a>
  <a class="stat" href="<?= e(url('riservata', 'lavori')) ?>"><b><?= count($lavori) ?></b><span>Lavori sul sito</span><i class="ico ico-libro"></i></a>
</div>

<div class="due-colonne">
  <section class="scheda">
    <div class="scheda-testa"><h2>Ultime richieste</h2><a class="bottone testo" href="<?= e(url('riservata', 'richieste')) ?>">Vedi tutte</a></div>
    <?php foreach (array_slice($q, 0, 4) as $r): ?>
      <a class="riga" href="<?= e(url('riservata', 'richieste')) ?>">
        <span class="iniziali"><?= e(mb_substr($r['firstName'], 0, 1) . mb_substr($r['lastName'], 0, 1)) ?></span>
        <span class="riga-testo"><strong><?= e($r['firstName'] . ' ' . $r['lastName']) ?></strong><small><?= e(unisci([$r['eventType'], data_it($r['eventDate'] ?? null, true), $r['location'] ?? ''])) ?></small></span>
        <span class="stato stato-<?= e($r['status']) ?>"><?= e(ucfirst($r['status'])) ?></span>
      </a>
    <?php endforeach; ?>
  </section>
  <section class="scheda">
    <div class="scheda-testa"><h2>Prossimi appuntamenti</h2><a class="bottone testo" href="<?= e(url('riservata', 'calendario')) ?>">Calendario</a></div>
    <?php foreach ($app as $a): $t = strtotime($a['start']); ?>
      <div class="riga">
        <span class="giorno"><b><?= date('j', $t) ?></b><small><?= e(mb_strtoupper(mb_substr(MESI[(int) date('n', $t) - 1], 0, 3))) ?></small></span>
        <span class="riga-testo"><strong><?= e($a['title']) ?></strong><small><?= e(unisci([($a['allDay'] ?? false) ? 'Tutto il giorno' : date('H:i', $t) . '–' . date('H:i', strtotime($a['end'])), $a['location'] ?? ''])) ?></small></span>
      </div>
    <?php endforeach; ?>
  </section>
</div>

<section class="scheda">
  <div class="scheda-testa"><h2>Scorciatoie</h2></div>
  <div class="scorciatoie">
    <a href="<?= e(url('riservata', 'lavori')) ?>"><i class="ico ico-libro"></i>Nuovo lavoro</a>
    <a href="<?= e(url('riservata', 'galleria')) ?>"><i class="ico ico-foto"></i>Carica foto</a>
    <a href="<?= e(url('riservata', 'calendario')) ?>"><i class="ico ico-calendario"></i>Fissa appuntamento</a>
    <a href="<?= e(url('riservata', 'home')) ?>"><i class="ico ico-pagina"></i>Modifica la home</a>
  </div>
</section>
