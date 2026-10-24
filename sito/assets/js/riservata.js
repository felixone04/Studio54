/* Studio 54 · area riservata, anteprima grafica: tutto funziona a vista ma
   niente viene salvato. Con il database verrà rifatta collegando i dati. */
(function () {
  'use strict';
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };

  /* Accesso: qualsiasi password porta alla panoramica (senza mai mettere la
     password nell'indirizzo). */
  var accesso = $('[data-accesso]');
  if (accesso) {
    accesso.addEventListener('submit', function (e) {
      e.preventDefault();
      location.href = accesso.getAttribute('action');
    });
    return;
  }

  /* Avviso breve in basso. */
  var avviso = $('#avviso-breve'), tAvviso;
  function dici(msg) {
    avviso.textContent = msg;
    avviso.hidden = false;
    clearTimeout(tAvviso);
    tAvviso = setTimeout(function () { avviso.hidden = true; }, 3200);
  }
  var DEMO = 'Anteprima grafica: il salvataggio arriverà con il database.';
  $$('[data-demo]').forEach(function (b) {
    b.addEventListener(b.tagName === 'SELECT' || b.type === 'checkbox' ? 'change' : 'click', function () { dici(DEMO); });
  });

  /* Menu laterale su telefono. */
  var lat = $('#laterale'), velo = $('[data-chiudi-laterale]');
  function laterale(si) { lat.classList.toggle('aperta', si); velo.classList.toggle('aperta', si); }
  $$('[data-apri-laterale]').forEach(function (b) { b.addEventListener('click', function () { laterale(true); }); });
  if (velo) velo.addEventListener('click', function () { laterale(false); });

  /* Richieste: filtro per stato. */
  var filtri = $('[data-filtra-stato]');
  if (filtri) {
    $$('.chip', filtri).forEach(function (c) {
      c.addEventListener('click', function () {
        $$('.chip', filtri).forEach(function (x) { x.classList.toggle('attivo', x === c); });
        var s = c.getAttribute('data-stato');
        $$('.richiesta').forEach(function (r) { r.hidden = !!s && r.getAttribute('data-stato') !== s; });
      });
    });
  }

  /* Lavori: occhio "visibile sul sito"; galleria: stella del carosello. */
  $$('[data-occhio]').forEach(function (b) {
    b.addEventListener('click', function () {
      var riga = b.closest('.riga'), spenta = riga.classList.toggle('spenta');
      $('.ico', b).className = 'ico ' + (spenta ? 'ico-occhio-no' : 'ico-occhio');
      dici(spenta ? 'Nascosto dal sito (anteprima).' : 'Di nuovo visibile sul sito (anteprima).');
    });
  });
  $$('[data-stella]').forEach(function (b) {
    b.addEventListener('click', function () { b.classList.toggle('accesa'); dici(DEMO); });
  });
  $$('[data-copia]').forEach(function (b) {
    b.addEventListener('click', function () {
      var u = new URL(b.getAttribute('data-copia'), location.href).href;
      if (navigator.clipboard) navigator.clipboard.writeText(u);
      dici('Link copiato: chi lo apre trova il pacchetto già scelto.');
    });
  });
  $$('.colore').forEach(function (b) {
    b.addEventListener('click', function () {
      $$('.colore').forEach(function (x) { x.classList.toggle('scelto', x === b); });
      mostraSalva();
    });
  });

  /* Moduli dei contenuti: compare la barra "Salva" alla prima modifica. */
  function mostraSalva() { var b = $('.barra-salva'); if (b) b.hidden = false; }
  $$('[data-demo-modulo]').forEach(function (f) {
    f.addEventListener('input', mostraSalva);
    var annulla = $('[data-annulla]', f);
    if (annulla) annulla.addEventListener('click', function () { f.reset(); $('.barra-salva', f).hidden = true; });
  });

  /* Calendario del mese, con gli appuntamenti d'esempio. */
  var cal = $('[data-calendario]');
  if (cal) {
    var eventi = JSON.parse(cal.getAttribute('data-calendario') || '[]');
    var mesi = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'];
    var oggi = new Date();
    var primo = eventi.length ? new Date(eventi[0].start) : oggi;
    var vista = new Date(primo.getFullYear(), primo.getMonth(), 1);
    var stessoGiorno = function (a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); };
    function disegna() {
      $('.cal-mese', cal).textContent = mesi[vista.getMonth()] + ' ' + vista.getFullYear();
      var griglia = $('.cal-griglia', cal);
      griglia.innerHTML = '';
      var inizio = new Date(vista);
      inizio.setDate(1 - ((vista.getDay() + 6) % 7)); // dal lunedì
      for (var k = 0; k < 42; k++) {
        var g = new Date(inizio); g.setDate(inizio.getDate() + k);
        if (k >= 35 && g.getMonth() !== vista.getMonth()) break;
        var cella = document.createElement('div');
        cella.className = 'cal-cella' + (g.getMonth() !== vista.getMonth() ? ' fuori' : '') + (stessoGiorno(g, oggi) ? ' oggi' : '');
        cella.innerHTML = '<span class="cal-num">' + g.getDate() + '</span>';
        eventi.forEach(function (ev) {
          if (!stessoGiorno(new Date(ev.start), g)) return;
          var e = document.createElement('span');
          e.className = 'cal-evento';
          e.textContent = (ev.allDay ? '' : new Date(ev.start).toTimeString().slice(0, 5) + ' ') + ev.title;
          e.title = ev.title;
          e.addEventListener('click', function () { apriFinestra('appuntamento', ev.title); });
          cella.appendChild(e);
        });
        griglia.appendChild(cella);
      }
    }
    $$('[data-mese]', cal).forEach(function (b) {
      b.addEventListener('click', function () { vista.setMonth(vista.getMonth() + (+b.getAttribute('data-mese'))); disegna(); });
    });
    disegna();
  }

  /* Finestre di modifica (solo grafica). */
  var fin = $('#finestra');
  var moduli = {
    appuntamento: ['Appuntamento', '<label class="campo"><span>Titolo</span><input value="{chi}"></label><div class="coppia"><label class="campo"><span>Giorno</span><input type="date"></label><label class="campo"><span>Luogo</span><input value="Studio"></label></div><div class="coppia"><label class="campo"><span>Dalle</span><input type="time" value="10:00"></label><label class="campo"><span>Alle</span><input type="time" value="11:00"></label></div><label class="campo"><span>Note</span><textarea rows="3"></textarea></label>'],
    servizio: ['Servizio', '<label class="campo"><span>Nome *</span><input value="{chi}"></label><label class="campo"><span>Descrizione</span><textarea rows="3"></textarea></label><div class="coppia"><label class="campo"><span>Categoria</span><input value="Fotografia"></label><label class="campo"><span>Prezzo interno (€)</span><input inputmode="decimal"></label></div>'],
    pacchetto: ['Pacchetto', '<label class="campo"><span>Nome *</span><input value="{chi}"></label><label class="campo"><span>Sottotitolo</span><input></label><label class="campo"><span>Descrizione</span><textarea rows="3"></textarea></label>'],
    lavoro: ['Lavoro', '<label class="campo"><span>Titolo *</span><input value="{chi}"></label><div class="coppia"><label class="campo"><span>Evento (es. Matrimonio)</span><input></label><label class="campo"><span>Data (es. Giugno 2024)</span><input></label></div><div class="coppia"><label class="campo"><span>Stagione</span><select><option>Automatica (dalla data)</option><option>Primavera</option><option>Estate</option><option>Autunno</option><option>Inverno</option></select></label><label class="campo"><span>Tipo di location</span><input placeholder="Masseria, Mare, Montagna…"></label></div><label class="campo"><span>Luogo</span><input></label><label class="campo"><span>Racconto</span><textarea rows="3"></textarea></label><p class="etichetta-campo">Foto</p><div class="azioni"><button type="button" class="bottone bordo"><i class="ico ico-carica"></i>Carica dal dispositivo</button><button type="button" class="bottone bordo"><i class="ico ico-link"></i>Da indirizzo</button></div>'],
    foto: ['Foto', '<div class="campo-foto"><button type="button" class="bottone bordo"><i class="ico ico-carica"></i>Carica foto</button></div><br><label class="campo"><span>Titolo *</span><input value="{chi}"></label><label class="campo"><span>Didascalia</span><textarea rows="2"></textarea></label><div class="coppia"><label class="campo"><span>Luogo</span><input></label><label class="campo"><span>Anno</span><input></label></div>']
  };
  function apriFinestra(tipo, chi) {
    var m = moduli[tipo];
    $('.finestra-titolo', fin).textContent = (chi ? 'Modifica ' : 'Nuovo ') + m[0].toLowerCase();
    var tmp = document.createElement('div');
    tmp.textContent = chi || '';
    $('.finestra-corpo', fin).innerHTML = m[1].replace('{chi}', tmp.innerHTML.replace(/"/g, '&quot;'));
    fin.hidden = false;
    var primo = $('input, textarea', fin);
    if (primo) primo.focus();
  }
  $$('[data-finestra]').forEach(function (b) {
    b.addEventListener('click', function () { apriFinestra(b.getAttribute('data-finestra'), b.getAttribute('data-chi') || ''); });
  });
  if (fin) {
    $('[data-chiudi-finestra]', fin).addEventListener('click', function () { fin.hidden = true; });
    $('[data-salva]', fin).addEventListener('click', function () { fin.hidden = true; dici(DEMO); });
    fin.addEventListener('click', function (e) { if (e.target === fin) fin.hidden = true; });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { fin.hidden = true; laterale(false); } });
  }
})();
