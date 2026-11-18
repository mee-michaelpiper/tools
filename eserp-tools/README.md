# esERP-Werkzeuge (nur lesend)

- `ApiMovementProbe` – nur lesen: was `GET /lager/bewegungen` je Datumsfenster für eine Bewegungsnummer liefert (URL, Anzahl, Roh-JSON). `dotnet run -- 630012991 "2026-10-21T00:00:00|2026-10-22T00:00:00"` (VPN, net10.0 – unter net9.0 TLS-Fehler RemoteCertificateNameMismatch).
- `EsSqlRead` – nur lesend: SQL gegen das esERP (vmsql005\ES2000, esdata_live = Prod). `./run.sh "SELECT …"`. Tabellenaufbau siehe `EsSqlRead/README.md`.
