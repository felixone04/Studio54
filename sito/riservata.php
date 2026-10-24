<?php
// Area riservata: ANTEPRIMA GRAFICA. I dati sono quelli d'esempio e nulla
// viene salvato. Verrà rifatta da zero insieme al database (accesso vero,
// richieste, calendario, contenuti) e sarà la stessa a cui accede l'app.
require __DIR__ . '/inc/app.php';

$sezioni = [
    'Attività' => [
        'panoramica' => ['Panoramica', 'griglia'],
        'richieste' => ['Richieste', 'busta'],
        'calendario' => ['Calendario', 'calendario'],
        'clienti' => ['Clienti', 'persone'],
    ],
    'Catalogo' => [
        'servizi' => ['Servizi e prodotti', 'servizi'],
        'pacchetti' => ['Pacchetti', 'pacco'],
        'lavori' => ['Lavori', 'libro'],
        'galleria' => ['Galleria', 'foto'],
    ],
    'Sito' => [
        'home' => ['Pagina Home', 'pagina'],
        'biografia' => ['Biografia', 'penna'],
        'contatti' => ['Identità e contatti', 'tessera'],
    ],
    'Sistema' => [
        'impostazioni' => ['Impostazioni', 'regola'],
    ],
];
$tutte = array_merge(...array_values($sezioni));
$sez = param('sez');
$accesso = $sez === '' || !isset($tutte[$sez]);
$c = contenuti();
$nuove = count(array_filter(dati()['quotes'] ?? [], fn($q) => ($q['status'] ?? '') === 'nuova'));
?><!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex">
  <title><?= e($accesso ? 'Area riservata' : $tutte[$sez][0]) ?> · <?= e($c['studioName'] ?? 'Studio 54') ?></title>
  <meta name="theme-color" content="#FAF0E6">
  <link rel="icon" type="image/png" href="assets/img/favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Josefin+Sans:ital,wght@0,300;0,400;0,600;1,300&family=Jost:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="<?= e(risorsa('assets/css/riservata.css')) ?>">
</head>
<body class="<?= $accesso ? 'accesso' : 'gestione' ?>">

<?php if ($accesso):
    $foto = foto_apertura()[0]['url'] ?? '';
?>
  <div class="accesso-griglia">
    <div class="accesso-foto">
      <img <?= foto_attr($foto, '55vw') ?> alt="">
      <span class="mirino" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
      <div class="accesso-cartoncino">
        <img src="assets/img/logo.png" alt="<?= e($c['studioName'] ?? '') ?>">
        <p>AREA RISERVATA</p>
      </div>
    </div>
    <div class="accesso-modulo">
      <form action="<?= e(url('riservata', 'panoramica')) ?>" method="get" data-accesso>
        <?php if (!STATICO): ?><input type="hidden" name="sez" value="panoramica"><?php endif; ?>
        <p class="etichetta"><span class="trattino"></span>AREA RISERVATA</p>
        <h1>Bentornato.</h1>
        <p class="tenue">Inserisci la password per gestire il sito.</p>
        <p class="avviso">Anteprima grafica: qualsiasi password apre la gestione con i dati d'esempio.</p>
        <label class="campo">
          <span>Password</span>
          <!-- Senza "name": la password non finisce mai nell'indirizzo. -->
          <input type="password" autocomplete="current-password" autofocus>
        </label>
        <label class="spunta-riga"><input type="checkbox" checked> Ricordami su questo dispositivo</label>
        <button class="bottone pieno largo" type="submit">ENTRA</button>
        <a class="bottone testo" href="<?= e(url('index')) ?>">&larr; Torna al sito</a>
      </form>
    </div>
  </div>

<?php else: ?>
  <div class="avviso-demo">Anteprima grafica dell'area riservata: dati d'esempio, le modifiche non vengono salvate.</div>
  <div class="guscio">
    <aside class="laterale" id="laterale">
      <a class="laterale-logo" href="<?= e(url('riservata', 'panoramica')) ?>"><img src="assets/img/logo.png" alt="<?= e($c['studioName'] ?? '') ?>"></a>
      <nav>
        <?php $primo = true; foreach ($sezioni as $gruppo => $voci): ?>
          <?php if (!$primo): ?><hr><?php endif; $primo = false; ?>
          <?php foreach ($voci as $id => [$nome, $icona]): ?>
            <a class="voce<?= $id === $sez ? ' attiva' : '' ?>" href="<?= e(url('riservata', $id)) ?>">
              <i class="ico ico-<?= e($icona) ?>"></i><span><?= e($nome) ?></span>
              <?php if ($id === 'richieste' && $nuove): ?><b class="contatore-tondo"><?= $nuove ?></b><?php endif; ?>
            </a>
          <?php endforeach; ?>
        <?php endforeach; ?>
      </nav>
      <div class="laterale-fondo">
        <a class="voce" href="<?= e(url('index')) ?>" target="_blank"><i class="ico ico-esterno"></i><span>Vedi il sito</span></a>
        <a class="voce" href="<?= e(url('riservata')) ?>"><i class="ico ico-esci"></i><span>Esci</span></a>
      </div>
    </aside>
    <div class="velo-laterale" data-chiudi-laterale></div>

    <div class="principale">
      <header class="testa-mobile">
        <button type="button" class="ico-bottone" data-apri-laterale aria-label="Menu"><i class="ico ico-menu"></i></button>
        <h1><?= e($tutte[$sez][0]) ?></h1>
        <a class="ico-bottone" href="<?= e(url('index')) ?>" target="_blank" aria-label="Vedi il sito"><i class="ico ico-esterno"></i></a>
      </header>
      <main class="pagina">
        <?php require __DIR__ . '/inc/riservata/' . $sez . '.php'; ?>
      </main>
    </div>
  </div>

  <div class="finestra" id="finestra" hidden role="dialog" aria-modal="true">
    <div class="finestra-box">
      <h2 class="finestra-titolo"></h2>
      <div class="finestra-corpo"></div>
      <div class="finestra-azioni">
        <button type="button" class="bottone testo" data-chiudi-finestra>Annulla</button>
        <button type="button" class="bottone pieno" data-salva>Salva</button>
      </div>
    </div>
  </div>
  <div class="avviso-breve" id="avviso-breve" hidden></div>
<?php endif; ?>

  <script src="<?= e(risorsa('assets/js/riservata.js')) ?>"></script>
</body>
</html>
