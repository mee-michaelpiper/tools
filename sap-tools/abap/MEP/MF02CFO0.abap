***INCLUDE MF02CFO0 .

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_BILD                                       *
*---------------------------------------------------------------------*
*        Springen zu beliebigem Bild.                                 *
*---------------------------------------------------------------------*
FORM OKCODE_BILD.
* ------ Dynpro 110 ändern, wenn 111 aktiv -----------------------------
  IF OK-CODE = '0110'.
    READ TABLE DYNTAB WITH KEY DYNNR = '0111'.
    IF SY-SUBRC = 0.
      OK-CODE = '0111'.
    ENDIF.
  ENDIF.
* ------ Dynpro bereits markiert in DYNTAB? ----------------------------
  RC = 0.
  LOOP AT DYNTAB WHERE DYNNR = OK-CODE.
    IF DYNTAB-XMARK = SPACE.
      RC = 4.
      DYNTAB-XMARK = 'X'.
      MODIFY DYNTAB.
    ENDIF.
  ENDLOOP.
  IF RC = 4.
    LOOP AT DYNTAB WHERE XLAST NE SPACE.
      CLEAR: DYNTAB-XLAST.
      MODIFY DYNTAB.
    ENDLOOP.
    PERFORM DYNTAB_XLAST_SETZEN.
  ENDIF.

* ------ Bildspezifische Vorbereitungen nötig? -------------------------
  PERFORM BILDSPEZIFISCHE_VORBEREITUNG USING OK-CODE.

* ------ Dynpro setzen -------------------------------------------------
  SET SCREEN OK-CODE.
  CLEAR OK-CODE.
  LEAVE SCREEN.
ENDFORM.                    "OKCODE_BILD

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_CASH                                       *
*---------------------------------------------------------------------*
*        Daten zur letzten Zahlung                                    *
*---------------------------------------------------------------------*
FORM OKCODE_CASH.

* ------ Keine Daten vorhanden? ----------------------------------------
  IF  KNKK-CASHD IS INITIAL.
    MESSAGE I744.
    EXIT.
  ENDIF.

* ------ Daten zur letzten Zahlung anzeigen ----------------------------
  PERFORM CALL_SCREEN USING 'CASH'.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_CASH

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_CV                                         *
*---------------------------------------------------------------------*
*        Anzeige des Kreditvektor                                     *
*---------------------------------------------------------------------*
FORM OKCODE_CV.
  DATA: LD_SUBRC LIKE SY-SUBRC.

  CALL FUNCTION 'CREDITCONTROL_SHOW_KNKKF1'
    EXPORTING
      I_KUNNR            = KNA1-KUNNR
      I_KKBER            = RF02L-KKBER
    EXCEPTIONS
      DATA_NOT_AVAILABLE = 1
      OTHERS             = 2.
  LD_SUBRC = SY-SUBRC.
  IF SY-SUBRC <> 0.
    CALL FUNCTION 'CREDITCONTROL_SHOW_KNKKF1'
      EXPORTING
        I_KUNNR            = KNA1-KUNNR
        I_KKBER            = RF02L-KKBER
        I_REGUL            = ' '
      EXCEPTIONS
        DATA_NOT_AVAILABLE = 1
        OTHERS             = 2.
    LD_SUBRC = SY-SUBRC.
  ENDIF.
  IF LD_SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_CV

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_DK40                                       *
*---------------------------------------------------------------------*
*        Sprung zum Report RFDKLI40.                                  *
*---------------------------------------------------------------------*
FORM OKCODE_DK40.
  SUBMIT RFDKLI40 VIA SELECTION-SCREEN AND RETURN.
ENDFORM.                    "OKCODE_DK40

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_DK41                                       *
*---------------------------------------------------------------------*
*        Sprung zum Report RFDKLI41.                                  *
*---------------------------------------------------------------------*
FORM OKCODE_DK41.
  GET PARAMETER ID 'RAS' FIELD TRAS-RASID.
  IF TRAS-RASID IS INITIAL.
    SELECT * FROM TRAS.
      EXIT.
    ENDSELECT.
  ENDIF.
  SUBMIT RFDKLI41 AND RETURN
         WITH     KUNNR = KNA1-KUNNR
         WITH     KKBER = RF02L-KKBER
         WITH     RASID = TRAS-RASID
         WITH     XC30  = 'X'
         WITH     HORDA = RF02L-HORDA.
* SUBMIT RFDKLI41 VIA SELECTION-SCREEN AND RETURN.
ENDFORM.                    "OKCODE_DK41
*&---------------------------------------------------------------------*
*&      Form  OKCODE_DK42
*&---------------------------------------------------------------------*
*       Sprung zum Report RFDKLI42
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM OKCODE_DK42.
  SUBMIT RFDKLI42 VIA SELECTION-SCREEN AND RETURN.
ENDFORM.                               " OKCODE_DK42
*&---------------------------------------------------------------------*
*&      Form  OKCODE_DK43
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM OKCODE_DK43.
  SUBMIT RFDKLI43 VIA SELECTION-SCREEN AND RETURN.
ENDFORM.                               " OKCODE_DK43

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_EINSTIEG                                   *
*---------------------------------------------------------------------*
*        OK-Code Verarbeitung auf Einstiegsbild                       *
*---------------------------------------------------------------------*
FORM OKCODE_EINSTIEG.

* ------ KLIM-XBEKA gewünscht? -----------------------------------------
  IF KLIM-AUSWL CS '110'
  OR KLIM-AUSWL CS '111'                                    "mi/4.5B
  OR KLIM-AUSWL CS '120'.
    KLIM-XBEKA = 'X'.
  ENDIF.

* ------ KLIM-XBEKK gewünscht? -----------------------------------------
  IF KLIM-AUSWL  CS '105'
  OR KLIM-AUSWL  CS '210'
  OR KLIM-AUSWL  CS '220'
  OR RF02L-KKBER NE SPACE.
    KLIM-XBEKK = 'X'.
  ENDIF.

* ------ Daten vorhanden? ----------------------------------------------
  IF  KLIM-XBEKA = 'X'
  AND KLIM-XEXKA = ' '.
    MESSAGE S704 WITH KNA1-KUNNR.
    IF T020-AKTYP = 'A'.
      PERFORM STEHENBLEIBEN.
    ENDIF.
  ENDIF.
  IF  KLIM-XBEKA = ' '
  AND KLIM-XBEKK = 'X'
  AND KLIM-XEXKK = 'F'.
    MESSAGE S711 WITH KNA1-KUNNR RF02L-KKBER.
    IF T020-AKTYP = 'A'.
      PERFORM STEHENBLEIBEN.
    ENDIF.
  ENDIF.

* ------ DYNTAB aufbauen -----------------------------------------------
  PERFORM DYNTAB_AUFBAUEN.

* ------ Feldgruppen aus T055 in X055 merken ---------------------------
  IF T020-AKTYP = 'V'.
    PERFORM X055_AUFBAUEN.
  ENDIF.

* ------ EXCTAB aufbauen -----------------------------------------------
  PERFORM EXCTAB_AUFBAUEN.

*------- Vergebene Limits in VKLTAB sammeln (auch wenn KLIM-XBEKK = ' ')
  PERFORM VKLTAB_FUELLEN.

*------- Generische Objektservices vorbereiten -------------------------
  PERFORM GEN_OBJ_SERVICE.

* ------ OK-Code bearbeiten --------------------------------------------
  CASE OK-CODE.

* ------ ENTER = Erstes Bild -------------------------------------------
    WHEN SPACE.
      PERFORM DYNTAB_ERSTES_BILD.

* ------ Änderungsbelege -----------------------------------------------
    WHEN 'AEBL'.
      PERFORM AENDERUNGSBELEGE_ANZEIGEN.
  ENDCASE.
ENDFORM.                    "OKCODE_EINSTIEG

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_F03                                        *
*---------------------------------------------------------------------*
*        Zurück von Standarddynpro                                    *
*        Springen auf Einstiegsbild (bez. bei Call zum Aufrufer).     *
*        Es erfolgt Sicherheitsabfrage.                               *
*---------------------------------------------------------------------*
FORM OKCODE_F03.
  CLEAR OK-CODE.
  PERFORM CHECK_AENDERUNGEN.

*------- Es wurden Daten geändert --------------------------------------
  IF KLIM-XCHNG = 'X'.
    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
      EXPORTING
        TITEL         = TEXT-P13
        TEXTLINE1     = TEXT-P09
        TEXTLINE2     = TEXT-P10
        DEFAULTOPTION = 'J'
      IMPORTING
        ANSWER        = ANSWER.
    CASE ANSWER.
      WHEN 'J'.
        PERFORM SCHLUSS_BEARBEITUNG.
      WHEN 'N'.
        IF SY-CALLD = 'X'.
          LEAVE.
        ELSE.
          LEAVE TO CURRENT TRANSACTION.           "946620
        ENDIF.
      WHEN 'A'.
        PERFORM STEHENBLEIBEN.
    ENDCASE.

*------- Es wurden keine Daten geändert bez. nur Anzeigetransaktion ----
  ELSE.
    IF SY-CALLD = 'X'.
      LEAVE.
    ELSE.
      LEAVE TO CURRENT TRANSACTION.           "946620
    ENDIF.
  ENDIF.
ENDFORM.                                                    "OKCODE_F03

*eject
*---------------------------------------------------------------------*
*       FORM OKCODE_F15                                               *
*---------------------------------------------------------------------*
*       Beenden der Bearbeitung mit F15.                              *
*---------------------------------------------------------------------*
FORM OKCODE_F15.
  CLEAR: OK-CODE.
  CASE T020-AKTYP.
    WHEN 'A'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'V'.
      PERFORM CHECK_AENDERUNGEN.
      IF KLIM-XCHNG = 'X'
      OR SY-DATAR   = 'X'.
        CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE'
          EXPORTING
            TITEL         = TEXT-P01
            DIAGNOSETEXT1 = TEXT-P06
            TEXTLINE1     = TEXT-P09
            TEXTLINE2     = TEXT-P10
            DEFAULTOPTION = 'J'
          IMPORTING
            ANSWER        = ANSWER.
        CASE ANSWER.
          WHEN 'J'.
            OK-CODE = 'UPDA'.
          WHEN 'N'.
            SET SCREEN 0.
            LEAVE SCREEN.
          WHEN 'A'.
        ENDCASE.
      ELSE.
        SET SCREEN 0.
        LEAVE SCREEN.
      ENDIF.
  ENDCASE.
ENDFORM.                                                    "OKCODE_F15

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_F17                                        *
*---------------------------------------------------------------------*
*        Verlassen der Transaktion mit 'ANDERES KONTO' (F17):         *
*        Soll Datensicherung erfolgen ?                               *
*---------------------------------------------------------------------*
FORM OKCODE_F17.
  CLEAR OK-CODE.
  CASE T020-AKTYP.

*------- Anzeigen ------------------------------------------------------
    WHEN 'A'.
      LEAVE TO CURRENT TRANSACTION.           "946620
*------- Ändern --------------------------------------------------------
    WHEN 'V'.
      PERFORM CHECK_AENDERUNGEN.
      IF KLIM-XCHNG = 'X'
      OR SY-DATAR   = 'X'.
        CALL FUNCTION 'POPUP_TO_CONFIRM_LOSS_OF_DATA'
          EXPORTING
            TITEL     = TEXT-P04
            TEXTLINE1 = TEXT-P09
            TEXTLINE2 = TEXT-P10
          IMPORTING
            ANSWER    = ANSWER.
        CASE ANSWER.
          WHEN 'J'.
            OK-CODE = 'UPDA'.
          WHEN 'N'.
            LEAVE TO CURRENT TRANSACTION.           "946620
          WHEN 'A'.
        ENDCASE.
*       IF ANSWER = 'J'.
*         LEAVE TO TRANSACTION SY-TCODE.
*       ELSE.
*         OK-CODE = 'STOP'.
*       ENDIF.
      ELSE.
        LEAVE TO CURRENT TRANSACTION.           "946620
      ENDIF.
  ENDCASE.
ENDFORM.                                                    "OKCODE_F17

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_FBL5                                       *
*---------------------------------------------------------------------*
*        Umfeld: Einzelposten (FBL5)                                  *
*---------------------------------------------------------------------*
FORM OKCODE_FBL5.

  CONSTANTS: LC_DATE LIKE SY-DATUM VALUE '99991231'.
  DATA: LD_KUNNR LIKE KNA1-KUNNR.

* ------ Buchungskreis erfragen ----------------------------------------
* bei jedem Durchlauf, da man evtl. unterschiedliche Buchungskreise
* auswaehlen moechte.
  PERFORM OKCODE_LBUD USING 'FBL5'.
  IF SY-SUBRC = 2.
    MESSAGE S760.
    PERFORM STEHENBLEIBEN.
  ENDIF.
  CHECK KLIM-BUKRS NE SPACE.

* ------ Vorschlagswerte setzen ----------------------------------------
  SET PARAMETER ID 'BUK' FIELD KLIM-BUKRS.
  SELECT * FROM  T021V
           WHERE TCODE = SY-TCODE.
    EXIT.
  ENDSELECT.
  IF SY-SUBRC = 0.
    SET PARAMETER ID 'DAV' FIELD T021V-VARNR.
  ENDIF.

* ------ set key date --------------------------------------------------

  SET PARAMETER ID 'FI_STIDA' FIELD LC_DATE.

* ------ set kunnr -----------------------------------------------------
  PERFORM ALPHAFORMAT(SAPFS000) USING RF02L-KUNNR LD_KUNNR.
  SET PARAMETER ID 'KUN' FIELD LD_KUNNR.

* ------ reset worklist ------------------------------------------------
  SET PARAMETER ID 'AVD' FIELD space.   " 1153512

* ------ Einzelposten zeigen -------------------------------------------
  SET PARAMETER ID 'FIT_X_AR' FIELD 'XXX  '.  "OPs+SHB+MP f. FBL5N.
  CALL TRANSACTION 'FBL5N' AND SKIP FIRST SCREEN.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_FBL5

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_FBL5_KKBER                                 *
*---------------------------------------------------------------------*
*        Umfeld: Einzelposten (FBL5) zum Kontrollbereich              *
*---------------------------------------------------------------------*
FORM OKCODE_FBL5_KKBER.

* ------ Anzeigen der Einzelposten zum Kontrollbereich -----------------
  CALL FUNCTION 'SHOW_LINE_ITEMS_FOR_CREDIT'
    EXPORTING
      I_KUNNR = KNA1-KUNNR
      I_KKBER = RF02L-KKBER
      I_TCODE = SY-TCODE
    EXCEPTIONS
      OTHERS  = 1.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_FBL5_KKBER

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_INFO                                       *
*---------------------------------------------------------------------*
*        Infosystem - Auswertungen anzeigen                           *
*---------------------------------------------------------------------*
FORM OKCODE_INFO.
  IN_ARBEIT = 'X'.
* Datensicherungsabfrage?
  CALL TRANSACTION 'F.30'.
ENDFORM.                    "OKCODE_INFO

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_LBUD                                       *
*---------------------------------------------------------------------*
*        Liste der Buchungskreise, in denen Debitor angelegt ist      *
*---------------------------------------------------------------------*
*  ->    O01_OKCOD: OK-Code, mit dem LBUD aufgerufen wurde            *
*---------------------------------------------------------------------*
FORM OKCODE_LBUD USING
            O01_OKCOD    TYPE C.
*ORM OKCODE_LBUD USING O01_OKCOD.
  PERFORM BUKTAB_FUELLEN.
  LNFIR = 1.
  DESCRIBE TABLE BUKTAB LINES LNMAX.
  IF LNMAX = 0.
    MESSAGE S768 WITH KNA1-KUNNR.
    PERFORM STEHENBLEIBEN.
  ENDIF.
* PERFORM CALL_SCREEN USING 'LBUD'.
  PERFORM CALL_ALV USING 'LBUD'.
  IF *T001-BUKRS = SPACE.
    PERFORM STEHENBLEIBEN.
  ENDIF.
  IF O01_OKCOD = 'LBUD'.
    PERFORM KNB1_LESEN.
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDFORM.                    "OKCODE_LBUD

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_LBUK                                       *
*---------------------------------------------------------------------*
*        Liste der Buchungskreise.                                    *
*---------------------------------------------------------------------*
FORM OKCODE_LBUK.
  CALL FUNCTION 'CREDITCONTROL_LIST_BUKRS'
    EXPORTING
      I_KKBER        = RF02L-KKBER
      I_BUKRS        = KLIM-BUKRS
    IMPORTING
      E_BUKRS        = KLIM-BUKRS
    EXCEPTIONS
      NO_COMPANY     = 1
      NOTHING_CHOSEN = 2.
  CASE SY-SUBRC.
    WHEN 1.
      MESSAGE S759 WITH RF02L-KKBER.
      PERFORM STEHENBLEIBEN.
    WHEN 2.
      PERFORM STEHENBLEIBEN.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    "OKCODE_LBUK

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_MAIL                                       *
*---------------------------------------------------------------------*
*        MAIL senden                                                  *
*---------------------------------------------------------------------*
FORM OKCODE_MAIL.
  CLEAR OK-CODE.
  CALL FUNCTION 'RR_SO_OBJECT_SEND'
    EXPORTING
      XBUKRS = KLIM-BUKRS
      XKKBER = RF02L-KKBER
      XKUNNR = KNA1-KUNNR
    TABLES
      TBUKRS = TBUKRS.
  IF sy-binpt IS INITIAL.
    COMMIT WORK.           "n1669916
  ENDIF.
  PERFORM STEHENBLEIBEN.   "n1669916
ENDFORM.                    "OKCODE_MAIL

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_NXT                                        *
*---------------------------------------------------------------------*
*        Übersicht KNKK-Daten auf POPUP                               *
*---------------------------------------------------------------------*
FORM OKCODE_NXT.
  CLEAR OK-CODE.
  CASE T020-AKTYP.

*------- Anzeigen ------------------------------------------------------
    WHEN 'A'.
      PERFORM NAECHSTER_KONTROLLBEREICH.

*------- Ändern --------------------------------------------------------
    WHEN 'V'.
      PERFORM CHECK_AENDERUNGEN.
      IF KLIM-XCHNG = 'X'.
        CALL FUNCTION 'POPUP_TO_CONFIRM_LOSS_OF_DATA'
          EXPORTING
            TITEL     = TEXT-P04
            TEXTLINE1 = TEXT-P02
            TEXTLINE2 = TEXT-P03
          IMPORTING
            ANSWER    = ANSWER.
        IF ANSWER = 'J'.
          PERFORM NAECHSTER_KONTROLLBEREICH.
        ELSE.
          OK-CODE = 'STOP'.
        ENDIF.
      ELSE.
        PERFORM NAECHSTER_KONTROLLBEREICH.
      ENDIF.
  ENDCASE.
ENDFORM.                    "OKCODE_NXT

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_OLDD                                       *
*---------------------------------------------------------------------*
*        Oldest Due Date auf POPUP                                    *
*---------------------------------------------------------------------*
FORM OKCODE_OLDD.

* ------ Ältesten fälligen Posten ermitteln ----------------------------
  IF KLIM-XOLDD = SPACE.
    KLIM-XBUKR = 'X'.
    KLIM-XFAPO = 'X'.
    CALL FUNCTION 'CUSTOMER_OLDEST_OPEN_ITEM'
         EXPORTING I_KKBER = RF02L-KKBER
                   I_KUNNR = KNA1-KUNNR
                   I_REGUL = ' '
*                  I_REGUL = 'X'
         IMPORTING E_KUNNR = OLDD-KUNNR
                   E_BELNR = OLDD-BELNR
                   E_BUKRS = OLDD-BUKRS
                   E_FAEDT = OLDD-FAEDT
                   E_GJAHR = OLDD-GJAHR
                   E_INFAE = OLDD-INFAE
                   E_VERZN = OLDD-VERZN
                   E_WAERS = OLDD-WAERS
                   E_WRBTR = OLDD-WRBTR
       EXCEPTIONS  NO_BUKRS = 1
                   NO_ITEMS = 2.
    CASE SY-SUBRC.

* ------ Ist der Debitor in mind. 1 Buchungskreis angelegt? ------------
      WHEN 1.
        KLIM-XBUKR = SPACE.
      WHEN 2.
        KLIM-XFAPO = SPACE.
    ENDCASE.
    KLIM-XOLDD = 'X'.
  ENDIF.

* ------ Debitor in einem Buchungskreis angelegt? ----------------------
  IF KLIM-XBUKR = SPACE.
    MESSAGE S768 WITH KNA1-KUNNR.
    PERFORM STEHENBLEIBEN.
  ENDIF.

* ------ Fällige Posten vorhanden? -------------------------------------
  IF KLIM-XFAPO = SPACE.
    MESSAGE S719.
    PERFORM STEHENBLEIBEN.
  ENDIF.

* ------ Posten mit ältester Nettofälligkeit anzeigen ------------------
  RFPOS-FAEDT = OLDD-FAEDT.
  RFPOS-VERZN = OLDD-VERZN.
  MOVE-CORRESPONDING OLDD TO BSID.
  PERFORM CALL_SCREEN USING 'OLDD'.

* ------ Stehenbleiben -------------------------------------------------
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_OLDD

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_REF                                        *
*---------------------------------------------------------------------*
*        Änderung des Referenzdebitors (KNKLI).                       *
*---------------------------------------------------------------------*
FORM OKCODE_REF.
  CLEAR OK-CODE.

* ------ Referenzliste leer? ---------------------------------------
  PERFORM CHECK_CHANGE_KNKLI.

* ------ Referenzdebitor ändern auf POPUP --------------------------
  IF SY-BINPT = SPACE.
    MESSAGE I792.
  ENDIF.
  OLD-KNKLI = KNKK-KNKLI.
  PERFORM CALL_SCREEN USING 'KNKL'.
  IF KNKK-KNKLI = SPACE.
    KNKK-KNKLI = OLD-KNKLI.
  ELSE.
    IF KNKK-KNKLI NE KNA1-KUNNR.
      CLEAR: KNKK-KLIMK.
    ENDIF.
  ENDIF.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_REF

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_REFD                                       *
*---------------------------------------------------------------------*
*        Anzeige der Daten des Referenzdebitors.                      *
*---------------------------------------------------------------------*
FORM OKCODE_REFD.
  CHECK KNKK-KNKLI NE KNA1-KUNNR.

* ------ Daten des Referenzdebitoren lesen -----------------------------
  IF RKNKK-KUNNR NE KNKK-KNKLI.
    SELECT SINGLE * FROM  KNKK
                    INTO  RKNKK
                    WHERE KUNNR = KNKK-KNKLI
                    AND   KKBER = RF02L-KKBER.
    IF SY-SUBRC NE 0.
      CLEAR: RKNKK.
      MESSAGE E711 WITH KNKK-KNKLI RF02L-KKBER.
    ENDIF.
  ENDIF.

* ------ Daten in *KNKK-Workarea stellen und anzeigen ------------------
   *KNKK = RKNKK.
   *T014-WAERS  = RF02L-WAERB.
   *RF02L-WAERB = RF02L-WAERB.
  PERFORM ERMITTELN_SAUFT USING KNKK-KNKLI SAUFT RF02L-HORDA.
   *RF02L-OBLIG = *KNKK-SKFOR + *KNKK-SSOBL + SAUFT.
  PERFORM AUSSCHOEPFUNGSGRAD_BERECHNEN
    USING *KNKK-KLIMK *RF02L-OBLIG *RF02L-KLPRZ.
  PERFORM CALL_SCREEN USING 'REFD'.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_REFD

*eject
*--------------------------------------------------------------
*        SUBROUTINE OKCODE_REFL
*--------------------------------------------------------------
*        Liste der referenzierenden Debitoren ausgeben.
*--------------------------------------------------------------
FORM OKCODE_REFL.

* ------ Referenzdebitoren ermitteln? -------------------------
  PERFORM AUFBAUEN_REFTAB.

* ------ Gibts Referenzdebitoren? -----------------------------
  IF KLIM-XREFL = 'N'.
    MESSAGE S736 WITH KNA1-KUNNR RF02L-KKBER.
    PERFORM STEHENBLEIBEN.
  ENDIF.

* ------ Referenzdebitoren anzeigen ---------------------------
  LNFIR = 1.
  DESCRIBE TABLE REFTAB LINES LNMAX.
  SORT REFTAB.
   *RF02L-WAERB = T014-WAERS.
*  PERFORM CALL_SCREEN USING 'REFL'.
  PERFORM CALL_ALV USING 'REFL'.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_REFL

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_RV02                                       *
*---------------------------------------------------------------------*
*        Vertriebsbelege - Gesperrte freigeben                        *
*---------------------------------------------------------------------*
FORM OKCODE_RV02.
  SUBMIT RVKRED02 VIA SELECTION-SCREEN AND RETURN.
ENDFORM.                    "OKCODE_RV02

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_RV03                                       *
*---------------------------------------------------------------------*
*        Vertriebsbelege - Genehmigte erneut prüfen                   *
*---------------------------------------------------------------------*
FORM OKCODE_RV03.
  SUBMIT RVKRED03 VIA SELECTION-SCREEN AND RETURN.
ENDFORM.                    "OKCODE_RV03

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_SD                                         *
*---------------------------------------------------------------------*
*        SD-Ausschöpfung                                              *
*---------------------------------------------------------------------*
FORM OKCODE_SD.
  PERFORM t014_lesen USING KNKK-KKBER.
  PERFORM CALL_SCREEN USING 'SD  '.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_SD

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE OKCODE_TEXT                                        *
*---------------------------------------------------------------------*
*       Anzeige / Pflege von Texten                                   *
*       Aufruf der Textverarbeitung.                                  *
*---------------------------------------------------------------------*
FORM OKCODE_TEXT.

*------- Call des Funktionsbausteins für Textverarbeitung --------------
  CALL FUNCTION 'FI_TEXTS_CREDM'
    EXPORTING
      I_OBJECT = 'KNKK'
      I_AKTYP  = T020-AKTYP
      I_KUNNR  = KNA1-KUNNR
      I_KKBER  = RF02L-KKBER
    IMPORTING
      E_UPDATE = TEXT_XUPD.

*------- Stehenbleiben -------------------------------------------------
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_TEXT

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE OKCODE_TEXZ                                        *
*---------------------------------------------------------------------*
*       Anzeige / Pflege von Texten auf KNKA-Ebene (zentral)          *
*       Aufruf der Textverarbeitung.                                  *
*---------------------------------------------------------------------*
FORM OKCODE_TEXZ.

*------- Call des Funktionsbausteins für Textverarbeitung --------------
  CALL FUNCTION 'FI_TEXTS_CREDZ'
    EXPORTING
      I_OBJECT = 'KNKA'
      I_AKTYP  = T020-AKTYP
      I_KUNNR  = KNA1-KUNNR
    IMPORTING
      E_UPDATE = TEXTZ_XUPD.

*------- Stehenbleiben -------------------------------------------------
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_TEXZ

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_UKK                                        *
*---------------------------------------------------------------------*
*        Übersicht KNKK-Daten auf POPUP                               *
*---------------------------------------------------------------------*
FORM OKCODE_UKK.
  OLD-LNFIR = LNFIR.
  OLD-LNMAX = LNMAX.
  LNFIR = 1.
  DESCRIBE TABLE VKLTAB LINES LNMAX.
  IF SY-TFILL = 0.
    MESSAGE S715.
  ELSE.

* ------ Fehlende Daten wegen mangelnder Berechtigung? -----------------
    IF XAUTF NE SPACE.
      MESSAGE S314.
    ENDIF.
    PERFORM CALL_SCREEN USING 'UKK'.
  ENDIF.
  LNFIR = OLD-LNFIR.
  LNMAX = OLD-LNMAX.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_UKK

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_UMA                                        *
*---------------------------------------------------------------------*
*        Umfeld: Mahndaten (KNB1)                                     *
*---------------------------------------------------------------------*
FORM OKCODE_UMA.

* ------ Buchungskreis erfragen ----------------------------------------
  IF KLIM-BUKRS = SPACE.
    PERFORM OKCODE_LBUD USING 'UMA'.
    IF SY-SUBRC = 2.
      MESSAGE S760.
      PERFORM STEHENBLEIBEN.
    ENDIF.
  ENDIF.

* ------ Mahndaten auf POPUP 1002 zeigen -------------------------------
  CHECK KLIM-BUKRS NE SPACE.
  PERFORM KNB1_LESEN.
  PERFORM KNB5_LESEN.
  PERFORM CALL_SCREEN USING 'UMA'.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_UMA

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_UZA                                        *
*---------------------------------------------------------------------*
*        Umfeld: Zahldaten (KNB1)                                     *
*---------------------------------------------------------------------*
FORM OKCODE_UZA.

* ------ Buchungskreis erfragen ----------------------------------------
  IF KLIM-BUKRS = SPACE.
    PERFORM OKCODE_LBUD USING 'UZA'.
    IF SY-SUBRC = 2.
      MESSAGE S760.
      PERFORM STEHENBLEIBEN.
    ENDIF.
  ENDIF.

* ------ Zahldaten auf POPUP 1001 zeigen -------------------------------
  CHECK KLIM-BUKRS NE SPACE.
  PERFORM KNB1_LESEN.
  PERFORM CALL_SCREEN USING 'UZA'.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_UZA

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE OKCODE_VWDT                                       *
*---------------------------------------------------------------------*
*        Verwaltungsdaten (ERNAM,ERDAT)                               *
*---------------------------------------------------------------------*
FORM OKCODE_VWDT.

* ------ Fehlen die Verwaltungsdaten? ----------------------------------
  IF  KNKK-ERNAM IS INITIAL
  AND KNKK-ERDAT IS INITIAL.
    MESSAGE S709.
  ENDIF.

* ------ Verwaltungsdaten zeigen ---------------------------------------
  PERFORM CALL_SCREEN USING 'VWDT'.
  PERFORM STEHENBLEIBEN.
ENDFORM.                    "OKCODE_VWDT
