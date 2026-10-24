# Studio 54 – sito e app

Due progetti separati, con la stessa grafica:

| Cartella | Cosa contiene |
|---|---|
| [`sito/`](sito) | Il sito web in **HTML, CSS, JavaScript e PHP**: home, lavori, biografia, preventivo e area riservata (per ora solo grafica). |
| [`app/`](app) | L'**app Android** in Flutter: le stesse pagine del sito e, dal menu, il gestionale per il titolare. |

## Anteprima online

- Sito: https://felixone04.github.io/Studio54/
- App Android: https://felixone04.github.io/Studio54/app/studio54.apk (si scarica anche dal link nel footer del sito)

GitHub Pages non esegue PHP: a ogni push su `master` la pubblicazione trasforma le pagine PHP in HTML statico
(`sito/tools/esporta.sh`) e aggiunge l'APK presa dall'ultima *release* del progetto.

## Stato attuale

- I contenuti sono quelli d'esempio, in `sito/data/contenuti.json` (generato dall'app con
  `dart run tool/export_seed.dart ../sito/data/contenuti.json`).
- Il modulo del preventivo fa tutti i controlli ma non salva ancora le richieste.
- L'area riservata del sito è un'anteprima grafica: verrà rifatta da zero collegata al database.

## Prossimo passo: dominio e Hostinger

1. Sito su Hostinger con il dominio dello studio, database MySQL.
2. In PHP: lettura dei contenuti dal database (funzione `dati()` in `sito/inc/app.php`), salvataggio dei
   preventivi, area riservata vera con accesso.
3. API in PHP protetta da una chiave, usata dall'app: in Flutter basta una nuova implementazione di
   `Repository` (`app/lib/data/repository.dart`) che legge e scrive tramite l'API.

## Comandi utili (app)

```bash
cd app
flutter test
flutter build apk --release --target-platform android-arm,android-arm64
```
