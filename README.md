# tools

Private Hilfs- und Analysewerkzeuge von M. Piper (nicht für die Organisation). Vor einem neuen Werkzeug hier nachsehen, ob es schon eins gibt.

| Ordner | Inhalt |
|---|---|
| `sap-tools/` | SAP (RFC/BAPI lesen: SapRead, RfcRead, BapiCheck; MEQ-Tests; ABAP-Quellen in `abap/`), Mongo (MongoRead), SMB, Prüfprogramme rund um ES (Buchhaltungsübergabe, Mapper), `local-dev/` (Portal/Worker/sapdata lokal starten), `prod-fixes/` |
| `eserp-tools/` | esERP: SQL lesend (EsSqlRead), API-Proben (ApiMovementProbe) |
| `jtl-tools/` | JTL-Wawi: SQL lesend (JtlSqlRead), Skripte aus dem SiSe-Shop |
| `ops-tools/` | Server- und Doku-Skripte (Windows-Server, Sicherungen, md2pdf) |

Regeln:
- **Keine Daten im Git:** `exports/`, `data/`, CSV/Excel, Logs, Zugangsdaten sind per `.gitignore` ausgeschlossen. Zugangsdaten kommen aus dem Key Vault bzw. den User-Secrets.
- Werkzeuge lesen nur; schreibende Werkzeuge (MEQ, prod-fixes) sind im Namen bzw. README gekennzeichnet und laufen nur nach ausdrücklicher Freigabe.
- Pfade zu Projekten relativ zu `~/repos/` (z. B. `../../../../Meesenburg.ES/src/…`). `~/repos/sap-tools` ist eine Verknüpfung auf `tools/sap-tools`.
