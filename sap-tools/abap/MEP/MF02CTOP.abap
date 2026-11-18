PROGRAM SAPMF02C MESSAGE-ID F4.
TYPE-POOLS: SLIS.

*-----------------------------------------------------------------------
*        Dynproreihenfolge und Zuordnung
*-----------------------------------------------------------------------
         INCLUDE MF02LDYN.

*-----------------------------------------------------------------------
*        DATA-Definitionen für Massenänderung (auch in RFDKLI50)
*-----------------------------------------------------------------------
         INCLUDE RFDKLII0.

*-----------------------------------------------------------------------
*        Open FI
*-----------------------------------------------------------------------
*        INCLUDE IS01AD30.
         INCLUDE IS01HK01.




*-----------------------------------------------------------------------
*        Tabellen
*-----------------------------------------------------------------------
TABLES:  BSID,                         " BIB für Oldest Due Date
         KNA1, *KNA1,                  " Debitor - Allg. Daten
         KNB1,                         " Debitor - Bukrs.Daten
         KNB4,                         " Debitor - Zahlverhalten
         KNB5,                         " Debitor - Mahnbereiche
         KNC1,                         " Debitor - Verkehrszahlen
         *KNKA,                        " Kontrollbereichsübergreifend
         *KNKK,                        " KNKK-Workarea für Nachlesen
         KNKKF1, KNKKF2.               " Kreditvektor

TABLES:  RF02L, *RF02L,                " Dynpro / Arbeitsfelder
         RF42B,                        " Dynpro / Arbeitsfelder
         RFPOS,                        " Einzelposten
         S066,                         " SD-Ausschöpfung
         S067.                         " SD-Ausschöpfung

TABLES:  TCURC,                        " Waehrungen
         TRAS,                         " Raster
         TTXOB,                        " Zulässige Textobjekte
         T000CM,                       " DSO-Parameter
         T001, *T001,                  " Buchungskreise
         T005,                         " Länder
         T014, *T014,                  " Kredit-Kontrollbereiche
         T014N,                        " Neu aufzubauende KKBER
         T014T,                        " Bez. des Kontrollbereichs
         T019W,                        " Window-Koordinaten
         T020,                         " Transaktionssteuerung Stammd.
         T021V,                        " Vorschlagswerte für FBL5
         T024B,                        " Sachbearbeitergruppen
         T055,                         " Felder zu Feldgruppen
         T055G,                        " Feldgruppen
         T691A,                        " Risikoklassen
         T691B, T691C,                 " Gruppen
         T691T.                        " ... Texte dazu

*mi/46b begin (7.10.99)
tables:  rf02d, rf02k.
*mi/46b end

CONTROLS ZAHLV_CONTROL TYPE TABLEVIEW USING SCREEN 220.
controls kkber_control type tableview using screen 1005.
controls kkber_control1 type tableview using screen 1004.

DATA gd_init TYPE c.

*eject
*-----------------------------------------------------------------------
*        Tabellen und Update-Kennzeichen zum Objekt KLIM
*-----------------------------------------------------------------------
         INCLUDE FF02LCDT.

*eject
*---------------------------------------------------------------------*
*        Interne Tabellen
*---------------------------------------------------------------------*

*------- Buchungskreise ------------------------------------------------
DATA:    BEGIN OF BUKTAB OCCURS 10,
           BUKRS        LIKE T001-BUKRS,    " Buchungskreis
           WAERS        LIKE T001-WAERS,    " Währung
           XZVER(1)     TYPE C,             " Kz.: KNB1-XZVER
           PERIV        LIKE T001-PERIV,    " GJ-Variante
           GJAHR        LIKE KNC1-GJAHR,    " Aktuelles Geschäftsjahr
           PTAGE(3)     TYPE N,             " Tage seit Periodenbeginn
           BUTXT        LIKE T001-BUTXT,    " Name und Ort
           AKONT        LIKE KNB1-AKONT,    " Reconciliation Account
           XNKLIMP(1)   TYPE C,             " AKONT without CM update
         END OF BUKTAB.

*------- Dynproreihenfolge und Status ----------------------------------
DATA:    BEGIN OF DYNTAB OCCURS 5,
           DYNNR(4)     TYPE C,             " Dynpronummer
           DTYPE(1)     TYPE C,             " A=KNKA, K=KNKK
           XMARK(1)     TYPE C,             " X=Selektierte Bilder
           XLAST(1)     TYPE C,             " X=Letztes helles Bild
         END OF DYNTAB.

*------- EXCTAB ( Verzeichnis der unzulässigen OK-CODEs ) --------------
DATA:    BEGIN OF EXCTAB OCCURS 5,
           OKCOD(5)          TYPE C,
         END OF EXCTAB.

*------- Zahlungsverhalten pro Kontrollbereich -------------------------
DATA:    BEGIN OF KKNB4 OCCURS 16.
           INCLUDE STRUCTURE IKNB4.
DATA:    END   OF KKNB4.

*------- KNB5-Daten ----------------------------------------------------
DATA:    BEGIN OF KNB5TAB OCCURS 10,
           BUKRS             LIKE KNB5-BUKRS,    " Buchungskreis
           MABER             LIKE KNB5-MABER,    " Mahnbereich
           MADAT             LIKE KNB5-MADAT,    " Datum ltzt. Mahnung
           GMVDT             LIKE KNB5-GMVDT,    " Ger.Mahnverfahren
           MAHNS             LIKE KNB5-MAHNS,    " Mahnstufe
         END   OF KNB5TAB.

*------- KNC1-Daten ----------------------------------------------------
DATA:    BEGIN OF KNC1TAB OCCURS 2,
           BUKRS             LIKE KNC1-BUKRS,    " Buchungskreis
           UABZG             LIKE KNC1-UABZG,    " Unber. Abzüge
           BABZG             LIKE KNC1-BABZG,    " Ber. Abzüge
           KUMAG             LIKE KNC1-KUMAG,    " Ausgleichsbetrag
         END   OF KNC1TAB.

*------- Referenzierende Debitoren -------------------------------------
DATA:    BEGIN OF REFTAB OCCURS 5,
           KUNNR        LIKE KNKK-KUNNR,    " Debitor
           KKBER        LIKE KNKK-KKBER,    " Kontrollbereich
           OBLIG        LIKE RF02L-OBLIG,   " Gesamtobligo
           WAERS        LIKE t014-waers,    " Währung
         END   OF REFTAB.

* ------ Buchungskreise für MAIL ---------------------------------------
DATA:    BEGIN OF TBUKRS OCCURS 0.
           INCLUDE STRUCTURE RSPARAMS.
DATA:    END   OF TBUKRS.

* ------ Buchungskreise zum Kontrollbereich (gesamt)--------------------
DATA:    BEGIN OF TCMTAB OCCURS 10.
           INCLUDE STRUCTURE T001CM.
DATA:    END   OF TCMTAB.

*------- Vergebene Kredit-Limits ---------------------------------------
DATA:    BEGIN OF VKLTAB OCCURS 5,
           XAUTH(1)     TYPE C,             " AUTHORITY
           KKBER        LIKE KNKK-KKBER,    " Kontrollbereich
           KKBTX        LIKE T014T-KKBTX,   " ... Bezeichnung
           KNKLI        LIKE KNKK-KNKLI,    " ... Limit bei wem ?
           KLIMA        LIKE RF02L-KLIMA,   " KLIMK in KNKA-WAERS
           WAERA        LIKE T014-WAERS,    " KNKA-WAERS
           KLIMK        LIKE RF02L-KLIMK,   " KLIMK in T014-WAERS
           WAERB        LIKE T014-WAERS,    " T014-WAERS
         END   OF VKLTAB.

*------- Felder zu Feldgruppen (aus T055) ------------------------------
DATA:    BEGIN OF X055 OCCURS 10,
           FELDN        LIKE T055-FELDN,    " Feldname
         END OF X055.

* ------ Dokumentenverwaltung ------------------------------------------
DATA:    BEGIN OF XDRAD OCCURS 2.
           INCLUDE STRUCTURE DRAD.
DATA:    END OF XDRAD.
DATA:    DRAD_OBJKY     LIKE DRAD-OBJKY.    " Objektschlüssel (KUNNR)
DATA:    DRAD_OPCOD     TYPE C.             " 2=Ändern, 3=Anzeigen
DATA:    DRAD_REFRESH   TYPE C.             " Refresh DVS?
DATA:    DRAD_XINIT     TYPE C.             " Init DVS?
DATA:    DRAD_VB        TYPE C.             " VB-Bedarf aus DVS?

*eject
*---------------------------------------------------------------------*
*        Strukturen
*---------------------------------------------------------------------*

*------- Aktuelle Rechenfelder für KNB4 --------------------------------
DATA:    BEGIN OF AKNB4,
           AGSXX        LIKE KNB4-AGS01,    " Ausgleich Skonto 1
           VZSXX(8)     TYPE P,             " Verzugstage Skonto 1
           AGNXX        LIKE KNB4-AGN01,    " Ausgleich Netto
           VZNXX(8)     TYPE P,             " Verzugstage Netto
         END   OF AKNB4.

*------- IMPORT-Parameter ----------------------------------------------
DATA:    BEGIN OF IMPPAR,
           OKCOD(4)     TYPE C,             " Zu setzender OK-Code
         END   OF IMPPAR.

*------- Hilfsfelder die gemeinsam gecleared werden koennen ------------
DATA:    BEGIN OF KLIM,
           AUSWL(40)    TYPE C,             " Auswahlleiste
           BUKRS        LIKE T001-BUKRS,    " Buchungskreis
           KLIMA        LIKE KNKK-KLIMK,    " KNKK-KLIMK in KNKA-WAERS
           KKBER        LIKE T014-KKBER,    " ... mit höchstem Einzell.
           NKKBE        LIKE T014-KKBER,    " nächster KKBER
           WAERA        LIKE KNKA-WAERS,    " WAERS für VKLTAB-KLIMA
           XBEKA(1)     TYPE C,             " Kz.: KNKA bearbeiten
           XBEKK(1)     TYPE C,             " Kz.: KNKK bearbeiten?
           XBUKR(1)     TYPE C,             " Kz.: Ein KNB1 existiert?
           XCHNG(1)     TYPE C,             " Kz.: Änderungen?
           XDELA(1)     TYPE C,             " Kz.: KNKA löschen?
           XDELK(1)     TYPE C,             " Kz.: KNKK löschen?
* IN_ARBEIT: Durch ERNAM/ERDAT ersetzen?
           XEXKA(1)     TYPE C,             " Kz.: KNKA vorhanden?
* F = Fehlt, X = vorhanden
           XEXKK(1)     TYPE C,             " Kz.: KNKK vorhanden?
* F = Fehlt, X = vorhanden
           XFAPO(1)     TYPE C,             " Kz.: Fällige Posten?
           XINIT(1)     TYPE C,             " Kz.: Initialisiert?
           XKNB1(1)     TYPE C,             " Kz.: KNB1 gelesen?
           XM712(1)     TYPE C,             " Kz.: Message 712 gesendet?
           XM743(1)     TYPE C,             " Kz.: Message 743 gesendet?
           XM762(1)     TYPE C,             " Kz.: Message 762 gesendet?
           XM774A(1)    TYPE C,             " Kz.: Message 774 (KUNNR)
           XM774R(1)    TYPE C,             " Kz.: Message 774 (KNKLI)
           XM778(1)     TYPE C,             " Kz.: Message 778 gesendet?
           XNEUA(1)     TYPE C,             " Kz.: Neuaufbauen?
           XNEUR(1)     TYPE C,             " Kz.: Neuaufbau m.RVKRED09
                                            "      wegen CTLPC-Änderung
           XNEUB(1)     TYPE C,             " Kz.: Neuaufb.Bearbeitergr?
           XOLDD(1)     TYPE C,             " Kz.: Oldest Due Date ?
           XREFL(1)     TYPE C,             " Kz.: Referenzliste?
           XTEXT(1)     TYPE C,             " Kz.: RF02L-XTEXT ermittelt
           XUEBE(1)     TYPE C,             " Kz.: Übersicht vorbereitet
           XZAVE(1)     TYPE C,             " Kz.: Zahlverhalten ermitt?
           XSUPR(1)     TYPE C,             " Kz.: SUPPRESS DIALOG 210?
         END OF KLIM.

*------- Kumulierte Daten ----------------------------------------------
DATA:    BEGIN OF KUMUL,
           AGSXX             LIKE KNB4-AGS01,    " Ausgleich Skonto 1
           VZSXX             LIKE KNB4-VZS01,    " Verzugstage Skonto 1
           AGNXX             LIKE KNB4-AGN01,    " Ausgleich Netto
           VZNXX             LIKE KNB4-VZN01,    " Verzugstage Netto
         END   OF KUMUL.

*------- Verwaltung der Massenänderung ---------------------------------
DATA:    BEGIN OF MASS,
           AKTUELL(6)        TYPE N,             " Aktuelle Anzahl
           GRENZE(6)         TYPE N              " Grenze für COMMIT
             VALUE '000010',                     " ... Default: 10
         END   OF MASS.

*------- Alter Inhalt von einzelnen Feldern ---------------------------
DATA:    BEGIN OF OLD,
           DYNNR        LIKE SY-DYNNR,      " Dynpronummer
           KNKLI        LIKE KNKK-KNKLI,    " Referenzdebitor
           LNFIR        LIKE SY-TABIX,      " Erste Zeile
           LNMAX        LIKE SY-TABIX,      " Anzahl Zeilen
           UPDKK        TYPE C,             " UPD_KNKK
         END OF OLD.

*------- Daten des Postens mit dem OLDEST DUE DATE ---------------------
DATA:    BEGIN OF OLDD,
           KUNNR        LIKE BSID-KUNNR,    " Debitor
           BELNR        LIKE BSID-BELNR,    " Belegnummer
           BUKRS        LIKE BSID-BUKRS,    " Buchungskreis
           GJAHR        LIKE BSID-GJAHR,    " Geschäftsjahr
           INFAE        LIKE BSID-INFAE,    " Invertierte Nettofälligk.
           FAEDT        LIKE RFPOS-FAEDT,   " Nettofälligkeit
           VERZN        LIKE RFPOS-VERZN,   " Verzugstage netto
           WRBTR        LIKE BSID-WRBTR,    " Betrag in Belegwährung
           WAERS        LIKE BSID-WAERS,    " Belegwährung
         END   OF OLDD.

*------- KNKK-Workarea für Referenzdebitor -----------------------------
DATA:    BEGIN OF RKNKK.
           INCLUDE STRUCTURE KNKK.
DATA:    END   OF RKNKK.

DATA: T_FIELDCAT  TYPE SLIS_T_FIELDCAT_ALV WITH HEADER LINE.

*------- Hilfsfelder für Feldgruppen aus T055 --------------------------
DATA:    X055_CHECK(1)  TYPE C,             " X055 schon aufgebaut
         X055_COUNT(3)  TYPE P.             " Anzahl Einträge in X055

*---------------------------------------------------------------------*
*        Einzelfelder
*---------------------------------------------------------------------*
DATA:    ACTVT          LIKE TACT-ACTVT,    " Aktivitätstyp
         ANSWER(1)      TYPE C.             " Antwort auf Dialogfenster

DATA:    CHAR1(50)      TYPE C,             " Hilfsfeld
         CHAR2(50)      TYPE C,             " Hilfsfeld
         CHARL1(1)      TYPE C,             " Hilfsfeld Länge 1
         COUNT(3)       TYPE N,             " Zähler
         CRS_FIELD      LIKE RFCU3-FNAME,   " Cursor-Position
         CRS_LINE       LIKE SY-STEPL.      " Cursor-Zeile

DATA:    ENQ_KEY        LIKE KNA1-KUNNR,    " gemerkter Sperr-Key
         ENQ_KEY_KNKLI  LIKE KNKK-KNKLI,    " gemerkter Sperr-Key KNKLI
         EX-CODE(5)     TYPE C.             " OK-Code AT EXIT-Command

DATA:    GJAHR          LIKE KNC1-GJAHR.    " Aktuelles Geschäftsjahr
DATA:    GD_CVDATUM     LIKE SY-DATUM,      " Erstellungsdatum CV
         GD_CV_TO_KNKK  TYPE C.             " Überschreiben SKFOR mit CV

DATA:    I(2)           TYPE N,             " Zaehler in Schleifen
         IDBXKZ(1)      TYPE C,             " D&B-Kennzeichen
         INDEX(2)       TYPE P.             " Index

DATA:    LNFIR          LIKE SY-TABIX,      " Erste Zeile d. Seite
         LNCNT          LIKE SY-LOOPC,      " Anzahl Loop-Zeilen
         LNCUR          LIKE SY-TABIX,      " Aktuelle Zeile
         LNMAX          LIKE SY-TABIX.      " Letzte Zeile

DATA:    MONAT          LIKE BKPF-MONAT.    " Periode

DATA:    OBLIG          LIKE RF02L-OBLIG,   " Obligo des Ref.Debitors
         OK-CODE(5)     TYPE C.             " Ok-Code

DATA:    POPUP_TITEL1(35) TYPE C.           " Titel für POPUP

DATA:    RATE           LIKE TCURR-UKURS,   " Kurs-Rate
         RC             LIKE SY-SUBRC,      " Returncode
         REFE1(8)       TYPE P,             " Hilfsfeld  gepackt
         REFE2(8)       TYPE P.             " Hilfsfeld  gepackt

DATA:    SAUFT          LIKE KNKK-SAUFT,    " Auftragswert
         SAVEDYNPRO(40) TYPE C,             " zu prozessierende Dynpros
         STARTDYNPRO    LIKE SY-DYNNR,      " erstes zu prozess. Dynpro
         STATUS(8)      TYPE C.             " CUA-Status

DATA:    TABIX          LIKE SY-TABIX,      " SAVE für SY-TABIX
         TEXT_XUPD(1)   TYPE C,             " X = Update Texte
         TEXTZ_XUPD(1)   TYPE C,             " X = Update Texte Zentral
         TITEL1(20)     TYPE C,             " Titel
         TITEL2(20)     TYPE C.             " Titel

DATA:    XAUTF(1)       TYPE C,             " Liste unvollständig?
         XAUTH(1)       TYPE C,             " Berechtigungsprüfung o.k.?
         XAUTH_ANA(1)   TYPE C,             " F_KNB1_ANA o.k.?
         XAUTH_KNKA(1)  TYPE C,             " F_KNKA_MAN o.k.?
         XPAAKT(1)      TYPE C,             " Zusatzkomponenten aktiv
         XDBAKT(1)      TYPE C,             " Aktiv an Schnittst. ZE/DE
         xexit(1)       type C,             " F12 bei ALV-Liste im Popup
         XHORDA(1)      TYPE C.             " Kz.: Horizont geändert

DATA:    ZVPER(11)      TYPE C.             " Perioden für Zahlverhalten

*---------------------------------------------------------------------*
*        Fieldsymbols
*---------------------------------------------------------------------*
FIELD-SYMBOLS: <F1>, <F2>.

*---------------------------------------------------------------------*
*        Felder und Strukturen fuer temporaere Notloesungen
*---------------------------------------------------------------------*
DATA:    IN_ARBEIT(1)   TYPE C.


*---------------------------------------------------------------------*
*        Felder für FI-ARI: Third-Party Integration
*---------------------------------------------------------------------*
TABLES:  THEAD.
TABLES:  RF61B.
TABLES:  RF61E.
TABLES:  RF61H.
DATA:    BEGIN OF TEXTLINES OCCURS 100.
           INCLUDE STRUCTURE RF61T.
DATA:    END   OF TEXTLINES.
DATA:    BEGIN OF TLINES OCCURS 100.
           INCLUDE STRUCTURE TLINE.
DATA:    END   OF TLINES.
DATA:    BEGIN OF OLDLINES OCCURS 100.
           INCLUDE STRUCTURE TLINE.
DATA:    END   OF OLDLINES.
DATA:    BEGIN OF CTEXT,
           INSERT(1),
         END   OF CTEXT.

* ------ Funktionstastentexte -----------------------
DATA:    BEGIN OF FKTTAB OCCURS 3.
           INCLUDE STRUCTURE RF61C.
DATA:    END OF FKTTAB.

* ------ Subscreens ----------------------------------------
DATA:    BEGIN OF SUBTAB OCCURS 2.
           INCLUDE STRUCTURE RF61E.
DATA:    END OF SUBTAB.

DATA:    BEGIN OF ARI,
           TDID  LIKE TTXID-TDID,
           PARTY LIKE TBE12-PARTY,
           PRDKT LIKE TBE22-PRDKT,
           LNUMM LIKE T061S-LNUMM,
*          PRTYP LIKE T061P-PRTYP VALUE '01',
           MPOOL LIKE T061S-MPOOL VALUE 'SAPMF02C',
           DYNNR LIKE T061S-SDYNN VALUE '0210',
           FUNCP LIKE T061S-FUNCP,
           DUMOD LIKE T061S-MPOOL VALUE 'SAPMF02C',
           DUDYN LIKE T061S-SDYNN VALUE '1099',
           RCODE LIKE RF61B-RCODE,
           RTEXT LIKE RF61B-RTEXT,
         END   OF ARI.

*mi/4.5B begin
*-----------------------------------------------------------------------
* ZAV - Includes
*-----------------------------------------------------------------------
TABLES:           KNVK,
                  LFA1.

DATA:             XKNVK         LIKE FKNVK OCCURS 0 WITH HEADER LINE,
                BEGIN OF XPARNUM OCCURS 10,
                  PARNR        LIKE KNVK-PARNR,    " Partnernummer
                  PARDU        LIKE KNVK-PARNR,    " Partner-Dummynummer
                  PARTX(1)     TYPE C,        " Kennzeichen 'Textbearb.'
                END OF XPARNUM.

         INCLUDE: SAPCAMFL,     "ZAV-Flag
                  MF02DTZA,     "Globale Daten für ZAV-Routinen
                  MF02DFZA.     "ZAV-Routinen

DATA:             CONVERSION    VALUE C_CONVERSION.
*mi/4.5B end
DATA:             INT_KNA1  TYPE KNA1.
