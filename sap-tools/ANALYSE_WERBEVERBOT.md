# Fehlendes Merkmal WERBEVERBOT bei Kundenanlage über YSDWS13

Stand 2026-10-06, MEP/MEQ nur lesend geprüft. Quellen: `abap/MEP/YCL_SDWS_INTERFACE_CMD*`.

## Kurzfassung
YSDWS13 kopiert die Klassifizierung des Musterkunden aus der **falschen Klasse**. WERBEVERBOT
(ATINN 0000000004, Werte J/N) gehört zur Klasse **DEBITOR** (CLINT 0000000001, Klassenart 011).
Die Schnittstelle nimmt aber **ZCRM_DEB_POTENTIAL** (CLINT 0000000191), die WERBEVERBOT nicht enthält.
Der Wert aus unserem Formular (SAP-API sendet `WERBEVERBOT / VALUE_NEUTRAL = J|N`) wird dadurch verworfen.

## Ablauf im Code
1. `FETCH_DETAIL_OBJCL` (CM006):
   ```abap
   SELECT SINGLE class FROM klah INTO mv_classnum
     WHERE klart = ms_dflt_value-klart.     " nur Klassenart 011 – keine Klasse!
   ```
   Klassenart 011 hat 50 Klassen; die DB liefert ZCRM_DEB_POTENTIAL. Danach
   `BAPI_OBJCL_GETDETAIL` für den Musterkunden **in dieser Klasse** → keine WERBEVERBOT-Zeile.
   `lt_return` wird nicht ausgewertet.
2. `MAP_CLASS_DATA` (CM00I, aus MAP_REF_CUSTOMER2NEW/CM008): überschreibt nur Merkmale, die
   bereits in `mt_allocvalueschar` stehen (`READ TABLE … IF sy-subrc = 0`). **Neue Merkmale werden
   nie angehängt** → Formularwert geht verloren, wenn der Musterkunde das Merkmal nicht hat.
3. `OBJCL_CREATE` (CM00A, aus CREATE_NEW_CUSTOMER/CM003): `BAPI_OBJCL_CREATE` für den neuen Kunden
   in ZCRM_DEB_POTENTIAL mit leeren Werten. Nur eine Klasse wird kopiert, der Musterkunde hat 34.

## Musterkunden (Mongo `Prod-ES-Worker/Customer-SalesOffices`)
10097840 (4900 Flensburg), 10097857 (2950 Hamburg), 10097858 (5900 Oldenburg),
10097859 (8900 Berlin), 10097860 (1900 Gütersloh), 10097861 (3800 Hamm), 10097862 (3900 Allensbach).
Kein abweichender MEQ-Musterkunde gepflegt.

| System | Klassifizierung der Musterkunden |
|---|---|
| MEP | je 34 Klassen inkl. DEBITOR, **WERBEVERBOT = J** bei allen 7 |
| MEQ | **keine** Klassifizierung (KSSK/AUSP leer) |

(0010010180 ist nur der Default-Musterkunde aus YSDWS_DFLT_VALUE für Aufrufe ohne IRefknr.)

## Auswirkung (KNA1 ab 2018, MEP)
| Ersteller | Kunden | WERBEVERBOT vorhanden | Zuordnung ZCRM_DEB_POTENTIAL |
|---|---|---|---|
| SRVUSR01 (Shop, 2019–2026) | 4.152 | 277 (fast alle 2023, vermutl. manuell) | 2.595 |
| MEESENBURG (2024–2026) | 9.071 | 2 | 8.864 |

Fehler besteht seit mindestens 2019, unabhängig von der HANA-Umstellung.

## Korrektur
**SAP (YSDWS13):** Klasse DEBITOR fest bzw. per Default-Wert vorgeben – besser: alle Klassen des
Musterkunden kopieren; fehlende Merkmale aus der Anfrage anhängen statt verwerfen; `lt_return`
auswerten. Danach funktioniert MEP sofort mit dem Formularwert (Musterkunden haben DEBITOR).
MEQ braucht dafür vorher DEBITOR/WERBEVERBOT an den 7 Musterkunden.

**Übergangslösung ohne ABAP-Änderung (SAP-API):** nach erfolgreicher Anlage (Kundennummer zurück)
`BAPI_OBJCL_CREATE` (KNA1, DEBITOR, 011, WERBEVERBOT = Formularwert) + `BAPI_TRANSACTION_COMMIT`;
bei Fehlern in der Anlage kein Aufruf. Mehrfachklassifizierung ist zulässig.

**Altbestand:** Kunden ohne WERBEVERBOT nachpflegen (Wert fachlich/Datenschutz klären).
