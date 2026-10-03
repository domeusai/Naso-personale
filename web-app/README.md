# Naso Personale Web

PWA in italiano per gestire una collezione privata di profumi. Non usa account, server applicativi, cloud o dipendenze remote.

## Pubblicare con GitHub Pages

1. Pubblica il repository su GitHub con il ramo che vuoi usare (per esempio `main`).
2. Nel repository apri **Settings → Pages**.
3. In **Build and deployment**, scegli **Deploy from a branch**, seleziona il ramo e la cartella **/(root)**, quindi salva.
4. Attendi la pubblicazione. Apri la web app all’indirizzo `https://<utente>.github.io/<repository>/web-app/`.

I percorsi di asset, manifest e service worker sono relativi: funzionano anche quando il repository viene servito da una sottocartella GitHub Pages. Pages fornisce HTTPS, necessario per installazione PWA, service worker e accesso alla fotocamera.

In alternativa, per pubblicare la PWA alla radice del dominio Pages, configura il workflow di Pages in modo che distribuisca il contenuto di `web-app/` invece della radice del repository. Non serve una fase di compilazione.

## Installare su iPhone

1. Apri l’indirizzo Pages con **Safari** su iPhone e carica la pagina mentre sei online.
2. Attendi il completamento del primo caricamento; il service worker mette in cache l’app e le sue risorse.
3. Tocca **Condividi → Aggiungi alla schermata Home**. Attiva **Apri come app web** se l’opzione compare, poi tocca **Aggiungi**.
4. Avvia Naso Personale dalla nuova icona. Dopo il primo caricamento, schede, immagini e funzioni dell’app sono disponibili offline.

Per l’uso come sito durante lo sviluppo puoi aprire `index.html`, ma fotocamera, service worker e modalità offline richiedono un server HTTPS o `localhost`. Per una prova locale avvia dalla root del repository `python3 -m http.server 8000` e visita `http://localhost:8000/web-app/`.

## Dati, foto e backup

Schede e immagini vengono salvate in **IndexedDB** sul dispositivo. Il browser non invia i dati a un server. I pulsanti **Esporta backup** e **Importa backup** creano e leggono un file JSON che include le immagini; in importazione puoi sostituire la collezione o unire il backup. Conserva il file esportato in un luogo sicuro: rimuovere i dati di Safari o il sito può cancellare anche l’archivio locale.

La fotocamera e la libreria foto sono gestite dal selettore immagini nativo di Safari. Il permesso viene richiesto quando aggiungi una foto.

## File e icone

- `index.html`: interfaccia completa e metadati iOS.
- `app.js`, `database.js`, `styles.css`: interazioni, IndexedDB e layout responsive.
- `manifest.json`, `service-worker.js`: installazione standalone e shell offline.
- `icons/`: icone PNG per iOS e browser, più sorgente SVG.

Per rigenerare le icone PNG con Node.js 18 o successivo: `node icons/generate-icons.mjs`.