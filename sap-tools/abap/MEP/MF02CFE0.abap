***INCLUDE MF02CFE0 .

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE ECNN_OKCODE                                       *
*---------------------------------------------------------------------*
*        SAP-ARI: Aufruf eines Partner-FBS                            *
*---------------------------------------------------------------------*
FORM ECNN_OKCODE.

* ------- Funktionsnummer aus OK-Code setzen ---------------------------
  ARI-LNUMM = OK-CODE+2(2).
  ARI-TDID  = SPACE.
  CLEAR: OK-CODE.

* ------- Funktion aktiv? ----------------------------------------------
  READ TABLE FKTTAB INDEX ARI-LNUMM.
  CHECK SY-SUBRC = 0.

* ------- Adressdaten setzen -------------------------------------------
  MOVE-CORRESPONDING KNA1 TO RF61H.
  IF RF61H-LAND1 NE SPACE.
    SELECT SINGLE * FROM T005 WHERE LAND1 = RF61H-LAND1.
    IF  SY-SUBRC   EQ 0
    AND T005-INTCA NE SPACE.
      RF61H-LAND1 = T005-INTCA.
    ENDIF.
  ENDIF.
* ------- Name des Partner-FBS ermitteln -------------------------------
  CALL FUNCTION 'OPEN_FI_FUNCTIONMODULE_GET'
       EXPORTING
            MPOOL         = ARI-MPOOL
            LNUMM         = ARI-LNUMM
       IMPORTING
           PARTY         = ARI-PARTY
            PRDKT         = ARI-PRDKT
            FUNCP         = ARI-FUNCP
       EXCEPTIONS
            NOTHING_FOUND = 01.

* ------- Partner-FBS eingetragen? -------------------------------------
  CHECK ARI-FUNCP NE SPACE.

* ------- Partner-FBS aufrufen -----------------------------------------
  CALL FUNCTION ARI-FUNCP
       EXPORTING
            ADDRESS   = RF61H
            IKNKK     = KNKK
            PARTY     = ARI-PARTY
            PRDKT     = ARI-PRDKT
            LANGU     = SY-LANGU
       IMPORTING
            EKNKK     = KNKK
            TDID      = ARI-TDID
            RCODE     = ARI-RCODE
            RTEXT     = ARI-RTEXT
       TABLES
            TEXTLINES = TEXTLINES.

* ------- Ergebnis: Text speichern (im Fehlerfall ist TEXTLINES leer) --
  IF ARI-TDID NE SPACE.
    PERFORM ARI_EXTERNEN_TEXT_SICHERN.
  ENDIF.

* ------- Fehler? ------------------------------------------------------
  IF NOT ARI-RCODE IS INITIAL
  OR NOT ARI-RTEXT IS INITIAL.
    MESSAGE S899 WITH ARI-RTEXT.
  ELSE.
    IF IDBXKZ = 'X' AND XDBAKT = 'X'.
      MOVE-CORRESPONDING KNKK TO KNKA.    "Ergebnis in KNKA speichern?
    ENDIF.
  ENDIF.

* ------- Auf Dynpro stehenbleiben -------------------------------------
  SET SCREEN SY-DYNNR.
  LEAVE SCREEN.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE ECS_COLLECT_EXCTAB                                *
*---------------------------------------------------------------------*
*        Nicht aktive Funktion in EXCTAB aufnehmen                    *
*---------------------------------------------------------------------*
FORM ECS_COLLECT_EXCTAB USING LNUMM like sy-index
                              CODE type c.
  READ TABLE FKTTAB INDEX LNUMM.
  IF SY-SUBRC = 0.
    IF T020-AKTYP = 'A'.
      CHECK FKTTAB-XSHOW = SPACE.
      EXCTAB-OKCOD = CODE.
      COLLECT EXCTAB.
    ENDIF.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE ECS_DUMMY_SUBSCREEN                               *
*---------------------------------------------------------------------*
*        Falls in T061S kein Subscreen definiert ist, wird ein        *
*        DUMMY-Eintrag vorgenommen, damit es keinen Laufzeitfehler    *
*        beim Prozessieren des Dynpros gibt.                          *
*---------------------------------------------------------------------*
FORM ECS_DUMMY_SUBSCREEN USING MODULPOOL like RF61B-SPOOLS
                               DYNPRO    like RF61B-SDYNNS.
  CHECK MODULPOOL IS INITIAL.
  MODULPOOL = ARI-DUMOD.
  DYNPRO    = ARI-DUDYN.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE ECS_INITIALISEREN                                 *
*---------------------------------------------------------------------*
*        Zusatzdynpros (subscreens) ermitteln                         *
*---------------------------------------------------------------------*
FORM ECS_INITIALISIEREN.
  CLEAR: RF61B.

* ------- Zusatzdynpros ------------------------------------------------
  CALL FUNCTION 'OPEN_FI_SUBSCREENS_GET'
     EXPORTING
          MPOOL         =  ARI-MPOOL
     TABLES
          SUBTAB        =  SUBTAB
     EXCEPTIONS
          NOTHING_FOUND = 01.
  IF SY-SUBRC = 0.
*   RF61B-SPOOLS = 'SAPMF02C'.                   "Auf Wunsch von D&B
*   RF61B-SDYNNS = '1090'.                       "ausgeblendet
    LOOP AT SUBTAB.
      CASE SY-TABIX.
        WHEN 1.
          RF61B-SPOOL1 = SUBTAB-SPOOL. RF61B-SDYNN1 = SUBTAB-SDYNN.
        WHEN 2.
          RF61B-SPOOL2 = SUBTAB-SPOOL. RF61B-SDYNN2 = SUBTAB-SDYNN.
        WHEN 3.
          RF61B-SPOOL3 = SUBTAB-SPOOL. RF61B-SDYNN3 = SUBTAB-SDYNN.
        WHEN 4.
          RF61B-SPOOL4 = SUBTAB-SPOOL. RF61B-SDYNN4 = SUBTAB-SDYNN.
        WHEN 5.
          RF61B-SPOOL5 = SUBTAB-SPOOL. RF61B-SDYNN5 = SUBTAB-SDYNN.
        WHEN 6.
          RF61B-SPOOL6 = SUBTAB-SPOOL. RF61B-SDYNN6 = SUBTAB-SDYNN.
      ENDCASE.
    ENDLOOP.
  ELSE.
    RF61B-SPOOLS = 'SAPMF02C'.
    RF61B-SDYNNS = '1090'.
  ENDIF.
  PERFORM ECS_DUMMY_SUBSCREEN USING RF61B-SPOOLS RF61B-SDYNNS.
  PERFORM ECS_DUMMY_SUBSCREEN USING RF61B-SPOOL1 RF61B-SDYNN1.
  PERFORM ECS_DUMMY_SUBSCREEN USING RF61B-SPOOL2 RF61B-SDYNN2.
  PERFORM ECS_DUMMY_SUBSCREEN USING RF61B-SPOOL3 RF61B-SDYNN3.
  PERFORM ECS_DUMMY_SUBSCREEN USING RF61B-SPOOL4 RF61B-SDYNN4.
  PERFORM ECS_DUMMY_SUBSCREEN USING RF61B-SPOOL5 RF61B-SDYNN5.
  PERFORM ECS_DUMMY_SUBSCREEN USING RF61B-SPOOL6 RF61B-SDYNN6.

* ------- Funktionstastentexte -----------------------------------------
  CALL FUNCTION 'OPEN_FI_FUNCTIONTEXTS_GET'
       EXPORTING
            MPOOL         = ARI-MPOOL
       TABLES
            FKTTAB        = FKTTAB
       EXCEPTIONS
            NOTHING_FOUND = 01.
  IF SY-SUBRC NE 1.
    LOOP AT FKTTAB.
      CASE SY-TABIX.
        WHEN 1. RF61B-FTEXT1 = FKTTAB-KTEXT.
        WHEN 2. RF61B-FTEXT2 = FKTTAB-KTEXT.
        WHEN 3. RF61B-FTEXT3 = FKTTAB-KTEXT.
        WHEN 4. RF61B-FTEXT4 = FKTTAB-KTEXT.
        WHEN 5. RF61B-FTEXT5 = FKTTAB-KTEXT.
        WHEN 6. RF61B-FTEXT6 = FKTTAB-KTEXT.
      ENDCASE.
    ENDLOOP.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM ARI_EXTERNEN_TEXT_SICHERN                                *
*---------------------------------------------------------------------*
*       Von extern empfangenen Text sichern                           *
*---------------------------------------------------------------------*
FORM ARI_EXTERNEN_TEXT_SICHERN.

* ------ Texte vorhanden aus externem Aufruf? --------------------------
  DESCRIBE TABLE TEXTLINES LINES SY-TFILL.
  CHECK SY-TFILL > 0.

* ------ Schlüssel für STXH füllen -------------------------------------
  CLEAR: THEAD.
  IF IDBXKZ = 'X' AND XDBAKT = 'X'.
    THEAD-TDOBJECT  = 'KNKA'.
    THEAD-TDNAME    = KNKK-KUNNR.
  ELSE.
    THEAD-TDOBJECT  = 'KNKK'.
    THEAD-TDNAME    = KNKK-KUNNR.
    THEAD-TDNAME+10 = KNKK-KKBER.
  ENDIF.
  THEAD-TDID     = ARI-TDID.
  THEAD-TDSPRAS  = SY-LANGU.

* ------ Format ergänzen -----------------------------------------------
  REFRESH: TLINES.
  LOOP AT TEXTLINES.
    TLINES-TDFORMAT = '/('.
    TLINES-TDLINE   = TEXTLINES-TDLINE.
    APPEND TLINES.
  ENDLOOP.

* ------ Text lesen ----------------------------------------------------
  CLEAR: CTEXT.
  CALL FUNCTION 'READ_TEXT'
       EXPORTING
            ID             = THEAD-TDID
            LANGUAGE       = SY-LANGU
            NAME           = THEAD-TDNAME
            OBJECT         = THEAD-TDOBJECT
            ARCHIVE_HANDLE = 0
       IMPORTING
            HEADER         = THEAD
       TABLES
            LINES          = OLDLINES
       EXCEPTIONS
            NOT_FOUND      = 04.

* ------ für INSERT vorbereiten ----------------------------------------
  IF SY-SUBRC = 4.
    CTEXT-INSERT = 'X'.
* ------ Format aus KNKA oder KNKK bestimmen ---------------------------
    SELECT SINGLE TDFORM FROM TTXOB INTO THEAD-TDFORM
                                    WHERE TDOBJECT = THEAD-TDOBJECT.
    IF SY-SUBRC NE 0.
      THEAD-TDFORM   = 'SYSTEM'.
    ENDIF.
    THEAD-TDVERSION = '00001'.
    THEAD-TDFUSER  = SY-UNAME.
    THEAD-TDFRELES = SY-SAPRL.
    THEAD-TDFDATE  = SY-DATUM.
    THEAD-TDFTIME  = SY-UZEIT.
  ENDIF.

* ------ für UPDATE hinten anhängen ------------------------------------
  IF CTEXT-INSERT = SPACE.
    LOOP AT OLDLINES.
      TLINES = OLDLINES.
      APPEND TLINES.
    ENDLOOP.
  ENDIF.

* ------ Sichern -------------------------------------------------------
  CALL FUNCTION 'SAVE_TEXT'
       EXPORTING
         HEADER          = THEAD
         INSERT          = CTEXT-INSERT
         SAVEMODE_DIRECT = 'X'
       TABLES
         LINES           = TLINES.
  MESSAGE S780(F4).
  COMMIT WORK.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM ARI_EXTERNEN_TEXT_Z_SICHERN                              *
*---------------------------------------------------------------------*
*       Von extern empfangenen Text in zentrale Texte sichern         *
*---------------------------------------------------------------------*
FORM ARI_EXTERNEN_TEXT_Z_SICHERN.

* ------ Texte vorhanden aus externem Aufruf? --------------------------
  DESCRIBE TABLE TEXTLINES LINES SY-TFILL.
  CHECK SY-TFILL > 0.

* ------ Schlüssel für STXH füllen -------------------------------------
  CLEAR: THEAD.
  THEAD-TDOBJECT  = 'KNKA'.
  THEAD-TDNAME    = KNKK-KUNNR.
  THEAD-TDID     = ARI-TDID.
  THEAD-TDSPRAS  = SY-LANGU.

* ------ Format ergänzen -----------------------------------------------
  REFRESH: TLINES.
  LOOP AT TEXTLINES.
    TLINES-TDFORMAT = '/('.
    TLINES-TDLINE   = TEXTLINES-TDLINE.
    APPEND TLINES.
  ENDLOOP.

* ------ Text lesen ----------------------------------------------------
  CLEAR: CTEXT.
  CALL FUNCTION 'READ_TEXT'
       EXPORTING
            ID             = THEAD-TDID
            LANGUAGE       = SY-LANGU
            NAME           = THEAD-TDNAME
            OBJECT         = THEAD-TDOBJECT
            ARCHIVE_HANDLE = 0
       IMPORTING
            HEADER         = THEAD
       TABLES
            LINES          = OLDLINES
       EXCEPTIONS
            NOT_FOUND      = 04.

* ------ für INSERT vorbereiten ----------------------------------------
  IF SY-SUBRC = 4.
    CTEXT-INSERT = 'X'.
    THEAD-TDFORM   = 'SYSTEM'.
    THEAD-TDVERSION = '00001'.
    THEAD-TDFUSER  = SY-UNAME.
    THEAD-TDFRELES = SY-SAPRL.
    THEAD-TDFDATE  = SY-DATUM.
    THEAD-TDFTIME  = SY-UZEIT.
  ENDIF.

* ------ für UPDATE hinten anhängen ------------------------------------
  IF CTEXT-INSERT = SPACE.
    LOOP AT OLDLINES.
      TLINES = OLDLINES.
      APPEND TLINES.
    ENDLOOP.
  ENDIF.

* ------ Sichern -------------------------------------------------------
  CALL FUNCTION 'SAVE_TEXT'
       EXPORTING
         HEADER          = THEAD
         INSERT          = CTEXT-INSERT
         SAVEMODE_DIRECT = 'X'
       TABLES
         LINES           = TLINES.
  MESSAGE S780(F4).
  COMMIT WORK.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE ERMITTELN_SAUFT                                   *
*---------------------------------------------------------------------*
*        Offenen Auftragswert ermitteln                               *
*---------------------------------------------------------------------*
* ->     S01_KONTO: Konto                                             *
*---------------------------------------------------------------------*
FORM ERMITTELN_SAUFT USING
            S01_KONTO    LIKE KNKK-KUNNR
            S01_SAUFT    LIKE KNKK-SAUFT
            S01_HORDA    LIKE RF02L-HORDA.
*ORM ERMITTELN_SAUFT USING S01_KONTO S01_SAUFT.
  CLEAR: S01_SAUFT.
* CHECK S01_KONTO = KNKK-KUNNR.                  "47951
* ------- Horizont wurde auf 'Initial' geändert ------------------------
  IF S01_HORDA IS INITIAL AND XHORDA = 'X'.
    S01_HORDA = '99991231'.
  ENDIF.
* ------- Default-Wert ermitteln (erster Aufruf) -----------------------
  IF S01_HORDA IS INITIAL AND XHORDA = SPACE.
    CALL FUNCTION 'SD_CREDIT_HORIZON_DATE'
         EXPORTING
              I_KKBER         = KNKK-KKBER
              I_CTLPC         = KNKK-CTLPC
              I_HORIZON_EXIST = 'X'
         IMPORTING
              E_HORIZON_DATE = S01_HORDA.
    IF S01_HORDA IS INITIAL.
      S01_HORDA = '99991231'.
    ENDIF.
  ENDIF.
* ------- Offenen Auftragswert ermitteln -------------------------------
  CALL FUNCTION 'SD_CREDIT_EXPOSURE'
       EXPORTING
            FLAG_OPEN_DELIVERY = 'X'
            FLAG_OPEN_INVOICE  = 'X'
            FLAG_OPEN_ORDER    = 'X'
            HORIZON_DATE       = S01_HORDA
*           HORIZON_DATE       = '99991231'
            KKBER              = KNKK-KKBER
            KNKLI              = S01_KONTO
*           T014               = ' '
       IMPORTING
            OPEN_DELIVERY      = S067-OLIKW
            OPEN_INVOICE       = S067-OFAKW
            OPEN_ORDER         = S066-OEIKW.
  S01_SAUFT   = S067-OLIKW + S067-OFAKW + S066-OEIKW.
  IF S01_HORDA = '99991231'.
    CLEAR S01_HORDA.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE EXCTAB_AUFBAUEN                                   *
*---------------------------------------------------------------------*
*        Aufbau der EXCTAB                                            *
*---------------------------------------------------------------------*
FORM EXCTAB_AUFBAUEN.
  REFRESH: EXCTAB.

* ------ DELK / NEUA / REFL / VWDT: KNKK in Bearbeitung und da? --------
  IF KLIM-XEXKK = 'F'
  OR KLIM-XBEKK = SPACE.
    EXCTAB-OKCOD = 'DELK'. APPEND EXCTAB.
    EXCTAB-OKCOD = 'NEUA'. APPEND EXCTAB.
    EXCTAB-OKCOD = 'REFL'. APPEND EXCTAB.
    EXCTAB-OKCOD = 'VWDT'. APPEND EXCTAB.
  ENDIF.

* ------ Verwaltungsdaten nicht beim Hinzufügen KNKK -------------------
  IF KLIM-XEXKK = 'F'.
    EXCTAB-OKCOD = 'VWDT'. APPEND EXCTAB.
  ENDIF.

* ------ Löschen KNKA nicht beim Hinzufügen ----------------------------
  IF KLIM-XEXKA = 'F'.
    EXCTAB-OKCOD = 'DELA'. APPEND EXCTAB.
  ENDIF.

* ------ Änderungsbelege nicht beim Hinzufügen -------------------------
  IF  KLIM-XEXKA = 'F'
  AND KLIM-XEXKK = 'F'.
    EXCTAB-OKCOD = 'AEKT'. APPEND EXCTAB.
    EXCTAB-OKCOD = 'AEFD'. APPEND EXCTAB.
  ENDIF.

* ------ Umfeld Zahldaten/Mahndaten nur, wenn KNKK bearbeitet ----------
  IF KLIM-XBEKK = SPACE.
    EXCTAB-OKCOD = 'LBUK'. APPEND EXCTAB.
    EXCTAB-OKCOD = 'UMA '. APPEND EXCTAB.
    EXCTAB-OKCOD = 'UZA '. APPEND EXCTAB.
    EXCTAB-OKCOD = 'OLDD'. APPEND EXCTAB.
  ENDIF.

* ------ Anderer Kontrollbereich nur, wenn KNKK bearbeitet -------------
  IF KLIM-XBEKK = SPACE.
    EXCTAB-OKCOD = 'ENXT'. APPEND EXCTAB.
  ENDIF.

* ------ Nicht auswählbare Sprungziele --------------------------------
* ------ ... fehlendes KNKA nicht anzeigen ----------------------------
  IF  KLIM-XEXKA = 'F'
  AND T020-AKTYP = 'A'.
    EXCTAB-OKCOD = '0120'. APPEND EXCTAB.
  ENDIF.
* ------ ... fehlendes KNKK nicht anzeigen ----------------------------
  IF  KLIM-XEXKK = 'F'
  AND T020-AKTYP = 'A'.
    EXCTAB-OKCOD = '0105'. APPEND EXCTAB.
    EXCTAB-OKCOD = '0210'. APPEND EXCTAB.
    EXCTAB-OKCOD = '0220'. APPEND EXCTAB.
  ENDIF.
* ------ ... bei fehlendem Kontrollbereich keine KNKK-Daten anzeigen --
  IF KLIM-XBEKK = SPACE.
    EXCTAB-OKCOD = '0105'. APPEND EXCTAB.
    EXCTAB-OKCOD = '0210'. APPEND EXCTAB.
    EXCTAB-OKCOD = '0220'. APPEND EXCTAB.
  ENDIF.

* ------ Übersicht nicht, wenn keine Berechtigung ----------------------
  IF XAUTH_ANA = 'N'.
    EXCTAB-OKCOD = '0105'. APPEND EXCTAB.
  ENDIF.

* ------ Zentraldaten nicht, wenn keine Berechtigung -------------------
  IF XAUTH_KNKA = SPACE.
    EXCTAB-OKCOD = '0120'. APPEND EXCTAB.
  ENDIF.

* ------ Daten zur letzten Zahlung nur, wenn KNKK zu bearbeiten und ex.-
  IF KLIM-XBEKK = SPACE
  OR KLIM-XEXKK = SPACE.
    EXCTAB-OKCOD = 'CASH'. APPEND EXCTAB.
  ENDIF.

* ------ F15 / F17 nicht bei Batch-Input ------------------------------
  PERFORM EXCTAB_FUELLEN_B-I.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE EXCTAB_FUELLEN_B-I                                *
*---------------------------------------------------------------------*
*        Batch-Input aktiv: Rücksprünge problematisch.                *
*---------------------------------------------------------------------*
FORM EXCTAB_FUELLEN_B-I.
  CHECK SY-BINPT NE SPACE.
  EXCTAB-OKCOD = 'EF03'. APPEND EXCTAB.
  EXCTAB-OKCOD = 'EF15'. APPEND EXCTAB.
  EXCTAB-OKCOD = 'EF17'. APPEND EXCTAB.
  EXCTAB-OKCOD = 'EANZ'. APPEND EXCTAB.
  EXCTAB-OKCOD = 'EAEN'. APPEND EXCTAB.
  EXCTAB-OKCOD = 'ENXT'. APPEND EXCTAB.
ENDFORM.
