# Entwurf RFC-Baustein `Z_ES_CUSTOMER_CREATE`

Stand 2026-10-06 · Entwurf für die SAP-Entwicklung · Zielsystem ECC 6.0 EhP7 (SAP_APPL 617, SAP_BASIS 740)

Ersetzt für die Neukundenanlage aus ES (Portal) den Webservice YSDWS13. Aufruf aus der
SAP-API (`Meesenburg.ES.API.SAPData`) per ERPConnect wie die übrigen RFC-Bausteine.

## Ziele / Unterschiede zu YSDWS13

| Problem heute (YSDWS13) | Lösung im RFC |
|---|---|
| Generische Qualifier/Wert-Listen; unbekannte Qualifier und Konvertierungsfehler werden **still ignoriert** („nicht gemappte Felder“) | **Typisierte Strukturen** – jedes Feld ist im DDIC definiert, Tippfehler fallen beim Mapping in der SAP-API auf |
| TAX-Items gehen verloren (ändert `ms_ref_cmd` statt `rs_central`) | Steuernummern direkt in `central_data`, Steuerkennzeichen (KNVI) explizit überschreibbar |
| Klassifizierung: nur **eine** zufällige Klasse (`SELECT SINGLE … klah`), neue Merkmale werden verworfen | **Alle** Klassen des Musterkunden kopieren, Merkmale aus der Anfrage überschreiben **oder anhängen** |
| Rückmeldungen von `BAPI_OBJCL_GETDETAIL` u. a. werden nicht ausgewertet | Alle Meldungen in `ET_RETURN`; jeder Fehler → Rollback |
| Teilerfolg möglich (Kunde angelegt, Klassifizierung/Kredit fehlgeschlagen) | **Eine LUW**: alles oder nichts |
| Session-ID/Caller-Customizing (YSDWS_CALLER, STVARVC), SOAP-Gateway, 502-Fehler ohne Ursache | Direkter RFC, Meldungen kommen im Ergebnis zurück |
| Kein Testlauf | `IV_TESTRUN = 'X'` prüft alles, legt nichts an (Formular-Vorprüfung möglich) |

**Bleibt gleich:** Musterkunde (`IV_REF_KUNNR`) als Vorlage für die SAP-Festwerte, Kopie über
`CMD_EI_API_EXTRACT=>GET_DATA` / `CMD_EI_API=>MAINTAIN_BAPI` (wie YSDWS13 CM003/CM004), Kreditdaten
wie `CREDITLIMIT_CHANGE` in YSDWS13 (CM005 + Methode creditlimit_change).

## DDIC

### `ZES_S_CUST_GENERAL` (KNA1 / Adresse)
| Feld | Typ | Bemerkung |
|---|---|---|
| NAME1 … NAME4 | AD_NAME1 … AD_NAME4 | |
| SORT1 | AD_SORT1 | Suchbegriff |
| STREET | AD_STREET | |
| HOUSE_NUM1 | AD_HSNM1 | |
| POST_CODE1 | AD_PSTCD1 | |
| CITY1 | AD_CITY1 | |
| COUNTRY | LAND1 | |
| REGION | REGIO | |
| LANGU | SPRAS | |
| PO_BOX / POST_CODE2 / PO_BOX_LOC | AD_POBX / AD_PSTCD2 / AD_POBXLOC | heute in YSDWS13 abgelehnt |
| TEL_NUMBER / FAX_NUMBER / SMTP_ADDR | AD_TLNMBR1 / AD_FXNMBR1 / AD_SMTPADR | |
| BRSCH | BRSCH | Branche (Privat: B38) |
| KTOKD | KTOKD | leer = vom Musterkunden |
| STCEG | STCEG | USt-IdNr. |
| STCD1 / STCD2 | STCD1 / STCD2 | Steuernummer |

### `ZES_S_CUST_SALES` (KNVV – nur die individuellen Felder)
VKBUR, KVGR2 (Rechnungsweg), ZTERM. VKORG/VTWEG/SPART kommen vom Musterkunden.

### `ZES_S_CUST_COMPANY` (KNB1)
ZTERM, YYFI_LEITWEGID. BUKRS, AKONT, YYFI_KTOGR kommen vom Musterkunden.

### `ZES_T_CUST_PARTNER` (Zeilentyp `ZES_S_CUST_PARTNER`)
PARVW (PARVW), KUNNZ (KUNNR) – z. B. YA/YI.

### `ZES_T_CUST_TAXIND` (Zeilentyp `ZES_S_CUST_TAXIND`, optional)
ALAND, TATYP, TAXKD – überschreibt KNVI des Musterkunden je Zeile.

### `ZES_T_CUST_CHARACT` (Zeilentyp `ZES_S_CUST_CHARACT`)
CLASS (KLASSE_D), ATNAM (ATNAM), ATWRT (ATWRT) – z. B. DEBITOR / WERBEVERBOT / J.

### `ZES_T_CUST_CONTACT` (optional, Ansprechpartner Rechnung)
NAMEV, NAME1, ABTNR, PAFKT, TEL_NUMBER, SMTP_ADDR.

## Schnittstelle

```abap
FUNCTION z_es_customer_create.
*"----------------------------------------------------------------------
*"  Remotefähig
*"  IMPORTING
*"     VALUE(IV_REF_KUNNR) TYPE KUNNR
*"     VALUE(IV_TESTRUN)   TYPE BAPIFLAG-BAPIFLAG DEFAULT SPACE
*"     VALUE(IS_GENERAL)   TYPE ZES_S_CUST_GENERAL
*"     VALUE(IS_SALES)     TYPE ZES_S_CUST_SALES
*"     VALUE(IS_COMPANY)   TYPE ZES_S_CUST_COMPANY
*"     VALUE(IV_REQUEST_ID) TYPE CHAR40 OPTIONAL    " Korrelation/Log (ES-Request-Id)
*"  EXPORTING
*"     VALUE(EV_KUNNR)     TYPE KUNNR
*"  TABLES
*"      IT_PARTNER  TYPE ZES_T_CUST_PARTNER OPTIONAL
*"      IT_TAXIND   TYPE ZES_T_CUST_TAXIND  OPTIONAL
*"      IT_CHARACT  TYPE ZES_T_CUST_CHARACT OPTIONAL
*"      IT_CONTACT  TYPE ZES_T_CUST_CONTACT OPTIONAL
*"      ET_RETURN   TYPE BAPIRET2_T
*"----------------------------------------------------------------------
```

## Ablauf (Pseudocode / ABAP-Skizze)

```abap
  DATA: ls_in      TYPE cmds_ei_main,
        ls_ref     TYPE cmds_ei_main,
        ls_error   TYPE cvis_message,
        ls_ok      TYPE cmds_ei_main,
        ls_msg_ok  TYPE cvis_message,
        ls_bad     TYPE cmds_ei_main,
        ls_msg_bad TYPE cvis_message.

  " 0) Berechtigung (z. B. F_KNA1_GRP/V_KNA1_VKO für srvusr01) prüfen

  " 1) Musterkunde lesen – wie YSDWS13 FETCH_DATA_CMD (CM004)
  APPEND VALUE #( header-object_instance-kunnr = iv_ref_kunnr
                  header-object_task           = 'M' ) TO ls_in-customers.
  cmd_ei_api_extract=>get_data( EXPORTING is_master_data = ls_in
                                IMPORTING es_master_data = ls_ref es_error = ls_error ).
  IF ls_error-is_error = abap_true.
    append_messages( ls_error-messages ).  " -> ET_RETURN
    RETURN.
  ENDIF.

  " 2) Vorlage zum Neukunden machen
  ASSIGN ls_ref-customers[ 1 ] TO FIELD-SYMBOL(<c>).
  CLEAR <c>-header-object_instance-kunnr.        " interne Nummernvergabe
  <c>-header-object_task = 'I'.
  " Tasks aller Unterstrukturen auf 'I' setzen (Adresse, company, sales, functions, tax_ind, contacts)
  " Kopierte Ansprechpartner/Kommunikation des Musterkunden entfernen (heute: werden mitkopiert!)

  " 3) Felder aus der Anfrage setzen – jeweils DATA + DATAX
  "    central_data-central-data:      ktokd (wenn gefüllt), brsch, stceg, stcd1, stcd2
  "    central_data-address-postal:    name, sort1, street, house_no, postl_cod1, city, country, region, langu, po_box …
  "    central_data-address-communication: Telefon/Fax/E-Mail (Tabellen phone/fax/smtp)
  "    central_data-tax_ind:            Zeilen aus IT_TAXIND überschreiben (task 'M'/'I')
  "    company_data-company[ 1 ]:       zterm, YYFI_LEITWEGID (Kundenfeld – Append in der
  "                                     CMD_EI-Struktur prüfen, sonst nach Anlage per Update im selben LUW)
  "    sales_data-sales[ 1 ]:           vkbur, kvgr2, zterm
  "    sales_data-sales[ 1 ]-functions: Partner aus IT_PARTNER (parvw/parza, partner) ersetzen/ergänzen
  "    contacts:                         aus IT_CONTACT

  " 4) Anlage
  cmd_ei_api=>initialize( ).
  cmd_ei_api=>maintain_bapi( EXPORTING iv_test_run         = iv_testrun
                                       iv_collect_messages = abap_true
                                       is_master_data      = ls_ref
                             IMPORTING es_master_data_correct   = ls_ok
                                       es_message_correct       = ls_msg_ok
                                       es_master_data_defective = ls_bad
                                       es_message_defective     = ls_msg_bad ).
  append_messages( ls_msg_ok-messages ).
  append_messages( ls_msg_bad-messages ).          " YSDWS13 wertet das NICHT aus
  IF ls_msg_ok-is_error = abap_true OR ls_msg_bad-is_error = abap_true.
    rollback_and_return( ).
  ENDIF.
  ev_kunnr = ls_ok-customers[ 1 ]-header-object_instance-kunnr.

  IF iv_testrun = abap_true.
    " Klassifizierung/Kredit nur prüfen (Merkmale/Werte gegen CABN/CAWN), dann Rollback
    rollback_and_return( ).
  ENDIF.

  " 5) Kreditdaten – wie YSDWS13 FETCH_DATA_CREDITMANAGEMENT (KNKA/KNKK) + CREDITLIMIT_CHANGE

  " 6) Klassifizierung: ALLE Klassen des Musterkunden
  SELECT k~class FROM kssk AS s INNER JOIN klah AS k ON k~clint = s~clint
    WHERE s~objek = @iv_ref_kunnr AND s~klart = '011' AND s~mafid = 'O'
    INTO TABLE @DATA(lt_class).
  " Klassen aus IT_CHARACT ergänzen, die der Musterkunde nicht hat
  LOOP AT it_charact INTO DATA(ls_ch).
    IF NOT line_exists( lt_class[ class = ls_ch-class ] ).
      APPEND VALUE #( class = ls_ch-class ) TO lt_class.
    ENDIF.
  ENDLOOP.

  LOOP AT lt_class INTO DATA(ls_class).
    DATA: lt_num  TYPE TABLE OF bapi1003_alloc_values_num,
          lt_char TYPE TABLE OF bapi1003_alloc_values_char,
          lt_curr TYPE TABLE OF bapi1003_alloc_values_curr,
          lt_ret  TYPE TABLE OF bapiret2.
    CLEAR: lt_num, lt_char, lt_curr, lt_ret.

    CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
      EXPORTING objectkey = CONV objnum( iv_ref_kunnr ) objecttable = 'KNA1'
                classnum  = ls_class-class               classtype   = '011'
      TABLES    allocvaluesnum = lt_num allocvalueschar = lt_char
                allocvaluescurr = lt_curr return = lt_ret.
    " 'Keine Zuordnung' ist ok für neu ergänzte Klassen, alles andere -> ET_RETURN

    " Werte aus der Anfrage: überschreiben ODER anhängen (YSDWS13 verwirft fehlende!)
    LOOP AT it_charact INTO ls_ch WHERE class = ls_class-class.
      ASSIGN lt_char[ charact = ls_ch-atnam ] TO FIELD-SYMBOL(<v>).
      IF sy-subrc = 0.
        <v>-value_char = ls_ch-atwrt. <v>-value_neutral = ls_ch-atwrt.
      ELSE.
        APPEND VALUE #( charact = ls_ch-atnam value_char = ls_ch-atwrt
                        value_neutral = ls_ch-atwrt ) TO lt_char.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'BAPI_OBJCL_CREATE'
      EXPORTING objectkeynew = CONV objnum( ev_kunnr ) objecttablenew = 'KNA1'
                classnumnew  = ls_class-class           classtypenew   = '011'
      TABLES    allocvaluesnum = lt_num allocvalueschar = lt_char
                allocvaluescurr = lt_curr return = lt_ret.
    append_messages_bapiret( lt_ret ).
  ENDLOOP.

  " 7) Abschluss: alles oder nichts
  IF line_exists( et_return[ type = 'E' ] ) OR line_exists( et_return[ type = 'A' ] ).
    rollback_and_return( ).   " BAPI_TRANSACTION_ROLLBACK, EV_KUNNR leeren
  ENDIF.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
  APPEND VALUE #( type = 'S' message = |Kunde { ev_kunnr ALPHA = OUT } angelegt| ) TO et_return.
ENDFUNCTION.
```

Hinweise für die SAP-Entwicklung:
- Eine bei Rollback bereits gezogene Kundennummer bleibt als Lücke im Nummernkreis – unkritisch.
- `MAINTAIN_BAPI` und `BAPI_OBJCL_*` schreiben über die Verbuchung; ohne Commit im Baustein
  wäre der Aufrufer zuständig. Wir empfehlen den Commit im Baustein (eine RFC-Session, ein Ergebnis).
- Kundenfelder (YYFI_LEITWEGID in KNB1): wie YSDWS13 das heute setzt (`set_data` auf die
  CMD-Struktur) prüfen und übernehmen.
- Logging: `IV_REQUEST_ID` + ET_RETURN optional in YSDWS_LOG_* bzw. eigenes Z-Log schreiben,
  damit Fehler in SAP nachvollziehbar sind (wir loggen zusätzlich in Mongo).

## Aufruf aus der SAP-API (Skizze, ERPConnect)

```csharp
var f = conn.CreateFunction("Z_ES_CUSTOMER_CREATE");
f.Exports["IV_REF_KUNNR"].ParamValue = SapCustomerMapper.GetReferenceCustomerNumber(salesOffice, system);
var g = f.Exports["IS_GENERAL"].ToStructure();
g["NAME1"] = request.Name1; /* … */
var ch = f.Tables["IT_CHARACT"].AddRow();
ch["CLASS"] = "DEBITOR"; ch["ATNAM"] = "WERBEVERBOT"; ch["ATWRT"] = request.AdvertisingBlocked ? "J" : "N";
f.Execute();
var kunnr = f.Imports["EV_KUNNR"].ParamValue as string;
var messages = f.Tables["ET_RETURN"]; // E/A -> Fehler, Kunde wurde NICHT angelegt
```

## Musterkunde in SAP oder Mapping in Mongo?

Empfehlung: **beides, mit klarer Aufteilung.**

- **In SAP am Musterkunden** bleiben die SAP-Festwerte: Abstimmkonto, Kontierungsgruppe,
  Steuerkennzeichen, Versand-/Preis-/Fakturadaten, Klassen, Kreditdaten usw. Das sind Dutzende
  Felder, die die Fachbereiche in XD03 kennen und pflegen können, die bei SAP-Customizing-Änderungen
  dort mitgezogen werden und die SAP beim Anlegen selbst validiert. In Mongo wären sie eine Kopie
  von SAP-Wissen, die niemand in SAP sieht und die erst beim Anlegen scheitert.
- **In Mongo (per Portal editierbar)** bleibt die *Zuordnung*: VK-Büro → Musterkunde, Partner
  YA/YI, ggf. Kontogruppe – also das, was ES fachlich entscheidet (heute `Customer-SalesOffices`).
- **Aus dem Formular** kommen alle kundenindividuellen Werte – explizit typisiert, nichts implizit.

Warum YSDWS13 mit Musterkunden arbeitet, ist nicht dokumentiert. Wahrscheinlich, weil es das
übliche SAP-Muster ist (XD01 „mit Vorlage“), der Fachbereich ohne IT pflegen kann und der Shop
nur wenige Felder liefern muss – SOAP-Overhead spielt dafür kaum eine Rolle. Das Problem war
nicht der Musterkunde, sondern das *stille* Kopieren/Verwerfen. Der RFC macht das sichtbar
(ET_RETURN, Testlauf) und behält den Vorteil.
