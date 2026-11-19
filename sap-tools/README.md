# sap-tools

Nur lesender SAP-Zugriff per RFC (RFC_READ_TABLE, RPY_PROGRAM_READ). Keine schreibenden Bausteine.
Zugangsdaten werden zur Laufzeit aus `../../Meesenburg.ES/src/Meesenburg.ES.API.SAPData/appsettings.json` gelesen.

```bash
cd SapRead && dotnet build
SAPSYS=MEP dotnet run --no-build -- table KNA1 "KUNNR = '0010010180'" KUNNR ERNAM ERDAT
SAPSYS=MEP dotnet run --no-build -- source "YCL_SDWS_INTERFACE_CMD========CM006"
SAPSYS=MEP dotnet run --no-build -- joblog YFI_ES_ERP_BUCHUNGEN 20004200   # Jobprotokoll (XBP)
SAPSYS=MEP dotnet run --no-build -- spool YFI_ES_ERP_BUCHUNGEN 20004200    # Spoolliste = Fehlerliste der Buchhaltungsübergabe je Beleg (XBP)
```

- `abap/<SYS>/` – gesicherte ABAP-Quellen (YSDWS*, Stand 2026-10-06)
- `exports/` – Objektlisten und Tabellenauszüge
- `ANALYSE_WERBEVERBOT.md` – Befund fehlendes Merkmal WERBEVERBOT bei Kundenanlage (YSDWS13)

## tools/ (Hilfsprogramme aus den Sitzungen, nur Quellcode)
- `tools/RfcRead` – nur lesend: Varianten/Verzeichnislisting per RFC (Lizenz aus sapdata-appsettings).
- `tools/BapiCheck` – nur lesend: SAP_Export-CSV wie YFI_UEBERGABE_BELEGE_ES2000 aufbauen und BAPI_ACC_DOCUMENT_CHECK (bucht nicht).
- `tools/SpoolParseTest` – Test für `SAPBroker.ParseTransferSpool` (Spoolliste des Übergabe-Reports) gegen eine echte Spool-Ausgabe von `SapRead spool`.
- `tools/LaterExportsTest` – Test für `AccountingTransferService.FindLaterExportsAsync` gegen die echte Freigabe (nur lesen, SMB-Zugang aus dem Key Vault per az).
- `tools/SmbChunkWriteTest` – Test für `SmbFileStream` des Workers (Datei per Link eingebunden) gegen die echte Freigabe, schreibt nur in MEQ `SiSe-Test` und löscht wieder: alter Weg (ganze Datei in einem WriteFile) muss ab 1 MiB mit „Not enough credits“ scheitern, neuer Weg 50 Dateien bis 8 MiB in einer Sitzung schreiben. `SMB_CREDS` aus `AdminSmbCredentials`, `dotnet run`. Anlass: Abbruch Abendexport 08./18.11.2026.
- `tools/TransferFileInspect` – alle Fassungen einer Übergabedatei (abgelehnt, Prüfung, ersetzt, gebucht …) mit den Zeilen bestimmter Referenzen zeigen, nur lesen: `dotnet run -- 20261109_183018 900010703 900010704`.
- `tools/SupplierMappingTest` – Test der Lieferanten-Umwandlung im Worker (Projektreferenz): Rechnungssteller W0100 (Lieferant 2) wird übersprungen, der Rest umgewandelt. `dotnet run`.
- `tools/CsvEscapeTest` – Maskieren in der Übergabe-CSV (Worker `CsvHelpers.EscapeField`): Steuerzeichen/„;“ erzeugen keine Zeile/Spalte. `dotnet run`.
- `tools/MaterialRequeryCheck` – nur lesen: Materialbewegungen einer Übergabedatei erneut aus esERP holen (Exportfenster aus Mongo und weites Fenster) und zeilengenau mit der Datei vergleichen; zeigt zerbrochene Zeilen. `MONGO_CS=… dotnet run -- SAP_Export_….csv` (VPN).
- `tools/MaterialGapAnalysis` – nur lesen: alle Materialbewegungen esERP seit 01.09. gegen alle Übergabedateien (fehlend, doppelt, geändert, Nummernfolge). `dotnet run -- <ausgabe.csv>` (VPN). Ergebnis 16.11.: `exports/material-abgleich-2026-11-16/`.
- `tools/SmbRead` – Freigaben per SMB lesen (Zugang aus dem Key Vault).
- `tools/mongoinsert` – JSON-Array in eine Collection einfügen, nur neue `_id` (MONGO_CS als Umgebungsvariable). Prod nur nach Freigabe!
- `local-dev/` – lokaler Schnelltest (sapdata, Worker, Portal) + Stolperfallen, siehe `local-dev/README.md`.
- `tools/mongowrite` – gezielte Einzeländerung (`update` mit Filter, der genau 1 Dokument treffen muss; `insert`), gibt vorher/nachher aus. Prod nur nach Freigabe!
- `prod-fixes/` – Skripte für einmalige Prod-Korrekturen (führt der Nutzer selbst aus).
- `tools/SmbBrowse` – nur lesend: Ordner der ES-Freigabe auflisten (`--recurse`), Dateien nach ./out laden (`--download`).


**Umgezogen (18.11.2026):** esERP-Werkzeuge (EsSqlRead, ApiMovementProbe) nach `../eserp-tools/`, JtlSqlRead nach `../jtl-tools/`.