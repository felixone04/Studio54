# Studio 54 – app Android (Flutter)

App Android dello studio, con la stessa grafica del sito (cartella `../sito`): pagine pubbliche e, dal menu "Area riservata", il gestionale per il titolare. Il codice gira anche sul web, ma il sito ufficiale è quello in HTML/PHP.

| Pagina | Percorso | Cosa fa |
|---|---|---|
| Home | `/#/` | Carosello di sole foto orizzontali (intere, 4 secondi ciascuna), manifesto, "La mostra" (galleria con lightbox), footer con info e contatti |
| Lavori | `/#/lavori` | Elenco filtrabile per evento, stagione e tipo di location; il dettaglio mostra solo le foto in collage |
| Preventivo | `/#/preventivo` | Modulo unico: evento (tipo, data, luogo), servizi, contatti; campi obbligatori con controllo dei caratteri |
| Biografia | `/#/biografia` | Storia dello studio e metodo di lavoro |
| Admin | `/#/admin` | Gestione di tutto il sito, richieste e calendario |

## Avvio

```bash
flutter pub get
flutter run            # telefono o emulatore collegato
flutter build apk --release --target-platform android-arm,android-arm64
```

Build di produzione: `flutter build web --release` (output in `build/web`).

> Nota: usa `google_fonts` 8.x. La 9.x dipende dal nuovo pacchetto `material_ui` ed è incompatibile con il `material.dart` di Flutter 3.47.

## Area admin

Al primo accesso (`/#/admin`) si crea la password. Sezioni:

- **Panoramica** – numeri e scorciatoie
- **Richieste preventivo** – elenco, stato (nuova → contattata → confermata), contatto rapido (telefono / WhatsApp / email), stima interna del totale, "Fissa appuntamento"
- **Calendario** – vista mensile + agenda del giorno, sincronizzato con Google Calendar
- **Servizi e prodotti** – aggiungi/modifica/ordina/nascondi; il prezzo è facoltativo e **solo interno**
- **Pacchetti** – combinazioni pronte di servizi
- **Galleria** – foto della mostra e del carosello (caricamento da computer o URL)
- **Lavori** – foto, didascalie, evento, stagione (automatica dal mese) e tipo di location (masseria, mare, montagna…)
- **Pagina Home / Biografia / Identità e contatti** – tutti i testi, le immagini, i contatti, il colore di accento e i tipi di festa del modulo
- **Impostazioni** – Client ID Google, password, backup/ripristino

## Google Calendar

Gli appuntamenti si scrivono nel **calendario principale** dell'account Google con cui si fa l'accesso, quindi compaiono su tutti i dispositivi che usano quel calendario.

Una sola volta serve un Client ID OAuth (Admin → Impostazioni riporta i passaggi, con l'indirizzo esatto da autorizzare):

1. console.cloud.google.com → nuovo progetto
2. Abilita **Google Calendar API**
3. Schermata consenso OAuth (Esterno) + il proprio Gmail come utente di prova
4. Credenziali → ID client OAuth → *Applicazione web* → origine JavaScript autorizzata = indirizzo del sito
5. Incolla il Client ID in Impostazioni (oppure `--dart-define=GOOGLE_CLIENT_ID=...` in fase di build)

Lo scope richiesto è solo `calendar.events`. Il token vive in memoria e dura circa un'ora: poi basta "Ricollega Google" dal Calendario.

## Dove stanno i dati (importante)

Per ora **tutti i dati sono nel browser** (localStorage) tramite `LocalRepository`. Significa che:

- le richieste di preventivo inviate dai visitatori restano nel *loro* browser, non arrivano al titolare;
- le modifiche fatte in admin si vedono solo da quel browser;
- le foto caricate dal computer sono incorporate nei dati (limite ~5 MB totali).

Per un sito reale serve un archivio online condiviso. L'app è già predisposta: basta implementare i due metodi di `Repository` (`lib/data/repository.dart`) — `read(key)` e `write(key, json)` — con Firebase/Supabase/API proprie e sostituire `LocalRepository` in `lib/main.dart`. Con un backend vero andrebbero anche: login admin con account (al posto della password locale), upload delle foto su storage, e scrittura delle richieste dal sito pubblico con regole di sicurezza.

La password admin protegge solo l'interfaccia, non i dati salvati nel browser.

## Struttura

```
lib/
  main.dart, app.dart          avvio, tema, router
  config.dart                  Client ID Google (opzionale)
  models/models.dart           contenuti, servizi, pacchetti, foto, richieste, appuntamenti
  data/                        Repository (+ implementazione locale) e dati di esempio
  state/app_state.dart         stato dell'app e operazioni
  services/                    Google Identity Services + API Calendar
  theme/app_theme.dart         palette, tipografia, tema chiaro per l'admin
  widgets/                     hero, galleria d'arte, navigazione, footer, componenti comuni
  pages/                       home, preventivo, biografia
  pages/admin/                 area riservata
```

I contenuti di esempio (testi, foto Unsplash, contatti fittizi) vanno sostituiti dall'admin.
