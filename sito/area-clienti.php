<?php
// Accesso all'area clienti. Nessuno può registrarsi dal sito: gli account li
// crea lo studio dal gestionale e manda al cliente email e password.
require __DIR__ . '/inc/app.php';
require __DIR__ . '/inc/clienti.php';

$pagina = '';
$titolo = 'Area clienti';
$noindex = true;
$classe_body = 'pagina-clienti';
$errore = '';

if (!STATICO) {
    sessione();
    if (isset($_GET['esci'])) {
        esci_cliente();
    } elseif (cliente_collegato()) {
        header('Location: ' . url('cliente'));
        exit;
    } elseif (($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
        $esito = accedi_cliente((string) ($_POST['email'] ?? ''), (string) ($_POST['password'] ?? ''));
        if ($esito === true) {
            header('Location: ' . url('cliente'));
            exit;
        }
        $errore = $esito;
    }
}

// Solo per l'anteprima statica: le email dei clienti d'esempio.
$demo = [];
if (STATICO) {
    foreach (dati()['clients'] ?? [] as $cl) {
        if ($cl['active'] ?? true) $demo[mb_strtolower($cl['email'])] = $cl['id'];
    }
}

require __DIR__ . '/inc/testa.php';
?>

<section class="clienti-accesso">
  <div class="clienti-accesso-foto">
    <img <?= foto_attr(foto_apertura()[0]['url'] ?? '', '50vw') ?> alt="">
    <span class="mirino" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
  </div>
  <div class="clienti-accesso-modulo">
    <form method="post" action="<?= e(url('area-clienti')) ?>" data-accesso-cliente
          <?php if (STATICO): ?>data-demo="<?= e(json_encode($demo)) ?>"<?php endif; ?> novalidate>
      <p class="etichetta entra"><span class="trattino"></span>AREA CLIENTI</p>
      <h1 class="entra">Bentornati.</h1>
      <p class="sottotitolo entra">Qui trovate le foto del vostro evento, l'album da sfogliare e i documenti.</p>

      <?php if (STATICO): ?>
        <p class="avviso-anteprima">Anteprima: entra con <b>anna.ricci@example.com</b> e la password <b>studio54</b>.</p>
      <?php endif; ?>

      <div class="campo" data-campo="email">
        <input id="c-email" name="email" type="email" inputmode="email" autocomplete="username" maxlength="80" placeholder=" " required>
        <label for="c-email">Email</label>
      </div>
      <div class="campo" data-campo="password">
        <input id="c-password" name="password" type="password" autocomplete="current-password" maxlength="80" placeholder=" " required>
        <label for="c-password">Password</label>
      </div>
      <p class="errore errore-accesso"><?= e($errore) ?></p>
      <button type="submit" class="pillola grande largo">ENTRA <i>&rarr;</i></button>
      <p class="nota-accesso">Non avete ancora i dati di accesso? Li riceverete dallo studio dopo la conferma del servizio.
        Per qualsiasi problema <a class="link" href="<?= e(url('preventivo')) ?>">scriveteci</a>.</p>
    </form>
  </div>
</section>

<?php require __DIR__ . '/inc/piede.php'; ?>
