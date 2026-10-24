/* Studio 54 · interazioni delle proposte per la home (pagina idee.php). */
(function () {
  'use strict';
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var due = function (n) { return (n < 10 ? '0' : '') + n; };
  var touch = window.matchMedia('(hover: none)').matches;

  /* 1 · Fisarmonica: si apre la striscia sotto il mouse; al tocco il primo
     tocco apre, il secondo porta ai lavori. */
  $$('.fisa').forEach(function (fisa) {
    var strisce = $$('.fisa-striscia', fisa);
    var apri = function (s) { strisce.forEach(function (x) { x.classList.toggle('aperta', x === s); }); };
    strisce.forEach(function (s) {
      s.addEventListener('mouseenter', function () { if (!touch) apri(s); });
      s.addEventListener('focus', function () { apri(s); });
      s.addEventListener('click', function (e) {
        if (!s.classList.contains('aperta')) { e.preventDefault(); apri(s); }
      });
    });
  });

  /* 2 · Messa a fuoco: scorrendo, ogni foto passa da sfocata a nitida. */
  $$('[data-fuoco]').forEach(function (sez) {
    var foto = $$('.fuoco-foto', sez), n = foto.length;
    var mirino = $('.fuoco-mirino', sez);
    var aggiorna = function () {
      var r = sez.getBoundingClientRect();
      var corsa = Math.max(1, sez.offsetHeight - window.innerHeight);
      var p = Math.min(0.9999, Math.max(0, -r.top / corsa)) * n;
      var k = Math.floor(p), t = p - k;
      // Sfocata all'inizio del suo tratto, nitida dopo il 45%.
      var nitido = Math.min(1, t / 0.45);
      foto.forEach(function (f, j) {
        f.classList.toggle('ora', j === k);
        if (j === k) {
          f.style.setProperty('--sfocato', ((1 - nitido) * 16).toFixed(1) + 'px');
          f.style.setProperty('--nitido', Math.max(0, (nitido - 0.6) / 0.4).toFixed(2));
        }
      });
      mirino.style.setProperty('--apertura', (1 - nitido).toFixed(2));
      sez.classList.toggle('a-fuoco', nitido >= 1);
    };
    window.addEventListener('scroll', aggiorna, { passive: true });
    window.addEventListener('resize', aggiorna);
    aggiorna();
  });

  /* 3 · Stampe sul tavolo: si trascinano e quella presa va sopra le altre. */
  $$('[data-tavolo]').forEach(function (tavolo) {
    var sopra = 100;
    $$('.stampa', tavolo).forEach(function (s) {
      var x0, y0, l0, t0, presa = false;
      s.addEventListener('pointerdown', function (e) {
        presa = true;
        s.setPointerCapture(e.pointerId);
        s.classList.add('presa');
        s.style.zIndex = ++sopra;
        x0 = e.clientX; y0 = e.clientY;
        l0 = s.offsetLeft; t0 = s.offsetTop;
      });
      s.addEventListener('pointermove', function (e) {
        if (!presa) return;
        var maxL = tavolo.clientWidth - s.offsetWidth * 0.4, maxT = tavolo.clientHeight - s.offsetHeight * 0.4;
        s.style.left = Math.min(maxL, Math.max(-s.offsetWidth * 0.6, l0 + e.clientX - x0)) + 'px';
        s.style.top = Math.min(maxT, Math.max(-s.offsetHeight * 0.4, t0 + e.clientY - y0)) + 'px';
      });
      var lascia = function () {
        if (!presa) return;
        presa = false;
        s.classList.remove('presa');
        // Posata di nuovo, un po' storta in modo diverso.
        s.style.setProperty('--r', (Math.random() * 14 - 7).toFixed(1) + 'deg');
      };
      s.addEventListener('pointerup', lascia);
      s.addEventListener('pointercancel', lascia);
    });
  });

  /* 4 · Prima e dopo: la linea si trascina (anche con le frecce). */
  $$('[data-prima-dopo]').forEach(function (pd) {
    var linea = $('.pd-linea', pd), attivo = false;
    var metti = function (v) {
      v = Math.min(100, Math.max(0, v));
      pd.style.setProperty('--p', v + '%');
      linea.setAttribute('aria-valuenow', Math.round(v));
    };
    var da = function (e) { var r = pd.getBoundingClientRect(); metti((e.clientX - r.left) / r.width * 100); };
    pd.addEventListener('pointerdown', function (e) { attivo = true; pd.setPointerCapture(e.pointerId); da(e); });
    pd.addEventListener('pointermove', function (e) { if (attivo) da(e); });
    pd.addEventListener('pointerup', function () { attivo = false; });
    pd.addEventListener('pointercancel', function () { attivo = false; });
    linea.addEventListener('keydown', function (e) {
      var v = parseFloat(getComputedStyle(pd).getPropertyValue('--p')) || 50;
      if (e.key === 'ArrowLeft') { metti(v - 5); e.preventDefault(); }
      if (e.key === 'ArrowRight') { metti(v + 5); e.preventDefault(); }
    });
  });

  /* 5 · Album: i fogli si girano come le pagine di un libro. */
  $$('[data-album]').forEach(function (album) {
    var fogli = $$('.foglio', album), n = fogli.length, girati = 0;
    var conto = $('.album-conto', album);
    var mostra = function () {
      fogli.forEach(function (f, k) {
        var g = k < girati;
        f.classList.toggle('girato', g);
        // I fogli già girati stanno sopra in ordine inverso.
        f.style.zIndex = g ? k + 1 : n - k;
      });
      conto.textContent = girati === 0 ? 'COPERTINA' : (girati === n ? 'FINE' : 'PAGINE ' + due(girati * 2) + '–' + due(girati * 2 + 1));
    };
    var vai = function (d) { girati = Math.min(n, Math.max(0, girati + d)); mostra(); };
    $$('[data-pagina]', album).forEach(function (b) { b.addEventListener('click', function () { vai(+b.getAttribute('data-pagina')); }); });
    fogli.forEach(function (f, k) { f.addEventListener('click', function () { vai(k < girati ? -1 : 1); }); });
    mostra();
  });
})();
