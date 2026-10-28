/* Studio 54 · il gestionale da computer (senza librerie).
 *
 * Una pagina sola, con le sezioni raggruppate per dove si vedono le
 * modifiche: sito e app insieme, solo sito, solo app. I dati arrivano da
 * S54 (assets/js/dati.js): per ora si salvano in questo browser, con il
 * database su Cloudflare andranno a sito e app di tutti. */
(function () {
  'use strict';

  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var esc = S54.esc;
  var app = $('#app');
  var copia = function (v) { return JSON.parse(JSON.stringify(v)); };
  var ico = function (n) { return '<i class="ico ico-' + n + '" aria-hidden="true"></i>'; };
  var nuovoId = function (p) { return p + Date.now().toString(36) + Math.floor(Math.random() * 1e4).toString(36); };

  var P = S54.pubblici();
  var Q = S54.privati(S54.leggiPagina('s54-gestionale'));

  var GRUPPI = [
    ['Attività', '', [['panoramica', 'Panoramica', 'griglia'], ['richieste', 'Richieste', 'busta'], ['calendario', 'Calendario', 'calendario']]],
    ['Sito e app', '', [['lavori', 'Lavori', 'libro'], ['preventivo', 'Preventivo', 'pagina'], ['biografia', 'Biografia', 'penna'], ['contatti', 'Contatti', 'tessera']]],
    ['Solo sito', 'schermo', [['carosello-sito', 'Carosello orizzontale', 'foto']]],
    ['Solo app', 'cellulare', [['carosello-app', 'Carosello verticale', 'cellulare'], ['clienti', 'Area clienti', 'persone']]],
    ['Sistema', '', [['impostazioni', 'Impostazioni', 'regola']]]
  ];
  var SEZIONI = {};
  GRUPPI.forEach(function (g) { g[2].forEach(function (s) { SEZIONI[s[0]] = s; }); });
  var STATI = { nuova: 'Nuova', contattata: 'Contattata', confermata: 'Confermata', archiviata: 'Archiviata' };
  var SUGGERIMENTI_LOCATION = ['Masseria', 'Mare', 'Montagna', 'Natura', 'Lago', 'Campagna', 'Villa', 'Città', 'Chiesa'];

  /* ------------------------------------------------------------- date */

  var MESI = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'];
  var due = function (n) { return (n < 10 ? '0' : '') + n; };
  function leggiData(v) {
    if (!v) return null;
    var d = new Date(/^\d{4}-\d{2}-\d{2}$/.test(v) ? v + 'T00:00' : v);
    return isNaN(d) ? null : d;
  }
  function dataIt(v, breve) {
    var d = typeof v === 'string' ? leggiData(v) : v;
    if (!d) return '';
    var m = MESI[d.getMonth()];
    return d.getDate() + ' ' + (breve ? m.slice(0, 3) : m) + ' ' + d.getFullYear();
  }
  var ora = function (d) { return due(d.getHours()) + ':' + due(d.getMinutes()); };
  var giornoIso = function (d) { return d.getFullYear() + '-' + due(d.getMonth() + 1) + '-' + due(d.getDate()); };
  var isoLocale = function (d) { return giornoIso(d) + 'T' + ora(d) + ':00.000'; };

  /* ------------------------------------------------------- salvataggio */

  var tAvviso;
  function avviso(msg, errore) {
    var a = $('#avviso-breve');
    a.textContent = msg;
    a.classList.toggle('errore', !!errore);
    a.hidden = false;
    clearTimeout(tAvviso);
    tAvviso = setTimeout(function () { a.hidden = true; }, errore ? 5500 : 2800);
  }
  var PIENO = 'Lo spazio di prova di questo browser è pieno: usa foto più leggere o indirizzi web.';
  function salvaP(msg) {
    if (S54.salvaPubblici(P)) { avviso(msg || 'Salvato: sito e app aggiornati.'); return true; }
    avviso(PIENO, true);
    return false;
  }
  function salvaQ(msg) {
    if (S54.salvaPrivati(Q)) { if (msg !== false) avviso(msg || 'Salvato.'); aggiornaNav(); return true; }
    avviso(PIENO, true);
    return false;
  }

  /* ---------------------------------------------- finestre di dialogo */

  var finestraEl = $('#finestra');
  function finestra(o) {
    $('.finestra-titolo', finestraEl).textContent = o.titolo;
    var corpo = $('.finestra-corpo', finestraEl);
    corpo.innerHTML = o.corpo;
    $('.finestra-box', finestraEl).classList.toggle('stretta', !!o.stretta);
    var az = $('.finestra-azioni', finestraEl);
    az.innerHTML = '';
    (o.azioni || [{ t: 'Chiudi' }]).forEach(function (a) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'bottone ' + (a.cls || 'testo') + (a.sinistra ? ' sinistra' : '');
      b.textContent = a.t;
      b.addEventListener('click', function () {
        if (!a.fn) { chiudiFinestra(); return; }
        Promise.resolve(a.fn(corpo)).then(function (r) { if (r !== false && !a.resta) chiudiFinestra(); });
      });
      az.appendChild(b);
    });
    finestraEl.hidden = false;
    if (o.dopo) o.dopo(corpo);
    var primo = $('input:not([type=checkbox]):not([type=file]), textarea', corpo);
    if (primo && o.fuoco !== false) primo.focus();
    corpo.scrollTop = 0;
  }
  function chiudiFinestra() { finestraEl.hidden = true; }
  function conferma(testo, si, fn) {
    finestra({ titolo: 'Conferma', corpo: '<p>' + esc(testo) + '</p>', stretta: true, azioni: [{ t: 'Annulla' }, { t: si || 'Elimina', cls: 'pieno', fn: fn }] });
  }
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && !finestraEl.hidden) chiudiFinestra(); });

  /* ----------------------------------------------------------- campi */

  function campo(id, etichetta, valore, o) {
    o = o || {};
    var attr = (o.tipo ? ' type="' + o.tipo + '"' : '') + (o.lista ? ' list="' + o.lista + '"' : '') + (o.attr || '');
    var input = o.area
      ? '<textarea id="' + id + '" rows="' + (o.righe || 4) + '"' + attr + '>' + esc(valore) + '</textarea>'
      : '<input id="' + id + '" value="' + esc(valore) + '"' + attr + '>';
    return '<label class="campo" data-per="' + id + '"><span>' + etichetta + '</span>' + input + (o.aiuto ? '<small class="tenue piccolo">' + o.aiuto + '</small>' : '') + '<p class="errore"></p></label>';
  }
  function errore(root, id, msg) {
    var c = $('[data-per="' + id + '"]', root);
    if (!c) return;
    c.classList.toggle('sbagliato', !!msg);
    $('.errore', c).textContent = msg || '';
  }
  var val = function (root, id) { var el = $('#' + id, root); return el ? el.value.trim() : ''; };
  function interruttore(id, acceso, titolo, sotto, disattivo) {
    return '<label class="riga-interruttore"><span><strong>' + titolo + '</strong>' + (sotto ? '<small>' + sotto + '</small>' : '') + '</span>' +
      '<span class="interruttore"><input type="checkbox" id="' + id + '"' + (acceso ? ' checked' : '') + (disattivo ? ' disabled' : '') + '><span></span></span></label>';
  }
  function testa(titolo, sotto, azioni) {
    return '<div class="testa-pagina"><div><h1>' + esc(titolo) + '</h1>' + (sotto ? '<p>' + sotto + '</p>' : '') + '</div>' + (azioni ? '<div class="testa-azioni">' + azioni + '</div>' : '') + '</div>';
  }
  var EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/;

  /** Una foto scelta dal computer, rimpicciolita (le foto pesanti riempirebbero
   * subito lo spazio di prova del browser). */
  function leggiImmagine(file, max) {
    return new Promise(function (ok, no) {
      var r = new FileReader();
      r.onload = function () {
        var img = new Image();
        img.onload = function () {
          var k = Math.min(1, max / Math.max(img.width, img.height));
          var c = document.createElement('canvas');
          c.width = Math.round(img.width * k); c.height = Math.round(img.height * k);
          c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
          ok(c.toDataURL('image/jpeg', 0.82));
        };
        img.onerror = no;
        img.src = r.result;
      };
      r.onerror = no;
      r.readAsDataURL(file);
    });
  }
  function leggiFile(file) {
    return new Promise(function (ok, no) { var r = new FileReader(); r.onload = function () { ok(r.result); }; r.onerror = no; r.readAsDataURL(file); });
  }
  /** Bottone "Carica dal computer" collegato a un <input type="file"> nascosto. */
  function caricatore(etichetta, accetta, multiplo) {
    return '<label class="bottone bordo">' + ico('carica') + etichetta + '<input type="file" accept="' + accetta + '"' + (multiplo ? ' multiple' : '') + ' hidden></label>';
  }
  function suCaricamento(root, sel, fn) {
    var input = $(sel + ' input[type=file]', root) || $(sel, root);
    if (!input) return;
    input.addEventListener('change', function () {
      var files = Array.prototype.slice.call(input.files || []);
      input.value = '';
      if (files.length) fn(files);
    });
  }
  var miniatura = function (u, w) { return S54.foto(u, w || 400); };

  /* ----------------------------------------------------- password */

  function sha256(t) {
    return crypto.subtle.digest('SHA-256', new TextEncoder().encode(t)).then(function (b) {
      return Array.prototype.map.call(new Uint8Array(b), function (x) { return (x < 16 ? '0' : '') + x.toString(16); }).join('');
    });
  }
  function sale() {
    var a = new Uint8Array(16); crypto.getRandomValues(a);
    return btoa(String.fromCharCode.apply(null, a)).replace(/\+/g, '-').replace(/\//g, '_');
  }
  /** Facile da dettare: niente lettere che si confondono (l, I, O, 0). */
  function generaPassword() {
    var c = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789', a = new Uint32Array(10);
    crypto.getRandomValues(a);
    return Array.prototype.map.call(a, function (x) { return c[x % c.length]; }).join('');
  }

  /* ========================================================= ACCESSO */

  var SESSIONE = 's54-titolare';
  function collegato() {
    try { return sessionStorage.getItem(SESSIONE) === '1' || localStorage.getItem(SESSIONE) === '1'; } catch (e) { return false; }
  }
  function disegnaAccesso() {
    var foto = ((P.carouselSite || []).filter(function (x) { return x.active !== false; })[0] || {}).url || '';
    app.innerHTML = '<div class="accesso-griglia"><div class="accesso-foto">' + (foto ? '<img ' + S54.srcset(foto, '55vw') + ' alt="">' : '') +
      '<div class="accesso-cartoncino"><img src="assets/img/logo.png" alt="' + esc(P.content.studioName || 'Studio 54') + '"><p>GESTIONALE</p></div></div>' +
      '<div class="accesso-modulo"><form id="form-accesso" novalidate><p class="etichetta"><span class="trattino"></span>GESTIONALE</p><h1>Bentornato.</h1>' +
      '<p class="tenue">Entra per gestire il sito e l\'app.</p><p class="avviso">Accesso di prova: nome utente <b>titolare</b>, password <b>studio54</b>.</p>' +
      // Senza "name": nome utente e password non finiscono mai nell'indirizzo.
      '<label class="campo"><span>Nome utente</span><input id="acc-utente" autocomplete="username"></label>' +
      '<label class="campo"><span>Password</span><input id="acc-pw" type="password" autocomplete="current-password"></label>' +
      '<p class="errore-accesso" id="acc-err"></p><label class="spunta-riga"><input type="checkbox" id="acc-ricorda" checked> Ricordami su questo computer</label>' +
      '<button class="bottone pieno largo" type="submit">ENTRA</button><a class="bottone testo" href="' + S54.url('index') + '">&larr; Torna al sito</a></form></div></div>';
    $('#acc-utente').focus();
    $('#form-accesso').addEventListener('submit', function (e) {
      e.preventDefault();
      var u = $('#acc-utente').value.trim().toLowerCase(), pw = $('#acc-pw').value, ad = Q.admin || {};
      if (!u || !pw) { $('#acc-err').textContent = 'Inserisci nome utente e password.'; return; }
      sha256((ad.passwordSalt || '') + '::' + pw).then(function (h) {
        if (u !== (ad.username || '').toLowerCase() || h !== ad.passwordHash) { $('#acc-err').textContent = 'Nome utente o password non corretti.'; return; }
        try { (($('#acc-ricorda').checked) ? localStorage : sessionStorage).setItem(SESSIONE, '1'); } catch (er) {}
        disegna();
      }).catch(function () { $('#acc-err').textContent = 'Questo browser non permette l\'accesso: apri il gestionale dall\'indirizzo https del sito.'; });
    });
  }
  function esci() {
    if (sporco) {
      finestra({
        titolo: 'Modifiche non salvate', stretta: true,
        corpo: '<p>Hai modifiche non salvate in questa sezione.</p>',
        azioni: [{ t: 'Resta qui' }, { t: 'Esci senza salvare', cls: 'pieno', fn: function () { sporco = false; esci(); } }]
      });
      return;
    }
    try { sessionStorage.removeItem(SESSIONE); localStorage.removeItem(SESSIONE); } catch (e) {}
    location.hash = '';
    disegna();
  }

  /* ========================================================= STRUTTURA */

  var sporco = false, hashPrima = location.hash;
  function corrente() { var h = location.hash.slice(1); return SEZIONI[h] ? h : 'panoramica'; }
  function disegnaGuscio() {
    app.innerHTML = '<div class="avviso-demo"><span>Prova senza database: le modifiche restano in questo browser e il sito le mostra subito, qui.</span><button type="button" data-azione="ripristina">Torna agli esempi</button></div>' +
      '<div class="guscio"><aside class="laterale" id="laterale"><a class="laterale-logo" href="#panoramica"><img src="assets/img/logo.png" alt="' + esc(P.content.studioName || 'Studio 54') + '"></a><nav id="nav" aria-label="Sezioni"></nav>' +
      '<div class="laterale-fondo"><a class="voce" href="' + S54.url('index') + '" target="_blank" rel="noopener">' + ico('esterno') + '<span>Vedi il sito</span></a>' +
      '<button type="button" class="voce" data-azione="esci" style="width:100%">' + ico('esci') + '<span>Esci</span></button></div></aside>' +
      '<div class="velo-laterale" id="velo" data-azione="chiudi-menu"></div><div class="principale"><header class="testa-mobile"><button type="button" class="ico-bottone" data-azione="menu" aria-label="Menu">' + ico('menu') + '</button><h1></h1>' +
      '<a class="ico-bottone" href="' + S54.url('index') + '" target="_blank" rel="noopener" aria-label="Vedi il sito">' + ico('esterno') + '</a></header><main class="pagina" id="pagina"></main></div></div>';
  }
  function aggiornaNav() {
    var nav = $('#nav');
    if (!nav) return;
    var nuove = Q.quotes.filter(function (q) { return q.status === 'nuova'; }).length, id = corrente();
    nav.innerHTML = GRUPPI.map(function (g) {
      return '<p class="gruppo">' + (g[1] ? ico(g[1]) : '') + esc(g[0].toUpperCase()) + '</p>' + g[2].map(function (s) {
        return '<a class="voce' + (s[0] === id ? ' attiva' : '') + '" href="#' + s[0] + '">' + ico(s[2]) + '<span>' + esc(s[1]) + '</span>' +
          (s[0] === 'richieste' && nuove ? '<b class="contatore-tondo">' + nuove + '</b>' : '') + '</a>';
      }).join('');
    }).join('');
  }
  function menuMobile(si) { $('#laterale').classList.toggle('aperta', si); $('#velo').classList.toggle('aperta', si); }
  function disegna() {
    if (!collegato()) { disegnaAccesso(); return; }
    if (!$('.guscio', app)) disegnaGuscio();
    var id = corrente();
    sporco = false;
    aggiornaNav();
    $('.testa-mobile h1').textContent = SEZIONI[id][1];
    document.title = SEZIONI[id][1] + ' · Gestionale';
    var p = $('#pagina');
    p.innerHTML = '';
    SEZIONE[id](p);
    window.scrollTo(0, 0);
    menuMobile(false);
    hashPrima = location.hash;
  }
  window.addEventListener('hashchange', function () {
    if (!sporco) { disegna(); return; }
    var verso = location.hash;
    history.replaceState(null, '', hashPrima || '#');
    finestra({
      titolo: 'Modifiche non salvate', stretta: true,
      corpo: '<p>Hai modifiche non salvate in questa sezione.</p>',
      azioni: [{ t: 'Resta qui' }, { t: 'Esci senza salvare', cls: 'pieno', fn: function () { sporco = false; location.hash = verso; } }]
    });
  });
  window.addEventListener('beforeunload', function (e) { if (sporco) { e.preventDefault(); e.returnValue = ''; } });
  document.addEventListener('click', function (e) {
    var a = e.target.closest('[data-azione]');
    if (!a || !app.contains(a)) return;
    var x = a.getAttribute('data-azione');
    if (x === 'menu') menuMobile(true);
    if (x === 'chiudi-menu') menuMobile(false);
    if (x === 'esci') esci();
    if (x === 'ripristina') conferma('Tornare ai dati d\'esempio? Le modifiche fatte in questo browser verranno cancellate.', 'Torna agli esempi', function () { S54.ripristina(); location.reload(); });
  });

  /** Barra in fondo con Salva e Annulla, per le sezioni con i testi. */
  function barraSalva(p, salva, annulla) {
    var b = document.createElement('div');
    b.className = 'barra-salva';
    b.hidden = !sporco;
    b.innerHTML = '<span>Modifiche non salvate</span><button type="button" class="bottone testo">Annulla</button><button type="button" class="bottone pieno">Salva</button>';
    b.children[1].addEventListener('click', function () { sporco = false; annulla(); });
    b.children[2].addEventListener('click', function () { if (salva() !== false) { sporco = false; b.hidden = true; } });
    p.appendChild(b);
  }
  function segnaSporco() { sporco = true; var b = $('.barra-salva'); if (b) b.hidden = false; }

  var SEZIONE = {};

  /* ======================================================= PANORAMICA */

  function iniziali(nome) {
    return (nome || '').trim().split(/\s+/).filter(Boolean).slice(0, 2).map(function (x) { return x[0].toUpperCase(); }).join('');
  }
  function rigaRichiesta(q) {
    var nome = S54.unisci([q.firstName, q.lastName], ' ');
    return '<a class="riga" href="#richieste"><span class="iniziali">' + esc(iniziali(nome)) + '</span><span class="riga-testo"><strong>' + esc(nome) +
      ' <span class="stato stato-' + esc(q.status) + '">' + esc(STATI[q.status] || '') + '</span></strong><small>' +
      esc(S54.unisci([q.eventType, dataIt(q.eventDate, true), q.location])) + '</small></span></a>';
  }
  function rigaAppuntamento(a) {
    var d = leggiData(a.start) || new Date();
    return '<button type="button" class="riga" data-app="' + esc(a.id) + '"><span class="giorno"><b>' + d.getDate() + '</b><small>' + MESI[d.getMonth()].slice(0, 3).toUpperCase() + '</small></span>' +
      '<span class="riga-testo"><strong>' + esc(a.title) + '</strong><small>' + esc(S54.unisci([a.allDay ? 'Tutto il giorno' : ora(d), a.location])) + '</small></span></button>';
  }
  function prossimiAppuntamenti() {
    var oggi = new Date(); oggi.setHours(0, 0, 0, 0);
    return Q.appointments.filter(function (a) { var d = leggiData(a.end || a.start); return d && d >= oggi; })
      .sort(function (a, b) { return leggiData(a.start) - leggiData(b.start); });
  }
  function apriAppuntamenti(root, dopo) {
    $$('[data-app]', root).forEach(function (b) {
      b.addEventListener('click', function (e) {
        e.stopPropagation();
        var a = Q.appointments.filter(function (x) { return x.id === b.getAttribute('data-app'); })[0];
        if (a) modaleAppuntamento(a, dopo);
      });
    });
  }

  SEZIONE.panoramica = function (p) {
    var tra30 = new Date(); tra30.setDate(tra30.getDate() + 30);
    var prossimi = prossimiAppuntamenti();
    var stat = [
      [Q.quotes.filter(function (q) { return q.status === 'nuova'; }).length, 'Richieste da leggere', 'busta', '#richieste'],
      [prossimi.filter(function (a) { return leggiData(a.start) < tra30; }).length, 'Appuntamenti nei prossimi 30 giorni', 'calendario', '#calendario'],
      [P.works.filter(function (w) { return w.published !== false; }).length, 'Lavori pubblicati', 'libro', '#lavori'],
      [Q.clients.filter(function (c) { return c.active !== false; }).length, 'Clienti con accesso all\'app', 'persone', '#clienti']
    ];
    p.innerHTML = testa('Panoramica', 'Quello che succede nello studio, a colpo d\'occhio.') +
      '<div class="statistiche">' + stat.map(function (s) { return '<a class="stat" href="' + s[3] + '"><b>' + s[0] + '</b><span>' + s[1] + '</span>' + ico(s[2]) + '</a>'; }).join('') + '</div>' +
      '<div class="due-colonne"><section class="scheda"><div class="scheda-testa"><h2>Ultime richieste</h2><a class="bottone testo piccolo" href="#richieste">Tutte</a></div>' +
      (Q.quotes.slice(0, 5).map(rigaRichiesta).join('') || '<p class="vuoto">Nessuna richiesta, per ora.</p>') + '</section>' +
      '<section class="scheda"><div class="scheda-testa"><h2>Prossimi appuntamenti</h2><a class="bottone testo piccolo" href="#calendario">Calendario</a></div>' +
      (prossimi.slice(0, 5).map(rigaAppuntamento).join('') || '<p class="vuoto">Nessun appuntamento in programma.</p>') + '</section></div>' +
      '<section class="scheda"><div class="scheda-testa"><h2>Scorciatoie</h2></div><div class="scorciatoie">' +
      '<a href="#lavori">' + ico('libro') + 'Lavori</a><a href="#carosello-sito">' + ico('schermo') + 'Carosello del sito</a><a href="#carosello-app">' + ico('cellulare') + 'Carosello dell\'app</a><a href="#clienti">' + ico('persone') + 'Area clienti</a></div></section>';
    apriAppuntamenti(p, function () { disegna(); });
  };

  /* ======================================================== RICHIESTE */

  var filtroStato = '', richiestaAperta = null;
  SEZIONE.richieste = function (p) {
    var conta = {};
    Q.quotes.forEach(function (q) { conta[q.status] = (conta[q.status] || 0) + 1; });
    var elenco = Q.quotes.filter(function (q) { return !filtroStato || q.status === filtroStato; });
    var chips = [['', 'Tutte', Q.quotes.length]].concat(Object.keys(STATI).map(function (k) { return [k, STATI[k], conta[k] || 0]; }));
    p.innerHTML = testa('Richieste', 'Le richieste di informazioni arrivate dal sito e dall\'app.') +
      '<div class="filtri-chip">' + chips.map(function (c) { return '<button type="button" class="chip' + (filtroStato === c[0] ? ' attivo' : '') + '" data-stato="' + c[0] + '">' + c[1] + ' (' + c[2] + ')</button>'; }).join('') + '</div>' +
      '<section class="scheda senza-margine">' + (elenco.map(function (q) {
        var nome = S54.unisci([q.firstName, q.lastName], ' ');
        var tel = (q.phone || '').replace(/[^0-9+]/g, '');
        return '<details class="richiesta" data-id="' + esc(q.id) + '"' + (q.id === richiestaAperta ? ' open' : '') + '><summary><span class="iniziali">' + esc(iniziali(nome)) + '</span>' +
          '<span class="riga-testo"><strong>' + esc(nome) + ' <span class="stato stato-' + esc(q.status) + '">' + esc(STATI[q.status] || '') + '</span></strong>' +
          '<small>' + esc(S54.unisci([q.eventType, dataIt(q.eventDate, true), q.location, (q.source === 'app' ? 'dall\'app' : 'dal sito') + ' il ' + dataIt(q.createdAt, true)])) + '</small></span>' + ico('giu') + '</summary>' +
          '<div class="richiesta-corpo"><div class="azioni">' +
          (tel ? '<a class="bottone bordo" href="tel:' + esc(tel) + '">' + ico('telefono') + esc(q.phone) + '</a><a class="bottone bordo" href="https://wa.me/' + esc(tel.replace('+', '')) + '" target="_blank" rel="noopener">' + ico('chat') + 'WhatsApp</a>' : '') +
          (q.email ? '<a class="bottone bordo" href="mailto:' + esc(q.email) + '">' + ico('busta') + esc(q.email) + '</a>' : '') + '</div>' +
          ((q.requests || []).length ? '<h3>Richieste</h3><div class="chips">' + q.requests.map(function (r) { return '<span class="chip piccolo">' + esc(r) + '</span>'; }).join('') + '</div>' : '') +
          (q.message ? '<h3>Messaggio</h3><p>' + esc(q.message) + '</p>' : '') +
          '<div class="richiesta-fondo"><label class="campo"><span>Stato</span><select data-cambia-stato>' + Object.keys(STATI).map(function (k) { return '<option value="' + k + '"' + (k === q.status ? ' selected' : '') + '>' + STATI[k] + '</option>'; }).join('') + '</select></label>' +
          '<button type="button" class="bottone pieno" data-fissa>' + ico('calendario') + (q.appointmentId ? 'Vedi l\'appuntamento' : 'Fissa appuntamento') + '</button><button type="button" class="bottone testo rosso" data-elimina>Elimina</button></div></div></details>';
      }).join('') || '<p class="vuoto">Nessuna richiesta.</p>') + '</section>';

    $$('[data-stato]', p).forEach(function (b) { b.addEventListener('click', function () { filtroStato = b.getAttribute('data-stato'); disegna(); }); });
    $$('.richiesta', p).forEach(function (d) {
      var q = Q.quotes.filter(function (x) { return x.id === d.getAttribute('data-id'); })[0];
      d.addEventListener('toggle', function () { if (d.open) richiestaAperta = q.id; });
      $('[data-cambia-stato]', d).addEventListener('change', function (e) { q.status = e.target.value; salvaQ('Stato aggiornato.'); disegna(); });
      $('[data-fissa]', d).addEventListener('click', function () {
        var esistente = Q.appointments.filter(function (a) { return a.id === q.appointmentId; })[0];
        modaleAppuntamento(esistente || { title: 'Incontro con ' + S54.unisci([q.firstName, q.lastName], ' ') + (q.eventType ? ' · ' + q.eventType : ''), location: 'Studio', quoteId: q.id }, function (a) {
          if (a) { q.appointmentId = a.id; if (q.status === 'nuova') q.status = 'contattata'; } else q.appointmentId = null;
          salvaQ(false);
          disegna();
        });
      });
      $('[data-elimina]', d).addEventListener('click', function () {
        conferma('Eliminare la richiesta di ' + S54.unisci([q.firstName, q.lastName], ' ') + '?', 'Elimina', function () {
          Q.quotes = Q.quotes.filter(function (x) { return x.id !== q.id; });
          salvaQ('Richiesta eliminata.');
          disegna();
        });
      });
    });
  };

  /* ===================================================== APPUNTAMENTI */

  function modaleAppuntamento(a, dopo) {
    var nuovo = !a.id;
    var inizio = leggiData(a.start);
    if (!inizio) { inizio = new Date(); inizio.setDate(inizio.getDate() + 1); inizio.setHours(10, 0, 0, 0); }
    var fine = leggiData(a.end) || new Date(inizio.getTime() + 3600000);
    finestra({
      titolo: nuovo ? 'Nuovo appuntamento' : 'Appuntamento',
      corpo: campo('ap-titolo', 'Titolo *', a.title || '') +
        '<div class="coppia">' + campo('ap-giorno', 'Giorno *', giornoIso(inizio), { tipo: 'date' }) +
        '<label class="campo"><span>&nbsp;</span><span class="spunta-riga" style="margin:12px 0 0"><input type="checkbox" id="ap-tutto"' + (a.allDay ? ' checked' : '') + '> Tutto il giorno</span></label></div>' +
        '<div class="coppia" id="ap-ore">' + campo('ap-inizio', 'Dalle', ora(inizio), { tipo: 'time' }) + campo('ap-fine', 'Alle', ora(fine), { tipo: 'time' }) + '</div>' +
        campo('ap-luogo', 'Luogo', a.location || '') + campo('ap-note', 'Note', a.notes || '', { area: true, righe: 3 }),
      dopo: function (c) {
        var ore = function () { $('#ap-ore', c).hidden = $('#ap-tutto', c).checked; };
        $('#ap-tutto', c).addEventListener('change', ore); ore();
      },
      azioni: (nuovo ? [] : [{ t: 'Elimina', cls: 'testo rosso', sinistra: true, fn: function () {
        Q.appointments = Q.appointments.filter(function (x) { return x.id !== a.id; });
        Q.quotes.forEach(function (q) { if (q.appointmentId === a.id) q.appointmentId = null; });
        salvaQ('Appuntamento eliminato.');
        if (dopo) dopo(null); else disegna();
      } }]).concat([{ t: 'Annulla' }, { t: 'Salva', cls: 'pieno', fn: function (c) {
        var titolo = val(c, 'ap-titolo'), giorno = val(c, 'ap-giorno'), tutto = $('#ap-tutto', c).checked;
        errore(c, 'ap-titolo', titolo ? '' : 'Scrivi un titolo');
        errore(c, 'ap-giorno', giorno ? '' : 'Scegli il giorno');
        if (!titolo || !giorno) return false;
        var s = leggiData(giorno + 'T' + (tutto ? '00:00' : val(c, 'ap-inizio') || '10:00'));
        var e = tutto ? new Date(s.getTime() + 86400000) : leggiData(giorno + 'T' + (val(c, 'ap-fine') || '11:00'));
        if (e <= s) { errore(c, 'ap-fine', 'Deve finire dopo l\'inizio'); return false; }
        var r = Object.assign({}, a, { id: a.id || nuovoId('a'), title: titolo, start: isoLocale(s), end: isoLocale(e), allDay: tutto, location: val(c, 'ap-luogo'), notes: val(c, 'ap-note') });
        if (nuovo) Q.appointments.push(r); else Q.appointments = Q.appointments.map(function (x) { return x.id === r.id ? r : x; });
        salvaQ('Appuntamento salvato.');
        if (dopo) dopo(r); else disegna();
      } }])
    });
  }

  /* ======================================================= CALENDARIO */

  var meseCal = new Date(); meseCal.setDate(1); meseCal.setHours(0, 0, 0, 0);
  SEZIONE.calendario = function (p) {
    var primo = new Date(meseCal), oggi = giornoIso(new Date());
    var inizio = new Date(primo); inizio.setDate(1 - ((primo.getDay() + 6) % 7));
    var ultimo = new Date(primo.getFullYear(), primo.getMonth() + 1, 0);
    var celle = Math.ceil(((primo.getDay() + 6) % 7 + ultimo.getDate()) / 7) * 7;
    var perGiorno = {};
    Q.appointments.forEach(function (a) { var d = leggiData(a.start); if (d) (perGiorno[giornoIso(d)] = perGiorno[giornoIso(d)] || []).push(a); });
    var griglia = '';
    for (var k = 0; k < celle; k++) {
      var g = new Date(inizio); g.setDate(inizio.getDate() + k);
      var iso = giornoIso(g), eventi = (perGiorno[iso] || []).sort(function (a, b) { return leggiData(a.start) - leggiData(b.start); });
      griglia += '<div class="cal-cella' + (g.getMonth() !== primo.getMonth() ? ' fuori' : '') + (iso === oggi ? ' oggi' : '') + '" data-giorno="' + iso + '" role="button" tabindex="0" aria-label="Nuovo appuntamento il ' + dataIt(g) + '">' +
        '<span class="cal-num">' + g.getDate() + '</span>' + eventi.map(function (a) {
          var d = leggiData(a.start);
          return '<button type="button" class="cal-evento" data-app="' + esc(a.id) + '">' + (a.allDay ? '' : ora(d) + ' ') + esc(a.title) + '</button>';
        }).join('') + '</div>';
    }
    var prossimi = prossimiAppuntamenti();
    p.innerHTML = testa('Calendario', 'Tocca un giorno per fissare un appuntamento, o un appuntamento per modificarlo.', '<button type="button" class="bottone pieno" data-nuovo>' + ico('piu') + 'Nuovo appuntamento</button>') +
      '<section class="scheda senza-margine"><div class="cal-testa"><button type="button" class="ico-bottone" data-mese="-1" aria-label="Mese precedente">' + ico('sinistra') + '</button>' +
      '<span class="cal-mese">' + MESI[primo.getMonth()] + ' ' + primo.getFullYear() + '</span><span style="display:flex;gap:4px"><button type="button" class="bottone testo piccolo" data-mese="0">Oggi</button>' +
      '<button type="button" class="ico-bottone" data-mese="1" aria-label="Mese successivo">' + ico('destra') + '</button></span></div>' +
      '<div class="cal-giorni">' + ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'].map(function (d) { return '<span>' + d + '</span>'; }).join('') + '</div><div class="cal-griglia">' + griglia + '</div></section>' +
      '<section class="scheda"><div class="scheda-testa"><h2>In programma</h2></div>' + (prossimi.slice(0, 8).map(rigaAppuntamento).join('') || '<p class="vuoto">Nessun appuntamento in programma.</p>') + '</section>';
    $$('[data-mese]', p).forEach(function (b) {
      b.addEventListener('click', function () {
        var d = +b.getAttribute('data-mese');
        if (d === 0) { meseCal = new Date(); meseCal.setDate(1); } else meseCal.setMonth(meseCal.getMonth() + d);
        disegna();
      });
    });
    $$('[data-giorno]', p).forEach(function (c) {
      var apri = function () { modaleAppuntamento({ start: c.getAttribute('data-giorno') + 'T10:00' }); };
      c.addEventListener('click', apri);
      c.addEventListener('keydown', function (e) { if (e.key === 'Enter') apri(); });
    });
    $('[data-nuovo]', p).addEventListener('click', function () { modaleAppuntamento({}); });
    apriAppuntamenti(p);
  };

  /* =========================================================== LAVORI */

  var featured = function () { return P.works.filter(function (w) { return w.featured; }).length; };
  SEZIONE.lavori = function (p) {
    p.innerHTML = testa('Lavori', 'Gli stessi sul sito e nell\'app. La <b>stella</b> mette un lavoro in evidenza nella home (al massimo 4); <b>Sito</b> e <b>App</b> scelgono dove si vede.',
      '<a class="bottone bordo" href="' + S54.url('lavori') + '" target="_blank" rel="noopener">' + ico('esterno') + 'Vedi sul sito</a><button type="button" class="bottone pieno" data-nuovo>' + ico('piu') + 'Nuovo lavoro</button>') +
      '<p class="tenue piccolo" style="margin:-12px 0 14px">In evidenza nella home: ' + featured() + ' di 4.</p>' +
      '<section class="scheda senza-margine">' + (P.works.map(function (w, i) {
        var nascosto = w.published === false;
        return '<div class="riga' + (nascosto ? ' spenta' : '') + '" data-i="' + i + '">' +
          '<div class="ordina"><button type="button" data-sposta="-1" aria-label="Sposta su"' + (i === 0 ? ' disabled' : '') + '>' + ico('su') + '</button><button type="button" data-sposta="1" aria-label="Sposta giù"' + (i === P.works.length - 1 ? ' disabled' : '') + '>' + ico('giu') + '</button></div>' +
          '<span class="miniatura larga"><img src="' + esc(miniatura(S54.copertina(w), 300)) + '" alt="" loading="lazy"></span>' +
          '<span class="riga-testo"><strong>' + esc(w.title) + '</strong><small>' + esc(S54.unisci([w.category, w.location, w.date, (w.photos || []).length + ' foto', nascosto ? 'nascosto' : ''])) + '</small></span>' +
          '<div class="riga-azioni"><button type="button" class="ico-bottone' + (w.featured ? ' acceso' : '') + '" data-stella aria-pressed="' + !!w.featured + '" title="In evidenza nella home">' + ico(w.featured ? 'stella-piena' : 'stella') + '</button>' +
          '<button type="button" class="chip piccolo" data-dove="onSite" aria-pressed="' + (w.onSite !== false) + '" title="Si vede sul sito">Sito</button>' +
          '<button type="button" class="chip piccolo" data-dove="onApp" aria-pressed="' + (w.onApp !== false) + '" title="Si vede nell\'app">App</button>' +
          '<button type="button" class="ico-bottone" data-pubblica title="' + (nascosto ? 'Nascosto: tocca per pubblicarlo' : 'Pubblicato: tocca per nasconderlo') + '">' + ico(nascosto ? 'occhio-no' : 'occhio') + '</button>' +
          '<button type="button" class="ico-bottone" data-modifica aria-label="Modifica">' + ico('matita') + '</button><button type="button" class="ico-bottone" data-elimina aria-label="Elimina">' + ico('cestino') + '</button></div></div>';
      }).join('') || '<p class="vuoto">Nessun lavoro. Aggiungi il primo.</p>') + '</section>';

    $('[data-nuovo]', p).addEventListener('click', function () { modaleLavoro(null); });
    $$('.riga[data-i]', p).forEach(function (r) {
      var i = +r.getAttribute('data-i'), w = P.works[i];
      $$('[data-sposta]', r).forEach(function (b) {
        b.addEventListener('click', function () {
          var j = i + +b.getAttribute('data-sposta');
          P.works.splice(j, 0, P.works.splice(i, 1)[0]);
          salvaP('Ordine salvato.'); disegna();
        });
      });
      $('[data-stella]', r).addEventListener('click', function () {
        if (!w.featured && featured() >= 4) { avviso('Ci sono già 4 lavori in evidenza: togli la stella a uno prima.', true); return; }
        w.featured = !w.featured;
        salvaP(w.featured ? 'In evidenza nella home.' : 'Tolto dalla home.'); disegna();
      });
      $$('[data-dove]', r).forEach(function (b) {
        b.addEventListener('click', function () {
          var k = b.getAttribute('data-dove');
          w[k] = w[k] === false;
          salvaP(w[k] ? 'Ora si vede ' + (k === 'onSite' ? 'sul sito.' : 'nell\'app.') : 'Non si vede più ' + (k === 'onSite' ? 'sul sito.' : 'nell\'app.'));
          disegna();
        });
      });
      $('[data-pubblica]', r).addEventListener('click', function () { w.published = w.published === false; salvaP(w.published ? 'Pubblicato.' : 'Nascosto.'); disegna(); });
      $('[data-modifica]', r).addEventListener('click', function () { modaleLavoro(w); });
      $('[data-elimina]', r).addEventListener('click', function () {
        conferma('Eliminare il lavoro “' + w.title + '”?', 'Elimina', function () { P.works.splice(i, 1); salvaP('Lavoro eliminato.'); disegna(); });
      });
    });
  };

  function modaleLavoro(w) {
    var nuovo = !w;
    var tipiPreventivo = (P.quoteForm.eventTypes || []).map(function (o) { return o.label; });
    var d = w ? copia(w) : { id: nuovoId('w-'), title: '', category: tipiPreventivo[0] || 'Matrimonio', location: '', date: '', season: '', setting: '', cover: '', photos: [], published: true, featured: false, onSite: true, onApp: true };
    var unici = function (l) { var v = {}; l.forEach(function (x) { if ((x || '').trim()) v[x.trim().toLowerCase()] = x.trim(); }); return Object.keys(v).map(function (k) { return v[k]; }); };
    var categorie = unici(P.works.map(function (x) { return x.category; }).concat(tipiPreventivo));
    var luoghi = unici(SUGGERIMENTI_LOCATION.concat(P.works.map(function (x) { return x.setting; })));
    finestra({
      titolo: nuovo ? 'Nuovo lavoro' : 'Modifica lavoro',
      corpo: campo('lv-title', 'Nome dei festeggiati *', d.title, { aiuto: 'Es. "Giulia & Marco" o "I 18 anni di Giorgia".' }) +
        '<datalist id="lv-categorie">' + categorie.map(function (c) { return '<option value="' + esc(c) + '">'; }).join('') + '</datalist>' +
        '<datalist id="lv-luoghi">' + luoghi.map(function (c) { return '<option value="' + esc(c) + '">'; }).join('') + '</datalist>' +
        '<div class="coppia">' + campo('lv-category', 'Tipologia', d.category, { lista: 'lv-categorie' }) + campo('lv-location', 'Location', d.location, { aiuto: 'Es. Sperlonga, Val d\'Orcia.' }) + '</div>' +
        '<div class="coppia">' + campo('lv-date', 'Data', d.date, { aiuto: 'Es. Giugno 2024.' }) +
        '<label class="campo"><span>Stagione</span><select id="lv-season"><option value="">Dalla data</option>' + S54.STAGIONI.map(function (s) { return '<option' + (d.season === s ? ' selected' : '') + '>' + s + '</option>'; }).join('') + '</select></label></div>' +
        campo('lv-setting', 'Tipo di location', d.setting, { lista: 'lv-luoghi', aiuto: 'Serve al filtro "Location" della pagina Lavori.' }) +
        '<h3 id="lv-conto"></h3><p class="nota-piccola" style="margin:-4px 0 10px">Orizzontali e verticali insieme: sul sito si dispongono da sole, nell\'app una sotto l\'altra. La stella sceglie la copertina.</p>' +
        '<div class="griglia-foto piccole" id="lv-foto"></div><p class="errore-accesso" id="lv-err-foto" style="margin-top:8px"></p>' +
        '<div class="aggiungi-foto">' + caricatore('Carica dal computer', 'image/*', true).replace('<label', '<label id="lv-carica"') +
        '<span class="riga-aggiungi" style="margin:0;flex:1;min-width:240px"><span class="campo" style="margin:0"><input id="lv-url" placeholder="Oppure incolla l\'indirizzo di una foto (https://…)"></span><button type="button" class="bottone bordo" id="lv-aggiungi">Aggiungi</button></span></div>' +
        '<h3>Dove si vede</h3>' + interruttore('lv-published', d.published !== false, 'Pubblicato', 'Spento: il lavoro resta qui ma non si vede da nessuna parte.') +
        interruttore('lv-featured', !!d.featured, 'In evidenza nella home', 'Al massimo 4 lavori, sul sito e nell\'app.') +
        interruttore('lv-onSite', d.onSite !== false, 'Sul sito') + interruttore('lv-onApp', d.onApp !== false, 'Nell\'app'),
      dopo: function (c) {
        function foto() {
          var cop = S54.copertina(d);
          $('#lv-conto', c).textContent = 'Foto (' + d.photos.length + ')';
          $('#lv-foto', c).innerHTML = d.photos.map(function (ph, i) {
            return '<figure class="foto-scheda"><div class="foto-scheda-img"><img src="' + esc(miniatura(ph.url, 300)) + '" alt="" loading="lazy">' + (ph.url === cop ? '<span class="segno copertina">Copertina</span>' : '') + '</div>' +
              '<div class="foto-scheda-fondo"><button type="button" class="ico-bottone" data-sx="' + i + '" aria-label="Sposta prima"' + (i ? '' : ' disabled') + '>' + ico('sinistra') + '</button>' +
              '<button type="button" class="ico-bottone" data-cop="' + i + '" aria-label="Usa come copertina">' + ico(ph.url === cop ? 'stella-piena' : 'stella') + '</button>' +
              '<button type="button" class="ico-bottone" data-dx="' + i + '" aria-label="Sposta dopo"' + (i < d.photos.length - 1 ? '' : ' disabled') + '>' + ico('destra') + '</button>' +
              '<button type="button" class="ico-bottone" data-via="' + i + '" aria-label="Togli">' + ico('cestino') + '</button></div></figure>';
          }).join('');
        }
        foto();
        $('#lv-foto', c).addEventListener('click', function (e) {
          var b = e.target.closest('button');
          if (!b) return;
          var sp = function (i, j) { d.photos.splice(j, 0, d.photos.splice(i, 1)[0]); };
          if (b.hasAttribute('data-sx')) sp(+b.getAttribute('data-sx'), +b.getAttribute('data-sx') - 1);
          if (b.hasAttribute('data-dx')) sp(+b.getAttribute('data-dx'), +b.getAttribute('data-dx') + 1);
          if (b.hasAttribute('data-cop')) d.cover = d.photos[+b.getAttribute('data-cop')].url;
          if (b.hasAttribute('data-via')) { var via = d.photos.splice(+b.getAttribute('data-via'), 1)[0]; if (via && via.url === d.cover) d.cover = ''; }
          foto();
        });
        suCaricamento(c, '#lv-carica', function (files) {
          Promise.all(files.map(function (f) { return leggiImmagine(f, 1800); })).then(function (urls) {
            urls.forEach(function (u) { d.photos.push({ id: nuovoId(d.id + '-'), url: u, caption: '' }); });
            foto();
          }).catch(function () { avviso('Questa foto non si riesce a leggere.', true); });
        });
        $('#lv-aggiungi', c).addEventListener('click', function () {
          var u = $('#lv-url', c).value.trim();
          if (!/^https?:\/\/\S+$/.test(u)) { avviso('Incolla un indirizzo che inizi con https://', true); return; }
          d.photos.push({ id: nuovoId(d.id + '-'), url: u, caption: '' });
          $('#lv-url', c).value = '';
          foto();
        });
      },
      azioni: (nuovo ? [] : [{ t: 'Elimina', cls: 'testo rosso', sinistra: true, fn: function () {
        conferma('Eliminare il lavoro “' + d.title + '”?', 'Elimina', function () { P.works = P.works.filter(function (x) { return x.id !== d.id; }); salvaP('Lavoro eliminato.'); disegna(); });
        return false;
      } }]).concat([{ t: 'Annulla' }, { t: 'Salva', cls: 'pieno', fn: function (c) {
        ['title', 'category', 'location', 'date', 'setting'].forEach(function (k) { d[k] = val(c, 'lv-' + k); });
        d.season = $('#lv-season', c).value;
        ['published', 'featured', 'onSite', 'onApp'].forEach(function (k) { d[k] = $('#lv-' + k, c).checked; });
        errore(c, 'lv-title', d.title ? '' : 'Scrivi il nome dei festeggiati');
        $('#lv-err-foto', c).textContent = d.photos.length ? '' : 'Aggiungi almeno una foto.';
        if (!d.title || !d.photos.length) return false;
        if (d.featured && !(w && w.featured) && featured() >= 4) { avviso('Ci sono già 4 lavori in evidenza: togli la stella a uno prima.', true); return false; }
        if (nuovo) P.works.unshift(d); else P.works = P.works.map(function (x) { return x.id === d.id ? d : x; });
        if (!salvaP('Lavoro salvato.')) return false;
        disegna();
      } }])
    });
  }

  /* ======================================================= PREVENTIVO */

  SEZIONE.preventivo = function (p) {
    var f = copia(P.quoteForm);
    f.eventTypes = f.eventTypes || []; f.requests = f.requests || [];
    var acceso = function (k) { return f[k] !== false; };
    function elenco(chiave, titolo, sotto, segnaposto) {
      return '<section class="scheda pannello"><h2>' + titolo + '</h2><p class="tenue">' + sotto + '</p><div data-elenco="' + chiave + '">' + f[chiave].map(function (o, i) {
        return '<div class="voce-elenco' + (o.active === false ? ' spenta' : '') + '" data-i="' + i + '"><span class="interruttore" title="Acceso o spento"><input type="checkbox" data-attiva' + (o.active !== false ? ' checked' : '') + ' aria-label="Mostra ' + esc(o.label) + '"><span></span></span>' +
          '<input type="text" data-nome value="' + esc(o.label) + '" aria-label="Nome della voce">' +
          '<div class="ordina"><button type="button" data-sposta="-1" aria-label="Sposta su"' + (i ? '' : ' disabled') + '>' + ico('su') + '</button><button type="button" data-sposta="1" aria-label="Sposta giù"' + (i < f[chiave].length - 1 ? '' : ' disabled') + '>' + ico('giu') + '</button></div>' +
          '<button type="button" class="ico-bottone" data-via aria-label="Elimina">' + ico('cestino') + '</button></div>';
      }).join('') + '</div><div class="riga-aggiungi"><label class="campo"><span>Nuova voce</span><input data-nuova="' + chiave + '" placeholder="' + segnaposto + '"></label><button type="button" class="bottone bordo" data-aggiungi="' + chiave + '">' + ico('piu') + 'Aggiungi</button></div></section>';
    }
    function d() {
      p.innerHTML = testa('Preventivo', 'Il modulo è lo stesso sul sito e nell\'app. Accendi e spegni ogni parte, aggiungi tipi di evento e richieste: le voci spente restano qui, pronte per quando servono.',
        '<a class="bottone bordo" href="' + S54.url('preventivo') + '" target="_blank" rel="noopener">' + ico('esterno') + 'Vedi il modulo</a>') +
        '<div class="due-colonne"><section class="scheda pannello"><h2>Parti del modulo</h2><p class="tenue">Le parti spente non compaiono.</p>' +
        interruttore('qf-showEvent', acceso('showEvent'), 'Tipo di evento', 'Se c\'è un solo tipo acceso è già scelto.') +
        interruttore('qf-showDate', acceso('showDate'), 'Data') + interruttore('qf-showLocation', acceso('showLocation'), 'Luogo') +
        interruttore('qf-showRequests', acceso('showRequests'), 'Richieste', 'Le voci da toccare: video, album, drone…') +
        interruttore('qf-showMessage', acceso('showMessage'), 'Messaggio', 'Per chiedere qualsiasi altra informazione.') + '</section>' +
        '<section class="scheda pannello"><h2>Contatti chiesti</h2><p class="tenue">Il nome si chiede sempre; serve almeno un recapito tra telefono ed email.</p>' +
        interruttore('qf-nome', true, 'Nome', 'Sempre richiesto.', true) + interruttore('qf-askLastName', acceso('askLastName'), 'Cognome') +
        interruttore('qf-askPhone', acceso('askPhone'), 'Telefono') + interruttore('qf-askEmail', acceso('askEmail'), 'Email') + '</section></div>' +
        '<div class="due-colonne">' + elenco('eventTypes', 'Tipi di evento', 'Per ora solo il matrimonio è acceso.', 'Es. Anniversario') +
        elenco('requests', 'Richieste', 'Le voci che il cliente può toccare.', 'Es. Video in 4K') + '</div>';
      barraSalva(p, function () {
        if (f.eventTypes.concat(f.requests).some(function (o) { return !(o.label || '').trim(); })) { avviso('Dai un nome a tutte le voci (o eliminale).', true); return false; }
        P.quoteForm = f;
        return salvaP('Salvato: il modulo è aggiornato.');
      }, function () { disegna(); });

      ['showEvent', 'showDate', 'showLocation', 'showRequests', 'showMessage', 'askLastName', 'askPhone', 'askEmail'].forEach(function (k) {
        $('#qf-' + k, p).addEventListener('change', function (e) {
          if ((k === 'askPhone' || k === 'askEmail') && !e.target.checked && !acceso(k === 'askPhone' ? 'askEmail' : 'askPhone')) {
            e.target.checked = true;
            avviso('Serve almeno un recapito: telefono o email.', true);
            return;
          }
          f[k] = e.target.checked;
          segnaSporco();
        });
      });
      $$('[data-elenco]', p).forEach(function (box) {
        var l = f[box.getAttribute('data-elenco')];
        $$('.voce-elenco', box).forEach(function (r) {
          var i = +r.getAttribute('data-i');
          $('[data-attiva]', r).addEventListener('change', function (e) { l[i].active = e.target.checked; r.classList.toggle('spenta', !e.target.checked); segnaSporco(); });
          $('[data-nome]', r).addEventListener('input', function (e) { l[i].label = e.target.value; segnaSporco(); });
          $$('[data-sposta]', r).forEach(function (b) { b.addEventListener('click', function () { l.splice(i + +b.getAttribute('data-sposta'), 0, l.splice(i, 1)[0]); segnaSporco(); d(); }); });
          $('[data-via]', r).addEventListener('click', function () { l.splice(i, 1); segnaSporco(); d(); });
        });
      });
      $$('[data-aggiungi]', p).forEach(function (b) {
        var k = b.getAttribute('data-aggiungi'), input = $('[data-nuova="' + k + '"]', p);
        var aggiungi = function () {
          var t = input.value.trim();
          if (!t) return;
          f[k].push({ id: nuovoId(k === 'eventTypes' ? 'ev-' : 'rq-'), label: t, active: true });
          segnaSporco(); d();
        };
        b.addEventListener('click', aggiungi);
        input.addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); aggiungi(); } });
      });
    }
    d();
  };

  /* ========================================== BIOGRAFIA E CONTATTI */

  /** Campo per una foto: anteprima, indirizzo e caricamento dal computer. */
  function campoFoto(id, etichetta, valore) {
    return '<div class="campo"><span>' + etichetta + '</span><div class="campo-foto">' + (valore ? '<img src="' + esc(miniatura(valore, 400)) + '" alt="" id="' + id + '-anteprima">' : '<span class="segnaposto" id="' + id + '-anteprima"></span>') +
      '<div><span class="campo" style="margin-bottom:10px"><input id="' + id + '" value="' + esc((valore || '').indexOf('data:') === 0 ? '' : valore) + '" placeholder="Indirizzo della foto (https://…)"></span>' +
      caricatore('Carica dal computer', 'image/*').replace('<label', '<label id="' + id + '-carica"') + '</div></div></div>';
  }
  function collegaFoto(root, id, imposta) {
    var aggiorna = function (u) {
      var vecchia = $('#' + id + '-anteprima', root), img = document.createElement('img');
      img.id = id + '-anteprima'; img.alt = ''; img.src = miniatura(u, 400);
      vecchia.replaceWith(img);
      imposta(u);
    };
    $('#' + id, root).addEventListener('change', function (e) {
      var u = e.target.value.trim();
      if (u) { aggiorna(u); return; }
      // Campo svuotato: la foto si toglie.
      var vecchia = $('#' + id + '-anteprima', root), vuota = document.createElement('span');
      vuota.className = 'segnaposto'; vuota.id = id + '-anteprima';
      vecchia.replaceWith(vuota);
      imposta('');
    });
    suCaricamento(root, '#' + id + '-carica', function (files) { leggiImmagine(files[0], 1800).then(function (u) { $('#' + id, root).value = ''; aggiorna(u); }); });
  }

  SEZIONE.biografia = function (p) {
    var c = copia(P.content);
    c.timeline = c.timeline || [];
    function d() {
      p.innerHTML = testa('Biografia', 'La pagina "Biografia", uguale sul sito e nell\'app.', '<a class="bottone bordo" href="' + S54.url('biografia') + '" target="_blank" rel="noopener">' + ico('esterno') + 'Vedi la pagina</a>') +
        '<section class="scheda pannello"><h2>La storia</h2><p class="tenue">Il racconto dello studio.</p>' +
        campo('bio-bioTitle', 'Titolo', c.bioTitle || '') + campo('bio-bioIntro', 'Frase in evidenza', c.bioIntro || '', { area: true, righe: 2, aiuto: 'Vai a capo per la seconda riga.' }) +
        campo('bio-bioStory', 'Racconto', c.bioStory || '', { area: true, righe: 8, aiuto: 'Separa i paragrafi con una riga vuota.' }) +
        campoFoto('bio-bioImage', 'Foto accanto al racconto', c.bioImage || '') + '</section>' +
        '<section class="scheda pannello"><h2>Il metodo</h2><p class="tenue">I passaggi del lavoro: numero, titolo e testo.</p>' + c.timeline.map(function (m, i) {
          return '<div class="passo-metodo" data-i="' + i + '"><div class="passo-metodo-testa"><span>Passaggio ' + (i + 1) + '</span><span style="display:flex"><span class="ordina"><button type="button" data-sposta="-1" aria-label="Sposta su"' + (i ? '' : ' disabled') + '>' + ico('su') + '</button><button type="button" data-sposta="1" aria-label="Sposta giù"' + (i < c.timeline.length - 1 ? '' : ' disabled') + '>' + ico('giu') + '</button></span><button type="button" class="ico-bottone" data-via aria-label="Elimina">' + ico('cestino') + '</button></span></div>' +
            '<div class="coppia" style="grid-template-columns:110px 1fr">' + campo('m' + i + '-year', 'Numero', m.year || '') + campo('m' + i + '-title', 'Titolo', m.title || '') + '</div>' + campo('m' + i + '-text', 'Testo', m.text || '', { area: true, righe: 2 }) + '</div>';
        }).join('') + '<button type="button" class="bottone bordo" data-aggiungi>' + ico('piu') + 'Aggiungi passaggio</button></section>';
      barraSalva(p, function () { P.content = c; return salvaP('Biografia salvata.'); }, function () { disegna(); });
      ['bioTitle', 'bioIntro', 'bioStory'].forEach(function (k) { $('#bio-' + k, p).addEventListener('input', function (e) { c[k] = e.target.value; segnaSporco(); }); });
      collegaFoto(p, 'bio-bioImage', function (u) { c.bioImage = u; segnaSporco(); });
      $$('.passo-metodo', p).forEach(function (r) {
        var i = +r.getAttribute('data-i');
        ['year', 'title', 'text'].forEach(function (k) { $('#m' + i + '-' + k, r).addEventListener('input', function (e) { c.timeline[i][k] = e.target.value; segnaSporco(); }); });
        $$('[data-sposta]', r).forEach(function (b) { b.addEventListener('click', function () { c.timeline.splice(i + +b.getAttribute('data-sposta'), 0, c.timeline.splice(i, 1)[0]); segnaSporco(); d(); }); });
        $('[data-via]', r).addEventListener('click', function () { c.timeline.splice(i, 1); segnaSporco(); d(); });
      });
      $('[data-aggiungi]', p).addEventListener('click', function () { c.timeline.push({ year: due(c.timeline.length + 1), title: '', text: '' }); segnaSporco(); d(); });
    }
    d();
  };

  SEZIONE.contatti = function (p) {
    var c = copia(P.content);
    c.contacts = c.contacts || {};
    var k = c.contacts;
    p.innerHTML = testa('Contatti', 'Nome dello studio e recapiti: compaiono in fondo a ogni pagina, sul sito e nell\'app. I campi vuoti non si vedono.') +
      '<section class="scheda pannello"><h2>Lo studio</h2><p class="tenue">Nome e frase di presentazione.</p><div class="coppia">' +
      campo('ct-studioName', 'Nome dello studio', c.studioName || '') + campo('ct-tagline', 'Frase (in alto nella biografia)', c.tagline || '') + '</div></section>' +
      '<section class="scheda pannello"><h2>Recapiti</h2><p class="tenue">Telefono, email, indirizzo e social.</p>' +
      '<div class="coppia">' + campo('ct-phone', 'Telefono', k.phone || '', { tipo: 'tel' }) + campo('ct-whatsapp', 'WhatsApp', k.whatsapp || '', { tipo: 'tel' }) + '</div>' +
      campo('ct-email', 'Email', k.email || '', { tipo: 'email' }) + campo('ct-address', 'Indirizzo', k.address || '') + campo('ct-hours', 'Orari', k.hours || '') +
      '<div class="coppia">' + campo('ct-instagram', 'Instagram (link)', k.instagram || '') + campo('ct-facebook', 'Facebook (link)', k.facebook || '') + '</div>' +
      campo('ct-vat', 'Partita IVA e dati legali', k.vat || '') + '</section>';
    barraSalva(p, function () {
      if (k.email && !EMAIL.test(k.email)) { errore(p, 'ct-email', 'Email non valida'); return false; }
      var ok = true;
      ['instagram', 'facebook'].forEach(function (n) {
        if (/^www\./i.test(k[n] || '')) k[n] = 'https://' + k[n];
        if (k[n] && !/^https?:\/\/\S+$/i.test(k[n])) { errore(p, 'ct-' + n, 'Scrivi un link che inizia con https://'); ok = false; }
      });
      if (!ok) return false;
      P.content = c;
      return salvaP('Contatti salvati.');
    }, function () { disegna(); });
    ['studioName', 'tagline'].forEach(function (n) { $('#ct-' + n, p).addEventListener('input', function (e) { c[n] = e.target.value; segnaSporco(); }); });
    ['phone', 'whatsapp', 'email', 'address', 'hours', 'instagram', 'facebook', 'vat'].forEach(function (n) {
      $('#ct-' + n, p).addEventListener('input', function (e) { k[n] = e.target.value.trim(); errore(p, 'ct-' + n, ''); segnaSporco(); });
    });
  };

  /* ========================================================= CAROSELLI */

  function carosello(p, chiave, verticale) {
    var l = P[chiave];
    p.innerHTML = testa(verticale ? 'Carosello verticale' : 'Carosello orizzontale',
      verticale
        ? '<span class="dove">' + ico('cellulare') + 'Solo nell\'app</span> Le foto riempiono lo schermo del telefono all\'apertura e scorrono da sole, 4 secondi l\'una. Usa foto <b>verticali</b>.'
        : '<span class="dove">' + ico('schermo') + 'Solo sul sito</span> Le foto scorrono a tutto schermo nella home, 4 secondi l\'una, con dissolvenza. Usa foto <b>orizzontali</b>.',
      verticale ? '' : '<a class="bottone bordo" href="' + S54.url('index') + '" target="_blank" rel="noopener">' + ico('esterno') + 'Vedi la home</a>') +
      '<section class="scheda pannello"><div class="griglia-foto' + (verticale ? ' verticali' : '') + '">' + l.map(function (f, i) {
        return '<figure class="foto-scheda' + (f.active === false ? ' spenta' : '') + '" data-i="' + i + '"><div class="foto-scheda-img"><img src="' + esc(miniatura(f.url, 500)) + '" alt="" loading="lazy"><span class="segno avviso-orient" hidden></span></div>' +
          '<div class="foto-scheda-fondo"><span class="interruttore" title="Mostra o nascondi"><input type="checkbox" data-attiva' + (f.active !== false ? ' checked' : '') + ' aria-label="Mostra nel carosello"><span></span></span>' +
          '<span style="display:flex"><button type="button" class="ico-bottone" data-sposta="-1" aria-label="Sposta prima"' + (i ? '' : ' disabled') + '>' + ico('sinistra') + '</button>' +
          '<button type="button" class="ico-bottone" data-sposta="1" aria-label="Sposta dopo"' + (i < l.length - 1 ? '' : ' disabled') + '>' + ico('destra') + '</button>' +
          '<button type="button" class="ico-bottone" data-via aria-label="Togli">' + ico('cestino') + '</button></span></div></figure>';
      }).join('') + '</div>' + (l.length ? '' : '<p class="vuoto">Nessuna foto: aggiungi la prima.</p>') +
      '<div class="aggiungi-foto">' + caricatore('Carica dal computer', 'image/*', true).replace('<label', '<label id="car-carica"') +
      '<span class="riga-aggiungi" style="margin:0;flex:1;min-width:240px"><span class="campo" style="margin:0"><input id="car-url" placeholder="Oppure incolla l\'indirizzo di una foto (https://…)"></span><button type="button" class="bottone bordo" id="car-aggiungi">Aggiungi</button></span></div></section>';

    $$('.foto-scheda', p).forEach(function (s) {
      var i = +s.getAttribute('data-i'), img = $('img', s);
      // Avviso se la foto ha l'orientamento sbagliato per questo carosello.
      var controlla = function () {
        if (!img.naturalWidth) return;
        var oriz = img.naturalWidth > img.naturalHeight, segno = $('.segno', s);
        if (verticale && oriz) { segno.textContent = 'Orizzontale: verrà tagliata'; segno.hidden = false; }
        if (!verticale && !oriz) { segno.textContent = 'Verticale: sul sito si salta'; segno.hidden = false; }
      };
      if (img.complete) controlla(); else img.addEventListener('load', controlla);
      $('[data-attiva]', s).addEventListener('change', function (e) { l[i].active = e.target.checked; salvaP(e.target.checked ? 'Foto mostrata.' : 'Foto nascosta.'); disegna(); });
      $$('[data-sposta]', s).forEach(function (b) { b.addEventListener('click', function () { l.splice(i + +b.getAttribute('data-sposta'), 0, l.splice(i, 1)[0]); salvaP('Ordine salvato.'); disegna(); }); });
      $('[data-via]', s).addEventListener('click', function () { conferma('Togliere questa foto dal carosello?', 'Togli', function () { l.splice(i, 1); salvaP('Foto tolta.'); disegna(); }); });
    });
    suCaricamento(p, '#car-carica', function (files) {
      Promise.all(files.map(function (f) { return leggiImmagine(f, 2200); })).then(function (urls) {
        urls.forEach(function (u) { l.push({ id: nuovoId(verticale ? 'ca' : 'cs'), url: u, active: true }); });
        if (salvaP('Foto aggiunte.')) disegna(); else l.splice(l.length - urls.length, urls.length);
      }).catch(function () { avviso('Questa foto non si riesce a leggere.', true); });
    });
    $('#car-aggiungi', p).addEventListener('click', function () {
      var u = $('#car-url', p).value.trim();
      if (!/^https?:\/\/\S+$/.test(u)) { avviso('Incolla un indirizzo che inizi con https://', true); return; }
      l.push({ id: nuovoId(verticale ? 'ca' : 'cs'), url: u, active: true });
      salvaP('Foto aggiunta.'); disegna();
    });
  }
  SEZIONE['carosello-sito'] = function (p) { carosello(p, 'carouselSite', false); };
  SEZIONE['carosello-app'] = function (p) { carosello(p, 'carouselApp', true); };

  /* ====================================================== AREA CLIENTI */

  SEZIONE.clienti = function (p) {
    p.innerHTML = testa('Area clienti', '<span class="dove">' + ico('cellulare') + 'Solo nell\'app</span> Nessuno può registrarsi da solo: crei tu l\'account, il cliente entra dall\'app (menu → Area clienti) con email o nome utente e la password, guarda le foto e i video della festa e li scarica in alta qualità.',
      '<button type="button" class="bottone pieno" data-nuovo>' + ico('piu') + 'Nuovo cliente</button>') +
      '<section class="scheda senza-margine">' + (Q.clients.map(function (c) {
        var foto = (c.media || []).filter(function (m) { return !m.isVideo; }).length, video = (c.media || []).length - foto;
        return '<button type="button" class="riga" data-id="' + esc(c.id) + '"><span class="iniziali">' + esc(iniziali(c.name)) + '</span><span class="riga-testo"><strong>' + esc(c.name) +
          ' <span class="stato stato-' + (c.active === false ? 'sospeso">Sospeso' : 'attivo">Attivo') + '</span></strong><small>' +
          esc(S54.unisci([c.email, c.eventTitle, foto + ' foto', video ? video + (video === 1 ? ' video' : ' video') : ''])) + '</small></span>' + ico('destra') + '</button>';
      }).join('') || '<p class="vuoto">Nessun cliente. Crea il primo account.</p>') + '</section>';
    $('[data-nuovo]', p).addEventListener('click', function () { modaleCliente(null); });
    $$('[data-id]', p).forEach(function (b) {
      b.addEventListener('click', function () { modaleCliente(Q.clients.filter(function (c) { return c.id === b.getAttribute('data-id'); })[0]); });
    });
  };

  function loginOccupato(login, tranne) {
    var l = (login || '').trim().toLowerCase();
    if (!l) return false;
    if (l === ((Q.admin || {}).username || '').toLowerCase()) return true;
    return Q.clients.some(function (c) {
      return c.id !== tranne && ((c.email || '').toLowerCase() === l || ((c.username || '').toLowerCase() === l));
    });
  }

  function modaleCliente(cl) {
    var nuovo = !cl;
    var d = cl ? copia(cl) : { id: nuovoId('cl-'), name: '', email: '', username: '', phone: '', passwordHash: '', passwordSalt: '', active: true, eventTitle: '', eventDate: '', location: '', welcome: '', media: [], files: [], createdAt: new Date().toISOString(), lastLogin: null };
    d.media = d.media || []; d.files = d.files || []; d.folders = d.folders || [];
    finestra({
      titolo: nuovo ? 'Nuovo cliente' : d.name,
      corpo: '<div class="coppia">' + campo('cl-name', 'Nome e cognome *', d.name) + campo('cl-email', 'Email *', d.email, { tipo: 'email', aiuto: 'Serve per entrare nell\'app.' }) + '</div>' +
        '<div class="coppia">' + campo('cl-username', 'Nome utente (facoltativo)', d.username, { aiuto: 'In alternativa all\'email, es. anna.paolo.' }) + campo('cl-phone', 'Telefono', d.phone, { tipo: 'tel', aiuto: 'Per mandargli i dati su WhatsApp.' }) + '</div>' +
        campo('cl-eventTitle', 'Evento', d.eventTitle, { aiuto: 'Es. "Il matrimonio di Anna e Paolo".' }) +
        '<div class="coppia">' + campo('cl-eventDate', 'Data', d.eventDate, { aiuto: 'Es. 18 maggio 2024.' }) + campo('cl-location', 'Luogo', d.location) + '</div>' +
        campo('cl-welcome', 'Benvenuto nella sua area', d.welcome, { area: true, righe: 2 }) +
        (nuovo ? '' : interruttore('cl-active', d.active !== false, 'Accesso attivo', 'Spento: il cliente non può più entrare.')) +
        '<h3 id="cl-conto"></h3><p class="nota-piccola" style="margin:-4px 0 10px">Il cliente li guarda nell\'app e li scarica sul telefono in alta qualità, uno alla volta.</p>' +
        '<p class="etichetta-campo">Cartelle</p><p class="nota-piccola" style="margin:-6px 0 8px">Per dividere foto e video in sezioni (es. Preparativi, Cerimonia, Festa). Sotto ogni foto scegli la sua cartella.</p><div class="cartelle" id="cl-cartelle"></div>' +
        '<div class="riga-aggiungi" style="margin:6px 0 16px"><span class="campo"><input id="cl-nuova-cartella" placeholder="Nuova cartella (es. Cerimonia)"></span><button type="button" class="bottone bordo" id="cl-aggiungi-cartella">' + ico('piu') + 'Crea cartella</button></div>' +
        '<div class="griglia-foto piccole" id="cl-media"></div>' +
        '<div class="aggiungi-foto">' + caricatore('Carica foto', 'image/*', true).replace('<label', '<label id="cl-carica"') +
        '<label class="campo" style="margin:0;min-width:200px"><select id="cl-da-lavoro"><option value="">Prendi le foto di un lavoro…</option>' + P.works.map(function (w) { return '<option value="' + esc(w.id) + '">' + esc(w.title) + '</option>'; }).join('') + '</select></label></div>' +
        '<div class="coppia" style="margin-top:12px">' + campo('cl-foto-url', 'Indirizzo di una foto (originale)', '', { attr: ' placeholder="https://…"' }) +
        '<div class="campo"><span>&nbsp;</span><button type="button" class="bottone bordo" id="cl-foto-aggiungi">Aggiungi foto</button></div></div>' +
        '<div class="coppia">' + campo('cl-video-url', 'Indirizzo di un video (mp4)', '', { attr: ' placeholder="https://…/video.mp4"' }) + campo('cl-video-poster', 'Foto di anteprima del video', '', { attr: ' placeholder="https://…"' }) + '</div>' +
        '<button type="button" class="bottone bordo" id="cl-video-aggiungi">' + ico('video') + 'Aggiungi video</button>' +
        '<h3 id="cl-conto-file"></h3><div id="cl-file"></div>' +
        '<div class="aggiungi-foto">' + caricatore('Carica PDF', 'application/pdf').replace('<label', '<label id="cl-pdf"') + '</div>' +
        '<div class="coppia">' + campo('cl-link-nome', 'Nome del link', '', { attr: ' placeholder="Es. Galleria su Google Drive"' }) + campo('cl-link-url', 'Indirizzo', '', { attr: ' placeholder="https://…"' }) + '</div>' +
        '<button type="button" class="bottone bordo" id="cl-link-aggiungi">' + ico('link') + 'Aggiungi link</button>',
      dopo: function (c) {
        function cartelle() {
          $('#cl-cartelle', c).innerHTML = d.folders.length ? d.folders.map(function (f, k) {
            var n = d.media.filter(function (m) { return m.folder === f.id; }).length;
            return '<span class="cartella-voce"><i class="ico ico-cartella"></i><input data-rinomina="' + k + '" value="' + esc(f.name) + '" aria-label="Nome della cartella"><small>' + n + '</small><button type="button" class="ico-bottone" data-via-cartella="' + k + '" aria-label="Elimina la cartella">' + ico('cestino') + '</button></span>';
          }).join('') : '<p class="tenue piccolo">Nessuna cartella: le foto si vedono tutte insieme.</p>';
        }
        function media() {
          cartelle();
          var foto = d.media.filter(function (m) { return !m.isVideo; }).length;
          $('#cl-conto', c).textContent = 'Foto e video (' + foto + ' foto, ' + (d.media.length - foto) + ' video)';
          $('#cl-media', c).innerHTML = d.media.map(function (m, i) {
            var anteprima = m.isVideo ? m.poster : m.url;
            return '<figure class="foto-scheda"><div class="foto-scheda-img">' + (anteprima ? '<img src="' + esc(miniatura(anteprima, 300)) + '" alt="" loading="lazy">' : '') + (m.isVideo ? '<span class="segno video">' + ico('video') + 'Video</span>' : '') + '</div>' +
              '<div class="foto-scheda-fondo"><button type="button" class="ico-bottone" data-sx="' + i + '" aria-label="Sposta prima"' + (i ? '' : ' disabled') + '>' + ico('sinistra') + '</button>' +
              '<button type="button" class="ico-bottone" data-dx="' + i + '" aria-label="Sposta dopo"' + (i < d.media.length - 1 ? '' : ' disabled') + '>' + ico('destra') + '</button>' +
              '<button type="button" class="ico-bottone" data-via="' + i + '" aria-label="Togli">' + ico('cestino') + '</button></div>' +
              (d.folders.length ? '<select class="scegli-cartella" data-cartella="' + i + '" aria-label="Cartella"><option value="">Senza cartella</option>' + d.folders.map(function (f) { return '<option value="' + esc(f.id) + '"' + (m.folder === f.id ? ' selected' : '') + '>' + esc(f.name || 'Senza nome') + '</option>'; }).join('') + '</select>' : '') + '</figure>';
          }).join('');
        }
        function file() {
          $('#cl-conto-file', c).textContent = 'Documenti e link (' + d.files.length + ')';
          $('#cl-file', c).innerHTML = d.files.map(function (f, i) {
            return '<div class="riga file-riga" data-f="' + i + '"><span class="file-tipo">' + (f.isLink ? 'LINK' : 'PDF') + '</span><span class="riga-testo"><strong>' + esc(f.name) + '</strong><small>' + esc(f.isLink ? f.url : 'Documento caricato') + '</small></span>' +
              '<button type="button" class="ico-bottone" data-via-file="' + i + '" aria-label="Togli">' + ico('cestino') + '</button></div>';
          }).join('');
        }
        media(); file();
        $('#cl-media', c).addEventListener('change', function (e) {
          var s = e.target.closest('[data-cartella]');
          if (s) { d.media[+s.getAttribute('data-cartella')].folder = s.value; cartelle(); }
        });
        $('#cl-cartelle', c).addEventListener('input', function (e) {
          var r = e.target.closest('[data-rinomina]');
          if (r) d.folders[+r.getAttribute('data-rinomina')].name = r.value;
        });
        $('#cl-cartelle', c).addEventListener('change', function () { media(); });
        $('#cl-cartelle', c).addEventListener('click', function (e) {
          var b = e.target.closest('[data-via-cartella]');
          if (!b) return;
          // Le foto della cartella eliminata restano, fuori dalle cartelle.
          var via = d.folders.splice(+b.getAttribute('data-via-cartella'), 1)[0];
          d.media.forEach(function (m) { if (m.folder === via.id) m.folder = ''; });
          media();
        });
        var nuovaCartella = function () {
          var n = val(c, 'cl-nuova-cartella');
          if (!n) return;
          d.folders.push({ id: nuovoId(d.id + '-c'), name: n });
          $('#cl-nuova-cartella', c).value = '';
          media();
        };
        $('#cl-aggiungi-cartella', c).addEventListener('click', nuovaCartella);
        $('#cl-nuova-cartella', c).addEventListener('keydown', function (e) { if (e.key === 'Enter') { e.preventDefault(); nuovaCartella(); } });
        $('#cl-media', c).addEventListener('click', function (e) {
          var b = e.target.closest('button');
          if (!b) return;
          var sp = function (i, j) { d.media.splice(j, 0, d.media.splice(i, 1)[0]); };
          if (b.hasAttribute('data-sx')) sp(+b.getAttribute('data-sx'), +b.getAttribute('data-sx') - 1);
          if (b.hasAttribute('data-dx')) sp(+b.getAttribute('data-dx'), +b.getAttribute('data-dx') + 1);
          if (b.hasAttribute('data-via')) d.media.splice(+b.getAttribute('data-via'), 1);
          media();
        });
        $('#cl-file', c).addEventListener('click', function (e) {
          var b = e.target.closest('[data-via-file]');
          if (b) { d.files.splice(+b.getAttribute('data-via-file'), 1); file(); }
        });
        suCaricamento(c, '#cl-carica', function (files) {
          Promise.all(files.map(function (f) { return leggiImmagine(f, 2400).then(function (u) { return { u: u, n: f.name }; }); })).then(function (l) {
            l.forEach(function (x) { d.media.push({ id: nuovoId(d.id + '-m'), url: x.u, original: x.u, isVideo: false, poster: '', name: x.n }); });
            media();
          }).catch(function () { avviso('Questa foto non si riesce a leggere.', true); });
        });
        $('#cl-da-lavoro', c).addEventListener('change', function (e) {
          var w = P.works.filter(function (x) { return x.id === e.target.value; })[0];
          e.target.value = '';
          if (!w) return;
          (w.photos || []).forEach(function (ph, i) {
            d.media.push({ id: nuovoId(d.id + '-m'), url: ph.url, original: ph.url, isVideo: false, poster: '', name: w.id.replace(/^w-/, '') + '-' + ('00' + (i + 1)).slice(-3) + '.jpg' });
          });
          if (!d.eventTitle) $('#cl-eventTitle', c).value = w.title;
          media();
        });
        $('#cl-foto-aggiungi', c).addEventListener('click', function () {
          var u = val(c, 'cl-foto-url');
          if (!/^https?:\/\/\S+$/.test(u)) { errore(c, 'cl-foto-url', 'Deve iniziare con https://'); return; }
          errore(c, 'cl-foto-url', '');
          d.media.push({ id: nuovoId(d.id + '-m'), url: u, original: u, isVideo: false, poster: '', name: '' });
          $('#cl-foto-url', c).value = '';
          media();
        });
        $('#cl-video-aggiungi', c).addEventListener('click', function () {
          var u = val(c, 'cl-video-url'), po = val(c, 'cl-video-poster');
          if (!/^https?:\/\/\S+$/.test(u)) { errore(c, 'cl-video-url', 'Deve iniziare con https://'); return; }
          errore(c, 'cl-video-url', '');
          d.media.push({ id: nuovoId(d.id + '-v'), url: u, original: '', isVideo: true, poster: po, name: '' });
          $('#cl-video-url', c).value = ''; $('#cl-video-poster', c).value = '';
          media();
        });
        suCaricamento(c, '#cl-pdf', function (files) {
          var f = files[0];
          if (f.size > 2 * 1024 * 1024) { avviso('Il PDF è troppo grande per la prova (max 2 MB): caricalo su Google Drive e aggiungilo come link.', true); return; }
          leggiFile(f).then(function (u) { d.files.push({ id: nuovoId(d.id + '-f'), name: f.name.replace(/\.pdf$/i, ''), url: u, isLink: false, note: '', addedAt: new Date().toISOString() }); file(); });
        });
        $('#cl-link-aggiungi', c).addEventListener('click', function () {
          var n = val(c, 'cl-link-nome'), u = val(c, 'cl-link-url');
          errore(c, 'cl-link-nome', n ? '' : 'Scrivi un nome');
          errore(c, 'cl-link-url', /^https?:\/\/\S+$/.test(u) ? '' : 'Deve iniziare con https://');
          if (!n || !/^https?:\/\/\S+$/.test(u)) return;
          d.files.push({ id: nuovoId(d.id + '-f'), name: n, url: u, isLink: true, note: '', addedAt: new Date().toISOString() });
          $('#cl-link-nome', c).value = ''; $('#cl-link-url', c).value = '';
          file();
        });
      },
      azioni: (nuovo ? [] : [
        { t: 'Elimina', cls: 'testo rosso', sinistra: true, fn: function () {
          conferma('Eliminare ' + d.name + '? Non potrà più entrare e foto, video e documenti della sua area verranno tolti.', 'Elimina', function () {
            Q.clients = Q.clients.filter(function (x) { return x.id !== d.id; });
            salvaQ('Cliente eliminato.'); disegna();
          });
          return false;
        } },
        { t: 'Nuova password', fn: function () {
          conferma('Generare una nuova password per ' + d.name + '? Quella attuale smetterà di funzionare.', 'Genera', function () {
            var pw = generaPassword(), s = sale();
            return sha256(s + '::' + pw).then(function (h) {
              Q.clients.forEach(function (x) { if (x.id === d.id) { x.passwordSalt = s; x.passwordHash = h; } });
              salvaQ(false);
              credenziali(Q.clients.filter(function (x) { return x.id === d.id; })[0], pw, false);
              return false;
            });
          });
          return false;
        } }
      ]).concat([{ t: 'Annulla' }, { t: nuovo ? 'Crea account' : 'Salva', cls: 'pieno', fn: function (c) {
        ['name', 'email', 'username', 'phone', 'eventTitle', 'eventDate', 'location', 'welcome'].forEach(function (k) { d[k] = val(c, 'cl-' + k); });
        if (!nuovo) d.active = $('#cl-active', c).checked;
        var ok = true;
        var e1 = d.name.length < 2 ? 'Scrivi nome e cognome' : '';
        var e2 = !EMAIL.test(d.email) ? 'Email non valida' : (loginOccupato(d.email, d.id) ? 'Questa email è già usata da un altro account' : '');
        var e3 = d.username && (/\s/.test(d.username) ? 'Senza spazi' : (loginOccupato(d.username, d.id) ? 'Questo nome utente è già usato' : ''));
        errore(c, 'cl-name', e1); errore(c, 'cl-email', e2); errore(c, 'cl-username', e3 || '');
        if (e1 || e2 || e3) ok = false;
        if (!ok) { c.scrollTop = 0; return false; }
        if (!nuovo) {
          Q.clients = Q.clients.map(function (x) { return x.id === d.id ? d : x; });
          if (salvaQ('Cliente salvato.')) disegna();
          return;
        }
        var pw = generaPassword();
        d.passwordSalt = sale();
        return sha256(d.passwordSalt + '::' + pw).then(function (h) {
          d.passwordHash = h;
          Q.clients.unshift(d);
          if (!salvaQ(false)) { Q.clients.shift(); return false; }
          disegna();
          credenziali(d, pw, true);
          return false;
        });
      } }])
    });
  }

  /** I dati da mandare al cliente: la password si vede solo qui. */
  function credenziali(c, pw, creato) {
    var nome = (c.name || '').trim().split(/\s+/)[0];
    var msg = 'Ciao ' + nome + ',\nle foto e i video del vostro evento sono pronti nella vostra area riservata di ' + (P.content.studioName || 'Studio 54') + '.\n\n' +
      'Aprite l\'app ' + (P.content.studioName || 'Studio 54') + ', toccate il menu e poi "Area clienti", ed entrate con:\n' +
      'Email: ' + c.email + '\n' + (c.username ? 'oppure nome utente: ' + c.username + '\n' : '') + 'Password: ' + pw + '\n\n' +
      'Da lì potete guardare e scaricare tutto in alta qualità.';
    var tel = (c.phone || '').replace(/\D/g, '');
    finestra({
      titolo: creato ? 'Account creato' : 'Nuova password', fuoco: false,
      corpo: '<p class="tenue">Manda questi dati al cliente. La password non si potrà più rivedere: se la perde, ne generi una nuova.</p><textarea class="messaggio-cliente" id="cred-msg" readonly>' + esc(msg) + '</textarea>',
      azioni: [{ t: 'Chiudi' }].concat(tel ? [{ t: 'WhatsApp', cls: 'bordo', resta: true, fn: function () { window.open('https://wa.me/' + tel + '?text=' + encodeURIComponent(msg), '_blank'); } }] : [])
        .concat([{ t: 'Email', cls: 'bordo', resta: true, fn: function () { window.open('mailto:' + c.email + '?subject=' + encodeURIComponent('La vostra area riservata') + '&body=' + encodeURIComponent(msg)); } },
          { t: 'Copia', cls: 'pieno', resta: true, fn: function (corpo) {
            var t = $('#cred-msg', corpo);
            var fatto = function () { avviso('Messaggio copiato.'); };
            if (navigator.clipboard) navigator.clipboard.writeText(msg).then(fatto, function () { t.select(); document.execCommand('copy'); fatto(); });
            else { t.select(); document.execCommand('copy'); fatto(); }
          } }])
    });
  }

  /* ====================================================== IMPOSTAZIONI */

  SEZIONE.impostazioni = function (p) {
    var ad = Q.admin || {};
    p.innerHTML = testa('Impostazioni', 'Accesso, copia di sicurezza e dati d\'esempio.') +
      '<div class="due-colonne"><section class="scheda pannello"><h2>Accesso al gestionale</h2><p class="tenue">Valgono qui e nell\'app (menu → Area clienti).</p><form id="form-credenziali" novalidate>' +
      campo('im-utente', 'Nome utente', ad.username || '', { attr: ' autocomplete="username"' }) + campo('im-attuale', 'Password attuale', '', { tipo: 'password', attr: ' autocomplete="current-password"' }) +
      '<div class="coppia">' + campo('im-nuova', 'Nuova password', '', { tipo: 'password', attr: ' autocomplete="new-password"', aiuto: 'Almeno 8 caratteri.' }) + campo('im-ripeti', 'Ripeti la nuova password', '', { tipo: 'password', attr: ' autocomplete="new-password"' }) + '</div>' +
      '<button type="submit" class="bottone pieno">Salva l\'accesso</button></form></section>' +
      '<section class="scheda pannello"><h2>Copia di sicurezza</h2><p class="tenue">Scarica tutti i dati in un file, o ricaricali da una copia.</p><div class="azioni">' +
      '<button type="button" class="bottone bordo" id="im-scarica">' + ico('scarica') + 'Scarica la copia</button>' + caricatore('Carica una copia', 'application/json,.json').replace('<label', '<label id="im-carica"') + '</div>' +
      '<h2 style="margin-top:26px">Dati d\'esempio</h2><p class="tenue" style="margin:2px 0 14px">Cancella le modifiche fatte in questo browser e torna ai lavori e ai testi d\'esempio.</p>' +
      '<button type="button" class="bottone testo rosso" id="im-esempi">Torna agli esempi</button>' +
      '<h2 style="margin-top:26px">Database</h2><p class="tenue" style="margin:2px 0 0">Per ora i dati restano in questo browser. Quando collegheremo il database (Cloudflare) ogni modifica arriverà subito al sito e all\'app di tutti.</p></section></div>';
    $('#form-credenziali', p).addEventListener('submit', function (e) {
      e.preventDefault();
      var u = val(p, 'im-utente'), att = $('#im-attuale', p).value, n = $('#im-nuova', p).value, r = $('#im-ripeti', p).value;
      errore(p, 'im-utente', u.length < 3 || /\s/.test(u) ? 'Almeno 3 caratteri, senza spazi' : (Q.clients.some(function (c) { return [c.email, c.username].map(function (x) { return (x || '').toLowerCase(); }).indexOf(u.toLowerCase()) >= 0; }) ? 'È già usato da un cliente' : ''));
      errore(p, 'im-nuova', n && n.length < 8 ? 'Almeno 8 caratteri' : '');
      errore(p, 'im-ripeti', n !== r ? 'Le due password non coincidono' : '');
      // L'errore sulla password attuale si ricontrolla a ogni invio.
      errore(p, 'im-attuale', att ? '' : 'Scrivi la password attuale');
      if ($$('.campo.sbagliato', p).length) return;
      sha256((ad.passwordSalt || '') + '::' + att).then(function (h) {
        if (h !== ad.passwordHash) { errore(p, 'im-attuale', 'Password attuale non corretta'); return; }
        errore(p, 'im-attuale', '');
        var fine = function () { ad.username = u; Q.admin = ad; salvaQ('Accesso aggiornato.'); disegna(); };
        if (!n) { fine(); return; }
        ad.passwordSalt = sale();
        sha256(ad.passwordSalt + '::' + n).then(function (h2) { ad.passwordHash = h2; fine(); });
      });
    });
    $('#im-scarica', p).addEventListener('click', function () {
      var blob = new Blob([JSON.stringify({ versione: 2, pubblici: P, privati: Q }, null, 1)], { type: 'application/json' });
      var a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'studio54-copia-' + giornoIso(new Date()) + '.json';
      document.body.appendChild(a); a.click(); a.remove();
      setTimeout(function () { URL.revokeObjectURL(a.href); }, 2000);
    });
    suCaricamento(p, '#im-carica', function (files) {
      var r = new FileReader();
      r.onload = function () {
        try {
          var j = JSON.parse(r.result), pub, pri;
          if (j && j.pubblici && j.privati) { pub = j.pubblici; pri = j.privati; }
          // Copia fatta dall'app: tutte le sezioni allo stesso livello, senza l'accesso.
          else if (j && j.content && Array.isArray(j.works)) { pub = j; pri = { quotes: j.quotes, appointments: j.appointments, clients: j.clients }; }
          else throw new Error();
          if (!Array.isArray(pub.works) || (pri.clients && !Array.isArray(pri.clients))) throw new Error();
          var nuoviP = {
            content: Object.assign({}, pub.content || P.content),
            carouselSite: pub.carouselSite || P.carouselSite, carouselApp: pub.carouselApp || P.carouselApp,
            works: pub.works, quoteForm: pub.quoteForm || P.quoteForm
          };
          nuoviP.content.contacts = nuoviP.content.contacts || {};
          var nuoviQ = {
            quotes: pri.quotes || [], appointments: pri.appointments || [], clients: pri.clients || [],
            admin: pri.admin && pri.admin.passwordHash ? pri.admin : Q.admin
          };
          conferma('Sostituire tutti i dati con quelli della copia?', 'Sostituisci', function () {
            P = nuoviP; Q = nuoviQ;
            if (salvaP('Copia caricata.') && salvaQ(false)) disegna();
          });
        } catch (e) { avviso('Questo file non è una copia di sicurezza valida.', true); }
      };
      r.readAsText(files[0]);
    });
    $('#im-esempi', p).addEventListener('click', function () {
      conferma('Tornare ai dati d\'esempio? Le modifiche fatte in questo browser verranno cancellate.', 'Torna agli esempi', function () { S54.ripristina(); location.reload(); });
    });
  };

  disegna();
})();
