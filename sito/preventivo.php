<?php
require __DIR__ . '/inc/app.php';

$pagina = 'preventivo';
$titolo = 'Preventivo';
$c = contenuti();
$servizi = array_values(array_filter(dati()['services'] ?? [], fn($s) => $s['active'] ?? true));
$categorie = [];
foreach ($servizi as $s) {
    $categorie[$s['category'] ?? 'Servizi'][] = $s;
}
$tipi = array_values(array_unique($c['eventTypes'] ?? []));
$foto_testa = trim($c['bannerImage'] ?? '') ?: (foto_apertura()[0]['url'] ?? '');

// Pacchetti visibili, per preselezionare i servizi da un link (?p=...).
$pacchetti = [];
foreach (dati()['packages'] ?? [] as $p) {
    if ($p['active'] ?? true) {
        $pacchetti[$p['id']] = $p['serviceIds'] ?? [];
    }
}

/*
 * Invio del modulo. Per ora non si salva nulla: quando ci sarà il database
 * la richiesta verrà registrata qui (e l'app la vedrà tra le "Richieste").
 * I controlli sono gli stessi fatti nel browser da sito.js.
 */
$inviata = null;
if (!STATICO && ($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
    $v = fn($k) => trim((string) ($_POST[$k] ?? ''));
    $errori = [];
    if ($v('tipo') === '' && $tipi) $errori[] = 'tipo';
    if (!preg_match('#^(\d{2})/(\d{2})/(\d{4})$#', $v('data'), $m) || !checkdate((int) $m[2], (int) $m[1], (int) $m[3])) $errori[] = 'data';
    if (mb_strlen($v('luogo')) < 2) $errori[] = 'luogo';
    foreach (['nome', 'cognome'] as $k) if (mb_strlen(preg_replace("/['\\s-]/u", '', $v($k))) < 2) $errori[] = $k;
    $cifre = strlen(preg_replace('/\D/', '', $v('telefono')));
    if ($cifre < 8 || $cifre > 15) $errori[] = 'telefono';
    if (!filter_var($v('email'), FILTER_VALIDATE_EMAIL)) $errori[] = 'email';
    if (empty($_POST['privacy'])) $errori[] = 'privacy';
    if (!$errori) $inviata = ['nome' => $v('nome'), 'telefono' => $v('telefono')];
}

require __DIR__ . '/inc/testa.php';
?>

<div class="contenitore preventivo">
  <?php if ($inviata): ?>
    <div class="grazie" data-grazie>
      <img src="assets/img/mark.png" alt="">
      <p class="etichetta"><span class="trattino"></span>RICHIESTA INVIATA</p>
      <h1>Grazie, <?= e($inviata['nome']) ?></h1>
      <p>Ti richiameremo al <?= e($inviata['telefono']) ?> per parlarne insieme.</p>
      <a class="pillola" href="<?= e(url('index')) ?>">TORNA ALLA HOME <i>&#8599;</i></a>
    </div>
  <?php else: ?>
  <div class="preventivo-testa">
    <div>
      <p class="etichetta entra"><span class="trattino"></span>PREVENTIVO GRATUITO</p>
      <h1 class="titolo-grande entra">RACCONTACI<br>IL TUO EVENTO</h1>
      <p class="sottotitolo entra">Bastano due minuti: compila i campi e ti richiamiamo noi con una proposta su misura. Gratuito e senza impegno.</p>
    </div>
    <?php if ($foto_testa !== ''): ?>
      <div class="preventivo-foto rivela"><img <?= foto_attr($foto_testa, '40vw') ?> alt=""></div>
    <?php endif; ?>
  </div>

  <form class="modulo" method="post" action="<?= e(url('preventivo')) ?>" novalidate data-modulo
        data-pacchetti="<?= e(json_encode($pacchetti)) ?>">
    <section class="passo-modulo" data-passo="evento">
      <h2><span>1</span>IL TUO EVENTO</h2>
      <div class="coppia">
        <div class="campo scelta" data-campo="tipo">
          <select id="tipo" name="tipo" <?= $tipi ? 'required' : '' ?>>
            <option value=""></option>
            <?php foreach ($tipi as $t): ?><option><?= e($t) ?></option><?php endforeach; ?>
          </select>
          <label for="tipo">Tipo di evento<?= $tipi ? ' *' : '' ?></label>
          <p class="errore"></p>
        </div>
        <div class="campo data" data-campo="data">
          <input id="data" name="data" inputmode="numeric" autocomplete="off" placeholder=" " maxlength="10">
          <label for="data">Data dell'evento *</label>
          <span class="suggerimento">gg/mm/aaaa</span>
          <button type="button" class="calendario" aria-label="Scegli dal calendario"></button>
          <input type="date" class="calendario-nativo" tabindex="-1" aria-hidden="true">
          <p class="errore"></p>
        </div>
      </div>
      <div class="campo" data-campo="altro" hidden>
        <input id="altro" name="altro" maxlength="60" placeholder=" ">
        <label for="altro">Di che evento si tratta? *</label>
        <p class="errore"></p>
      </div>
      <div class="campo" data-campo="luogo">
        <input id="luogo" name="luogo" maxlength="80" placeholder=" ">
        <label for="luogo">Luogo *</label>
        <span class="suggerimento">Città o nome della location</span>
        <p class="errore"></p>
      </div>
    </section>

    <?php if ($servizi): ?>
    <section class="passo-modulo" data-passo="servizi">
      <h2><span>2</span>COSA TI SERVE</h2>
      <p class="nota">Tocca una o più voci.</p>
      <?php foreach ($categorie as $nome => $lista): ?>
        <?php if (count($categorie) > 1): ?><p class="gruppo"><?= e(maiuscolo($nome)) ?></p><?php endif; ?>
        <div class="scelte">
          <?php foreach ($lista as $s): ?>
            <button type="button" class="scelta-voce" data-servizio="<?= e($s['id']) ?>" aria-pressed="false"><?= e($s['name']) ?></button>
          <?php endforeach; ?>
        </div>
      <?php endforeach; ?>
      <input type="hidden" name="servizi" value="">
      <p class="errore errore-servizi"></p>
    </section>
    <?php endif; ?>

    <section class="passo-modulo" data-passo="contatti">
      <h2><span><?= $servizi ? 3 : 2 ?></span>I TUOI CONTATTI</h2>
      <div class="coppia">
        <div class="campo" data-campo="nome">
          <input id="nome" name="nome" autocomplete="given-name" maxlength="40" placeholder=" ">
          <label for="nome">Nome *</label>
          <p class="errore"></p>
        </div>
        <div class="campo" data-campo="cognome">
          <input id="cognome" name="cognome" autocomplete="family-name" maxlength="40" placeholder=" ">
          <label for="cognome">Cognome *</label>
          <p class="errore"></p>
        </div>
      </div>
      <div class="coppia">
        <div class="campo icona-tel" data-campo="telefono">
          <input id="telefono" name="telefono" type="tel" inputmode="tel" autocomplete="tel" maxlength="20" placeholder=" ">
          <label for="telefono">Telefono *</label>
          <span class="suggerimento">Es. 333 123 4567</span>
          <p class="errore"></p>
        </div>
        <div class="campo icona-mail" data-campo="email">
          <input id="email" name="email" type="email" inputmode="email" autocomplete="email" maxlength="80" placeholder=" ">
          <label for="email">Email *</label>
          <span class="suggerimento">nome@email.it</span>
          <p class="errore"></p>
        </div>
      </div>
      <div class="campo area" data-campo="note">
        <textarea id="note" name="note" rows="3" maxlength="500" placeholder=" "></textarea>
        <label for="note">Note (facoltative)</label>
        <span class="conta-caratteri">0/500</span>
      </div>
    </section>

    <label class="consenso" data-campo="privacy">
      <input type="checkbox" name="privacy" value="1">
      <span class="spunta" aria-hidden="true"></span>
      <span>Acconsento al trattamento dei miei dati per essere ricontattato. *</span>
    </label>
    <p class="errore errore-privacy"></p>

    <div class="modulo-invio">
      <button type="submit" class="pillola grande">INVIA LA RICHIESTA <i>&rarr;</i></button>
      <span class="nota">* campi obbligatori</span>
    </div>
  </form>

  <div class="grazie" data-grazie hidden>
    <img src="assets/img/mark.png" alt="">
    <p class="etichetta"><span class="trattino"></span>RICHIESTA INVIATA</p>
    <h1 class="grazie-titolo">Grazie</h1>
    <p class="grazie-testo"></p>
    <div class="grazie-azioni">
      <a class="pillola" href="<?= e(url('index')) ?>">TORNA ALLA HOME <i>&#8599;</i></a>
      <button type="button" class="link grazie-nuova">Nuova richiesta</button>
    </div>
  </div>
  <?php endif; ?>
</div>

<?php require __DIR__ . '/inc/piede.php'; ?>
