***INCLUDE MF02CFB0 .

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE BUKTAB_FUELLEN                                     *
*---------------------------------------------------------------------*
*       Die Buchungskreise, die den neu aufzubauenden Kontrollbereich *
*       referenzieren, werden in BUKTAB gesammelt.                    *
*---------------------------------------------------------------------*
FORM BUKTAB_FUELLEN.
  DATA: ls_takof TYPE takof.                                 "n1935185
  CHECK KLIM-XKNB1 = SPACE.

* ------ Potentiell mögliche Buchungskreise ermitteln ------------------
  CALL FUNCTION 'FI_CM_GET_COMP_CODES'
       EXPORTING
            I_KKBER  = RF02L-KKBER
       TABLES
            T_BUKTAB = TCMTAB.

* ------ Sind Buchungskreise, in denen Deb. angelegt ist, dabei --------
  REFRESH: BUKTAB.
  SELECT * FROM KNB1 WHERE KUNNR = KNA1-KUNNR.
    CLEAR: BUKTAB.
    LOOP AT TCMTAB WHERE BUKRS = KNB1-BUKRS.
      EXIT.
    ENDLOOP.
    CHECK SY-SUBRC = 0.
    CALL FUNCTION 'FI_COMPANY_CODE_DATA'
         EXPORTING
              I_BUKRS      = TCMTAB-BUKRS
         IMPORTING
              E_T001       = T001
         EXCEPTIONS
              ERROR_MESSAGE = 1.
    CHECK SY-SUBRC = 0.
    MOVE-CORRESPONDING T001 TO BUKTAB.
    BUKTAB-XZVER = KNB1-XZVER.
*begin of insertion note 1935185
    BUKTAB-AKONT = KNB1-AKONT.
*      Abstimmkonto ohne Kreditmanagement-Fortschreibung?
    CALL FUNCTION 'FI_READ_TAKOF'
      EXPORTING
        i_bukrs           = knb1-bukrs
        i_akont           = knb1-akont
      IMPORTING
        e_akof            = ls_takof
      EXCEPTIONS
        invalid_call      = 1
        no_entry_in_takof = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      clear ls_takof.
    ENDIF.
    BUKTAB-XNKLIMP = LS_TAKOF-XNKLIMP.
*end of insertion note 1935185
    APPEND BUKTAB.
  ENDSELECT.
  KLIM-XKNB1 = 'X'.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM   BEENDEN_JA_NEIN                                        *
*---------------------------------------------------------------------*
*       Letztes Datenbild erreicht:                                   *
*       Verlassen der Bearbeitung?                                    *
*---------------------------------------------------------------------*
FORM BEENDEN_JA_NEIN.

*------- Ändern --------------------------------------------------------
  IF T020-AKTYP = 'V'.
    CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE'
      EXPORTING TITEL         = TEXT-P07
                DEFAULTOPTION = 'N'
                DIAGNOSETEXT1 = TEXT-P08
                TEXTLINE1     = TEXT-P02
                TEXTLINE2     = TEXT-P03
      IMPORTING ANSWER    = ANSWER.
  ENDIF.

*------- Anzeigen ------------------------------------------------------
  IF T020-AKTYP = 'A'.
    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
      EXPORTING TITEL         = TEXT-P07
                DEFAULTOPTION = 'N'
                TEXTLINE1     = TEXT-P11
                TEXTLINE2     = TEXT-P12
      IMPORTING ANSWER    = ANSWER.
  ENDIF.

* ------ Reagieren auf Antwort -----------------------------------------
  CASE ANSWER.
    WHEN 'J'.
      IF SY-CALLD = 'X'.
        LEAVE.
      ELSE.
        LEAVE TO CURRENT TRANSACTION.           "946620
      ENDIF.
    WHEN 'N'.
      PERFORM STEHENBLEIBEN.
    WHEN 'A'.
      PERFORM STEHENBLEIBEN.
  ENDCASE.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE BERECHTIGUNG_PRUEFEN_ANA                           *
*---------------------------------------------------------------------*
*       Prüfung der Berechtigung zur Kontoanalyse (F_KNB1_ANA)        *
*---------------------------------------------------------------------*
FORM BERECHTIGUNG_PRUEFEN_ANA.
  IF XAUTH_ANA = SPACE.

* ------ Buchungskreise in BUKTAB sammeln ------------------------------
    PERFORM BUKTAB_FUELLEN.

* ------ Initialisierung: Berechtigung o.k. ----------------------------
    XAUTH_ANA = 'Y'.

* ------ Berechtigung für jeden Buchungskreis prüfen -------------------
    LOOP AT BUKTAB.
      AUTHORITY-CHECK OBJECT 'F_KNB1_ANA'
                      ID     'BUKRS' FIELD BUKTAB-BUKRS.
      IF SY-SUBRC NE 0.
        XAUTH_ANA = 'N'.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDIF.

* ------ Fehlende Berechtigung? ----------------------------------------
  CHECK XAUTH_ANA = 'N'.
  MESSAGE S492 WITH BUKTAB-BUKRS 'F_KNB1_ANA'.
  PERFORM STEHENBLEIBEN.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE BERECHTIGUNG_PRUEFEN_BED                           *
*---------------------------------------------------------------------*
*       Prüfung der Berechtigung zur Berechtigungsgruppe (F_KNKK_BED) *
*       (ab 4.0C)                                                     *
*---------------------------------------------------------------------*
FORM BERECHTIGUNG_PRUEFEN_BED.
  CALL FUNCTION 'CREDITCONTROL_AUTH_KNKK_BED'
       EXPORTING
            I_ACTVT      = ACTVT
            I_BRGRU      = KNA1-BEGRU.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE BERECHTIGUNG_PRUEFEN_BUK                           *
*---------------------------------------------------------------------*
*       Prüfung der allgemeinen Berechtigung F_BKPF_BUK               *
*---------------------------------------------------------------------*
FORM BERECHTIGUNG_PRUEFEN_BUK.
  XAUTH = 'X'.

* ------ Buchungskreise zum Kontrollbereich in BUKTAB stellen ----------
  PERFORM BUKTAB_FUELLEN.

* ------ Berechtigung für jeden Buchungskreis prüfen -------------------
  LOOP AT BUKTAB.
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
                    ID     'BUKRS' FIELD BUKTAB-BUKRS
                    ID     'ACTVT' FIELD '02'.
    IF SY-SUBRC NE 0.
      XAUTH = SPACE.
      EXIT.
    ENDIF.
  ENDLOOP.

* ------ Fehlende Berechtigung? ----------------------------------------
  CHECK XAUTH = SPACE.
  MESSAGE S754 WITH BUKTAB-BUKRS 'F_BKPF_BUK' '02'.
  PERFORM STEHENBLEIBEN.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE BERECHTIGUNG_PRUEFEN_KNKA                          *
*---------------------------------------------------------------------*
*       Berechtigung für Zentraldaten (F_KNKA_MAN)                    *
*---------------------------------------------------------------------*
FORM BERECHTIGUNG_PRUEFEN_KNKA USING P_ACTVT  LIKE TACT-ACTVT.

* ------ Initialisierung: Berechtigung o.k. ----------------------------
  XAUTH_KNKA = 'X'.

* ------ Berechtigung prüfen -------------------------------------------
  CALL FUNCTION 'CREDITCONTROL_AUTHORITY_KNKA'
    EXPORTING   I_ACTVT      = P_ACTVT
    EXCEPTIONS  NO_AUTHORITY = 4.

  CHECK SY-SUBRC NE 0.
  CLEAR: XAUTH_KNKA.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE BERECHTIGUNG_PRUEFEN_KNKK                          *
*---------------------------------------------------------------------*
*       Prüfung der KKBER-Berechtigung F_KNKA_KKB                     *
*---------------------------------------------------------------------*
* ->    KKBER: Zu prüfender Kontrollbereich                           *
* ->    REACT: Reaktion auf fehlende Berechtigung:                    *
*                 ERROR = Errormeldung                                *
*                 SKIP  = Eintrag überspringen (in Listanzeige)       *
*---------------------------------------------------------------------*
FORM BERECHTIGUNG_PRUEFEN_KNKK USING
            KKBER        LIKE RF02L-KKBER
            REACT        TYPE C
            P_ACTVT      LIKE TACT-ACTVT.

DATA: LD_KUNNR LIKE KNA1-KUNNR.


* ------ KKBER-Berechtigung --------------------------------------------
  XAUTH = 'X'.
  CALL FUNCTION 'CREDITCONTROL_AUTHORITY_KNKK'
    EXPORTING   I_ACTVT      = P_ACTVT
                I_KKBER      = KKBER
    EXCEPTIONS  NO_AUTHORITY = 4.
  CHECK SY-SUBRC NE 0.
  CASE REACT.
    WHEN 'ERROR'.
      CASE P_ACTVT.
        WHEN '02'.
*----- Anzeigeberechtigung vorhanden? ----------------------------------
          IF SY-BINPT = SPACE AND SY-CALLD = 'X'.
            PERFORM BERECHTIGUNG_PRUEFEN_KNKK USING KKBER REACT '03'.
          ENDIF.
          IF  XAUTH = 'X' AND SY-BINPT = SPACE
                          AND SY-CALLD = 'X'.
*----- ... ja, FD33 aufrufen -------------------------------------------
            PERFORM ALPHAFORMAT(SAPFS000) USING RF02L-KUNNR LD_KUNNR.
            SET PARAMETER ID 'KUN' FIELD LD_KUNNR.
            SET PARAMETER ID 'KKB' FIELD RF02L-KKBER.
            SET PARAMETER ID 'CDY' FIELD SAVEDYNPRO.
            MESSAGE S740 WITH KKBER 'F_KNKA_KKB' P_ACTVT.
            CALL TRANSACTION 'FD33' AND SKIP FIRST SCREEN.
            LEAVE PROGRAM.
          ELSE.
            MESSAGE E740 WITH KKBER 'F_KNKA_KKB' P_ACTVT.
          ENDIF.
        WHEN '03'.
          MESSAGE E739 WITH KKBER 'F_KNKA_KKB' P_ACTVT.
      ENDCASE.
    WHEN 'SKIP'.
      XAUTH = SPACE.
      XAUTF = 'X'.
  ENDCASE.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE BETRAG_UMRECHNEN                                   *
*---------------------------------------------------------------------*
*       Umrechnung in Kreditlimitwährung                              *
*---------------------------------------------------------------------*
*  ->   B01_LOCAM: Local Amount                                       *
*  ->   B01_LOCCU: Local Currency                                     *
*  ->   B01_FORCU: Foreign Currency                                   *
*  ->   B01_FORAM: Foreign Amount                                     *
*---------------------------------------------------------------------*
FORM BETRAG_UMRECHNEN USING
  B01_LOCAM B01_LOCCU B01_FORCU B01_FORAM.
  CALL FUNCTION 'CONVERT_TO_FOREIGN_CURRENCY'
    EXPORTING DATE             = SY-DATLO
              LOCAL_AMOUNT     = B01_LOCAM
              LOCAL_CURRENCY   = B01_LOCCU
              FOREIGN_CURRENCY = B01_FORCU
    IMPORTING FOREIGN_AMOUNT   = B01_FORAM
              EXCHANGE_RATE    = RATE
    EXCEPTIONS
              OTHERS = 1.
  IF sy-subrc NE 0.                                "n1980185
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE sy-msgty.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE BILDSPEZIFISCHE_VORBEREITUNG                       *
*---------------------------------------------------------------------*
*       Dynprospezifische Vorbereitungen:                             *
*---------------------------------------------------------------------*
*  ->   B01_DYNNR: Dynpronummer                                       *
*---------------------------------------------------------------------*
FORM BILDSPEZIFISCHE_VORBEREITUNG USING
            B01_DYNNR    TYPE C.
*ORM BILDSPEZIFISCHE_VORBEREITUNG USING B01_DYNNR.
  CASE B01_DYNNR.
    WHEN '0105'.
      PERFORM VORBEREITUNG_UEBERSICHT.
    WHEN '0220'.
      PERFORM ZAHLUNGSVERHALTEN_ERMITTELN.
      LNFIR = 1.
      DESCRIBE TABLE KKNB4 LINES LNMAX.
  ENDCASE.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM BLAETTERN                                                *
*---------------------------------------------------------------------*
*       Blättern in einer internen Tabelle.                           *
*---------------------------------------------------------------------*
*  -->  B01_LNFIR Index des ersten Eintrags                           *
*  -->  B01_LNMAX Gesamtzahl aller Einträge                           *
*  -->  B01_LNCNT Anzahl der Loopzeilen                               *
*---------------------------------------------------------------------*
FORM BLAETTERN USING
            B02_LNFIR    LIKE SYST-TABIX
            B02_LNMAX    LIKE SYST-TABIX
            B02_LNCNT    LIKE SYST-LOOPC.
*ORM BLAETTERN USING B02_LNFIR B02_LNMAX B02_LNCNT.
DATA: LOOPI(1) TYPE C.                 " Loop-Input?

* ------ Dynpro mit Loop-Input? ----------------------------------------
  CLEAR: LOOPI.

* ------ Blättern ------------------------------------------------------
  CALL FUNCTION 'FI_CUST_SCROLL'
     EXPORTING  I_INPUT = LOOPI
                I_OKCOD = OK-CODE
                I_LNFIR = B02_LNFIR
                I_LNMAX = B02_LNMAX
                I_LOOPC = B02_LNCNT
     IMPORTING  E_LNFIR = B02_LNFIR.
  CLEAR: OK-CODE.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE BLAETTERN_ZURUECK                                  *
*---------------------------------------------------------------------*
*       Zum vorigen Bild springen.                                    *
*---------------------------------------------------------------------*
FORM BLAETTERN_ZURUECK.
  CLEAR: OK-CODE.
  READ TABLE DYNTAB WITH KEY DYNTAB-DYNNR.
  IF SY-SUBRC NE 0.
    MESSAGE A308 WITH 'ZURUECK_BLAETTERN'.
  ENDIF.

  INDEX     = SY-TABIX - 1.
  COUNT     = INDEX.
  OLD-DYNNR = DYNTAB-DYNNR.

  DO COUNT TIMES.
    READ TABLE DYNTAB INDEX INDEX.
    IF DYNTAB-XMARK = 'X'.
      PERFORM BILDSPEZIFISCHE_VORBEREITUNG USING DYNTAB-DYNNR.
      SET SCREEN DYNTAB-DYNNR.
      LEAVE SCREEN.
    ELSE.
      INDEX = INDEX - 1.
    ENDIF.
  ENDDO.

* ------ Erstes Bild erreicht? -----------------------------------------
  MESSAGE S757.
  READ TABLE DYNTAB WITH KEY OLD-DYNNR.
  PERFORM STEHENBLEIBEN.
ENDFORM.
