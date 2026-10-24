<?php
$q = dati()['quotes'] ?? [];
$conta = array_count_values(array_map(fn($x) => $x['status'] ?? 'nuova', $q));
$stati = ['nuova' => 'Nuova', 'contattata' => 'Contattata', 'confermata' => 'Confermata', 'archiviata' => 'Archiviata'];
$pacchetti = [];
foreach (dati()['packages'] ?? [] as $p) $pacchetti[$p['id']] = $p['name'];
?>
<div class="testa-pagina">
  <div>
    <h1>Richieste</h1>
    <p>Le richieste di preventivo arrivate dal sito e dall'app.</p>
  </div>
</div>

<div class="filtri-chip" data-filtra-stato>
  <button type="button" class="chip attivo" data-stato="">Tutte (<?= count($q) ?>)</button>
  <?php foreach ($stati as $k => $n): ?>
    <button type="button" class="chip" data-stato="<?= e($k) ?>"><?= e($n) ?> (<?= $conta[$k] ?? 0 ?>)</button>
  <?php endforeach; ?>
</div>

<section class="scheda senza-margine">
  <?php foreach ($q as $r):
      $tot = 0; $prezzi = 0;
      foreach ($r['serviceIds'] as $id) { $s = servizio($id); if ($s && isset($s['internalPrice'])) { $tot += $s['internalPrice']; $prezzi++; } }
      $tel = preg_replace('/[^0-9+]/', '', $r['phone']);
  ?>
    <details class="richiesta" data-stato="<?= e($r['status']) ?>">
      <summary>
        <span class="iniziali"><?= e(mb_substr($r['firstName'], 0, 1) . mb_substr($r['lastName'], 0, 1)) ?></span>
        <span class="riga-testo">
          <strong><?= e($r['firstName'] . ' ' . $r['lastName']) ?> <span class="stato stato-<?= e($r['status']) ?>"><?= e($stati[$r['status']] ?? '') ?></span></strong>
          <small><?= e(unisci([$r['eventType'], data_it($r['eventDate'] ?? null, true), $r['location'] ?? '', 'richiesta del ' . data_it($r['createdAt'], true)])) ?></small>
        </span>
        <i class="ico ico-giu"></i>
      </summary>
      <div class="richiesta-corpo">
        <div class="azioni">
          <a class="bottone bordo" href="tel:<?= e($tel) ?>"><i class="ico ico-telefono"></i><?= e($r['phone']) ?></a>
          <a class="bottone bordo" href="https://wa.me/<?= e(ltrim($tel, '+')) ?>" target="_blank" rel="noopener"><i class="ico ico-chat"></i>WhatsApp</a>
          <a class="bottone bordo" href="mailto:<?= e($r['email']) ?>"><i class="ico ico-busta"></i><?= e($r['email']) ?></a>
        </div>
        <h3><?= !empty($r['packageId']) && isset($pacchetti[$r['packageId']]) ? 'Pacchetto ' . e($pacchetti[$r['packageId']]) . ' · servizi richiesti' : 'Servizi richiesti' ?></h3>
        <div class="chips">
          <?php foreach ($r['serviceIds'] as $id): ?><span class="chip piccolo"><?= e(servizio($id)['name'] ?? '(servizio rimosso)') ?></span><?php endforeach; ?>
        </div>
        <?php if ($prezzi): ?><p class="tenue piccolo">Stima interna: € <?= number_format($tot, 0, ',', '.') ?><?= $prezzi < count($r['serviceIds']) ? ' (parziale)' : '' ?> · non visibile al cliente</p><?php endif; ?>
        <?php if (!empty($r['message'])): ?><h3>Note del cliente</h3><p><?= e($r['message']) ?></p><?php endif; ?>
        <div class="richiesta-fondo">
          <label class="campo stretto"><span>Stato</span>
            <select data-demo>
              <?php foreach ($stati as $k => $n): ?><option value="<?= e($k) ?>" <?= $k === $r['status'] ? 'selected' : '' ?>><?= e($n) ?></option><?php endforeach; ?>
            </select>
          </label>
          <button type="button" class="bottone pieno" data-finestra="appuntamento" data-chi="<?= e($r['firstName'] . ' ' . $r['lastName'] . ' · ' . $r['eventType']) ?>"><i class="ico ico-calendario"></i>Fissa appuntamento</button>
          <button type="button" class="bottone testo rosso" data-demo>Elimina</button>
        </div>
      </div>
    </details>
  <?php endforeach; ?>
</section>
