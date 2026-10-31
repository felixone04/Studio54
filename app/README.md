# Studio 54 – app Android (Flutter)

App Android dello studio, con la stessa grafica del sito (cartella `../sito`): le pagine pubbliche, l'area clienti e, entrando dall'area clienti con le credenziali del titolare, il gestionale.

| Pagina | Percorso | Cosa fa |
|---|---|---|
| Home | `/` | Carosello a tutto schermo (foto verticali; con il telefono girato quelle orizzontali del sito), poi i 4 lavori in evidenza |
| Lavori | `/lavori` | Elenco filtrabile per evento, stagione e location; il dettaglio mostra solo le foto (una sotto l'altra, sparse sul tablet in orizzontale) |
| Preventivo | `/preventivo` | Modulo a passi (evento, richieste, contatti, messaggio, riepilogo) con le voci scelte nel gestionale |
| Biografia | `/biografia` | Storia dello studio e metodo di lavoro |
| Area clienti | `/area-clienti` | Foto e video del cliente, divisi in cartelle, da guardare e scaricare; documenti e link |
| Gestionale | `/admin` | Richieste, calendario, lavori, preventivo, testi, caroselli, clienti, impostazioni |

## Avvio

```bash
flutter pub get
flutter test
flutter build apk --release --target-platform android-arm,android-arm64
# poi copia build/app/outputs/flutter-apk/app-release.apk in ../apk/studio54.apk
```

> Nota: usa `google_fonts` 8.x. La 9.x dipende dal nuovo pacchetto `material_ui` ed è incompatibile con il `material.dart` di Flutter 3.47.

## Gestionale

Si entra dall'Area clienti con le credenziali del titolare (di prova: `titolare` / `studio54`). Le sezioni sono raggruppate come nel gestionale del sito:

- **Attività** – Panoramica, Richieste (stato nuova → contattata → confermata, contatto rapido, "Fissa appuntamento"), Calendario
- **Sito e app** – Lavori (stella = in evidenza, Sito/App = dove si vede), Preventivo (voci e parti accese), Biografia, Contatti, Carosello orizzontale e verticale (si usa quello del verso dello schermo)
- **Solo app** – Area clienti (account, cartelle, foto, video, documenti)
- **Sistema** – Impostazioni: accesso del titolare, copia di sicurezza, dati d'esempio

## Dove stanno i dati

Per ora **tutti i dati sono sul telefono** (SharedPreferences, tramite `LocalRepository`), separati da quelli del sito. Quando arriverà il database (Cloudflare) basterà implementare i due metodi di `Repository` (`lib/data/repository.dart`) — `read(key)` e `write(key, json)` — con l'API e sostituire `LocalRepository` in `lib/main.dart`.

La copia di sicurezza dell'app e quella del gestionale del sito si possono caricare l'una nell'altra.

## Struttura

```
lib/
  main.dart, app.dart          avvio, router, tasto indietro, barre di sistema
  models/models.dart           contenuti, lavori, modulo preventivo, richieste, appuntamenti, clienti
  data/                        Repository (+ implementazione locale) e dati d'esempio
  state/app_state.dart         stato dell'app e operazioni
  services/                    salvataggio in galleria, tasto indietro, barre di sistema, Google Calendar (solo web)
  theme/app_theme.dart         palette, tipografia, misure, tema del gestionale
  widgets/                     barra e menu, footer, carosello, foto a schermo intero, icone sottili, componenti comuni
  pages/                       home, lavori, preventivo, biografia, area clienti
  pages/admin/                 gestionale
```

I contenuti d'esempio (testi, foto Unsplash, contatti fittizi) si sostituiscono dal gestionale.