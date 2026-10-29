/* Studio 54 · i dati del sito, letti da sito e gestionale (senza librerie).
 *
 * La pagina li riceve da PHP (<script id="s54-dati">). Finché non c'è il
 * database, le modifiche fatte dal gestionale restano in questo browser
 * (localStorage) e il sito le mostra subito, sempre in questo browser. Con
 * Cloudflare queste funzioni chiederanno e salveranno i dati tramite l'API:
 * sito e gestionale non cambiano. */
window.S54 = (function () {
  'use strict';

  var CHIAVE_PUBBLICI = 's54-pubblici-v2';
  var CHIAVE_PRIVATI = 's54-privati-v2';
  var CHIAVE_RICHIESTE = 's54-richieste-v2';
  var PUBBLICI = ['content', 'carouselSite', 'carouselApp', 'works', 'quoteForm'];

  function leggiPagina(id) {
    var el = document.getElementById(id);
    if (!el) return {};
    try { return JSON.parse(el.textContent) || {}; } catch (e) { return {}; }
  }
  function leggi(k) {
    try { var v = localStorage.getItem(k); return v ? JSON.parse(v) : null; } catch (e) { return null; }
  }
  function scrivi(k, v) {
    try { localStorage.setItem(k, JSON.stringify(v)); return true; } catch (e) { return false; }
  }
  function togli(k) { try { localStorage.removeItem(k); } catch (e) {} }
  var copia = function (v) { return JSON.parse(JSON.stringify(v)); };

  var base = leggiPagina('s54-dati');
  var bozza = leggi(CHIAVE_PUBBLICI);

  /** Testi, caroselli, lavori e modulo: quelli del gestionale, se modificati qui. */
  function pubblici() {
    var d = copia(base);
    if (bozza) PUBBLICI.forEach(function (k) { if (bozza[k] !== undefined) d[k] = copia(bozza[k]); });
    d.content = d.content || {};
    d.content.contacts = d.content.contacts || {};
    d.carouselSite = d.carouselSite || [];
    d.carouselApp = d.carouselApp || [];
    d.works = d.works || [];
    d.quoteForm = d.quoteForm || {};
    return d;
  }

  function salvaPubblici(d) {
    var v = {};
    PUBBLICI.forEach(function (k) { v[k] = d[k]; });
    var ok = scrivi(CHIAVE_PUBBLICI, v);
    if (ok) bozza = v;
    return ok;
  }

  /** Richieste, calendario, clienti e accesso del titolare (solo gestionale).
   * Vi aggiunge le richieste arrivate dal modulo del sito in questo browser. */
  function privati(iniziali) {
    var d = leggi(CHIAVE_PRIVATI) || copia(iniziali || {});
    d.quotes = d.quotes || [];
    d.appointments = d.appointments || [];
    d.clients = d.clients || [];
    d.admin = d.admin || (iniziali && iniziali.admin) || {};
    var nuove = leggi(CHIAVE_RICHIESTE) || [];
    if (nuove.length) {
      var ids = d.quotes.map(function (q) { return q.id; });
      // Dalla più vecchia alla più nuova: ognuna va in cima, la più nuova resta prima.
      nuove.slice().reverse().forEach(function (q) { if (ids.indexOf(q.id) < 0) d.quotes.unshift(q); });
      // Si tolgono dalla coda solo se sono state salvate davvero.
      if (scrivi(CHIAVE_PRIVATI, d)) togli(CHIAVE_RICHIESTE);
    }
    return d;
  }

  function salvaPrivati(d) { return scrivi(CHIAVE_PRIVATI, d); }

  /** Una richiesta inviata dal modulo del sito. */
  function nuovaRichiesta(q) {
    var l = leggi(CHIAVE_RICHIESTE) || [];
    l.unshift(q);
    return scrivi(CHIAVE_RICHIESTE, l);
  }

  /** Torna ai dati d'esempio (cancella le modifiche fatte in questo browser). */
  function ripristina() {
    [CHIAVE_PUBBLICI, CHIAVE_PRIVATI, CHIAVE_RICHIESTE].forEach(togli);
    bozza = null;
  }

  /* -------------------------------------------------------------- aiuti */

  var ext = document.documentElement.getAttribute('data-ext') || 'html';

  /** Indirizzo di una pagina del sito: lavoro.html?id=... o lavoro.php?id=... */
  function url(pagina, id) {
    return pagina + '.' + ext + (id ? '?id=' + encodeURIComponent(id) : '');
  }

  /** Le foto di Unsplash si chiedono alla larghezza che serve. */
  function foto(u, w) {
    u = u || '';
    if (u.indexOf('images.unsplash.com') < 0) return u;
    if (/[?&]w=\d+/.test(u)) return u.replace(/([?&])w=\d+/, '$1w=' + w);
    return u + (u.indexOf('?') < 0 ? '?' : '&') + 'w=' + w;
  }

  /** Attributi src, srcset e sizes per un <img>. */
  function srcset(u, sizes) {
    if ((u || '').indexOf('images.unsplash.com') < 0) return 'src="' + esc(u) + '"';
    var set = [480, 800, 1200, 1600, 2200].map(function (w) { return esc(foto(u, w)) + ' ' + w + 'w'; }).join(', ');
    return 'src="' + esc(foto(u, 1200)) + '" srcset="' + set + '" sizes="' + esc(sizes || '100vw') + '"';
  }

  function esc(t) {
    return String(t == null ? '' : t).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  var MESI = { gennaio: 'Inverno', febbraio: 'Inverno', marzo: 'Primavera', aprile: 'Primavera', maggio: 'Primavera', giugno: 'Estate', luglio: 'Estate', agosto: 'Estate', settembre: 'Autunno', ottobre: 'Autunno', novembre: 'Autunno', dicembre: 'Inverno' };
  var STAGIONI = ['Primavera', 'Estate', 'Autunno', 'Inverno'];

  /** Stagione scelta, altrimenti quella del mese scritto nella data. */
  function stagione(w) {
    if ((w.season || '').trim()) return w.season.trim();
    var d = (w.date || '').toLowerCase();
    for (var m in MESI) if (d.indexOf(m) >= 0) return MESI[m];
    return '';
  }

  function copertina(w) {
    return (w.cover || '').trim() || ((w.photos || [])[0] || {}).url || '';
  }

  /** I lavori visibili sul sito, nell'ordine scelto. */
  function lavoriSito(d) {
    return (d.works || []).filter(function (w) { return w.published !== false && w.onSite !== false; });
  }

  /** Al massimo quattro lavori in evidenza nella home. */
  function inEvidenza(d) {
    return lavoriSito(d).filter(function (w) { return w.featured; }).slice(0, 4);
  }

  function unisci(parti, sep) {
    return parti.map(function (p) { return (p || '').trim(); }).filter(Boolean).join(sep || ' · ');
  }

  return {
    pubblici: pubblici, salvaPubblici: salvaPubblici,
    privati: privati, salvaPrivati: salvaPrivati,
    nuovaRichiesta: nuovaRichiesta, ripristina: ripristina,
    inBozza: function () { return !!bozza; },
    url: url, foto: foto, srcset: srcset, esc: esc,
    stagione: stagione, STAGIONI: STAGIONI, copertina: copertina,
    lavoriSito: lavoriSito, inEvidenza: inEvidenza, unisci: unisci,
    leggiPagina: leggiPagina
  };
})();
