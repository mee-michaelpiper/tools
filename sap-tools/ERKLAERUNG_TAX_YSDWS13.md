# YSDWS13: Steuerkennzeichen aus der Anfrage gehen verloren

Stand 2026-10-06 · Quelle: `abap/MEP/YCL_SDWS_INTERFACE_CMD========CM00H.abap` (Methode `MAP_CENTRAL_DATA`)

## Kurz gesagt

Wenn wir bei der Kundenanlage Steuerkennzeichen mitschicken (TAX-Items, Tabelle KNVI, z. B.
„Deutschland, Mehrwertsteuer, steuerpflichtig“), kommen sie in SAP nie an. Der neue Kunde bekommt
immer die Steuerkennzeichen des **Musterkunden**. Die Ursache ist ein Fehler in **einer einzigen
Code-Zeile**, die Korrektur ist ebenfalls eine Zeile.

## Für Nicht-ABAPler erklärt

Stell dir vor, die Schnittstelle arbeitet mit einem Formular auf Papier:

1. Sie holt sich das ausgefüllte Formular des Musterkunden aus dem Schrank (**Original**).
2. Sie macht davon eine **Fotokopie**. Die Kopie wird später als neuer Kunde in SAP eingereicht.
3. Name, Adresse, Telefon usw. aus unserer Anfrage trägt sie korrekt **auf der Kopie** ein.
4. Die Steuerkennzeichen aus unserer Anfrage trägt sie aber versehentlich **ins Original** ein.
5. Eingereicht wird die Kopie. Dort stehen noch die alten Steuerkennzeichen des Musterkunden.

Unsere Steuerwerte landen also auf einem Blatt, das danach niemand mehr ansieht. Es gibt keine
Fehlermeldung, deshalb ist das nie aufgefallen.

## Für den ABAP-Entwickler

Methode `YCL_SDWS_INTERFACE_CMD->MAP_CENTRAL_DATA` (Include CM00H), aufgerufen aus
`MAP_REF_CUSTOMER2NEW` (CM008) mit `is_ref = ms_ref_cmd-customers[ 1 ]-central_data`:

```abap
14    rs_central  = is_ref.                 " Kopie der Musterkunden-Daten (Rückgabewert)
...
100 *       TAX Data
101     DATA ls_tax_key TYPE cmds_ei_tax_ind_key.
102     lt_comm = is_master-itm.
103     DELETE lt_comm WHERE vakey NS 'TAX'.
104     ASSIGN ms_ref_cmd-customers[ 1 ]-central_data-tax_ind TO FIELD-SYMBOL(<tax>).   " <-- FEHLER
105
106     LOOP AT lt_comm ASSIGNING <com>.
...
110       ls_tax_key = <com>-vakey+3.
111       READ TABLE <tax>-tax_ind WITH KEY data_key = ls_tax_key ASSIGNING FIELD-SYMBOL(<tax_ind>).
112       IF sy-subrc NE 0.
113         APPEND INITIAL LINE TO <tax>-tax_ind ASSIGNING <tax_ind>.
114       ENDIF.
115       <tax_ind>-task = 'I'.
116       set_data( EXPORTING it_source = lt_in CHANGING cs_target = <tax_ind>-data ).
117     ENDLOOP.
...
121     LOOP AT <tax>-tax_ind ASSIGNING <tax_ind>.
122       <tax_ind>-task = 'I'.
123     ENDLOOP.
```

- In Zeile 14 wird `rs_central` als **Kopie** von `is_ref` gefüllt. Ab hier ist `rs_central` die
  Struktur, die zurückgegeben und später an `CMD_EI_API=>MAINTAIN_BAPI` übergeben wird.
- In Zeile 104 zeigt `<tax>` aber auf **`ms_ref_cmd`** (die Musterkunden-Daten im Attribut), nicht
  auf `rs_central`. Alle Änderungen in Zeilen 106–123 (Werte setzen, Zeilen anhängen, Task `'I'`)
  landen in `ms_ref_cmd` und sind für das Ergebnis wirkungslos.
- `rs_central-tax_ind` enthält deshalb unverändert die KNVI-Zeilen des Musterkunden.

Vermutlich stammt die Zeile aus der früheren Variante, die noch direkt auf `ms_ref_cmd` arbeitete
(in CM008 Zeilen 102–124 auskommentiert). Beim Umbau auf `map_central_data` wurde sie nicht angepasst.

### Korrektur (eine Zeile)

```abap
104     ASSIGN rs_central-tax_ind TO FIELD-SYMBOL(<tax>).
```

Danach gelten die Schleifen in Zeilen 106–123 für die Daten, die wirklich angelegt werden.

### Bitte beim Test beachten

- **Schlüsselformat:** Der Code erwartet im Vakey `TAX` + Schlüssel `cmds_ei_tax_ind_key`
  (ALAND 3 Zeichen + TATYP 4 Zeichen), also z. B. `TAXDE MWST` (mit Leerzeichen, weil ALAND drei
  Stellen hat). Qualifier `TAXKD`, Wert z. B. `1`.
- **Fehler sichtbar machen:** `set_data` ignoriert unbekannte Qualifier und Konvertierungsfehler
  stillschweigend. Für TAX wäre eine Meldung in `ET_RETURN` hilfreich, wenn ein Qualifier nicht passt.
- **Nicht betroffen:** USt-IdNr. (`STCEG`) und Steuernummern (`STCD1/STCD2`) gehen über
  `rs_central-central-data` (Zeile 16/17). Beide kommen nachweislich an: USt-IdNr. am MEQ-Testkunden
  10097932, Steuernummer (STCD1) am MEQ-Testkunden 10097934.

## Was wir auf ES-Seite tun

Die SAP-API schickt derzeit **keine** TAX-Items mit (`SapCustomerMapper`: „TAX-Items übernimmt das
ABAP derzeit nicht“). Die Steuerkennzeichen kommen vom Musterkunden des Verkaufsbüros. Nach der
Korrektur können wir sie gezielt mitsenden, z. B. für Kunden außerhalb Deutschlands.

Verwandt: [ANALYSE_WERBEVERBOT.md](ANALYSE_WERBEVERBOT.md) (Klassifizierung, CM006/CM00A/CM00I),
[rfc-entwurf/Z_ES_CUSTOMER_CREATE.md](rfc-entwurf/Z_ES_CUSTOMER_CREATE.md).
