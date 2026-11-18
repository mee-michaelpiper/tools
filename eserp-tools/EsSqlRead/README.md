# EsSqlRead

Nur lesend: SQL-Abfragen gegen die esERP-Datenbanken (Lesebenutzer `apiReadOnly`, liest alle Datenbanken).
Zugang: KV-Secret `esErpSqlReadonly` (kv-meesenburg-prod; JSON: server, database=master, username, password, encrypt,
trustServerCertificate=true – der SQL-Server hat noch ein selbst erzeugtes Zertifikat, nicht von meesenburg-VMCA001-CA;
IT soll eins der CA für vmsql005.meesenburg.de ausstellen, dann auf false).

```bash
./run.sh "SELECT name FROM sys.databases" ["weitere Abfrage" …]
```
Jede Abfrage läuft in einer Transaktion, die zurückgerollt wird. Tabellen immer voll qualifizieren (`esdata_live.dbo.PERSONAL`).
Prod schonend abfragen: große Tabellen (ARTMLIE_DET 328 Mio., KUNDEN_DET/_REV je 34 Mio. Zeilen) nicht ohne Index-Filter scannen.

## Aufbau (Stand 27.10.2026)
Server `vmsql005.meesenburg.de\ES2000` (SQL Server 2019, 15.0.4500).

| Datenbank | Inhalt |
|---|---|
| `esdata_live` | **Prod** (143 Personal = API esapi.meesenburg.de) |
| `esdata_dev` | DEV (esapi-test) |
| `esdata_test` | Test |
| `esdata` | alt (6 Personal, Stand 2025) |
| `esmat_live` / `_dev` / `_test` / `esmat` | Materialkatalog |
| `esnls`, `esnls_dev` | Texte/Sprachen (vermutlich) |
| `com4work`, `com4Work_live`, `com4cockpit` | com4vision-Produkte (nicht untersucht) |

Allgemein in esdata_*:
- ~2.680 Tabellen, Spaltennamen meist GROSS, die API benennt sie camelCase (z. B. `persEndDat` ↔ Spalte `PERSENDEDAT`, `monatAllowed` ↔ `MONTALLOWED`).
- **Keine Fremdschlüssel** auf PERSONAL – Bezüge laufen nur über Spalten wie `PERSONALNR`, `AENDERPERSNR`, `ERSTELLPERSNR`, `PERSNRVK`, `GEPRUEFTPERSNR`, `PERSNREINTRAG` … Wer löscht, hinterlässt verwaiste Sätze (Beispiel: TERMINE von Personal 91413108 ohne PERSONAL-Satz).
- **Änderungsprotokoll**: zu ~800 Tabellen gibt es `<TAB>_REV` (Revision: REVNRNEW, REVNROLD, AENDERDAT, STATUS …) und `<TAB>_DET` (je Revision ein Feld: REVNR, FELDNAME, INTVAL/FLOATVAL/BOOLVAL/STRINGVAL/DATETIMEVAL/MEMOVAL). Die Haupttabelle hat dazu eine Spalte `REVNR`.
- `SAP_CHANGED` in ARTIKEL, KUNDEN, LIEFER, GPARTNER (→ API `…/sap-changed-null`).
- Personalnummer 999 = Benutzer der esERP-API (`PERSNREINTRAG`/`AENDERPERSNR` = 999 → von der Schnittstelle).

Personal und Kalender:
- `PERSONAL`: Stammsatz, `PERSENDEDAT` (= API persEndDat), `STATUS`.
- `TERMINE`: Kalender (TERMINNR, PERSONALNR, TERMINBEGINN/-ENDE, MATCHCODE, AKTIVARTNR, STATUS, UrlbLfdNr → URLBANTR).
  - `AKTIVARTNR = 9999`: Abwesenheiten aus dem SAP-Abgleich (MATCHCODE leer, „Abwesend“, „Arzttermin“ …).
  - **MATCHCODE „Ausgeschieden“**: legt das esERP selbst an, wenn `persEndDat` über die API gesetzt wird (Beginn = Ende, ~6 Monate lang).
- `URLBANTR`: Urlaubs-/Abwesenheitsanträge zu den Terminen.
- `ABWESENHEIT_SAP_MAPPING`: SAPNr (Beleg aus BAPI_EMPATTABS_GETLIST) → LfdNr (URLBANTR) + TerminNr, ErstelltAm/GeaendertAm, IstAktuell (setzt `/abwesenheiten/sync/complete` zurück; nicht berührte werden gelöscht).

## Referenzsuche vor dem Löschen (`refscan.py`, 28.10.2026)
`/usr/bin/python3 refscan.py [--db esdata_live] 12767916 …` – sucht die Personalnummern in allen int/bigint-Spalten (Personal-Spalten überall, übrige in Tabellen ≤ 2 Mio. Zeilen), `_REV`/`_DET` getrennt als „Protokoll“.
Typische Treffer und Bedeutung:
- `PERSONAL.PERSKALORDER` = eigene Nummer (Kalenderreihenfolge), immer da.
- `TERMINE_DET`/`URLBANTR_DET.INTVAL` = Protokoll unserer SAP-Abwesenheiten (angelegt/gelöscht), unkritisch.
- `TERMINE.PERSONALNR` mit MATCHCODE „Ausgeschieden“, AKTIVARTNR 9999, PERSNREINTRAG 999 = vom esERP zum Austrittsdatum angelegt.
- `PERS_KEN` = Anmeldung (LIZENZART, Windows-Benutzer, `AADObjectID`), 99 Einträge; `EINPERS` = Benutzereinstellungen (ID/Wert), `EINPERSM` = Oberflächenstand inkl. JSON „Recent“ (zuletzt geöffnete Kunden/Angebote …) – fehlt `EINPERSM`, hat die Person den Client nie benutzt.
- `ADRGPS` (PERSONENART 8 = Personal) = Geokoordinate der Personaladresse.
