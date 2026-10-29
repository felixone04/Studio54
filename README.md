# Studio 54 – sito e app

Due progetti separati, con la stessa grafica:

| Cartella | Cosa contiene |
|---|---|
| [`sito/`](sito) | Il sito web in **HTML, CSS, JavaScript e PHP**: home, lavori, biografia, preventivo e gestionale (`riservata`). |
| [`app/`](app) | L'**app Android** in Flutter: le stesse pagine del sito e, dal menu, il gestionale per il titolare. |
| [`apk/`](apk) | L'APK pronta da installare sul telefono (`studio54.apk`). |

## Anteprima online

- Sito: https://felixone04.github.io/Studio54/
- App Android: il file [`apk/studio54.apk`](apk/studio54.apk), da copiare sul telefono e installare. Per ora sito e app restano separati: il sito non ha link all'app.

GitHub Pages non esegue PHP: a ogni push su `master` la pubblicazione trasforma le pagine PHP in HTML statico
(`sito/tools/esporta.sh`).

## Stato attuale

- I contenuti sono quelli d'esempio, in `sito/data/contenuti.json` e `gestionale.json` (generati
  dall'app, dalla cartella `app`, con `dart run tool/export_seed.dart ../sito/data`).
- Senza database tutto resta nel browser (sito) o sul telefono (app): le richieste del preventivo
  arrivano al gestionale aperto nello stesso browser, e le modifiche fatte nel gestionale si vedono lì.
- Il gestionale del sito funziona nell'anteprima su GitHub (accesso di prova: `titolare` / `studio54`).
  Nella versione PHP l'accesso arriverà dal server insieme al database.

## Prossimo passo: database su Cloudflare e sito su Hostinger

1. Database e foto su Cloudflare (D1 per i dati, R2 per foto e video, un Worker come API).
2. Sito su Hostinger con il dominio dello studio: i PHP leggono i contenuti dall'API (funzione `dati()`
   in `sito/inc/app.php`), il gestionale entra con un accesso controllato dal server.
3. L'app usa la stessa API: in Flutter basta una nuova implementazione di `Repository`
   (`app/lib/data/repository.dart`) che legge e scrive tramite l'API.

## Comandi utili (app)

```bash
cd app
flutter test
flutter build apk --release --target-platform android-arm,android-arm64
```
