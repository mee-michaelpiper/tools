# Lokaler Test (Portal, sapdata, Worker) – ohne AppHost

Reihenfolge: `./start-sapdata-dev.sh` (Port 5241) → `./start-worker-dev.sh` (5471, Dev-Profil) → `./start-web-dev.sh` (https://localhost:7009).
Am besten jeweils als Hintergrundprozess starten (nicht über nohup – siehe unten).

## Stolperfallen
- **sapdata 500 „Unable to load shared library sapnwrfc“**: `DYLD_LIBRARY_PATH` fehlt. macOS (SIP) entfernt DYLD_* bei `nohup`, `/usr/bin/env` usw. → Skript direkt starten, Variablen per `export` im Skript.
- **Portal startet nicht „RedisConnectionString not found“**: `Cache__Provider=Mongo` setzen (Redis gibt es nicht).
- **zsh `export` mit Bindestrich** (`services__meesenburg-es-api-sapdata__http__0`) geht nicht → `exec env NAME=… dotnet run`.
- **Pakete 1.0.x noch nicht veröffentlicht** (NU1102/401): `dotnet restore --source <localfeed> --source https://api.nuget.org/v3/index.json --source <Azure-DevOps-Feed>`, danach `build --no-restore`. Local Feed: `~/repos/sap-tools/localfeed` (neue Pakete nach `pack` dorthin kopieren).
- **`az` für die sapdata-API (api://448e0a21-…) abgelaufen** → nicht per curl testen, sondern über den Worker (holt sein Token per Client-Credentials aus dem Key Vault) oder Nutzer bitten `az login` zu erneuern. Key-Vault-Token (`vault.azure.net`) funktioniert separat.
- **Worker lokal**: nur Dev-Profil (Dev-ES-Worker, Jobs:Transport=Mongo, InvoiceMail/InvoiceDispatch/Accounting gesperrt). Jobs einreihen mit `jobqueue`:
  `export MONGO_CS="$(az keyvault secret show --vault-name kv-meesenburg-prod --name MongoDBConnectionString --query value -o tsv)"`
  `dotnet run -- queue '{"Types":["customer"]}'` / `dotnet run -- status <id>` (Job + Dev-ES-Search/SearchMeta). JobType im Code anpassen.
- **Portal-Login lokal**: im Chrome des Nutzers „Mit Microsoft anmelden“ (SSO, kein Passwort). Nach Neustart des Portals ist die Sitzung weg.
- **Gescoptes CSS (*.razor.css)** braucht Neustart des Portals (kein Hot Reload bei `dotnet run`).
- **MudBlazor.min.css** hat Regeln mit ID-Spezifität, z. B. `#components-reconnect-modal button { color; margin:40px !important; uppercase }` → eigene Regeln immer mit derselben ID schreiben.
- Dashboard-Kacheln „nicht erreichbar“ lokal = ApiService/andere Dienste laufen nicht, kein Fehler.
- **`dotnet pack` packt bei Authorization/Jobs.Contracts die ALTE DLL** (`GeneratePackageOnBuild=true` → pack baut nicht neu, nimmt bin/Release vom letzten Release-Build; 04.11.2026 so 1.0.13/1.0.17 kaputt erzeugt und verworfen). Richtig: `dotnet build <projekt> -c Release` (erzeugt das nupkg in bin/Release), dann nach localfeed kopieren und prüfen: `unzip -l <nupkg> | grep dll` (Datum von heute?) bzw. `unzip -p … | strings | grep <neuer Typ>`.
- **Nie veröffentlichte Paketversionen neu packen und nie `~/.nuget/packages/<paket>/<version>` löschen:** Der DevOps-Feed braucht `AZURE_DEVOPS_PAT`, den meine Shell nicht hat (401). Änderung am Paket = neue Version; Anzeige-Texte lieber im Web (z. B. `JobUi.AreaTitle`). Vorher fragen, ob die Version schon veröffentlicht ist.
- **Mongo (Prod-ES-*) läuft im Rechenzentrum** (`vmmocl001–003.meesenburg.de:27017`, Replica Set) – nur mit VPN erreichbar. „TimeoutException … selecting a server … Disconnected“ bei MongoRead = VPN/Netz prüfen. Pods im AKS loggen nur nach Mongo (kubectl logs ist leer).

## Buchhaltungsübergabe in MEQ testen (20.10.2026)
- MEQ-Ordner auf der Freigabe: `Daten\Programme\SAP\MEQ\ES_ERP\Rechnungen` (= `/DFS-MEQ/ES_ERP/Rechnungen/` auf dem MEQ-Server). `EsErpSmbCredentials` (es2kerp) hat **keine** Rechte → `AdminSmbCredentials` (api-service) nehmen.
- **Nicht** die MEQ-Variante „MEE ÜBERGABE“ nutzen: der Report liest *alle* Einträge im Ordner (dort liegen FIS-Testdateien von 2025). Eigene Variante **„SISE TEST“** → `…/Rechnungen/SiSe-Test/` (mit `verarbeitet`/`fehlerhaft`).
- Ablauf: CSV (UTF-8, CRLF, 2 Kopfzeilen wie Prod) → `tools/BapiCheck` mit `SAPSYS=MEQ` prüfen → `tools/SmbPutMeq put …\SiSe-Test <datei>` (SMB_CREDS = AdminSmbCredentials) → `tools/MeqTransferRun run` (XBP-Job YFI_ES_ERP_BUCHUNGEN_SISETEST, zeigt Jobprotokoll) → BKPF/BSEG per SapRead `SAPSYS=MEQ`.
- Alle RFC-Werkzeuge außer SapRead brauchen `DYLD_LIBRARY_PATH=~/repos/sap-tools/SapRead/bin/Debug/net10.0`.
