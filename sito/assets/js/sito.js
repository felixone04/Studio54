/* Studio 54 · il sito pubblico (senza librerie).
   Disegna le pagine con i dati di S54 (assets/js/dati.js) e ne gestisce il
   comportamento: logo d'apertura, barra, menu, carosello, filtri, foto a
   schermo intero e modulo preventivo. */
(function () {
  'use strict';

  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var esc = S54.esc;
  var D = S54.pubblici();
  var C = D.content;
  var K = C.contacts;
  var due = function (n) { return (n < 10 ? '0' : '') + n; };
  var cifre = function (t) { return (t || '').replace(/[^0-9+]/g, ''); };
  var maiuscolo = function (t) { return (t || '').toLocaleUpperCase('it-IT'); };
  var FRECCIA_S = '<svg viewBox="0 0 24 24"><path d="m14.5 6-6 6 6 6"/></svg>';
  var FRECCIA_D = '<svg viewBox="0 0 24 24"><path d="m9.5 6 6 6-6 6"/></svg>';
  // La foto a schermo intero si chiede grande quanto lo schermo (fino all'8K).
  var LARGA = Math.max(2400, Math.min(7680, Math.round(Math.max(screen.width, screen.height) * (window.devicePixelRatio || 1))));

  /* ================================================= PARTI COMUNI A TUTTE */

  var menuContatti = $('[data-menu-contatti]');
  if (menuContatti) {
    menuContatti.innerHTML =
      (K.phone ? '<a href="tel:' + esc(cifre(K.phone)) + '">' + esc(K.phone) + '</a>' : '') +
      (K.email ? '<a href="mailto:' + esc(K.email) + '">' + esc(K.email) + '</a>' : '');
  }

  var piede = $('[data-piede]');
  if (piede) {
    // Solo indirizzi web veri (http/https): mai "javascript:" o simili.
    var web = function (u) { u = (u || '').trim(); if (/^www\./i.test(u)) u = 'https://' + u; return /^https?:\/\/\S+$/i.test(u) ? u : ''; };
    var link = function (t, h, fuori) { return '<a class="link" href="' + esc(h) + '"' + (fuori ? ' target="_blank" rel="noopener"' : '') + '>' + esc(t) + '</a>'; };
    var wa = (K.whatsapp || '').replace(/\D/g, '');
    piede.innerHTML = '<div class="piede-dentro"><div class="piede-colonne">' +
      '<div><h3>SCRIVETECI</h3>' + (K.email ? link(K.email, 'mailto:' + K.email) : '') + (K.phone ? link(K.phone, 'tel:' + cifre(K.phone)) : '') + (wa ? link('WhatsApp', 'https://wa.me/' + wa, true) : '') + '</div>' +
      '<div><h3>STUDIO</h3>' + (K.address ? link(K.address, 'https://www.google.com/maps/search/?api=1&query=' + encodeURIComponent(K.address), true) : '') + (K.hours ? '<p>' + esc(K.hours) + '</p>' : '') + '</div>' +
      '<div><h3>SOCIAL</h3>' + (web(K.instagram) ? link('Instagram', web(K.instagram), true) : '') + (web(K.facebook) ? link('Facebook', web(K.facebook), true) : '') + '</div>' +
      '<div><h3>ESPLORA</h3>' + link('Home', S54.url('index')) + link('Lavori', S54.url('lavori')) + link('Biografia', S54.url('biografia')) + link('Preventivo', S54.url('preventivo')) + '</div>' +
      '</div><img class="piede-logo" src="assets/img/logo.png" alt="' + esc(C.studioName || 'Studio 54') + '">' +
      '<div class="piede-fondo"><span>&copy; ' + new Date().getFullYear() + ' ' + esc(C.studioName || '') + (K.vat ? '  ·  ' + esc(K.vat) : '') + '</span>' +
      '<span class="piede-link"><span class="punto"></span><a class="link" href="' + S54.url('riservata') + '">Area riservata</a></span></div></div>';
  }

  if (S54.inBozza()) {
    // Il titolare vede subito le modifiche fatte dal gestionale (solo qui).
    var avviso = document.createElement('div');
    avviso.className = 'avviso-bozza';
    avviso.innerHTML = '<span>Stai vedendo le modifiche del gestionale (solo in questo browser).</span><a href="' + S54.url('riservata') + '">Gestionale</a>';
    document.body.appendChild(avviso);
  }

  /** La scheda di un lavoro: foto principale, nome, location e tipologia. */
  function scheda(w) {
    return '<a class="scheda-lavoro rivela" href="' + S54.url('lavoro', w.id) + '"' +
      ' data-evento="' + esc((w.category || '').trim().toLowerCase()) + '"' +
      ' data-stagione="' + esc(S54.stagione(w).toLowerCase()) + '"' +
      ' data-location="' + esc((w.setting || '').trim().toLowerCase()) + '">' +
      '<span class="scheda-foto"><img ' + S54.srcset(S54.copertina(w), '(max-width: 599px) 100vw, (min-aspect-ratio: 2/1) 34vw, 50vw') + ' alt="" loading="lazy"></span>' +
      '<span class="scheda-nome">' + esc(w.title) + '</span>' +
      '<span class="scheda-info">' + esc(S54.unisci([w.location, w.category])) + '</span></a>';
  }

  /* ===================================================== DISEGNO PAGINE */

  var pagina = document.body.getAttribute('data-pagina');

  // Home: il carosello e i lavori in evidenza.
  var carosello = $('[data-carosello]');
  // Schermo in orizzontale: le foto orizzontali. In verticale (telefono,
  // tablet, monitor girato): quelle verticali, come nell'app. Manca una serie:
  // si usa l'altra.
  var orizzontale = window.matchMedia('(min-aspect-ratio: 1/1)');
  var fotoAttive = function (l) { return (l || []).filter(function (p) { return p.active !== false && (p.url || '').trim(); }); };
  var serieGiusta = function () { return fotoAttive(orizzontale.matches ? D.carouselSite : D.carouselApp).length > 0; };
  function disegnaCarosello() {
    var orizz = orizzontale.matches;
    if (!serieGiusta()) orizz = !orizz;
    var foto = fotoAttive(orizz ? D.carouselSite : D.carouselApp);
    carosello.innerHTML = foto.map(function (p, i) {
      // La stessa foto, sfocata, ai lati sui monitor molto larghi (vedi CSS).
      var sf = (p.url || '').indexOf('data:') === 0 ? '' : ' style="--sf:url(&quot;' + esc(S54.foto(p.url, 800)) + '&quot;)"';
      return '<figure class="diapo' + (i === 0 ? ' attiva' : '') + '"' + sf + '><img ' + S54.srcset(p.url, '(min-aspect-ratio: 1/1) 100vw, 120vw') + ' alt=""' + (i > 1 ? ' loading="lazy"' : '') + '></figure>';
    }).join('') + (foto.length > 1 ? '<div class="apertura-frecce"><button class="tondo chiaro ap-prec" type="button" aria-label="Foto precedente">' + FRECCIA_S + '</button><button class="tondo chiaro ap-succ" type="button" aria-label="Foto successiva">' + FRECCIA_D + '</button></div>' : '');
    carosello.hidden = !foto.length;
    document.body.classList.toggle('senza-apertura', !foto.length);
  }
  if (carosello) disegnaCarosello();
  var evidenza = $('[data-evidenza]');
  if (evidenza) {
    var scelti = S54.inEvidenza(D);
    evidenza.innerHTML = scelti.length ? '<div class="lavori-griglia">' + scelti.map(scheda).join('') + '</div>' : '';
    if (!scelti.length) evidenza.hidden = true;
  }

  // Lavori: i filtri e tutte le schede.
  var lavoriBox = $('[data-lavori]');
  if (lavoriBox) {
    var lavori = S54.lavoriSito(D);
    var valori = function (leggi, ordine) {
      var v = {};
      lavori.forEach(function (w) { var x = (leggi(w) || '').trim(); if (x && !v[x.toLowerCase()]) v[x.toLowerCase()] = x; });
      var l = Object.keys(v).map(function (k) { return v[k]; });
      if (ordine) l.sort(function (a, b) { return ordine.indexOf(a) - ordine.indexOf(b); });
      return l;
    };
    var filtri = [
      ['evento', 'Evento', valori(function (w) { return w.category; })],
      ['stagione', 'Stagione', valori(S54.stagione, S54.STAGIONI)],
      ['location', 'Location', valori(function (w) { return w.setting; })]
    ].filter(function (f) { return f[2].length > 1; });
    lavoriBox.innerHTML = (filtri.length ? '<div class="filtri" data-filtri><div class="filtri-voci">' + filtri.map(function (f) {
      var opz = f[2].map(function (v) { return '<li role="option" data-v="' + esc(v.toLowerCase()) + '">' + esc(v) + '</li>'; }).join('');
      var testi = f[2].map(function (v) { return '<span data-v="' + esc(v.toLowerCase()) + '">' + esc(v) + '</span>'; }).join('');
      return '<div class="filtro" data-filtro="' + f[0] + '"><button type="button" class="filtro-voce" aria-haspopup="listbox" aria-expanded="false">' +
        '<span class="filtro-nome">' + maiuscolo(f[1]) + '</span><span class="filtro-valore"><span class="visibile" data-v="">Tutti</span>' + testi + '</span><span class="filtro-freccia" aria-hidden="true"></span></button>' +
        '<ul class="filtro-menu" role="listbox" hidden><li role="option" data-v="" aria-selected="true">Tutti</li>' + opz + '</ul></div>';
    }).join('') + '</div><div class="filtri-esito" hidden><span class="contatore filtri-conto"></span><button type="button" class="link filtri-azzera">AZZERA</button></div></div>' : '') +
      (lavori.length ? '<div class="lavori-griglia">' + lavori.map(scheda).join('') + '</div>' : '<p class="vuoto">Presto qui i nostri lavori.</p>') +
      '<p class="vuoto filtri-nessuno" hidden>Nessun lavoro con questi filtri.</p>';
  }

  // Un lavoro: solo le sue foto.
  var collageBox = $('[data-collage]');
  if (collageBox) {
    var id = new URLSearchParams(location.search).get('id');
    var w = S54.lavoriSito(D).filter(function (x) { return x.id === id; })[0];
    if (!w || !(w.photos || []).length) {
      collageBox.classList.add('lavoro-assente');
      collageBox.innerHTML = '<p>Questo lavoro non è più in mostra.</p><a class="link etichetta" href="' + S54.url('lavori') + '">&larr; TUTTI I LAVORI</a>';
    } else {
      document.title = w.title + ' · ' + (C.studioName || 'Studio 54');
      collageBox.innerHTML = w.photos.map(function (p, i) {
        return '<figure class="tavola" data-foto="' + esc(S54.foto(p.url, LARGA)) + '" tabindex="0" role="button" aria-label="' + esc(p.caption || 'Foto ' + (i + 1)) + '">' +
          '<img ' + S54.srcset(p.url, i === 0 ? '100vw' : '(max-aspect-ratio: 1/1) 100vw, 70vw') + ' alt="' + esc(p.caption || '') + '"></figure>';
      }).join('');
    }
  }

  // Biografia.
  var bioBox = $('[data-biografia]');
  if (bioBox) {
    var paragrafi = (C.bioStory || '').split(/\n\s*\n/).map(function (p) { return p.trim(); }).filter(Boolean);
    var metodo = C.timeline || [];
    bioBox.innerHTML = '<section class="sezione bio"><div class="bio-griglia"><div class="bio-testo">' +
      '<p class="etichetta entra"><span class="trattino"></span>' + esc(maiuscolo(C.tagline || 'Chi siamo')) + '</p>' +
      '<h1 class="titolo-grande entra">' + esc(maiuscolo(C.bioTitle || '')) + '</h1>' +
      (C.bioIntro ? '<p class="sottotitolo grande entra">' + esc(C.bioIntro).replace(/\n/g, '<br>') + '</p>' : '') +
      (paragrafi.length ? '<span class="linea-corta"></span>' + paragrafi.map(function (p, i) { return '<p class="rivela ' + (i ? 'bio-paragrafo' : 'bio-attacco') + '">' + esc(p) + '</p>'; }).join('') : '') +
      '</div>' + (C.bioImage ? '<div class="bio-foto rivela"><img ' + S54.srcset(C.bioImage, '(max-width: 1023px) 100vw, 45vw') + ' alt=""></div>' : '') + '</div></section>' +
      (metodo.length ? '<section class="sezione metodo"><div class="contenitore-stretto"><p class="etichetta"><span class="trattino"></span>IL METODO</p><div class="metodo-passi">' +
        metodo.map(function (m) { return '<div class="passo rivela"><p class="passo-numero">' + esc(m.year) + '</p><p class="passo-titolo">' + esc(maiuscolo(m.title)) + '</p>' + (m.text ? '<p class="passo-testo">' + esc(m.text) + '</p>' : '') + '</div>'; }).join('') +
        '</div></div></section>' : '');
  }

  // Preventivo: tutto in una pagina, con le parti accese dal gestionale.
  var prevBox = $('[data-preventivo]');
  var F = D.quoteForm;
  var attive = function (l) { return (l || []).filter(function (o) { return o.active !== false && (o.label || '').trim(); }); };
  var tipi = attive(F.eventTypes), richieste = attive(F.requests);
  var acceso = function (k) { return F[k] !== false; };
  var conTipo = acceso('showEvent') && tipi.length > 0;
  var conData = acceso('showDate'), conLuogo = acceso('showLocation');
  var conRichieste = acceso('showRequests') && richieste.length > 0;
  var conMessaggio = acceso('showMessage');
  var conCognome = acceso('askLastName'), conTelefono = acceso('askPhone');
  var conEmail = acceso('askEmail') || !conTelefono;
  if (prevBox) {
    var n = 0;
    var titolo = function (t) { return '<h2><span>' + (++n) + '</span>' + t + '</h2>'; };
    var testo = function (id, etichetta, extra) {
      extra = extra || {};
      return '<div class="campo' + (extra.classe ? ' ' + extra.classe : '') + '" data-campo="' + id + '">' +
        '<input id="' + id + '" name="' + id + '" placeholder=" "' + (extra.attr || '') + '>' +
        '<label for="' + id + '">' + etichetta + '</label>' + (extra.aiuto ? '<span class="suggerimento">' + extra.aiuto + '</span>' : '') +
        (extra.dopo || '') + '<p class="errore"></p></div>';
    };
    var html = '';
    if (conTipo || conData || conLuogo) {
      html += '<section class="passo-modulo" data-passo="evento">' + titolo('IL VOSTRO EVENTO');
      if (conTipo) {
        html += '<div class="campo" data-campo="tipo"><div class="scelte" role="radiogroup" aria-label="Tipo di evento">' + tipi.map(function (t) {
          return '<button type="button" class="scelta-voce" role="radio" data-tipo="' + esc(t.label) + '" aria-pressed="' + (tipi.length === 1) + '" aria-checked="' + (tipi.length === 1) + '">' + esc(t.label) + '</button>';
        }).join('') + '</div><p class="errore"></p></div>';
      }
      var coppia = [];
      if (conData) coppia.push(testo('data', "Data dell'evento *", { classe: 'data', attr: ' inputmode="numeric" autocomplete="off" maxlength="10"', aiuto: 'gg/mm/aaaa', dopo: '<button type="button" class="calendario" aria-label="Scegli dal calendario"></button><input type="date" class="calendario-nativo" tabindex="-1" aria-hidden="true">' }));
      if (conLuogo) coppia.push(testo('luogo', 'Luogo *', { attr: ' maxlength="80"', aiuto: 'Città o nome della location' }));
      if (coppia.length) html += coppia.length === 2 ? '<div class="coppia">' + coppia.join('') + '</div>' : coppia[0];
      html += '</section>';
    }
    if (conRichieste) {
      html += '<section class="passo-modulo" data-passo="richieste">' + titolo('LE VOSTRE RICHIESTE') + '<p class="nota">Toccate una o più voci. *</p><div class="scelte">' +
        richieste.map(function (r) { return '<button type="button" class="scelta-voce" data-richiesta="' + esc(r.label) + '" aria-pressed="false">' + esc(r.label) + '</button>'; }).join('') + '</div><p class="errore errore-richieste"></p></section>';
    }
    var nome = [testo('nome', 'Nome *', { attr: ' autocomplete="given-name" maxlength="40"' })];
    if (conCognome) nome.push(testo('cognome', 'Cognome *', { attr: ' autocomplete="family-name" maxlength="40"' }));
    var recapiti = [];
    if (conTelefono) recapiti.push(testo('telefono', 'Telefono *', { classe: 'icona-tel', attr: ' type="tel" inputmode="tel" autocomplete="tel" maxlength="20"', aiuto: 'Es. 333 123 4567' }));
    if (conEmail) recapiti.push(testo('email', 'Email *', { classe: 'icona-mail', attr: ' type="email" inputmode="email" autocomplete="email" maxlength="80"', aiuto: 'nome@email.it' }));
    var riga = function (l) { return l.length === 2 ? '<div class="coppia">' + l.join('') + '</div>' : l.join(''); };
    html += '<section class="passo-modulo" data-passo="contatti">' + titolo('I VOSTRI CONTATTI') + riga(nome) + riga(recapiti) + '</section>';
    if (conMessaggio) {
      html += '<section class="passo-modulo" data-passo="messaggio">' + titolo('IL VOSTRO MESSAGGIO') +
        '<div class="campo area" data-campo="note"><textarea id="note" name="note" rows="4" maxlength="500" placeholder=" "></textarea><label for="note">Altre informazioni (facoltativo)</label><span class="conta-caratteri">0/500</span></div></section>';
    }
    prevBox.innerHTML = '<form class="modulo" novalidate data-modulo>' + html +
      '<label class="consenso" data-campo="privacy"><input type="checkbox" name="privacy" value="1"><span class="spunta" aria-hidden="true"></span><span>Acconsento al trattamento dei miei dati per essere ricontattato. *</span></label><p class="errore errore-privacy"></p>' +
      '<div class="modulo-invio"><button type="submit" class="pillola grande">INVIA LA RICHIESTA <i>&rarr;</i></button><span class="nota">* campi obbligatori</span></div></form>' +
      '<div class="grazie" data-grazie hidden><img src="assets/img/mark.png" alt=""><p class="etichetta"><span class="trattino"></span>RICHIESTA INVIATA</p><h1 class="grazie-titolo">Grazie</h1><p class="grazie-testo"></p>' +
      '<div class="grazie-azioni"><a class="pillola" href="' + S54.url('index') + '">TORNA ALLA HOME <i>&#8599;</i></a><button type="button" class="link grazie-nuova">Nuova richiesta</button></div></div>';
  }

  /* ====================================================== LOGO D'APERTURA */

  // Quando il logo d'apertura sparisce la pagina è "pronta": partono le
  // animazioni e il carosello (così la prima foto dura davvero 4 secondi).
  var partito = false;
  function avvia() {
    if (partito) return;
    partito = true;
    document.body.classList.add('pronto');
    document.dispatchEvent(new Event('s54-pronto'));
  }
  function quandoPronto(fn) {
    if (partito) fn(); else document.addEventListener('s54-pronto', fn, { once: true });
  }
  var intro = $('#intro');
  var senzaIntro = document.documentElement.classList.contains('senza-intro');
  if (intro && !senzaIntro) {
    var inizio = Date.now();
    var chiudi = function () {
      setTimeout(function () {
        intro.classList.add('via');
        setTimeout(avvia, 250);
      }, Math.max(0, 2000 - (Date.now() - inizio)));
    };
    if (document.readyState === 'complete') chiudi(); else window.addEventListener('load', chiudi);
    // Mai più di 4 secondi, anche con la connessione lenta.
    setTimeout(function () { intro.classList.add('via'); avvia(); }, 4000);
  } else {
    requestAnimationFrame(avvia);
  }

  /* ========================================================= BARRA E MENU */

  var barra = $('#barra');
  // Sopra la foto d'apertura della home la barra è trasparente; altrove ha il bianco della pagina, senza riga di stacco.
  // Il passaggio segue lo scorrimento: mentre il bordo della foto sale verso
  // la barra, il vetro si riempie piano piano ed è pieno quando la foto è
  // passata tutta sotto.
  var INCHIOSTRO = [30, 27, 23];
  var pPrima = -1, inAttesa = false;
  var aggiornaBarra = function () {
    inAttesa = false;
    if (!barra) return;
    var p = 1;
    if (carosello && !carosello.hidden) {
      var hb = barra.offsetHeight, bordo = carosello.getBoundingClientRect().bottom;
      p = Math.min(1, Math.max(0, 1 - (bordo - hb) / (hb * 1.5)));
    }
    p = Math.round(p * 1000) / 1000;
    if (p === pPrima) return;
    pPrima = p;
    barra.style.setProperty('--p', p);
    barra.style.color = 'rgb(' + INCHIOSTRO.map(function (c) { return Math.round(255 + (c - 255) * p); }).join(',') + ')';
  };
  var chiediBarra = function () { if (!inAttesa) { inAttesa = true; requestAnimationFrame(aggiornaBarra); } };
  window.addEventListener('scroll', chiediBarra, { passive: true });
  window.addEventListener('resize', aggiornaBarra);
  aggiornaBarra();

  // Dopo un ricaricamento il segno "menu o foto aperti" nella cronologia non vale più.
  if (history.state && history.state.s54) history.replaceState(null, '');

  var menu = $('#menu');
  var apriMenu = $('.barra-menu');
  if (menu && apriMenu) {
    var tChiudi = null;
    var mostra = function (si, daStoria) {
      clearTimeout(tChiudi);
      if (si) {
        menu.hidden = false;
        requestAnimationFrame(function () { menu.classList.add('aperto'); });
        $('.menu-chiudi', menu).focus();
        // Il tasto indietro del telefono chiude il menu invece di lasciare la pagina.
        if (!daStoria) history.pushState({ s54: 'menu' }, '');
      } else {
        menu.classList.remove('aperto');
        tChiudi = setTimeout(function () { menu.hidden = true; }, 450);
        apriMenu.focus();
        if (!daStoria && history.state && history.state.s54 === 'menu') history.back();
      }
      apriMenu.setAttribute('aria-expanded', si ? 'true' : 'false');
      document.body.style.overflow = si ? 'hidden' : '';
    };
    apriMenu.addEventListener('click', function () { mostra(true); });
    $('.menu-chiudi', menu).addEventListener('click', function () { mostra(false); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && !menu.hidden) mostra(false); });
    window.addEventListener('popstate', function () { if (!menu.hidden && menu.classList.contains('aperto')) mostra(false, true); });
    // Tornando dalla cache del browser il menu non deve restare aperto.
    window.addEventListener('pageshow', function (e) { if (e.persisted && !menu.hidden) mostra(false, true); });
    // Da una voce del menu si va alla pagina al posto del passaggio "menu aperto",
    // così il tasto indietro non ci ripassa.
    $$('.menu-voci a, .menu-testa a', menu).forEach(function (a) {
      a.addEventListener('click', function (e) {
        if (history.state && history.state.s54 === 'menu' && !e.ctrlKey && !e.metaKey && !e.shiftKey) { e.preventDefault(); location.replace(a.href); }
      });
    });
  }

  /* ----------------------------------------------------- comparsa morbida */

  if ('IntersectionObserver' in window) {
    var oss = new IntersectionObserver(function (voci) {
      voci.forEach(function (v) {
        if (v.isIntersecting) { v.target.classList.add('visto'); oss.unobserve(v.target); }
      });
    }, { threshold: 0.05 });
    $$('.rivela').forEach(function (el) { oss.observe(el); });
  } else {
    $$('.rivela').forEach(function (el) { el.classList.add('visto'); });
  }

  /** Sfoglia con il dito: chiama fn(+1) verso sinistra, fn(-1) verso destra. */
  function sfoglia(el, fn) {
    var x0 = null, y0 = 0;
    el.addEventListener('touchstart', function (e) { x0 = e.touches[0].clientX; y0 = e.touches[0].clientY; }, { passive: true });
    el.addEventListener('touchend', function (e) {
      if (x0 === null) return;
      var dx = e.changedTouches[0].clientX - x0, dy = e.changedTouches[0].clientY - y0;
      x0 = null;
      if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy) * 1.5) fn(dx < 0 ? 1 : -1);
    }, { passive: true });
  }

  /* ================================================= FOTO A SCHERMO INTERO */

  // Solo la foto, grande, con le frecce e la X: nessuna scritta.
  var visore = $('#visore');
  var vFoto = [], vI = 0;
  function vMostra() {
    var img = $('figure img', visore);
    img.style.opacity = 0;
    img.onload = function () { img.style.opacity = 1; };
    img.src = vFoto[vI];
    $$('.visore-prec, .visore-succ', visore).forEach(function (b) { b.hidden = vFoto.length < 2; });
  }
  var vDa = null;
  function vApri(foto, i) {
    vFoto = foto; vI = i;
    vDa = document.activeElement;
    visore.hidden = false;
    document.body.style.overflow = 'hidden';
    vMostra();
    $('.visore-chiudi', visore).focus();
    // Il tasto indietro del telefono chiude la foto invece di lasciare la pagina.
    history.pushState({ s54: 'visore' }, '');
  }
  function vChiudi(daStoria) {
    if (visore.hidden) return;
    visore.hidden = true;
    document.body.style.overflow = '';
    if (vDa && vDa.focus) vDa.focus({ preventScroll: true });
    if (daStoria !== true && history.state && history.state.s54 === 'visore') history.back();
  }
  function vVai(d) { vI = (vI + d + vFoto.length) % vFoto.length; vMostra(); }
  if (visore) {
    $('.visore-chiudi', visore).addEventListener('click', vChiudi);
    $('.visore-prec', visore).addEventListener('click', function () { vVai(-1); });
    $('.visore-succ', visore).addEventListener('click', function () { vVai(1); });
    document.addEventListener('keydown', function (e) {
      if (visore.hidden) return;
      if (e.key === 'Escape') vChiudi();
      if (e.key === 'ArrowRight' && vFoto.length > 1) vVai(1);
      if (e.key === 'ArrowLeft' && vFoto.length > 1) vVai(-1);
    });
    sfoglia(visore, function (d) { if (vFoto.length > 1) vVai(d); });
    window.addEventListener('popstate', function () { vChiudi(true); });
  }

  /* ============================================================ CAROSELLO */

  $$('[data-carosello]').forEach(function (car) {
    var intervallo = +car.getAttribute('data-intervallo') || 4000;
    var tutte = [], mostrate = [];
    var i = 0, timer = null, tUscita = null;

    function disegna() {
      if (!mostrate.length) return;
      var d = mostrate[i];
      var prima = $('.diapo.attiva', car);
      // Dissolvenza incrociata: la foto che esce resta sotto finché la nuova
      // non è comparsa del tutto.
      tutte.forEach(function (x) { if (x !== prima) x.classList.remove('uscente'); });
      if (prima && prima !== d) { prima.classList.remove('attiva'); prima.classList.add('uscente'); }
      clearTimeout(tUscita);
      tUscita = setTimeout(function () { $$('.diapo.uscente', car).forEach(function (x) { x.classList.remove('uscente'); }); }, 1500);
      if (prima !== d) {
        var img = $('img', d); img.style.animation = 'none'; void img.offsetWidth; img.style.animation = '';
        d.classList.add('attiva');
      }
      $$('.ap-prec, .ap-succ', car).forEach(function (b) { b.hidden = mostrate.length < 2; });
    }
    function riparti() {
      clearInterval(timer);
      if (!partito || document.hidden) return;
      if (mostrate.length > 1) timer = setInterval(function () { i = (i + 1) % mostrate.length; disegna(); }, intervallo);
    }
    function vai(k) {
      var n = mostrate.length;
      if (n < 2) return;
      i = ((k % n) + n) % n;
      disegna();
      riparti();
    }
    // Prepara le foto appena disegnate (all'apertura e girando lo schermo).
    function prepara() {
      tutte = $$('.diapo', car);
      mostrate = tutte.slice();
      i = 0;
      // Schermo in orizzontale: una verticale caricata per sbaglio si salta (come
      // nell'app). In verticale un'orizzontale si mostra, tagliata quanto serve.
      var giusta = serieGiusta() && orizzontale.matches;
      tutte.forEach(function (d) {
        var img = $('img', d);
        var controlla = function () {
          if (tutte.indexOf(d) < 0 || !giusta || !img.naturalWidth || mostrate.length < 2) return;
          if (img.naturalWidth > img.naturalHeight) return;
          var corrente = mostrate[i];
          mostrate = mostrate.filter(function (x) { return x !== d; });
          var k = mostrate.indexOf(corrente);
          i = k >= 0 ? k : 0;
          disegna();
          riparti();
        };
        if (img.complete) controlla(); else img.addEventListener('load', controlla);
      });
      $$('.ap-prec', car).forEach(function (b) { b.addEventListener('click', function () { vai(i - 1); }); });
      $$('.ap-succ', car).forEach(function (b) { b.addEventListener('click', function () { vai(i + 1); }); });
      disegna();
    }
    sfoglia(car, function (d) { vai(i + d); });
    document.addEventListener('visibilitychange', function () { if (document.hidden) clearInterval(timer); else riparti(); });
    prepara();
    // Il conto dei 4 secondi parte quando sparisce il logo d'apertura.
    quandoPronto(riparti);
    // Lo schermo si gira: cambiano le foto, senza ricaricare la pagina.
    var girato = function () {
      clearInterval(timer);
      disegnaCarosello();
      prepara();
      riparti();
      aggiornaBarra();
    };
    if (orizzontale.addEventListener) orizzontale.addEventListener('change', girato);
    else orizzontale.addListener(girato);
  });

  /* ======================================================== FILTRI LAVORI */

  $$('[data-filtri]').forEach(function (box) {
    var scelte = {};
    var lavori = $$('.scheda-lavoro');
    var esito = $('.filtri-esito', box);
    var nessuno = $('.filtri-nessuno');

    function applica() {
      var visibili = 0;
      lavori.forEach(function (w) {
        var ok = Object.keys(scelte).every(function (k) { return !scelte[k] || w.getAttribute('data-' + k) === scelte[k]; });
        w.hidden = !ok;
        if (ok) { visibili++; w.classList.add('visto'); }
      });
      var attivi = Object.keys(scelte).some(function (k) { return scelte[k]; });
      esito.hidden = !attivi;
      $('.filtri-conto', box).textContent = due(visibili) + (visibili === 1 ? ' TROVATO' : ' TROVATI');
      if (nessuno) nessuno.hidden = visibili > 0;
    }
    function chiudiTutti(tranne) {
      $$('.filtro', box).forEach(function (f) {
        if (f === tranne) return;
        $('.filtro-menu', f).hidden = true;
        $('.filtro-voce', f).setAttribute('aria-expanded', 'false');
      });
    }
    $$('.filtro', box).forEach(function (f) {
      var id = f.getAttribute('data-filtro');
      var voce = $('.filtro-voce', f), lista = $('.filtro-menu', f);
      function scegli(v) {
        scelte[id] = v;
        f.classList.toggle('attivo', !!v);
        $$('.filtro-valore span', f).forEach(function (s) { s.classList.toggle('visibile', s.getAttribute('data-v') === v); });
        $$('li', lista).forEach(function (li) { li.setAttribute('aria-selected', li.getAttribute('data-v') === v ? 'true' : 'false'); });
        lista.hidden = true;
        voce.setAttribute('aria-expanded', 'false');
        applica();
      }
      f.scegli = scegli;
      voce.addEventListener('click', function (e) {
        e.stopPropagation();
        var apri = lista.hidden;
        chiudiTutti(f);
        lista.hidden = !apri;
        voce.setAttribute('aria-expanded', apri ? 'true' : 'false');
        if (apri) { var sel = $('li[aria-selected="true"]', lista); (sel || $('li', lista)).focus(); }
      });
      $$('li', lista).forEach(function (li) {
        li.tabIndex = -1;
        li.addEventListener('click', function () { scegli(li.getAttribute('data-v')); voce.focus(); });
        li.addEventListener('keydown', function (e) {
          if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); li.click(); }
          if (e.key === 'ArrowDown' && li.nextElementSibling) li.nextElementSibling.focus();
          if (e.key === 'ArrowUp' && li.previousElementSibling) li.previousElementSibling.focus();
          if (e.key === 'Escape') { lista.hidden = true; voce.setAttribute('aria-expanded', 'false'); voce.focus(); }
        });
      });
    });
    document.addEventListener('click', function () { chiudiTutti(null); });
    $('.filtri-azzera', box).addEventListener('click', function () { $$('.filtro', box).forEach(function (f) { f.scegli(''); }); });
    // Con un filtro nell'indirizzo (es. ?evento=matrimonio) la scelta è già fatta.
    var qs = new URLSearchParams(location.search);
    $$('.filtro', box).forEach(function (f) {
      var v = (qs.get(f.getAttribute('data-filtro')) || '').toLowerCase();
      if (v && $$('li', f).some(function (li) { return li.getAttribute('data-v') === v; })) f.scegli(v);
    });
  });

  /* ============================================== COLLAGE (dettaglio lavoro) */

  $$('[data-collage]').forEach(function (box) {
    var tavole = $$('.tavola', box);
    if (!tavole.length) return;
    var rapporti = tavole.map(function () { return 1.5; });
    function rapporto(k) { return Math.min(3, Math.max(0.4, rapporti[k])); }

    // La prima orizzontale in apertura; poi ritmi diversi in base alle
    // proporzioni: verticale + due orizzontali, orizzontale + due verticali,
    // coppie, foto singole. Nessuna foto viene tagliata.
    function piano(oriz) {
      var n = oriz.length, righe = [], k = 1, giro = 0;
      righe.push({ tipo: 'una', ids: [0] });
      var o = function (d) { return k + d < n ? oriz[k + d] : null; };
      while (k < n) {
        var a = o(0), b = o(1), c = o(2);
        if (!a) {
          if (b === true && c === true) { righe.push({ tipo: 'pila', alta: k, su: k + 1, giu: k + 2 }); k += 3; }
          else if (b === false && c !== null) { righe.push({ tipo: 'fila', ids: [k, k + 1, k + 2] }); k += 3; }
          else if (b !== null) { righe.push({ tipo: 'fila', ids: [k, k + 1] }); k += 2; }
          else { righe.push({ tipo: 'una', ids: [k] }); k += 1; }
        } else {
          if (b === false && c === false) { righe.push({ tipo: 'fila', ids: [k, k + 1, k + 2] }); k += 3; }
          else if (b === true && c === false) { righe.push({ tipo: 'pila', alta: k + 2, su: k, giu: k + 1 }); k += 3; }
          else if (b === true && c === true && giro % 2) { righe.push({ tipo: 'una', ids: [k] }); k += 1; }
          else if (b !== null) { righe.push({ tipo: 'fila', ids: [k, k + 1] }); k += 2; }
          else { righe.push({ tipo: 'una', ids: [k] }); k += 1; }
        }
        giro++;
      }
      return righe;
    }
    function misura(t, w, h) { t.style.width = w + 'px'; t.style.height = h + 'px'; return t; }
    var ordine = [];
    function componi() {
      // In apertura la prima orizzontale; le altre restano in ordine.
      var prima = -1;
      for (var q = 0; q < tavole.length; q++) { if (rapporti[q] > 1) { prima = q; break; } }
      ordine = tavole.map(function (_, q) { return q; });
      // Sul telefono, una sotto l'altra, l'ordine resta quello del gestionale.
      if (prima > 0 && window.innerWidth >= 600) { ordine.splice(prima, 1); ordine.unshift(prima); }
      var r = function (pos) { return rapporto(ordine[pos]); };
      var t = function (pos) { return tavole[ordine[pos]]; };
      // L'altezza resta ferma mentre si ricompone: la pagina non salta. La
      // dissolvenza si vede solo la prima volta.
      if (box.classList.contains('composto')) { box.style.minHeight = box.offsetHeight + 'px'; box.classList.add('ricomposto'); }
      box.innerHTML = '';
      var stile = getComputedStyle(box);
      var piena = Math.floor(box.clientWidth - parseFloat(stile.paddingLeft) - parseFloat(stile.paddingRight)) - 1;
      // Come --px nel CSS: oltre FullHD anche gli spazi crescono con lo schermo.
      var px = orizzontale.matches
        ? Math.max(1, Math.min(window.innerWidth / 1920, window.innerHeight / 1080))
        : Math.max(1, Math.min(window.innerWidth / 1080, window.innerHeight / 1920));
      var spazio = Math.max(10, Math.min(22 * px, piena * 0.018));
      box.style.setProperty('--spazio', spazio + 'px');
      // Altezza dello schermo senza le barre del browser che vanno e vengono.
      var alto = document.documentElement.clientHeight, maxH = alto * 0.9;
      // Monitor molto larghi: una larghezza comune a tutte le righe, così restano
      // a filo e la foto più larga non è molto più alta dello schermo.
      if (window.innerWidth >= 600) piena = Math.min(piena, Math.floor(alto * 1.95));
      var riga = function () { var d = document.createElement('div'); d.className = 'collage-riga'; box.appendChild(d); return d; };
      if (window.innerWidth < 600) {
        // Telefono: una sotto l'altra, intere.
        ordine.forEach(function (_, pos) { riga().appendChild(misura(t(pos), piena + 1, (piena + 1) / r(pos))); });
      } else {
        var lato = 0;
        // Righe a specchio: la foto più larga una volta a sinistra e una a
        // destra (il visore segue l'ordine scelto nel gestionale).
        var specchio = function (d, pezzi) {
          var larghe = pezzi.map(function (x) { return x[1]; });
          var max = Math.max.apply(null, larghe), min = Math.min.apply(null, larghe);
          if (max - min > 2) {
            var i = larghe.indexOf(max), sinistra = lato++ % 2 === 0;
            if (sinistra ? i > (pezzi.length - 1) / 2 : i < (pezzi.length - 1) / 2) pezzi.reverse();
          }
          pezzi.forEach(function (x) { d.appendChild(x[0]); });
        };
        piano(ordine.map(function (_, pos) { return r(pos) > 1; })).forEach(function (p) {
          var d = riga();
          if (p.tipo === 'una') {
            var h = piena / r(p.ids[0]);
            if (r(p.ids[0]) <= 1) h = Math.min(h, maxH);
            d.appendChild(misura(t(p.ids[0]), h * r(p.ids[0]), h));
          } else if (p.tipo === 'fila') {
            var somma = p.ids.reduce(function (s, k) { return s + r(k); }, 0);
            var hf = Math.min((piena - spazio * (p.ids.length - 1)) / somma, maxH);
            specchio(d, p.ids.map(function (k) { return [misura(t(k), hf * r(k), hf), hf * r(k)]; }));
          } else {
            // La colonna delle due orizzontali è larga quanto basta perché
            // finisca alla stessa altezza della verticale.
            var av = r(p.alta), kk = 1 / r(p.su) + 1 / r(p.giu);
            var c = (piena - spazio - av * spazio) / (av * kk + 1);
            var hp = c * kk + spazio;
            var col = document.createElement('div');
            col.className = 'collage-colonna';
            col.appendChild(misura(t(p.su), c, c / r(p.su)));
            col.appendChild(misura(t(p.giu), c, c / r(p.giu)));
            specchio(d, [[misura(t(p.alta), av * hp, hp), av * hp], [col, c]]);
          }
        });
      }
      box.classList.add('composto');
      box.style.minHeight = '';
    }
    // Si compone quando si conoscono le proporzioni di tutte le foto (al
    // massimo dopo 3 secondi, con quelle note fino ad allora). Fino ad allora
    // il collage resta nascosto, così la pagina non salta. Le proporzioni
    // lette si ricordano: alla visita successiva il collage è subito pronto.
    var CHIAVE = 's54-proporzioni', note = {};
    try { note = JSON.parse(localStorage.getItem(CHIAVE)) || {}; } catch (e) {}
    var chiave = function (k) { return tavole[k].getAttribute('data-foto'); };
    // Le foto caricate dal gestionale stanno dentro i dati: si leggono subito e
    // non si ricordano (raddoppierebbero il peso nel browser).
    var daRicordare = function (k) { return chiave(k).indexOf('data:') !== 0; };
    var ricorda = function (k) {
      if (!daRicordare(k)) return;
      note[chiave(k)] = Math.round(rapporti[k] * 1000) / 1000;
      try { localStorage.setItem(CHIAVE, JSON.stringify(note)); } catch (e) {}
    };
    var note0 = tavole.map(function (_, k) { var v = daRicordare(k) && note[chiave(k)]; if (v > 0) rapporti[k] = v; return v > 0; });
    var fatto = false, larghezza = 0, altezza = 0;
    var larghezzaUtile = function () { var s = getComputedStyle(box); return box.clientWidth - parseFloat(s.paddingLeft) - parseFloat(s.paddingRight); };
    function pronta() {
      if (fatto) return;
      fatto = true;
      larghezza = larghezzaUtile();
      altezza = document.documentElement.clientHeight;
      componi();
      // Si ricompone se cambia la larghezza (o molto l'altezza): non quando sul
      // telefono compare o sparisce la barra del browser.
      var t0;
      window.addEventListener('resize', function () {
        clearTimeout(t0);
        t0 = setTimeout(function () {
          // La larghezza utile cambia anche con i margini, che crescono con lo schermo.
          var alto = document.documentElement.clientHeight, utile = larghezzaUtile();
          if (Math.abs(utile - larghezza) > 1 || Math.abs(alto - altezza) > 150) { larghezza = utile; altezza = alto; componi(); }
        }, 150);
      });
    }
    // Le misure di una foto arrivano prima della foto intera: si controlla
    // spesso, senza aspettare che sia scaricata tutta.
    var lette = note0.slice(), inizio = Date.now();
    // Una foto che arriva dopo i 3 secondi, o diversa da come la si ricordava
    // (sostituita): si ricompone, per non tagliarla.
    var t1;
    function controllaArrivo(k) {
      var img = $('img', tavole[k]);
      var arrivata = function () {
        if (!img.naturalWidth) return;
        var vero = img.naturalWidth / img.naturalHeight;
        if (Math.abs(vero - rapporti[k]) < 0.01) return;
        rapporti[k] = vero;
        ricorda(k);
        if (fatto) { clearTimeout(t1); t1 = setTimeout(componi, 120); }
      };
      if (img.complete) arrivata(); else img.addEventListener('load', arrivata, { once: true });
    }
    (function controlla() {
      tavole.forEach(function (tv, k) {
        if (lette[k]) return;
        var img = $('img', tv);
        if (img.naturalWidth) { rapporti[k] = img.naturalWidth / img.naturalHeight; lette[k] = true; ricorda(k); }
        else if (img.complete) lette[k] = true; // non si carica: resta 3:2
      });
      if (lette.every(Boolean) || Date.now() - inizio > 3000) {
        tavole.forEach(function (_, k) { controllaArrivo(k); });
        pronta();
      }
      else setTimeout(controlla, 50);
    })();
    tavole.forEach(function (tv, k) {
      var apri = function () {
        var seq = (ordine.length ? ordine : tavole.map(function (_, q) { return q; }));
        vApri(seq.map(function (q) { return tavole[q].getAttribute('data-foto'); }), Math.max(0, seq.indexOf(k)));
      };
      tv.addEventListener('click', apri);
      tv.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); apri(); } });
    });
  });

  /* ============================================================ PREVENTIVO */

  $$('[data-modulo]').forEach(function (form) {
    var campo = function (n) { return $('[data-campo="' + n + '"]', form); };
    var input = function (n) { var c = campo(n); return c && $('input, textarea', c); };
    var provato = false;
    // Un solo tipo acceso è già scelto; se la parte è spenta, nessun tipo.
    var tipo = conTipo && tipi.length === 1 ? tipi[0].label : '';

    /* Controlli, uguali a quelli dell'app. */
    var regole = {
      data: function (v) {
        if (!v) return "Indicate la data dell'evento";
        var m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(v);
        if (!m) return 'Scrivete la data come gg/mm/aaaa';
        var d = new Date(+m[3], +m[2] - 1, +m[1]);
        if (d.getFullYear() !== +m[3] || d.getMonth() !== +m[2] - 1 || d.getDate() !== +m[1]) return 'Questa data non esiste';
        var oggi = new Date(); oggi.setHours(0, 0, 0, 0);
        if (d < oggi) return 'La data è già passata';
        var limite = new Date(oggi); limite.setFullYear(oggi.getFullYear() + 5);
        if (d > limite) return 'Scegliete una data entro 5 anni';
        return '';
      },
      luogo: function (v) { return v.length < 2 ? "Indicate la città o la location dell'evento" : ''; },
      nome: function (v) { return nomeOk(v, 'nome'); },
      cognome: function (v) { return nomeOk(v, 'cognome'); },
      telefono: function (v) {
        if (!v) return 'Inserite il numero di telefono';
        var c = v.replace(/\D/g, '').length;
        return c < 8 || c > 15 ? 'Numero non valido: servono da 8 a 15 cifre' : '';
      },
      email: function (v) {
        if (!v) return "Inserite l'indirizzo email";
        return /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$/.test(v) ? '' : 'Email non valida (es. nome@email.it)';
      }
    };
    function nomeOk(v, cosa) {
      if (!v) return 'Inserite il ' + cosa;
      return v.replace(/['\s\-]/g, '').length < 2 ? 'Il ' + cosa + ' deve avere almeno 2 lettere' : '';
    }
    function controlla(n, mostra) {
      var c = campo(n);
      if (!c) return '';
      var msg = regole[n](input(n).value.trim());
      if (mostra) { c.classList.toggle('sbagliato', !!msg); $('.errore', c).textContent = msg; input(n).setAttribute('aria-invalid', msg ? 'true' : 'false'); }
      return msg;
    }
    function controllaTipo(mostra) {
      var c = campo('tipo');
      if (!c) return '';
      var msg = tipo ? '' : 'Scegliete il tipo di evento';
      if (mostra) $('.errore', c).textContent = msg;
      return msg;
    }

    /* Caratteri ammessi mentre si scrive. */
    var filtriTesto = {
      telefono: function (v) {
        v = v.replace(/[^0-9+ ]/g, '');
        var l = v.replace(/^\s+/, ''), piu = l.charAt(0) === '+';
        return (piu ? '+' : '') + (piu ? l.slice(1) : l).replace(/\+/g, '');
      },
      nome: function (v) { return v.replace(/[^A-Za-zÀ-ÖØ-öø-ÿ' \-]/g, ''); },
      cognome: function (v) { return v.replace(/[^A-Za-zÀ-ÖØ-öø-ÿ' \-]/g, ''); },
      email: function (v) { return v.replace(/\s/g, ''); },
      data: function (v) {
        var d = v.replace(/\D/g, '').slice(0, 8), o = '';
        for (var k = 0; k < d.length; k++) { if (k === 2 || k === 4) o += '/'; o += d[k]; }
        return o;
      }
    };
    Object.keys(regole).forEach(function (n) {
      var el = input(n);
      if (!el) return;
      el.addEventListener('input', function () {
        if (filtriTesto[n]) { var p = filtriTesto[n](el.value); if (p !== el.value) el.value = p; }
        // Mentre si scrive l'errore compare solo dopo il primo invio; uno già
        // mostrato si aggiorna (e sparisce appena il campo è giusto).
        controlla(n, provato || campo(n).classList.contains('sbagliato'));
      });
      el.addEventListener('blur', function () { if (el.value || provato) controlla(n, true); });
    });

    /* Tipo di evento: una sola scelta. */
    $$('[data-tipo]', form).forEach(function (b) {
      b.addEventListener('click', function () {
        tipo = b.getAttribute('data-tipo');
        $$('[data-tipo]', form).forEach(function (x) { var on = x === b; x.setAttribute('aria-pressed', on); x.setAttribute('aria-checked', on); });
        controllaTipo(true);
      });
    });
    /* Richieste: almeno una. */
    var erroreRichieste = $('.errore-richieste', form);
    function controllaRichieste(mostra) {
      var msg = erroreRichieste && !$('[data-richiesta][aria-pressed="true"]', form) ? 'Scegliete almeno una richiesta' : '';
      if (mostra && erroreRichieste) erroreRichieste.textContent = msg;
      return msg;
    }
    $$('[data-richiesta]', form).forEach(function (b) {
      b.addEventListener('click', function () {
        b.setAttribute('aria-pressed', b.getAttribute('aria-pressed') === 'true' ? 'false' : 'true');
        if (provato) controllaRichieste(true);
      });
    });

    /* Data dal calendario. */
    var nativo = $('.calendario-nativo', form), testoData = input('data');
    if (nativo && testoData) {
      var oggi = new Date();
      var iso = function (d) { return d.getFullYear() + '-' + due(d.getMonth() + 1) + '-' + due(d.getDate()); };
      nativo.min = iso(oggi);
      var fra5 = new Date(oggi); fra5.setFullYear(oggi.getFullYear() + 5); nativo.max = iso(fra5);
      $('.calendario', form).addEventListener('click', function () {
        try { nativo.showPicker(); } catch (e) { nativo.focus(); nativo.click(); }
      });
      nativo.addEventListener('change', function () {
        if (!nativo.value) return;
        var p = nativo.value.split('-');
        testoData.value = p[2] + '/' + p[1] + '/' + p[0];
        testoData.dispatchEvent(new Event('input'));
      });
    }

    var note = input('note'), conto = $('.conta-caratteri', form);
    if (note) note.addEventListener('input', function () { conto.textContent = note.value.length + '/500'; });

    var consenso = $('.consenso', form), spunta = $('input', consenso), errorePrivacy = $('.errore-privacy', form);
    function controllaConsenso(mostra) {
      var msg = spunta.checked ? '' : 'Serve il consenso per inviare la richiesta';
      if (mostra) { consenso.classList.toggle('sbagliato', !!msg); errorePrivacy.textContent = msg; }
      return msg;
    }
    spunta.addEventListener('change', function () { if (provato) controllaConsenso(true); });

    var valore = function (n) { var el = input(n); return el ? el.value.trim() : ''; };

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      provato = true;
      var primo = null;
      if (controllaTipo(true)) primo = campo('tipo');
      ['data', 'luogo'].forEach(function (n) { if (controlla(n, true) && !primo) primo = campo(n); });
      if (controllaRichieste(true) && !primo) primo = $('[data-passo="richieste"]', form);
      ['nome', 'cognome', 'telefono', 'email'].forEach(function (n) { if (controlla(n, true) && !primo) primo = campo(n); });
      if (controllaConsenso(true) && !primo) primo = consenso;
      if (primo) {
        // Mai sotto la barra in alto, anche con il telefono girato.
        var y = primo.getBoundingClientRect().top + window.scrollY - Math.max(window.innerHeight * 0.2, barra.offsetHeight + 16);
        window.scrollTo({ top: y, behavior: 'smooth' });
        var fuoco = $('input, textarea, button', primo);
        if (fuoco) fuoco.focus({ preventScroll: true });
        return;
      }
      var d = valore('data').split('/');
      var richiesta = {
        id: 'web-' + Date.now().toString(36),
        createdAt: new Date().toISOString(),
        firstName: valore('nome'), lastName: valore('cognome'),
        phone: valore('telefono'), email: valore('email'),
        eventType: tipo,
        eventDate: d.length === 3 ? d[2] + '-' + d[1] + '-' + d[0] : null,
        location: valore('luogo'),
        requests: $$('[data-richiesta][aria-pressed="true"]', form).map(function (b) { return b.getAttribute('data-richiesta'); }),
        message: valore('note'),
        source: 'sito', status: 'nuova', appointmentId: null
      };
      // Senza database la richiesta resta in questo browser: il gestionale,
      // aperto qui, la mostra tra le Richieste.
      var erroreInvio = $('.errore-invio', form);
      if (!S54.nuovaRichiesta(richiesta)) {
        if (!erroreInvio) {
          erroreInvio = document.createElement('p');
          erroreInvio.className = 'errore errore-invio';
          erroreInvio.setAttribute('role', 'alert');
          $('.modulo-invio', form).after(erroreInvio);
        }
        erroreInvio.textContent = 'Non siamo riusciti a inviare la richiesta. Riprovate, oppure chiamateci o scriveteci.';
        return;
      }
      if (erroreInvio) erroreInvio.textContent = '';
      var grazie = $('[data-grazie]');
      $('.grazie-titolo', grazie).textContent = 'Grazie, ' + richiesta.firstName;
      $('.grazie-testo', grazie).textContent = richiesta.phone
        ? 'Vi richiameremo al ' + richiesta.phone + ' per parlarne insieme.'
        : 'Vi scriveremo a ' + richiesta.email + ' per parlarne insieme.';
      form.hidden = true;
      grazie.hidden = false;
      window.scrollTo({ top: 0, behavior: 'smooth' });
      $('.grazie-nuova', grazie).onclick = function () {
        form.reset(); provato = false;
        tipo = conTipo && tipi.length === 1 ? tipi[0].label : '';
        $$('[data-tipo]', form).forEach(function (x) { var on = x.getAttribute('data-tipo') === tipo; x.setAttribute('aria-pressed', on); x.setAttribute('aria-checked', on); });
        $$('[data-richiesta]', form).forEach(function (b) { b.setAttribute('aria-pressed', 'false'); });
        if (erroreRichieste) erroreRichieste.textContent = '';
        $$('.campo', form).forEach(function (c) { c.classList.remove('sbagliato'); var er = $('.errore', c); if (er) er.textContent = ''; });
        if (conto) conto.textContent = '0/500';
        grazie.hidden = true; form.hidden = false;
      };
    });
  });
})();
