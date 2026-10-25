/* Studio 54 · comportamento del sito pubblico (senza librerie). */
(function () {
  'use strict';

  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var due = function (n) { return (n < 10 ? '0' : '') + n; };

  /* ------------------------------------------------------ logo d'apertura */

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

  /* ---------------------------------------------------------- barra e menu */

  var barra = $('#barra');
  var aperturaHome = $('.pagina-home .apertura');
  var orizzontale = window.matchMedia('(min-aspect-ratio: 1/1)');
  // La barra non ha uno sfondo suo: prende quello della sezione che le passa
  // sotto (crema, lino...), così non si vede mai uno stacco.
  var coloreSotto = function () {
    var y = barra.offsetHeight + 1, x = window.innerWidth / 2;
    var el = document.elementFromPoint(x, Math.min(y, window.innerHeight - 1));
    var blocco = el && el.closest('main > *, .piede');
    var c = blocco ? getComputedStyle(blocco).backgroundColor : '';
    if (!c || c === 'transparent' || /rgba\(.*,\s*0\)$/.test(c)) c = '';
    barra.style.setProperty('--sotto', c || 'var(--carta)');
  };
  var aggiornaBarra = function () {
    if (!barra) return;
    coloreSotto();
    barra.classList.toggle('scorsa', window.scrollY > 10);
    // Nella home in orizzontale la barra è trasparente finché sta sopra la
    // foto d'apertura; poi prende il colore del sito.
    var suFoto = !!aperturaHome && orizzontale.matches &&
      window.scrollY < aperturaHome.offsetHeight - barra.offsetHeight;
    barra.classList.toggle('su-foto', suFoto);
  };
  window.addEventListener('scroll', aggiornaBarra, { passive: true });
  window.addEventListener('resize', aggiornaBarra);
  aggiornaBarra();

  var menu = $('#menu');
  var apriMenu = $('.barra-menu');
  if (menu && apriMenu) {
    var mostra = function (si) {
      if (si) {
        menu.hidden = false;
        requestAnimationFrame(function () { menu.classList.add('aperto'); });
      } else {
        menu.classList.remove('aperto');
        setTimeout(function () { menu.hidden = true; }, 450);
      }
      apriMenu.setAttribute('aria-expanded', si ? 'true' : 'false');
      document.body.style.overflow = si ? 'hidden' : '';
    };
    apriMenu.addEventListener('click', function () { mostra(true); });
    $('.menu-chiudi', menu).addEventListener('click', function () { mostra(false); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && !menu.hidden) mostra(false); });
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

  /* ------------------------------------------------- foto a schermo intero */

  var lb = $('#lightbox');
  var lbFoto = [], lbI = 0;
  function lbMostra() {
    var p = lbFoto[lbI];
    var img = $('figure img', lb);
    img.style.opacity = 0;
    img.onload = function () { img.style.opacity = 1; };
    img.src = p.src;
    img.alt = p.titolo || '';
    $('.lb-titolo', lb).textContent = p.titolo || '';
    $('.lb-meta', lb).textContent = p.meta || '';
    $('.lb-conto', lb).textContent = due(lbI + 1) + ' / ' + due(lbFoto.length);
  }
  function lbApri(foto, i) {
    lbFoto = foto; lbI = i;
    lb.hidden = false;
    document.body.style.overflow = 'hidden';
    lbMostra();
    $('.lb-chiudi', lb).focus();
  }
  function lbChiudi() { lb.hidden = true; document.body.style.overflow = ''; }
  function lbVai(d) { lbI = (lbI + d + lbFoto.length) % lbFoto.length; lbMostra(); }
  if (lb) {
    $('.lb-chiudi', lb).addEventListener('click', lbChiudi);
    $('.lb-prec', lb).addEventListener('click', function () { lbVai(-1); });
    $('.lb-succ', lb).addEventListener('click', function () { lbVai(1); });
    document.addEventListener('keydown', function (e) {
      if (lb.hidden) return;
      if (e.key === 'Escape') lbChiudi();
      if (e.key === 'ArrowRight') lbVai(1);
      if (e.key === 'ArrowLeft') lbVai(-1);
    });
    sfoglia(lb, function (d) { lbVai(d); });
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

  function apribile(el, fn) {
    el.addEventListener('click', fn);
    el.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); fn(); } });
  }

  /* ============================================================= APERTURA */

  $$('[data-carosello]').forEach(function (car) {
    var intervallo = +car.getAttribute('data-intervallo') || 4000;
    var tutte = $$('.diapo', car);
    var mostrate = tutte.slice();
    var i = 0, timer = null;

    var tUscita = null;
    function disegna() {
      var n = mostrate.length;
      if (!n) { tutte.forEach(function (x) { x.classList.remove('attiva', 'uscente'); }); return; }
      var d = mostrate[i];
      var prima = $('.diapo.attiva', car);
      // Dissolvenza incrociata: la foto che esce resta sotto finché la nuova
      // non è comparsa del tutto.
      tutte.forEach(function (x) { if (x !== prima) x.classList.remove('uscente'); });
      if (prima && prima !== d) { prima.classList.remove('attiva'); prima.classList.add('uscente'); }
      clearTimeout(tUscita);
      tUscita = setTimeout(function () { $$('.diapo.uscente', car).forEach(function (x) { x.classList.remove('uscente'); }); }, 1500);
      if (prima !== d) {
        // Riavvia la leggera "avvicinata" della foto che entra.
        var img = $('img', d); img.style.animation = 'none'; void img.offsetWidth; img.style.animation = '';
        d.classList.add('attiva');
      }
      car.classList.add('cambio');
      setTimeout(function () {
        $$('.ap-titolo', car).forEach(function (e) { e.textContent = d.getAttribute('data-titolo'); });
        $$('.ap-meta', car).forEach(function (e) { e.textContent = d.getAttribute('data-meta'); });
        $$('.ap-didascalia', car).forEach(function (e) { e.textContent = d.getAttribute('data-didascalia'); });
        $$('.ap-numero', car).forEach(function (e) { e.textContent = n > 1 ? due(i + 1) : ''; });
        car.classList.remove('cambio');
      }, 350);
      $$('.ap-conto', car).forEach(function (e) { e.textContent = n > 1 ? due(i + 1) + ' / ' + due(n) : ''; });
      $$('.ap-prec, .ap-succ', car).forEach(function (b) { b.hidden = n < 2; });
      $$('.avanzamento', car).forEach(function (a) {
        a.style.setProperty('--durata', intervallo + 'ms');
        a.innerHTML = '';
        if (n < 2) return;
        for (var k = 0; k < n; k++) {
          var s = document.createElement('span');
          s.className = k < i ? 'fatto' : (k === i ? 'ora' : '');
          a.appendChild(s);
        }
      });
    }
    function vai(k) {
      var n = mostrate.length;
      if (!n) return;
      i = ((k % n) + n) % n;
      disegna();
      riparti();
    }
    function riparti() {
      clearInterval(timer);
      if (!partito) return;
      if (mostrate.length > 1) timer = setInterval(function () { i = (i + 1) % mostrate.length; disegna(); }, intervallo);
    }

    // Nel carosello solo foto orizzontali: le verticali si tolgono appena
    // se ne conoscono le proporzioni.
    tutte.forEach(function (d) {
      var img = $('img', d);
      var controlla = function () {
        if (img.naturalWidth && img.naturalWidth <= img.naturalHeight) {
          var corrente = mostrate[i];
          mostrate = mostrate.filter(function (x) { return x !== d; });
          var k = mostrate.indexOf(corrente);
          i = k >= 0 ? k : 0;
          disegna();
          riparti();
        }
      };
      if (img.complete) controlla(); else img.addEventListener('load', controlla);
    });

    $$('.ap-prec', car).forEach(function (b) { b.addEventListener('click', function () { vai(i - 1); }); });
    $$('.ap-succ', car).forEach(function (b) { b.addEventListener('click', function () { vai(i + 1); }); });
    sfoglia(car, function (d) { vai(i + d); });
    document.addEventListener('visibilitychange', function () {
      if (!partito) return;
      if (document.hidden) clearInterval(timer); else riparti();
    });
    // La prima foto si vede già sotto il logo; il conto dei 4 secondi e la
    // linea di avanzamento partono quando il logo sparisce.
    disegna();
    quandoPronto(function () { disegna(); riparti(); });
  });

  /* ==================================================== STAMPE SUL TAVOLO */

  $$('[data-tavolo]').forEach(function (tavolo) {
    var stampe = $$('.stampa', tavolo), sopra = 100;
    var foto = stampe.map(function (s) { return { src: s.getAttribute('data-foto'), titolo: s.getAttribute('data-titolo'), meta: s.getAttribute('data-meta') }; });
    stampe.forEach(function (s, k) {
      var x0, y0, l0, t0, presa = false, mossa = false;
      s.addEventListener('pointerdown', function (e) {
        presa = true; mossa = false;
        s.setPointerCapture(e.pointerId);
        s.classList.add('presa');
        s.style.zIndex = ++sopra;
        x0 = e.clientX; y0 = e.clientY;
        l0 = s.offsetLeft; t0 = s.offsetTop;
      });
      s.addEventListener('pointermove', function (e) {
        if (!presa) return;
        var dx = e.clientX - x0, dy = e.clientY - y0;
        if (!mossa && Math.abs(dx) + Math.abs(dy) < 6) return;
        mossa = true;
        var maxL = tavolo.clientWidth - s.offsetWidth * 0.4, maxT = tavolo.clientHeight - s.offsetHeight * 0.4;
        s.style.left = Math.min(maxL, Math.max(-s.offsetWidth * 0.6, l0 + dx)) + 'px';
        s.style.top = Math.min(maxT, Math.max(-s.offsetHeight * 0.4, t0 + dy)) + 'px';
      });
      var lascia = function () {
        if (!presa) return;
        presa = false;
        s.classList.remove('presa');
        // Se non è stata spostata è un tocco: si guarda la foto.
        if (!mossa) { lbApri(foto, k); return; }
        // Posata di nuovo, un po' storta in modo diverso.
        s.style.setProperty('--r', (Math.random() * 14 - 7).toFixed(1) + 'deg');
      };
      s.addEventListener('pointerup', lascia);
      s.addEventListener('pointercancel', function () { presa = false; s.classList.remove('presa'); });
      s.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); lbApri(foto, k); } });
    });
  });
  /* ======================================================== FILTRI LAVORI */

  $$('[data-filtri]').forEach(function (box) {
    var scelte = {};
    var lavori = $$('.lavoro');
    var esito = $('.filtri-esito', box);
    var nessuno = $('.filtri-nessuno');

    function applica() {
      var visibili = 0;
      lavori.forEach(function (w) {
        var ok = Object.keys(scelte).every(function (k) { return !scelte[k] || w.getAttribute('data-' + k) === scelte[k]; });
        w.hidden = !ok;
        if (ok) visibili++;
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
          if (e.key === 'Escape') { lista.hidden = true; voce.focus(); }
        });
      });
    });
    document.addEventListener('click', function () { chiudiTutti(null); });
    $('.filtri-azzera', box).addEventListener('click', function () {
      $$('.filtro', box).forEach(function (f) { f.scegli(''); });
    });
    // Arrivando con un filtro nell'indirizzo (es. ?evento=matrimonio dal
    // mosaico della home) la scelta è già fatta.
    var qs = new URLSearchParams(location.search);
    $$('.filtro', box).forEach(function (f) {
      var v = (qs.get(f.getAttribute('data-filtro')) || '').toLowerCase();
      if (v && $('li[data-v="' + v.replace(/"/g, '') + '"]', f)) f.scegli(v);
    });
  });

  /* ============================================== COLLAGE (dettaglio lavoro) */

  $$('[data-collage]').forEach(function (box) {
    var tavole = $$('.tavola', box);
    var CAP = 36; // spazio della didascalia
    var rapporti = tavole.map(function () { return 1.5; });

    function rapporto(k) { return Math.min(3, Math.max(0.4, rapporti[k])); }

    // La prima orizzontale in apertura; poi ritmi diversi in base alle
    // proporzioni: verticale + due orizzontali, orizzontale + due verticali,
    // coppie, foto singole. Nessuna foto viene tagliata.
    function piano(oriz) {
      var n = oriz.length, righe = [], k = 1, giro = 0;
      if (!n) return righe;
      righe.push({ tipo: 'una', ids: [0] });
      var o = function (d) { return k + d < n ? oriz[k + d] : null; };
      while (k < n) {
        var a = o(0), b = o(1), c = o(2);
        if (!a) {
          if (b === true && c === true) { righe.push({ tipo: 'pila', alta: k, su: k + 1, giu: k + 2, sinistra: true }); k += 3; }
          else if (b === false && c !== null) { righe.push({ tipo: 'fila', ids: [k, k + 1, k + 2] }); k += 3; }
          else if (b !== null) { righe.push({ tipo: 'fila', ids: [k, k + 1] }); k += 2; }
          else { righe.push({ tipo: 'una', ids: [k] }); k += 1; }
        } else {
          if (b === false && c === false) { righe.push({ tipo: 'fila', ids: [k, k + 1, k + 2] }); k += 3; }
          else if (b === true && c === false) { righe.push({ tipo: 'pila', alta: k + 2, su: k, giu: k + 1, sinistra: false }); k += 3; }
          else if (b === true && c === true && giro % 2) { righe.push({ tipo: 'una', ids: [k] }); k += 1; }
          else if (b !== null) { righe.push({ tipo: 'fila', ids: [k, k + 1] }); k += 2; }
          else { righe.push({ tipo: 'una', ids: [k] }); k += 1; }
        }
        giro++;
      }
      return righe;
    }

    function misura(t, w, h) {
      t.style.width = w + 'px';
      $('.tavola-foto', t).style.height = h + 'px';
      $('.tavola-foto', t).style.aspectRatio = 'auto';
      return t;
    }

    function componi() {
      // In apertura la prima orizzontale; le altre restano in ordine.
      var prima = -1;
      for (var q = 0; q < tavole.length; q++) { if (rapporti[q] > 1) { prima = q; break; } }
      var ordine = tavole.map(function (_, q) { return q; });
      if (prima > 0) { ordine.splice(prima, 1); ordine.unshift(prima); }
      ordine.forEach(function (q, pos) { $('.n', tavole[q]).textContent = due(pos + 1); tavole[q].setAttribute('data-pos', pos); });
      var r = function (pos) { return rapporto(ordine[pos]); };
      var t = function (pos) { return tavole[ordine[pos]]; };

      box.innerHTML = '';
      var piena = Math.floor(box.clientWidth) - 1;
      var stile = getComputedStyle(box);
      piena -= parseFloat(stile.paddingLeft) + parseFloat(stile.paddingRight);
      var spazio = Math.max(10, Math.min(22, piena * 0.018));
      box.style.setProperty('--spazio', spazio + 'px');
      var maxH = window.innerHeight * 0.9;
      var telefono = window.innerWidth < 600;
      var riga = function () { var d = document.createElement('div'); d.className = 'collage-riga'; box.appendChild(d); return d; };

      if (telefono) {
        // Una sotto l'altra, intere.
        ordine.forEach(function (_, pos) { riga().appendChild(misura(t(pos), piena, piena / r(pos))); });
      } else {
        piano(ordine.map(function (_, pos) { return r(pos) > 1; })).forEach(function (p) {
          var d = riga();
          if (p.tipo === 'una') {
            var h = piena / r(p.ids[0]);
            if (r(p.ids[0]) <= 1) h = Math.min(h, maxH);
            d.appendChild(misura(t(p.ids[0]), h * r(p.ids[0]), h));
          } else if (p.tipo === 'fila') {
            var somma = p.ids.reduce(function (s, k) { return s + r(k); }, 0);
            var hf = Math.min((piena - spazio * (p.ids.length - 1)) / somma, maxH);
            p.ids.forEach(function (k) { d.appendChild(misura(t(k), hf * r(k), hf)); });
          } else {
            // La colonna delle due orizzontali è larga quanto basta perché
            // finisca alla stessa altezza della verticale.
            var av = r(p.alta), kk = 1 / r(p.su) + 1 / r(p.giu);
            var c = (piena - spazio - av * (CAP + spazio)) / (av * kk + 1);
            var hp = c * kk + CAP + spazio;
            var col = document.createElement('div');
            col.className = 'collage-colonna';
            col.appendChild(misura(t(p.su), c, c / r(p.su)));
            col.appendChild(misura(t(p.giu), c, c / r(p.giu)));
            var alta = misura(t(p.alta), av * hp, hp);
            if (p.sinistra) { d.appendChild(alta); d.appendChild(col); } else { d.appendChild(col); d.appendChild(alta); }
          }
        });
      }
      box.classList.add('composto');
    }

    // Si compone quando si conoscono le proporzioni di tutte le foto (al
    // massimo dopo 3 secondi, con quelle note fino ad allora).
    var mancanti = tavole.length, fatto = false;
    function pronta() {
      if (fatto) return;
      fatto = true;
      componi();
      var t0;
      window.addEventListener('resize', function () { clearTimeout(t0); t0 = setTimeout(componi, 150); });
    }
    tavole.forEach(function (tv, k) {
      var img = $('img', tv);
      var letta = function () {
        if (img.naturalWidth) rapporti[k] = img.naturalWidth / img.naturalHeight;
        if (--mancanti === 0) pronta();
      };
      if (img.complete && img.naturalWidth) letta();
      else { img.addEventListener('load', letta, { once: true }); img.addEventListener('error', letta, { once: true }); }
    });
    setTimeout(pronta, 3000);

    var titolo = box.getAttribute('data-titolo'), meta = box.getAttribute('data-meta');
    tavole.forEach(function (tv) {
      apribile(tv, function () {
        var ordinate = tavole.slice().sort(function (a, b) { return (+a.getAttribute('data-pos') || 0) - (+b.getAttribute('data-pos') || 0); });
        var foto = ordinate.map(function (x) { return { src: x.getAttribute('data-foto'), titolo: x.getAttribute('data-didascalia') || titolo, meta: meta }; });
        lbApri(foto, ordinate.indexOf(tv));
      });
    });
  });

  /* ============================================================ PREVENTIVO */

  $$('[data-modulo]').forEach(function (form) {
    var campo = function (n) { return $('[data-campo="' + n + '"]', form); };
    var input = function (n) { var c = campo(n); return c && $('input, select, textarea', c); };
    var toccati = {};
    var provato = false;

    /* Controlli, uguali a quelli dell'app. */
    var regole = {
      tipo: function (v) { return !v && input('tipo').required ? 'Scegli il tipo di evento' : ''; },
      data: function (v) {
        if (!v) return "Inserisci la data dell'evento";
        var m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(v);
        if (!m) return 'Scrivi la data come gg/mm/aaaa';
        var d = new Date(+m[3], +m[2] - 1, +m[1]);
        if (d.getFullYear() !== +m[3] || d.getMonth() !== +m[2] - 1 || d.getDate() !== +m[1]) return 'Questa data non esiste';
        var oggi = new Date(); oggi.setHours(0, 0, 0, 0);
        if (d < oggi) return 'La data è già passata';
        var limite = new Date(oggi); limite.setFullYear(oggi.getFullYear() + 5);
        if (d > limite) return 'Scegli una data entro 5 anni';
        return '';
      },
      altro: function (v) { return input('tipo').value === 'Altro' && !v ? 'Scrivi di che evento si tratta' : ''; },
      luogo: function (v) { return v.length < 2 ? "Indica la città o la location dell'evento" : ''; },
      nome: function (v) { return nomeOk(v, 'nome'); },
      cognome: function (v) { return nomeOk(v, 'cognome'); },
      telefono: function (v) {
        if (!v) return 'Inserisci il numero di telefono';
        var c = v.replace(/\D/g, '').length;
        return c < 8 || c > 15 ? 'Numero non valido: servono da 8 a 15 cifre' : '';
      },
      email: function (v) {
        if (!v) return "Inserisci l'indirizzo email";
        return /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$/.test(v) ? '' : 'Email non valida (es. nome@email.it)';
      }
    };
    function nomeOk(v, cosa) {
      if (!v) return 'Inserisci il ' + cosa;
      return v.replace(/['\s\-]/g, '').length < 2 ? 'Il ' + cosa + ' deve avere almeno 2 lettere' : '';
    }

    function controlla(n, mostra) {
      var c = campo(n);
      if (!c || c.hidden) return '';
      var msg = regole[n](input(n).value.trim());
      if (mostra) {
        c.classList.toggle('sbagliato', !!msg);
        $('.errore', c).textContent = msg;
      }
      return msg;
    }

    /* Caratteri ammessi mentre si scrive. */
    var filtri = {
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
      var evento = el.tagName === 'SELECT' ? 'change' : 'input';
      el.addEventListener(evento, function () {
        if (filtri[n]) { var p = filtri[n](el.value); if (p !== el.value) el.value = p; }
        if (n === 'tipo') {
          campo('tipo').classList.toggle('pieno', !!el.value);
          campo('altro').hidden = el.value !== 'Altro';
        }
        toccati[n] = true;
        controlla(n, true);
      });
      el.addEventListener('blur', function () { if (el.value || provato) { toccati[n] = true; controlla(n, true); } });
    });

    /* Data dal calendario. */
    var nativo = $('.calendario-nativo', form), testoData = input('data');
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

    /* Note: caratteri usati. */
    var note = input('note'), conto = $('.conta-caratteri', form);
    note.addEventListener('input', function () { conto.textContent = note.value.length + '/500'; });

    /* Servizi. */
    var voci = $$('.scelta-voce', form);
    var erroreServizi = $('.errore-servizi', form);
    function servizi() { return voci.filter(function (b) { return b.getAttribute('aria-pressed') === 'true'; }).map(function (b) { return b.getAttribute('data-servizio'); }); }
    function controllaServizi(mostra) {
      var msg = voci.length && !servizi().length ? 'Scegli almeno una voce' : '';
      if (mostra && erroreServizi) erroreServizi.textContent = msg;
      return msg;
    }
    voci.forEach(function (b) {
      b.addEventListener('click', function () {
        b.setAttribute('aria-pressed', b.getAttribute('aria-pressed') === 'true' ? 'false' : 'true');
        if (provato) controllaServizi(true);
      });
    });
    // Arrivando da un link con un pacchetto o un servizio, le voci sono già scelte.
    var qs = new URLSearchParams(location.search);
    var pacchetti = JSON.parse(form.getAttribute('data-pacchetti') || '{}');
    var pre = (qs.get('p') && pacchetti[qs.get('p')]) || (qs.get('s') ? [qs.get('s')] : []);
    voci.forEach(function (b) { if (pre.indexOf(b.getAttribute('data-servizio')) >= 0) b.setAttribute('aria-pressed', 'true'); });

    /* Consenso. */
    var consenso = $('.consenso', form), spunta = $('input', consenso), errorePrivacy = $('.errore-privacy', form);
    function controllaConsenso(mostra) {
      var msg = spunta.checked ? '' : 'Serve il consenso per inviare la richiesta.';
      if (mostra) { consenso.classList.toggle('sbagliato', !!msg); errorePrivacy.textContent = msg; }
      return msg;
    }
    spunta.addEventListener('change', function () { if (provato) controllaConsenso(true); });

    /* Invio. */
    form.addEventListener('submit', function (e) {
      provato = true;
      var primo = null;
      ['tipo', 'data', 'altro', 'luogo'].forEach(function (n) { if (controlla(n, true) && !primo) primo = campo(n); });
      if (controllaServizi(true) && !primo) primo = $('[data-passo="servizi"]', form);
      ['nome', 'cognome', 'telefono', 'email'].forEach(function (n) { if (controlla(n, true) && !primo) primo = campo(n); });
      if (controllaConsenso(true) && !primo) primo = consenso;
      $('input[name="servizi"]', form).value = servizi().join(',');
      if (primo) {
        e.preventDefault();
        var y = primo.getBoundingClientRect().top + window.scrollY - window.innerHeight * 0.15;
        window.scrollTo({ top: y, behavior: 'smooth' });
        return;
      }
      // Anteprima senza database: la richiesta non si invia, si mostra il
      // ringraziamento. Con il database il modulo andrà al server (PHP).
      if (!form.hasAttribute('data-invia')) {
        e.preventDefault();
        var grazie = $('[data-grazie][hidden]');
        $('.grazie-titolo', grazie).textContent = 'Grazie, ' + input('nome').value.trim();
        $('.grazie-testo', grazie).textContent = 'Ti richiameremo al ' + input('telefono').value.trim() + ' per parlarne insieme.';
        form.hidden = true;
        $('.preventivo-testa').hidden = true;
        grazie.hidden = false;
        window.scrollTo({ top: 0, behavior: 'smooth' });
        $('.grazie-nuova', grazie).onclick = function () {
          form.reset(); provato = false;
          voci.forEach(function (b) { b.setAttribute('aria-pressed', 'false'); });
          $$('.campo', form).forEach(function (c) { c.classList.remove('sbagliato', 'pieno'); var er = $('.errore', c); if (er) er.textContent = ''; });
          campo('altro').hidden = true;
          conto.textContent = '0/500';
          grazie.hidden = true; form.hidden = false; $('.preventivo-testa').hidden = false;
        };
      }
    });
  });

  /* ========================================================== AREA CLIENTI */

  // Accesso. Con PHP il modulo va al server, che controlla email e password;
  // nell'anteprima statica si entra solo con i clienti d'esempio.
  $$('[data-accesso-cliente]').forEach(function (form) {
    var demo = form.getAttribute('data-demo');
    var errore = $('.errore-accesso', form);
    form.addEventListener('submit', function (e) {
      var email = $('#c-email', form).value.trim().toLowerCase(), pw = $('#c-password', form).value;
      if (!email || !pw) { e.preventDefault(); errore.textContent = 'Inserite email e password.'; return; }
      if (!demo) return;
      e.preventDefault();
      var id = JSON.parse(demo)[email];
      if (!id || pw !== 'studio54') { errore.textContent = 'Email o password non corrette.'; return; }
      location.href = 'cliente-' + encodeURIComponent(id) + '.html';
    });
  });

  // Album da sfogliare: due pagine affiancate su schermi larghi, una pagina
  // alla volta su telefono. I fogli girano come in un libro vero.
  $$('[data-album]').forEach(function (album) {
    var foto = JSON.parse(album.getAttribute('data-foto') || '[]');
    var libro = $('.album-libro', album), conto = $('.album-conto', album);
    var titolo = album.getAttribute('data-titolo'), data = album.getAttribute('data-data');
    var fogli = [], girati = 0, singolo = null;
    function pagina(classe, html) { var d = document.createElement('div'); d.className = classe; d.innerHTML = html; return d; }
    function testoCopertina() {
      var t = document.createElement('div');
      t.className = 'copertina-dentro';
      t.innerHTML = '<img src="assets/img/mark.png" alt=""><p></p><small></small>';
      $('p', t).textContent = titolo; $('small', t).textContent = data;
      return t;
    }
    function faccia(classe, p) {
      var f = pagina('faccia ' + classe, '');
      if (!p) { f.appendChild(testoCopertina()); return f; }
      var img = document.createElement('img'); img.src = p.src; img.alt = p.didascalia || ''; img.loading = 'lazy';
      f.appendChild(img);
      if (p.didascalia) { var c = document.createElement('figcaption'); c.textContent = p.didascalia; f.appendChild(c); }
      return f;
    }
    function costruisci() {
      var s = window.innerWidth < 720;
      if (s === singolo) return;
      singolo = s; girati = 0; fogli = [];
      album.classList.toggle('singolo', s);
      libro.innerHTML = '';
      var fine = pagina('pagina-fissa destra', '<div class="copertina-dentro"><p>FINE</p><small>' + foto.length + ' foto</small></div>');
      if (s) {
        // Una pagina alla volta: la copertina, poi le foto una sopra l'altra.
        libro.appendChild(fine);
        var pagine = [null].concat(foto);
        pagine.forEach(function (p) {
          var f = pagina('foglio', '');
          f.appendChild(faccia('fronte', p));
          fogli.push(f);
        });
      } else {
        var sx = pagina('pagina-fissa sinistra', ''); sx.appendChild(testoCopertina());
        libro.appendChild(sx); libro.appendChild(fine);
        for (var k = 0; k < foto.length; k += 2) {
          var f = pagina('foglio', '');
          f.appendChild(faccia('fronte', foto[k]));
          var dietro = foto[k + 1] ? faccia('retro', foto[k + 1]) : pagina('faccia retro', '');
          f.appendChild(dietro);
          fogli.push(f);
        }
      }
      fogli.forEach(function (f, k) {
        libro.appendChild(f);
        f.addEventListener('click', function () { vai(k < girati ? -1 : 1); });
      });
      mostra();
    }
    function mostra() {
      var n = fogli.length;
      fogli.forEach(function (f, k) {
        var g = k < girati;
        f.classList.toggle('girato', g);
        f.style.zIndex = g ? k + 1 : n - k + 10;
      });
      if (singolo) conto.textContent = girati === 0 ? 'COPERTINA' : (girati >= n ? 'FINE' : due(girati) + ' / ' + due(foto.length));
      else conto.textContent = girati === 0 ? 'COPERTINA' : (girati >= n ? 'FINE' : 'PAGINE ' + due(girati * 2 - 1) + '–' + due(Math.min(foto.length, girati * 2)));
    }
    function vai(d) { girati = Math.min(fogli.length, Math.max(0, girati + d)); mostra(); }
    $$('[data-pagina]', album).forEach(function (b) { b.addEventListener('click', function () { vai(+b.getAttribute('data-pagina')); }); });
    sfoglia(libro, vai);
    var grande = $('.album-grande', album);
    if (grande) grande.addEventListener('click', function () {
      var i = singolo ? Math.max(0, girati - 1) : Math.max(0, girati * 2 - 1);
      lbApri(foto.map(function (p) { return { src: p.grande, titolo: p.didascalia || titolo, meta: '' }; }), Math.min(i, foto.length - 1));
    });
    costruisci();
    var t0; window.addEventListener('resize', function () { clearTimeout(t0); t0 = setTimeout(costruisci, 150); });
  });

  // Cambio password del cliente: per ora solo i controlli (il salvataggio
  // arriverà con il database).
  $$('[data-cambia-password]').forEach(function (form) {
    var err = $('.errore-password', form);
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var a = $('#p-nuova', form).value, b = $('#p-ripeti', form).value;
      var vecchio = $('.messaggio-ok', form); if (vecchio) vecchio.remove();
      if (a.length < 8) { err.textContent = 'La password deve avere almeno 8 caratteri.'; return; }
      if (a !== b) { err.textContent = 'Le due password non coincidono.'; return; }
      err.textContent = '';
      var ok = document.createElement('p'); ok.className = 'messaggio-ok';
      ok.textContent = 'Anteprima: la nuova password verrà salvata quando il sito sarà collegato al database.';
      form.appendChild(ok); form.reset();
    });
  });
})();