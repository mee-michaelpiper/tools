***INCLUDE MF02CFS0 .

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE SCHLUSS_BEARBEITUNG                               *
*---------------------------------------------------------------------*
*        Ermitteln ob sich in den einzelnen Tabellen                  *
*        Daten geaendert haben. Durch Vergleich die geaenderten       *
*        Felder finden.                                               *
*        Verbuchungsaufruf abschicken.                                *
*        Bearbeitungsmeldung.                                         *
*---------------------------------------------------------------------*
FORM SCHLUSS_BEARBEITUNG.

*------- UPD_FLAGs für Änderungsbeleg ----------------------------------
  IF KLIM-XDELA = 'X'.
    UPD_KNKA = 'D'.
  ENDIF.
  IF KLIM-XDELK = 'X'.
    UPD_KNKK = 'D'.
  ENDIF.

*------- Schlüsselfelder setzen ----------------------------------------
  IF UPD_KNKA = 'I'.
    KNKA-KUNNR = KNA1-KUNNR.
  ENDIF.
  IF UPD_KNKK = 'I'.
    KNKK-KUNNR = KNA1-KUNNR.
    KNKK-KKBER = RF02L-KKBER.
  ENDIF.

*------- Bei Neuaufbau: Prüfen, ob Referenzliste vorliegt? -------------
  IF KNKK-KNKLI NE YKNKK-KNKLI.                  " Differenzen
    KLIM-XNEUA = 'X'.                            " Differenzen
    CLEAR: KLIM-XREFL.                           " Differenzen
  ENDIF.                                         " Differenzen
  IF KLIM-XNEUA = 'X'.
    PERFORM AUFBAUEN_REFTAB.
    TRANSLATE KLIM-XREFL USING 'N '.
  ENDIF.

*------- ERNAM/ERDAT setzen --------------------------------------------
  IF UPD_KNKK = 'I'.
    KNKK-ERNAM = SY-UNAME.
    KNKK-ERDAT = SY-DATUM.
  ENDIF.

*------- Sicherheitshalber KNKLI überprüfen und notfalls setzen --------
  IF UPD_KNKK CO 'IU'.
    IF KNKK-KNKLI IS INITIAL.
      KNKK-KNKLI = KNKK-KUNNR.
    ENDIF.
  ENDIF.

*------- AEDAT/AETXT setzen (nicht bei DVS-Änderungen) -----------------
  OLD-UPDKK = UPD_KNKK.                " UPD_KNKK für VB merken
  IF TEXT_XUPD = SPACE.
    IF UPD_KNKK = 'U'.
      KNKK-AEDAT = SY-DATUM.
      KNKK-AENAM = SY-UNAME.
    ENDIF.
  ELSE.
    KNKK-AETXT = SY-DATUM.             " Datum letzte Textänderung
    IF UPD_KNKK = 'U'.
      KNKK-AEDAT = SY-DATUM.           " Datum letzte KNKK-Änderung
      KNKK-AENAM = SY-UNAME.
    ENDIF.
    IF UPD_KNKK = SPACE.
      UPD_KNKK = 'U'.                  " für Änd.Beleg KNKK-AETXT
    ENDIF.
  ENDIF.

*------- Änderungsbeleg erstellen --------------------------------------
  IF UPD_KNKA   NE SPACE
  OR UPD_KNKK   NE SPACE
  OR KLIM-XNEUA NE SPACE
  OR TEXT_XUPD  NE SPACE.
    OBJECTID        = KNA1-KUNNR.
    TCODE           = SY-TCODE.
    UTIME           = SY-UZEIT.
    UDATE           = SY-DATUM.
    USERNAME        = SY-UNAME.
    XF02C-T014WAERS = RF02L-WAERB.
     *XF02C-T014WAERS = RF02L-WAERB.
    PERFORM CD_CALL_KLIM.
  ENDIF.
* UPD_KNKK = OLD-UPDKK.           " UPD_KNKK restaurieren

  IF UPD_KNKK NE SPACE AND XDBAKT = 'X'.
    IF UPD_KNKK CO 'UI'.
      CASE KLIM-XEXKA.
        WHEN 'X'.
          UPD_KNKA = 'U'.
        WHEN 'F'.
          UPD_KNKA = 'I'.
      ENDCASE.
    ENDIF.
    MOVE-CORRESPONDING KNKK TO KNKA.
  ENDIF.
*------- Änderungen durchführen ----------------------------------------
  IF UPD_KNKA   NE SPACE
  OR UPD_KNKK   NE SPACE
  OR KLIM-XNEUA NE SPACE
  OR TEXT_XUPD  NE SPACE.
    IF  T000CM-XCVRD NE SPACE
    AND T000CM-XCVCR EQ SPACE
    AND SY-BINPT = SPACE
    AND GD_CV_TO_KNKK = 'X'.
*------- Kreditvektor wird genutzt, aber nicht erstellt
      PERFORM KNKK_LESEN USING 'KLIM'.
    ENDIF.
    IF  UPD_KNKK NE SPACE
    AND UPD_KNKK NE 'I'.
      PERFORM KNKK_LESEN USING 'CASH'.
    ENDIF.
    CALL FUNCTION 'CREDITLIMIT_CHANGE' IN UPDATE TASK
      EXPORTING
        I_KNKA   = KNKA
        I_KNKK   = KNKK
        UPD_KNKA = UPD_KNKA
        UPD_KNKK = UPD_KNKK
        YKNKA    = YKNKA
        YKNKK    = YKNKK
        XNEUA    = KLIM-XNEUA
        XREFL    = KLIM-XREFL.
    IF KLIM-XNEUA NE SPACE.                                 "K11K100791
* Bei Auftreten des Laufzeitfehlers 'TIME_OUT' sind die ausgesternten
* Zeilen zu aktivieren (vgl. Hinweis 99937)
*   CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE'
*        EXPORTING
*             DEFAULTOPTION  = 'Y'
*             DIAGNOSETEXT1  = TEXT-101
*             DIAGNOSETEXT2  = TEXT-102
*             DIAGNOSETEXT3  = ' '
*             TEXTLINE1      = TEXT-100
*             TITEL          = ' '
*             CANCEL_DISPLAY = ' '
*       IMPORTING
*            ANSWER         = ANSWER.
*   IF ANSWER = 'J'.
      IF SY-BINPT = 'X'.           "n1293818
*       SD_CREDIT_RECREATE cannot be started in batch input
*       RFDKLI20 should be called instead
*        IF T014N-KKBER IS INITIAL.   "n1895198
*          T014N-KKBER = KNKK-KKBER.
*          INSERT INTO T014N VALUES T014N.
*        ENDIF.
*        MESSAGE S778 WITH KNKK-KKBER.
        MESSAGE I792.
      ELSE.
        IF UPD_KNKK = 'I' OR UPD_KNKK = 'U'.
*----- Inform SD_CREDIT_RECREATE that a INSERT OCCURS --------
        EXPORT UPD_KNKK TO MEMORY ID '&FD32%'.
      ENDIF.
      CALL FUNCTION 'SD_CREDIT_RECREATE'                    "K11K100791
           EXPORTING                                        "K11K100791
               AFTER_CHANGE_KNKLI        = 'X'              "K11K100791
               AFTER_CHANGE_TVAP_TVLP    = 'X'              "K11K100791
               KKBER                     = KNKK-KKBER       "K11K100791
               KUNNR                     = KNKK-KUNNR       "K11K100791
               PROTOCOL                  = ' '              "K11K100791
               RECHECK_DOCUMENTS         = 'X'              "K11K100791
               SET_COMMIT                = 'X'              "K11K100791
               TKNKK                     = KNKK.            "K11K100791
      ENDIF.
    ELSEIF KNKK-KNKLI NE YKNKK-KNKLI                        "K11K100791
    AND UPD_KNKK  NE 'I'.                                   "K11K100791
*   CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE'
*       EXPORTING
*             DEFAULTOPTION  = 'Y'
*             DIAGNOSETEXT1  = TEXT-101
*             DIAGNOSETEXT2  = TEXT-102
*             DIAGNOSETEXT3  = ' '
*             TEXTLINE1      = TEXT-100
*             TITEL          = ' '
*             CANCEL_DISPLAY = ' '
*      IMPORTING
*            ANSWER         = ANSWER.
*    IF ANSWER = 'J'.
      CALL FUNCTION 'SD_CREDIT_RECREATE'                    "K11K100791
           EXPORTING                                        "K11K100791
                AFTER_CHANGE_KNKLI        = 'X'             "K11K100791
                AFTER_CHANGE_TVAP_TVLP    = ' '             "K11K100791
                KKBER                     = KNKK-KKBER      "K11K100791
                KUNNR                     = KNKK-KUNNR      "K11K100791
                PROTOCOL                  = ' '             "K11K100791
                RECHECK_DOCUMENTS         = 'X'             "K11K100791
                SET_COMMIT                = 'X'             "K11K100791
                TKNKK                     = KNKK.           "K11K100791
*   ENDIF.
    ENDIF.                                                  "K11K100791
  ENDIF.

  IF  KLIM-XNEUA EQ SPACE
  AND KLIM-XNEUR NE SPACE.
    IF 1 = 2.
      MESSAGE I796.
    ENDIF.
    CALL FUNCTION 'CUSTOMIZED_MESSAGE'
    EXPORTING
          I_ARBGB = 'F4'
          I_DTYPE = 'I'
          I_MSGNR = '796'
          I_VAR01 = space
          I_VAR02 = space
          I_VAR03 = space
          I_VAR04 = space.
  ENDIF.

  IF  KLIM-XNEUA EQ SPACE
  AND KLIM-XNEUB NE SPACE.
    IF 1 = 2.
      MESSAGE I721.
    ENDIF.
    CALL FUNCTION 'CUSTOMIZED_MESSAGE'
    EXPORTING
          I_ARBGB = 'F4'
          I_DTYPE = 'I'
          I_MSGNR = '721'
          I_VAR01 = space
          I_VAR02 = space
          I_VAR03 = space
          I_VAR04 = space.
   ENDIF.

* -------Open FI -------------------------------------------------------
  IF OFIWA-XCHNG NE SPACE.
    CALL FUNCTION 'OPEN_FI_PERFORM_00001520_E'
      EXPORTING
        I_KUNNR = KNKK-KUNNR
        I_KKBER = KNKK-KKBER.
  ENDIF.
  UPD_KNKK = OLD-UPDKK.           " UPD_KNKK restaurieren für Message

*------- Aufruf der Textverbuchung, falls Textverarbeitung erfolgt -----
  IF ( T020-AKTYP NE 'A' AND TEXT_XUPD  EQ 'X' )
  OR ( T020-AKTYP NE 'A' AND TEXTZ_XUPD  EQ 'X' ).

    CALL FUNCTION 'FI_TEXTS_CREDM_UPDATE'
      EXPORTING
        I_KUNNR = KNA1-KUNNR
        I_KKBER = RF02L-KKBER.
    CALL FUNCTION 'FI_TEXTS_CREDZ_UPDATE'
      EXPORTING
        I_KUNNR = KNA1-KUNNR.

    CALL FUNCTION 'FI_TEXTS_CRED_CHANGEPOINTER'.

  ENDIF.

*------- Bearbeitungsmeldung ('Gelöscht/Geändert/Angelegt') ------------
  CASE UPD_KNKA.
    WHEN SPACE.
      CASE UPD_KNKK.
        WHEN 'D'.
          MESSAGE S765 WITH KNKK-KKBER TEXT-007.
        WHEN 'I'.
          MESSAGE S765 WITH KNKK-KKBER TEXT-009.
        WHEN 'U'.
          MESSAGE S765 WITH KNKK-KKBER TEXT-008.
      ENDCASE.
    WHEN 'D'.
      CASE UPD_KNKK.
        WHEN SPACE.
          MESSAGE S766 WITH TEXT-007.
        WHEN 'D'.
          MESSAGE S764 WITH TEXT-007 KNKK-KKBER TEXT-007.
        WHEN 'I'.
          MESSAGE S764 WITH TEXT-007 KNKK-KKBER TEXT-009.
        WHEN 'U'.
          MESSAGE S764 WITH TEXT-007 KNKK-KKBER TEXT-008.
      ENDCASE.
    WHEN 'I'.
      CASE UPD_KNKK.
        WHEN SPACE.
          MESSAGE S766 WITH TEXT-009.
        WHEN 'D'.
          MESSAGE S764 WITH TEXT-009 KNKK-KKBER TEXT-007.
        WHEN 'I'.
          MESSAGE S764 WITH TEXT-009 KNKK-KKBER TEXT-009.
        WHEN 'U'.
          MESSAGE S764 WITH TEXT-009 KNKK-KKBER TEXT-008.
      ENDCASE.
    WHEN 'U'.
      CASE UPD_KNKK.
        WHEN SPACE.
          MESSAGE S766 WITH TEXT-008.
        WHEN 'D'.
          MESSAGE S764 WITH TEXT-008 KNKK-KKBER TEXT-007.
        WHEN 'I'.
          MESSAGE S764 WITH TEXT-008 KNKK-KKBER TEXT-009.
        WHEN 'U'.
          MESSAGE S764 WITH TEXT-008 KNKK-KKBER TEXT-008.
      ENDCASE.
  ENDCASE.

*------- Bearbeitungsmeldung: Neuaufbau / Texte / DVS (Sondermeldungen)-
  IF  UPD_KNKA = SPACE
  AND UPD_KNKK = SPACE.
    IF TEXT_XUPD = 'X'
    OR TEXTZ_XUPD = 'X'.
      MESSAGE S780.
    ELSE.
      IF DRAD_VB = 'X'.
        MESSAGE S725.
      ELSE.
        MESSAGE S732.
      ENDIF.
    ENDIF.
  ENDIF.
  IF OFIWA-XCHNG NE SPACE.
    MESSAGE S312.
  ENDIF.

*------- COMMIT WORK ---------------------------------------------------
  IF T020-FUNCL = 'M'.
    MASS-AKTUELL = MASS-AKTUELL + 1.
    IF MASS-AKTUELL > MASS-GRENZE.
      COMMIT WORK.
      CLEAR: MASS-AKTUELL.
    ENDIF.
*   CALL FUNCTION 'DEQUEUE_ALL'.  " unnötig wegen ENQ (siehe SPERREN)?
  ELSE.
    COMMIT WORK.
  ENDIF.

*------- Verlassen der Transaktion bei Batch-Input ---------------------
  IF SY-BINPT = 'X'.
    SET SCREEN 0.
    LEAVE SCREEN.
  ENDIF.

*------- Zurück zum Rufer? / Im Normalfall: Transaktion neu aufrufen ---
  IF SY-CALLD = 'X'.
    IF T020-FUNCL = SPACE.
      LEAVE.
    ELSE.
*     nichts: in TRANSAKTIONS_INIT bleiben
    ENDIF.
  ELSE.
    IF EX-CODE = 'F15'.
      SET SCREEN 0.
      LEAVE SCREEN.
    ELSE.
      LEAVE TO CURRENT TRANSACTION.           "946620
    ENDIF.
  ENDIF.
ENDFORM.                    "SCHLUSS_BEARBEITUNG

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE sichern_ja_nein                                   *
*---------------------------------------------------------------------*
*        Transaktionsende erreicht: Sichern ja / Nein ?               *
*---------------------------------------------------------------------*
FORM SICHERN_JA_NEIN.
  CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE'
    EXPORTING
      TITEL         = TEXT-P07
      DIAGNOSETEXT1 = TEXT-P05
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
ENDFORM.                    "SICHERN_JA_NEIN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE SPERREN                                           *
*---------------------------------------------------------------------*
*        Sperren des Kreditlimitstammsatzes (auf KNKA-Ebene).         *
*---------------------------------------------------------------------*
FORM SPERREN.
  CHECK T020-AKTYP NE 'A'.
  RC = 0.

*------- Evtl. Sperre für 'altes' Konto zurücknehmen -------------------
  IF  ENQ_KEY NE SPACE
  AND ENQ_KEY NE KNA1-KUNNR.
    CALL FUNCTION 'DEQUEUE_EXKNKA'
      EXPORTING
        KUNNR          = ENQ_KEY
      EXCEPTIONS
        SYSTEM_FAILURE = 1.
    ENQ_KEY = SPACE.
  ENDIF.

*------- aktuelles Konto sperren ---------------------------------------
  CHECK KNA1-KUNNR NE SPACE.
  IF ENQ_KEY EQ SPACE.
    CALL FUNCTION 'ENQUEUE_EXKNKA'
      EXPORTING
        KUNNR          = KNA1-KUNNR
      EXCEPTIONS
        FOREIGN_LOCK   = 1
        SYSTEM_FAILURE = 2.
    CASE SY-SUBRC.

*------- Konto von anderem Benutzer gesperrt ---------------------------
      WHEN 1.
        RC = 4.
        IF T020-FUNCL = SPACE.
          MESSAGE E309 WITH KNA1-KUNNR.
        ELSE.
          MESSAGE S309 WITH KNA1-KUNNR.
        ENDIF.

*------- Systemfehler --------------------------------------------------
      WHEN 2.
        RC = 4.
        IF T020-FUNCL = SPACE.
          MESSAGE E302.
        ELSE.
          MESSAGE S302.
        ENDIF.
    ENDCASE.
    IF RC = 0.
      ENQ_KEY = KNA1-KUNNR.
    ENDIF.
  ENDIF.
ENDFORM.                    "SPERREN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE SPERREN_KNKLI                                     *
*---------------------------------------------------------------------*
*        Sperren des Kreditlimitstammsatzes des Referenzdebitoren     *
*        (auf KNKA-Ebene).                                            *
*---------------------------------------------------------------------*
*  ->    S01_KNKLI: Referenzdebitor                                   *
*---------------------------------------------------------------------*
FORM SPERREN_KNKLI USING
            S01_KNKLI    LIKE KNKK-KNKLI.
*ORM SPERREN_KNKLI USING S01_KNKLI.
  CHECK T020-AKTYP NE 'A'.

*------- Evtl. Sperre für 'altes' Konto zurücknehmen -------------------
  IF  ENQ_KEY_KNKLI NE SPACE
  AND ENQ_KEY_KNKLI NE S01_KNKLI.
    CALL FUNCTION 'DEQUEUE_EXKNKA'
      EXPORTING
        KUNNR          = ENQ_KEY_KNKLI
      EXCEPTIONS
        SYSTEM_FAILURE = 1.
    ENQ_KEY = SPACE.
  ENDIF.

*------- Referenzdebitor sperren ---------------------------------------
  CHECK S01_KNKLI NE SPACE.
  IF ENQ_KEY_KNKLI EQ SPACE.
    CALL FUNCTION 'ENQUEUE_EXKNKA'
      EXPORTING
        KUNNR          = S01_KNKLI
      EXCEPTIONS
        FOREIGN_LOCK   = 1
        SYSTEM_FAILURE = 2.
    CASE SY-SUBRC.

*------- Konto von anderem Benutzer gesperrt ---------------------------
      WHEN 1.
        MESSAGE E328 WITH S01_KNKLI.

*------- Systemfehler --------------------------------------------------
      WHEN 2.
        MESSAGE E302.
    ENDCASE.
    ENQ_KEY_KNKLI = S01_KNKLI.
  ENDIF.
ENDFORM.                    "SPERREN_KNKLI

*eject
*---------------------------------------------------------------------*
*       FORM  STEHENBLEIBEN                                           *
*---------------------------------------------------------------------*
*       Das aktuelle Dynpro erneut prozessieren                       *
*---------------------------------------------------------------------*
FORM STEHENBLEIBEN.
  SET SCREEN SY-DYNNR.
  LEAVE SCREEN.
ENDFORM.                    "STEHENBLEIBEN
