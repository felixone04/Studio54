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
    foto: ['Foto', '<div class="campo-foto"><button type="button" class="bottone bordo"><i class="ico ico-carica"></i>Carica foto</button></div><br><label class="campo"><span>Titolo *</span><input value="{chi}"></label><label class="campo"><span>Didascalia</span><textarea rows="2"></textarea></label><div class="coppia"><label class="campo"><span>Luogo</span><input></label><label class="campo"><span>Anno</span><input></label></div>'],
    cliente: ['Cliente', '<div class="coppia"><label class="campo"><span>Nome e cognome *</span><input name="nome" value="{chi}"></label><label class="campo"><span>Email *</span><input name="email" type="email"></label></div><label class="campo"><span>Telefono (per WhatsApp)</span><input name="telefono" type="tel"></label><label class="campo"><span>Evento (es. Il matrimonio di Anna e Paolo)</span><input></label><div class="coppia"><label class="campo"><span>Data</span><input placeholder="18 maggio 2024"></label><label class="campo"><span>Luogo</span><input></label></div><label class="campo"><span>Benvenuto nella sua area</span><textarea rows="2"></textarea></label>'],
    pdf: ['Documento', '<div class="campo-foto"><button type="button" class="bottone bordo"><i class="ico ico-carica"></i>Scegli il PDF</button><span class="tenue piccolo">Fino a 20 MB</span></div><br><label class="campo"><span>Nome del documento *</span><input></label><label class="campo"><span>Nota per il cliente</span><input></label>'],
    link: ['Link', '<label class="campo"><span>Nome *</span><input placeholder="Galleria completa"></label><label class="campo"><span>Indirizzo *</span><input type="url" placeholder="https://"></label><label class="campo"><span>Nota per il cliente</span><input></label>']
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
  /* Clienti: alla creazione (o con "Nuova password") si genera la password
     e si prepara il messaggio da mandare al cliente. */
  var cred = $('#credenziali'), creando = false;
  function generaPassword() {
    var s = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789', p = '', r = new Uint32Array(10);
    crypto.getRandomValues(r);
    for (var k = 0; k < 10; k++) p += s[r[k] % s.length];
    return p;
  }
  function mostraCredenziali(nome, email, telefono, titolo) {
    var area = new URL('area-clienti' + (location.pathname.slice(-5) === '.html' ? '.html' : '.php'), location.href).href;
    var msg = 'Ciao ' + (nome.split(' ')[0] || '') + ',\nda oggi puoi vedere le foto del tuo evento e i documenti nella tua area riservata di Studio 54.\n\n' +
      'Indirizzo: ' + area + '\nEmail: ' + email + '\nPassword: ' + generaPassword() + '\n\nTi consigliamo di cambiare la password al primo accesso.';
    $('.finestra-titolo', cred).textContent = titolo;
    $('.messaggio-cliente', cred).value = msg;
    $('[data-whatsapp]', cred).href = 'https://wa.me/' + (telefono || '').replace(/\D/g, '') + '?text=' + encodeURIComponent(msg);
    $('[data-email-cliente]', cred).href = 'mailto:' + encodeURIComponent(email) + '?subject=' + encodeURIComponent('La tua area riservata di Studio 54') + '&body=' + encodeURIComponent(msg);
    cred.hidden = false;
  }
  if (cred) {
    $('[data-chiudi-credenziali]', cred).addEventListener('click', function () { cred.hidden = true; });
    $('[data-copia-messaggio]', cred).addEventListener('click', function () {
      var t = $('.messaggio-cliente', cred);
      if (navigator.clipboard) navigator.clipboard.writeText(t.value); else { t.select(); document.execCommand('copy'); }
      dici('Messaggio copiato.');
    });
    $$('[data-nuova-password]').forEach(function (b) {
      b.addEventListener('click', function () { mostraCredenziali(b.getAttribute('data-nuova-password'), b.getAttribute('data-email'), '', 'Nuova password'); });
    });
    $$('[data-nuovo-cliente]').forEach(function (b) {
      b.addEventListener('click', function () { creando = true; apriFinestra('cliente', ''); });
    });
  }

  if (fin) {
    $('[data-chiudi-finestra]', fin).addEventListener('click', function () { fin.hidden = true; creando = false; });
    $('[data-salva]', fin).addEventListener('click', function () {
      if (creando) {
        var nome = $('[name="nome"]', fin).value.trim(), email = $('[name="email"]', fin).value.trim();
        if (!nome || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { dici('Inserisci nome ed email del cliente.'); return; }
        fin.hidden = true; creando = false;
        mostraCredenziali(nome, email, $('[name="telefono"]', fin).value, 'Account creato');
        return;
      }
      fin.hidden = true; dici(DEMO);
    });
    fin.addEventListener('click', function (e) { if (e.target === fin) fin.hidden = true; });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { fin.hidden = true; laterale(false); } });
  }
})();
