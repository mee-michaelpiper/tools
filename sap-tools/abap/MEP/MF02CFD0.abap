***INCLUDE MF02CFD0 .

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE DEBITORENSTAMM_LESEN                              *
*---------------------------------------------------------------------*
*        Tabellen initialisieren.                                     *
*        Konto sperren.                                               *
*        KNKA und KNKK einlesen.                                      *
*        Bearbeitungskennzeichen setzen.                              *
*        Berechtigungen prüfen.                                       *
*---------------------------------------------------------------------*
FORM DEBITORENSTAMM_LESEN.
  PERFORM KONTODATEN_ZURUECKSETZEN.

  PERFORM ALPHAFORMAT(SAPFS000) USING RF02L-KUNNR KNA1-KUNNR.
  SET PARAMETER ID 'KUN' FIELD KNA1-KUNNR.

*------- Konto sperren -------------------------------------------------
  IF T020-FUNCL = SPACE.
    PERFORM SPERREN.
  ENDIF.
  PERFORM KNA1_LESEN.
  PERFORM KNKA_LESEN.
  PERFORM BERECHTIGUNG_PRUEFEN_KNKA USING ACTVT.
  PERFORM BERECHTIGUNG_PRUEFEN_BED.

*------- KNKK bearbeiten? ----------------------------------------------
  IF RF02L-KKBER NE SPACE.
    IF RF02L-KKBER NE T014-KKBER.
      SELECT SINGLE * FROM T014 WHERE KKBER = RF02L-KKBER.
      IF SY-SUBRC NE 0.
        CLEAR T014.
        SET CURSOR FIELD 'RF02L-KKBER'.
        MESSAGE E124 WITH RF02L-KKBER.
      ENDIF.
      PERFORM T014T_LESEN USING RF02L-KKBER.
    ENDIF.
    PERFORM BERECHTIGUNG_PRUEFEN_KNKK USING RF02L-KKBER 'ERROR' ACTVT.
    KNKK-KKBER = RF02L-KKBER.
    PERFORM KNKK_LESEN USING SPACE.
    PERFORM T014N_LESEN.

*------- Referenzdebitor sperren ---------------------------------------
    IF  KLIM-XEXKK EQ 'X'
    AND KNKK-KNKLI NE KNKK-KUNNR
    AND KNKK-KNKLI NE SPACE.
      PERFORM SPERREN_KNKLI USING KNKK-KNKLI.
    ENDIF.

*------- Anzeigefelder setzen -----------------------------------------
    RF02L-WAERB = T014-WAERS.
    RF02L-KKBTX = T014T-KKBTX.
     *RF02L-WAERB = T014-WAERS.
    S066-CMWAE  = T014-WAERS.
    S067-CMWAE  = T014-WAERS.
  ELSE.
    CLEAR T014.
  ENDIF.

*------- Anzeigefeld RF02L-KUNDE setzen --------------------------------
  RF02L-KUNDE = KNA1-KUNNR.
ENDFORM.                    "DEBITORENSTAMM_LESEN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE DELETE_KNKA                                       *
*---------------------------------------------------------------------*
*        Löschen von KNKA                                             *
*---------------------------------------------------------------------*
FORM DELETE_KNKA.

* ------ Frage stellen -------------------------------------------------
  CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_VALUE'
    EXPORTING
      TITEL         = TEXT-PT8
      TEXT_BEFORE   = TEXT-P54
      OBJECTVALUE   = KNA1-KUNNR
      TEXT_AFTER    = TEXT-P55
      DEFAULTOPTION = 'Y'
    IMPORTING
      ANSWER        = ANSWER.

* ------ Antwort ausführen ---------------------------------------------
  IF ANSWER = 'J'.
    KLIM-XDELA = 'X'.
    PERFORM CHECK_AENDERUNGEN.
    PERFORM SCHLUSS_BEARBEITUNG.
  ELSE.
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDFORM.                    "DELETE_KNKA

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE DELETE_KNKK                                       *
*---------------------------------------------------------------------*
*        Löschen von KNKK                                             *
*---------------------------------------------------------------------*
FORM DELETE_KNKK.
  PERFORM CHECK_DELETE_KNKK.

* ------ Frage stellen -------------------------------------------------
  CHAR1    = KNA1-KUNNR.
  CHAR1+15 = RF02L-KKBER.
  CONDENSE CHAR1.
  CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_VALUE'
    EXPORTING
      TITEL         = TEXT-PT5
      TEXT_BEFORE   = TEXT-P21
      OBJECTVALUE   = CHAR1
      TEXT_AFTER    = TEXT-P22
      DEFAULTOPTION = 'Y'
    IMPORTING
      ANSWER        = ANSWER.

* ------ Antwort ausführen ---------------------------------------------
  IF ANSWER = 'J'.
    KLIM-XDELK = 'X'.
    PERFORM CHECK_AENDERUNGEN.
    PERFORM SCHLUSS_BEARBEITUNG.
  ELSE.
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDFORM.                    "DELETE_KNKK

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE DSO_ERKLAEREN                                      *
*---------------------------------------------------------------------*
*       DSO erklaeren                                                 *
*---------------------------------------------------------------------*
FORM DSO_ERKLAEREN.
  PERFORM DSO_PARAMETER.
  CALL FUNCTION 'CUSTOMER_DSO_EXPLANATION'
    EXPORTING
      I_KKBER      = KNKK-KKBER
      I_KUNNR      = KNA1-KUNNR
      I_ANZBUPER   = T000CM-DSOPP
      I_XCHILDS    = T000CM-DSOCH
      I_ACTBALANCE = T000CM-DSOAB.
ENDFORM.                    "DSO_ERKLAEREN

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE DSO_ERMITTELN                                      *
*---------------------------------------------------------------------*
*       DSO ermitteln                                                 *
*---------------------------------------------------------------------*
FORM DSO_ERMITTELN.
  PERFORM DSO_PARAMETER.
  CALL FUNCTION 'CUSTOMER_DSO_CALCULATION'
    EXPORTING
      I_KKBER      = KNKK-KKBER
      I_KUNNR      = KNA1-KUNNR
      I_ANZBUPER   = T000CM-DSOPP
      I_XCHILDS    = T000CM-DSOCH
      I_ACTBALANCE = T000CM-DSOAB
    IMPORTING
      E_DSOIN      = RF02L-DSOIN.
ENDFORM.                    "DSO_ERMITTELN

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE DSO_PARAMETER                                      *
*---------------------------------------------------------------------*
*       DSO-Parameter ermitteln                                       *
*---------------------------------------------------------------------*
FORM DSO_PARAMETER.
  IF T000CM-DSOPP IS INITIAL.
    SELECT SINGLE * FROM T000CM.
    IF SY-SUBRC     EQ 0.
      IF T000CM-DSOPP IS INITIAL.
        T000CM-DSOPP = '003'.
      ENDIF.
    ELSE.
      T000CM-DSOPP = '003'.
      T000CM-DSOCH = ' '.
      T000CM-DSOAB = 'X'.
    ENDIF.
  ENDIF.
ENDFORM.                    "DSO_PARAMETER

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE DYNPRO_ANKREUZEN                                  *
*---------------------------------------------------------------------*
*        Dynpro ankreuzen, wenn per GPA (CDY) gewünscht               *
*---------------------------------------------------------------------*
*  ->    D01_DYNNR: Dynpronummer (ohne führende '0')                  *
*---------------------------------------------------------------------*
FORM DYNPRO_ANKREUZEN USING
            D01_DYNNR    TYPE C.
*ORM DYNPRO_ANKREUZEN USING D01_DYNNR.
  CHECK KLIM-AUSWL CS D01_DYNNR.
  CHAR1   = 'RF02L-D0'.
  CHAR1+8 = D01_DYNNR.
  ASSIGN (CHAR1) TO <F1>.
  <F1> = 'X'.
ENDFORM.                    "DYNPRO_ANKREUZEN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE DYNSEL_EINTRAGEN                                  *
*---------------------------------------------------------------------*
*        Prüfen, ob Dynpro markiert ist und Aufnehmen in KLIM-AUSWL.  *
*---------------------------------------------------------------------*
*  ->    D01_FELD : Feldname des Ankreuzfeldes.                       *
*---------------------------------------------------------------------*
FORM DYNSEL_EINTRAGEN USING
            D01_FELD     TYPE C.
*ORM DYNSEL_EINTRAGEN USING D01_FELD.
  CHAR1 = D01_FELD.
  ASSIGN (CHAR1) TO <F1>.
  CHECK <F1> NE SPACE.
  SHIFT KLIM-AUSWL BY 4 PLACES RIGHT.
  KLIM-AUSWL(1)   = '/'.
  SHIFT CHAR1 BY 8 PLACES.
  KLIM-AUSWL+1(3) = CHAR1.
ENDFORM.                    "DYNSEL_EINTRAGEN

*eject
*---------------------------------------------------------------------*
*       FORM   DYNTAB_AUFBAUEN                                        *
*---------------------------------------------------------------------*
*       Die interne Tabelle DYNTAB wird aus der im Datenbereich       *
*       festgelegten Dynprofolge DYNSEQL aufgebaut.                   *
*       Der Dynprotyp (Bereich) wird übernommen.                      *
*---------------------------------------------------------------------*
FORM DYNTAB_AUFBAUEN.
  REFRESH: DYNTAB.

*------- Dyntab aufbauen -----------------------------------------------
  CLEAR CHAR1.
  WHILE CHAR1(4) NE '$END'
    VARY CHAR1(4)  FROM DYNSEQL-D01 NEXT DYNSEQL-D02
    VARY CHARL1    FROM DYNSEQL-T01 NEXT DYNSEQL-T02.
    CLEAR DYNTAB.
    IF CHAR1(4) = '$END'.
      EXIT.
    ENDIF.
    IF CHARL1 CN 'AK'.
      MESSAGE A308 WITH 'DYNTAB_AUFBAUEN'.
    ENDIF.

* ------ Übersicht, Anschrift und Zahlverhalten nicht bei BATCH-INPUT --
    IF SY-BINPT = 'X'.
      CHECK CHAR1(4) NE '0105'
        AND CHAR1(4) NE '0110'
        AND CHAR1(4) NE '0220'.
    ENDIF.

* ------ Dynpronummer und Typ ------------------------------------------
    DYNTAB-DYNNR = CHAR1(4).
    DYNTAB-DTYPE = CHARL1.

* ------ Kontrollbereichsdynpros, nur wenn gewünscht -------------------
    IF KLIM-XBEKK = SPACE.
      CHECK DYNTAB-DTYPE = 'A'.
    ENDIF.

* ------ Zentraldaten nur, wenn berechtigt -----------------------------
    IF XAUTH_KNKA = SPACE.
      CHECK DYNTAB-DYNNR NE '0120'.
    ENDIF.

* ------ Dynpro markieren ----------------------------------------------
    CHAR2   = 'RF02L-D'.
    CHAR2+7 = DYNTAB-DYNNR.
    ASSIGN (CHAR2) TO <F1>.
    DYNTAB-XMARK = <F1>.

*mi/4.5B begin
* ------ Wenn ZAV aktiv, neues Anschrift-Dynpro 111 verwenden ----------
    IF NOT ZAV_FLAG IS INITIAL AND CHAR1(4) = '0110'.
      DYNTAB-DYNNR = CHAR1(4) = '0111'.
    ENDIF.
*mi/4.5B end

* ------ Aufnehmen in DYNTAB -------------------------------------------
    APPEND DYNTAB.
  ENDWHILE.

* ------ Letztes Dynpro ermitteln --------------------------------------
  PERFORM DYNTAB_XLAST_SETZEN.
ENDFORM.                    "DYNTAB_AUFBAUEN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE DYNTAB_ERSTES_BILD                                *
*---------------------------------------------------------------------*
*        Ermitteln und Setzen des ersten Dynpros.                     *
*---------------------------------------------------------------------*
FORM DYNTAB_ERSTES_BILD.
  GET PARAMETER ID 'CDX' FIELD STARTDYNPRO.
  PERFORM ERSTES_BILD_BESTIMMEN.
  CLEAR STARTDYNPRO.
  SET PARAMETER ID 'CDX' FIELD STARTDYNPRO.
* ------ Bildspezifische Vorbereitung nötig? ---------------------------
  PERFORM BILDSPEZIFISCHE_VORBEREITUNG USING DYNTAB-DYNNR.

* ------ Zahlungsverhalten ermitteln? ----------------------------------
  SET SCREEN DYNTAB-DYNNR.
  LEAVE SCREEN.
ENDFORM.                    "DYNTAB_ERSTES_BILD

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE DYNTAB_XLAST_SETZEN                               *
*---------------------------------------------------------------------*
*        Kennzeichnen des letzten Dynpros.                            *
*---------------------------------------------------------------------*
FORM DYNTAB_XLAST_SETZEN.
  LOOP AT DYNTAB WHERE XMARK NE SPACE.
    TABIX = SY-TABIX.
  ENDLOOP.
  IF SY-SUBRC = 0.
    READ TABLE DYNTAB INDEX TABIX.
    DYNTAB-XLAST = 'X'.
    MODIFY DYNTAB INDEX TABIX.
  ENDIF.
ENDFORM.                    "DYNTAB_XLAST_SETZEN
*&---------------------------------------------------------------------*
*&      Form  ERSTES_BILD_BESTIMMEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ERSTES_BILD_BESTIMMEN.
  LOOP AT DYNTAB WHERE DYNNR = STARTDYNPRO
                   AND XMARK NE SPACE.
    EXIT.
  ENDLOOP.
  IF SY-SUBRC NE 0.
    LOOP AT DYNTAB WHERE XMARK NE SPACE.
      EXIT.
    ENDLOOP.
    IF SY-SUBRC NE 0.
      MESSAGE A308 WITH 'DYNPRO_ERSTES_BILD'.
    ENDIF.
  ENDIF.

ENDFORM.                    " ERSTES_BILD_BESTIMMEN
*&---------------------------------------------------------------------*
*&      Form  DB_INIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DB_INIT.
  TABLES: T061S.
  SELECT SINGLE * FROM T061S WHERE MPOOL = 'SAPMF02C/RFDKLI40'
                               AND LNUMM = '00'.
  IF SY-SUBRC = 0 AND  T061S-FUNCP NE SPACE.
    XDBAKT = 'X'.
    CALL FUNCTION T061S-FUNCP
      IMPORTING
        E_IDBXKZ = IDBXKZ.
  ENDIF.

ENDFORM.                    " DB_INIT
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_LIST_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_OKCODE  text
*----------------------------------------------------------------------*
FORM DISPLAY_LIST_ALV USING    P_OKCODE TYPE C.
DATA: LD_BUK_SELFIELD TYPE SLIS_SELFIELD.

  CASE P_OKCODE.
    WHEN 'LBUD'.
      CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
           EXPORTING
                I_TITLE                 = TEXT-U90
                I_SELECTION             = 'X'
*           I_ZEBRA                 = ' '
                I_SCREEN_START_COLUMN   = 10
                I_SCREEN_START_LINE     = 10
*           I_SCREEN_END_COLUMN     = 0
*           I_SCREEN_END_LINE       = 0
*           I_CHECKBOX_FIELDNAME    =
*           I_LINEMARK_FIELDNAME    =
*           I_SCROLL_TO_SEL_LINE    = 'X'
                I_TABNAME               = 'BUKTAB'
*           I_STRUCTURE_NAME        =
                IT_FIELDCAT             = T_FIELDCAT[]
*           IT_EXCLUDING            =
*           I_CALLBACK_PROGRAM      =
*           I_CALLBACK_USER_COMMAND =
          IMPORTING
            ES_SELFIELD             = LD_BUK_SELFIELD
            E_EXIT                  = XEXIT
           TABLES
                T_OUTTAB                = BUKTAB
           EXCEPTIONS
                PROGRAM_ERROR           = 1
                OTHERS                  = 2.
      IF SY-SUBRC = 0 AND XEXIT = SPACE.
         READ TABLE BUKTAB INDEX LD_BUK_SELFIELD-TABINDEX.
         *T001-BUKRS = BUKTAB-BUKRS.
        KLIM-BUKRS  = BUKTAB-BUKRS.
      ELSE.
         *T001-BUKRS = SPACE.
      ENDIF.
    WHEN 'REFL'.
      CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
           EXPORTING
                I_TITLE                 = TEXT-U80
                I_SELECTION             = SPACE
*           I_ZEBRA                 = ' '
                I_SCREEN_START_COLUMN   = 10
                I_SCREEN_START_LINE     = 10
*           I_SCREEN_END_COLUMN     = 0
*           I_SCREEN_END_LINE       = 0
*           I_CHECKBOX_FIELDNAME    =
*           I_LINEMARK_FIELDNAME    =
*           I_SCROLL_TO_SEL_LINE    = 'X'
                I_TABNAME               = 'REFTAB'
*           I_STRUCTURE_NAME        =
                IT_FIELDCAT             = T_FIELDCAT[]
*           IT_EXCLUDING            =
*           I_CALLBACK_PROGRAM      =
*           I_CALLBACK_USER_COMMAND =
*      IMPORTING
*           ES_SELFIELD             =
*           E_EXIT                  =
           TABLES
                T_OUTTAB                = REFTAB
           EXCEPTIONS
                PROGRAM_ERROR           = 1
                OTHERS                  = 2.


  ENDCASE.
ENDFORM.                    " DISPLAY_LIST_ALV
*&---------------------------------------------------------------------*
*&      Form  DYNP_VALUES_READ
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DYNP_VALUES_READ.

  DATA:  LT_DYNPVAL LIKE DYNPREAD OCCURS 1 WITH HEADER LINE.


  REFRESH LT_DYNPVAL.
  LT_DYNPVAL-FIELDNAME = 'RF02L-D0105'.
  APPEND LT_DYNPVAL.
  LT_DYNPVAL-FIELDNAME = 'RF02L-D0110'.
  APPEND LT_DYNPVAL.
  LT_DYNPVAL-FIELDNAME = 'RF02L-D0120'.
  APPEND LT_DYNPVAL.
  LT_DYNPVAL-FIELDNAME = 'RF02L-D0210'.
  APPEND LT_DYNPVAL.
  LT_DYNPVAL-FIELDNAME = 'RF02L-D0220'.
  APPEND LT_DYNPVAL.

  CALL FUNCTION 'DYNP_VALUES_READ'
       EXPORTING
            DYNAME     = 'SAPMF02C'
            DYNUMB     = '0100'
       TABLES
            DYNPFIELDS = LT_DYNPVAL.

  LOOP AT LT_DYNPVAL.
    CASE LT_DYNPVAL-FIELDNAME.
      WHEN 'RF02L-D0105'.
        RF02L-D0105 = LT_DYNPVAL-FIELDVALUE.
      WHEN 'RF02L-D0110'.
        RF02L-D0110 = LT_DYNPVAL-FIELDVALUE.
      WHEN 'RF02L-D0120'.
        RF02L-D0120 = LT_DYNPVAL-FIELDVALUE.
      WHEN 'RF02L-D0210'.
        RF02L-D0210 = LT_DYNPVAL-FIELDVALUE.
      WHEN 'RF02L-D0220'.
        RF02L-D0220 = LT_DYNPVAL-FIELDVALUE.
    ENDCASE.
  ENDLOOP.
ENDFORM.                               " DYNP_VALUES_READ
