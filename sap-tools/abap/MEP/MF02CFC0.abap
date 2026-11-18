***INCLUDE MF02CFC0 .

*eject
*---------------------------------------------------------------------*
*       FORM  CALL_SCREEN                                             *
*---------------------------------------------------------------------*
*       Anhand der Tabelle T019W werden der zu callende Screen und    *
*       seine Koordinaten ermittelt.                                  *
*---------------------------------------------------------------------*
*  -->  C01_WINFK   Funktion des Windows                              *
*---------------------------------------------------------------------*
FORM CALL_SCREEN USING
            C01_WINFK    TYPE C.
  CLEAR gd_init.
  SELECT SINGLE * FROM  T019W
                  WHERE MPOOL = SY-REPID
                  AND   BUVAR = SPACE
                  AND   WINFK = C01_WINFK.
  IF SY-SUBRC = 0.
    CALL SCREEN T019W-WINNR
         STARTING AT T019W-SPVON T019W-ZLVON
         ENDING   AT T019W-SPBIS T019W-ZLBIS.
    IF OK-CODE(3) = 'ENT'.
      OK-CODE = SPACE.
    ENDIF.
  ELSE.
    MESSAGE A306 WITH C01_WINFK.
  ENDIF.
ENDFORM.                    "CALL_SCREEN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE CD_CALL                                           *
*---------------------------------------------------------------------*
*        Verbuchungsaufruf fuer Aenderungsbelegschreibung.            *
*---------------------------------------------------------------------*
INCLUDE FF02LCDC.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE CHECK_AENDERUNGEN                                 *
*---------------------------------------------------------------------*
*        Prüfe, ob Daten geändert wurden.                             *
*---------------------------------------------------------------------*
FORM CHECK_AENDERUNGEN.
  CLEAR: KLIM-XCHNG.
  CHECK T020-AKTYP = 'V'.

*------- Konto ist selbst LIMIT-Kunde -> BETRAG 0 ? --------------------
  IF KLIM-XDELK = SPACE.
    IF KNKK-KNKLI = KNA1-KUNNR.
      IF KNKK-KLIMK = 0.
        IF KLIM-XM762       EQ SPACE
        AND IMPPAR-OKCOD(3) NE 'TXT'.
          KLIM-XM762 = 'X'.
          MESSAGE I762 WITH RF02L-WAERB.  "Ab 4.0 i-message
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

* ------ Neuaufbau? ----------------------------------------------------
  IF KLIM-XNEUA NE SPACE.
    KLIM-XCHNG = 'X'.
  ENDIF.

* ------ KNKA ----------------------------------------------------------
  IF KLIM-XDELA = SPACE.
    KNKA-KLIMG  = KNKA-KLIMG  * 1.
    YKNKA-KLIMG = YKNKA-KLIMG * 1.
    KNKA-KLIME  = KNKA-KLIME  * 1.
    YKNKA-KLIME = YKNKA-KLIME * 1.
    IF YKNKA NE KNKA OR
    ( NOT SY-BINPT IS INITIAL AND RF02L-D0120 = 'X' ).
      KLIM-XCHNG = 'X'.
      IF KLIM-XEXKA = 'X'.
        UPD_KNKA = 'U'.
      ELSE.
        UPD_KNKA = 'I'.
      ENDIF.
    ENDIF.
  ENDIF.

* ------ KNKK ------------------------------------------------------
  IF KLIM-XDELK = SPACE.
    KNKK-KLIMK  = KNKK-KLIMK  * 1.
    YKNKK-KLIMK = YKNKK-KLIMK * 1.
    IF KNKK NE YKNKK.
      KLIM-XCHNG = 'X'.
      IF KLIM-XEXKK = 'X'.
        UPD_KNKK = 'U'.
      ELSE.
        UPD_KNKK = 'I'.
      ENDIF.
    ENDIF.
  ENDIF.

*------- Textverarbeitung ----------------------------------------------
  IF TEXT_XUPD = 'X'.
    KLIM-XCHNG = 'X'.
  ENDIF.

*-------Textverarbeitung(zentral)---------------------------------------
  IF TEXTZ_XUPD = 'X'.
    KLIM-XCHNG = 'X'.
  ENDIF.

*------- Dokumentenverwaltung ------------------------------------------
  IF DRAD_VB   = 'X'.
    KLIM-XCHNG = 'X'.
  ENDIF.

*------- Open FI -------------------------------------------------------
  IF OFIWA-XCHNG NE SPACE.
    KLIM-XCHNG = 'X'.
  ENDIF.
ENDFORM.                    "CHECK_AENDERUNGEN

*eject
*---------------------------------------------------------------------*
*       FORM  CHECK_CHANGE_KNKLI                                      *
*---------------------------------------------------------------------*
*       Es wird geprüft, ob die Referenzliste leer ist und            *
*       damit KNKLI änderbar ist.                                     *
*---------------------------------------------------------------------*
FORM CHECK_CHANGE_KNKLI.

* ------ Referenzliste aufbauen ------------------------------------
  PERFORM AUFBAUEN_REFTAB.

* ------ Referenzliste nicht leer? ---------------------------------
  DESCRIBE TABLE REFTAB LINES SY-TFILL.
  IF SY-TFILL > 0.
*   MESSAGE E710 WITH SY-TFILL KNA1-KUNNR.
    MESSAGE S710 WITH SY-TFILL KNA1-KUNNR.
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDFORM.                    "CHECK_CHANGE_KNKLI

*eject
*---------------------------------------------------------------------*
*       FORM  CHECK_DELETE_KNKK                                       *
*---------------------------------------------------------------------*
*       Kreditlimitsätze, auf die noch verwiesen wird, können         *
*       nicht gelöscht werden.                                        *
*---------------------------------------------------------------------*
FORM CHECK_DELETE_KNKK.
  IF YKNKK-KNKLI = KNA1-KUNNR.

* ------ Über DB-Index prüfen, ob anderes KNKK aktuelles referiert -----
    RC = 0.
    SELECT * FROM  KNKK
             INTO *KNKK
             WHERE KNKLI = KNKK-KUNNR
             AND   KKBER = KNKK-KKBER.
      IF *KNKK-KUNNR NE KNA1-KUNNR.
        RC = 4.
        EXIT.
      ENDIF.
    ENDSELECT.
    IF RC NE 0.
      MESSAGE E703 WITH *KNKK-KUNNR KNKK-KUNNR.
    ENDIF.
  ELSE.

* ------ Limit wird bei anderem Konto gepflegt -------------------------
    MESSAGE E716 WITH YKNKK-KNKLI.
  ENDIF.
ENDFORM.                    "CHECK_DELETE_KNKK
*&---------------------------------------------------------------------*
*&      Form  CALL_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0987   text
*----------------------------------------------------------------------*
FORM CALL_ALV USING P_OKCODE TYPE C.
  PERFORM FILL_T_FIELDCAT USING P_OKCODE.
  PERFORM DISPLAY_LIST_ALV USING P_OKCODE.
ENDFORM.                    " CALL_ALV

*&---------------------------------------------------------------------*
*&      Form  FILL_T_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_OKCODE  text
*----------------------------------------------------------------------*
FORM FILL_T_FIELDCAT USING    P_OKCODE TYPE C.
* build the fieldcat
  CLEAR: T_FIELDCAT.
  REFRESH: T_FIELDCAT.
  CASE P_OKCODE.
    WHEN 'LBUD'.
      CLEAR T_FIELDCAT.
      T_FIELDCAT-TABNAME       = 'BUKTAB'.
      T_FIELDCAT-FIELDNAME     = 'BUKRS'.
      T_FIELDCAT-REF_FIELDNAME = 'BUKRS'.
      T_FIELDCAT-REF_TABNAME   = 'T001'.
      APPEND T_FIELDCAT.

      CLEAR T_FIELDCAT.
      T_FIELDCAT-TABNAME       = 'BUKTAB'.
      T_FIELDCAT-FIELDNAME     = 'BUTXT'.
      T_FIELDCAT-REF_FIELDNAME = 'BUTXT'.
      T_FIELDCAT-REF_TABNAME   = 'T001'.
      APPEND T_FIELDCAT.

    WHEN 'REFL'.

      CLEAR T_FIELDCAT.
      T_FIELDCAT-TABNAME       = 'REFTAB'.
      T_FIELDCAT-FIELDNAME     = 'KUNNR'.
      T_FIELDCAT-REF_FIELDNAME = 'KUNNR'.
      T_FIELDCAT-REF_TABNAME   = 'KNKK'.
      APPEND T_FIELDCAT.

      CLEAR T_FIELDCAT.
      T_FIELDCAT-TABNAME       = 'REFTAB'.
      T_FIELDCAT-FIELDNAME     = 'KKBER'.
      T_FIELDCAT-REF_FIELDNAME = 'KKBER'.
      T_FIELDCAT-REF_TABNAME   = 'KNKK'.
      APPEND T_FIELDCAT.

      CLEAR T_FIELDCAT.
      T_FIELDCAT-TABNAME       = 'REFTAB'.
      T_FIELDCAT-FIELDNAME     = 'OBLIG'.
      T_FIELDCAT-REF_FIELDNAME = 'OBLIG'.
      T_FIELDCAT-REF_TABNAME   = 'RF02L'.
      T_FIELDCAT-CFIELDNAME    = 'WAERS'.
      APPEND T_FIELDCAT.

      CLEAR T_FIELDCAT.
      T_FIELDCAT-TABNAME       = 'REFTAB'.
      T_FIELDCAT-FIELDNAME     = 'WAERS'.
      T_FIELDCAT-REF_FIELDNAME = 'WAERS'.
      T_FIELDCAT-REF_TABNAME   = 'T014'.
      APPEND T_FIELDCAT.
  ENDCASE.
ENDFORM.                    " FILL_T_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  CHECK_BLOCK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->i_KNKK_KNKLI  text
*----------------------------------------------------------------------*
FORM check_block  USING i_kunnr type kunnr.

  data ld_cvp_xblck type cvp_xblck.

  SELECT SINGLE cvp_xblck FROM kna1 INTO ld_cvp_xblck
           WHERE kunnr = i_kunnr.
  IF ld_cvp_xblck ne SPACE.
    MESSAGE E048(F4) WITH i_kunnr.
  ENDIF.
ENDFORM.                    " CHECK_BLOCK
