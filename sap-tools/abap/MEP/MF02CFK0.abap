***INCLUDE MF02CFK0 .

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE KLIMG_KLIME_AKTUALISIEREN                          *
*---------------------------------------------------------------------*
*       Neuberechnen von                                              *
*                                                                     *
*          RF02L-KLIMG : Aktuell vergebenes Gesamtlimit               *
*          RF02L-KLIME : Aktuell vergebenes maximales Einzellimit     *
*          KLIM-KKBER  : KKBER mit aktuell vergebenem max. Einzellimit*
*---------------------------------------------------------------------*
FORM KLIMG_KLIME_AKTUALISIEREN.
  CLEAR: RF02L-KLIMG, RF02L-KLIME, KLIM-KKBER.

* ------ Berechnung nur, wenn KNKA-WAERS gefüllt -----------------------
  IF KNKA-WAERS NE SPACE.
    LOOP AT VKLTAB.

* ------ Gesamtlimit kumulieren, höchstes Einzellimit merken -----------
      RF02L-KLIMG = RF02L-KLIMG + VKLTAB-KLIMA.
      IF VKLTAB-KLIMA > RF02L-KLIME.
        RF02L-KLIME = VKLTAB-KLIMA.
        KLIM-KKBER = VKLTAB-KKBER.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                    "KLIMG_KLIME_AKTUALISIEREN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE KNA1_LESEN                                        *
*---------------------------------------------------------------------*
*        Einlesen der Debitorendaten aus Tabelle KNA1.                *
*        Bei Änderungstransaktion: Merken des alten Standes in YKNA1. *
*---------------------------------------------------------------------*
FORM KNA1_LESEN.

* ------ KNA1 lesen ----------------------------------------------------
  SELECT SINGLE * FROM KNA1 WHERE KUNNR = KNA1-KUNNR.
  IF SY-SUBRC NE 0.
    MESSAGE E443 WITH KNA1-KUNNR.
  ELSE.
    CHECK KNA1-LOEVM = 'X'.
    MESSAGE W131(F2) WITH KNA1-KUNNR.
  ENDIF.
ENDFORM.                                                    "KNA1_LESEN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE *KNA1_LESEN                                       *
*---------------------------------------------------------------------*
*        Einlesen der Debitorendaten in Tabelle *KNA1:                *
*---------------------------------------------------------------------*
FORM *KNA1_LESEN.
  SELECT SINGLE * INTO  *KNA1
                  FROM  KNA1
                  WHERE KUNNR = *KNA1-KUNNR.
ENDFORM.                    "SELECT

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE KNB1_LESEN                                        *
*---------------------------------------------------------------------*
*        Einlesen von KNB1 (Zahldaten, Mahndaten).                    *
*---------------------------------------------------------------------*
FORM KNB1_LESEN.
  CHECK KNB1-BUKRS NE KLIM-BUKRS
    AND KLIM-BUKRS NE SPACE.

* ------ KNB1 lesen ----------------------------------------------------
  SELECT SINGLE * FROM KNB1 WHERE KUNNR = KNA1-KUNNR
                            AND   BUKRS = KLIM-BUKRS.
  IF SY-SUBRC NE 0.
    CLEAR: KNB1.
    MESSAGE S444 WITH KNA1-KUNNR KLIM-BUKRS.
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDFORM.                                                    "KNB1_LESEN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE KNB5_LESEN                                        *
*---------------------------------------------------------------------*
*        Einlesen von KNB5 (Mahndaten im Default-Mahnbereich SPACE).  *
*---------------------------------------------------------------------*
FORM KNB5_LESEN.
  CHECK KNB5-BUKRS NE KLIM-BUKRS
    AND KLIM-BUKRS NE SPACE.

* ------ KNB5 lesen ----------------------------------------------------
  SELECT SINGLE * FROM KNB5 WHERE KUNNR = KNA1-KUNNR
                            AND   BUKRS = KLIM-BUKRS
                            AND   MABER = SPACE.
  IF SY-SUBRC NE 0.
    CLEAR: KNB5.
    MESSAGE S761 WITH SPACE.                     " nicht möglich
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDFORM.                                                    "KNB5_LESEN

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE KNC1_LESEN                                         *
*---------------------------------------------------------------------*
*       Lesen von KNC1.                                               *
*---------------------------------------------------------------------*
* ->    K01_BUKRS: Buchungskreis.                                     *
* ->    K01_GJAHR: Geschäftsjahr.                                     *
*---------------------------------------------------------------------*
FORM KNC1_LESEN USING
            K01_BUKRS    LIKE BUKTAB-BUKRS
            K01_GJAHR    LIKE KNC1-GJAHR.
*ORM KNC1_LESEN USING K01_BUKRS K01_GJAHR.
  SELECT SINGLE * FROM  KNC1
                  WHERE KUNNR = KNA1-KUNNR
                  AND   BUKRS = K01_BUKRS
                  AND   GJAHR = K01_GJAHR.
ENDFORM.                                                    "KNC1_LESEN

*eject
*---------------------------------------------------------------------*
*        FORM KNKA_LESEN                                              *
*---------------------------------------------------------------------*
*        Einlesen der kontrollbereichsübergreifenden Daten aus        *
*        Tabelle KNKA.                                                *
*---------------------------------------------------------------------*
FORM KNKA_LESEN.

* ------ KNKA lesen ----------------------------------------------------
  SELECT SINGLE * FROM KNKA WHERE KUNNR = KNA1-KUNNR.
  IF SY-SUBRC = 0.
    KLIM-XEXKA = 'X'.
  ELSE.
    KLIM-XEXKA = 'F'.
    CLEAR: KNKA, YKNKA.
    KNKA-KUNNR  = KNA1-KUNNR.
    YKNKA-KUNNR = KNA1-KUNNR.
  ENDIF.

* ------ Alten Stand in YKNKA merken -----------------------------------
  IF  T020-AKTYP = 'V'
  AND KLIM-XEXKA = 'X'.
    YKNKA = KNKA.
  ENDIF.
ENDFORM.                    "KNKA_LESEN

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE KNKK_LESEN                                        *
*---------------------------------------------------------------------*
*        Einlesen der Kontrollbereichsdaten aus Tabelle KNKK          *
*---------------------------------------------------------------------*
FORM KNKK_LESEN USING P_CHAR.
  DATA: LD_CASHD LIKE KNKK-CASHD,
        LD_CASHA LIKE KNKK-CASHA,
        LD_CASHC LIKE KNKK-CASHC.
  DATA: LD_KLIMK LIKE KNKK-KLIMK,
        LD_SKFOR LIKE KNKK-SKFOR,
        LD_SSOBL LIKE KNKK-SSOBL.

  DATA: LD_SUBRC LIKE SY-SUBRC.
  DATA: LS_KNKKF1 LIKE KNKKF1.

  IF P_CHAR = SPACE.
  KNKK-KUNNR = KNA1-KUNNR.
  SELECT SINGLE * FROM KNKK  WHERE KUNNR = KNKK-KUNNR
                             AND   KKBER = KNKK-KKBER.

  IF SY-SUBRC = 0.
    KLIM-XEXKK = 'X'.
    IF IDBXKZ = 'X' AND XDBAKT = 'X'.
      IF KLIM-XEXKA = 'X'.
        MOVE-CORRESPONDING KNKA TO KNKK.
      ENDIF.
    ENDIF.
      PERFORM READ_KNKKF1 USING KNKK LS_KNKKF1 LD_SUBRC.
      IF LD_SUBRC = 0.
* ------- SD prüft gegen Daten aus Kreditvektor; Limit sollte eigentlich
* ------- im FI und SD gleich sein; SKFOR und SSOBL sollten eigentlich
* ------- im dezentralen SD-System immer 0 sein, weil bei Überleitung
* ------- ins FI die Belege im Sendesystem (SD) direkt ausgeglichen
* ------- werden und dann per ALE ins FI geschickt werden
        GD_CV_TO_KNKK = 'X'.
        KNKK-KLIMK    = LS_KNKKF1-KLIMK.
        KNKK-SKFOR    = LS_KNKKF1-SKFOR.
        KNKK-SSOBL    = LS_KNKKF1-SSOBL.
        WRITE LS_KNKKF1-TMSTMP(8) TO GD_CVDATUM DD/MM/YYYY.
        IF RF02L-D0105 = 'X' OR RF02L-D0210 = 'X' OR RF02L-D0120 = 'X'.
* ------- Info, falls Status, Übersicht oder Zentraldaten markiert
          MESSAGE I713 WITH KNKK-KUNNR KNKK-KKBER GD_CVDATUM.
      ENDIF.
    ENDIF.

* ------- SD-Werte / Ausschöpfungsgrad ---------------------------------
    IF KNKK-KNKLI = KNA1-KUNNR.
      PERFORM ERMITTELN_SAUFT USING KNKK-KNKLI RF02L-SAUFT RF02L-HORDA.
      RF02L-OBLIG = KNKK-SKFOR + KNKK-SSOBL + RF02L-SAUFT.
      PERFORM AUSSCHOEPFUNGSGRAD_BERECHNEN
        USING KNKK-KLIMK RF02L-OBLIG RF02L-KLPRZ.
    ENDIF.

* ------- KNKK-KNKLI muß gepflegt sein ---------------------------------
    IF KNKK-KNKLI IS INITIAL.
      MESSAGE A308 WITH 'KNKK_LESEN' KNKK-KUNNR KNKK-KKBER.
    ENDIF.
  ELSE.
    KLIM-XEXKK = 'F'.
*begin of insertion note 1935185
    IF T020-AKTYP NE 'A'.
      PERFORM BUKTAB_FUELLEN.
      DESCRIBE TABLE BUKTAB LINES SY-TFILL.
      IF SY-TFILL = 0.
        CALL FUNCTION 'CUSTOMIZED_MESSAGE'
          EXPORTING
            I_ARBGB = 'F4'
            I_DTYPE = '-'
            I_MSGNR = '768'
            I_VAR01 = KNA1-KUNNR.
      ENDIF.
      IF 1 = 2.
        MESSAGE S768 WITH KNA1-KUNNR.
      ENDIF.
    ENDIF.
*end of insertion note 1935185
    CLEAR: KNKK, YKNKK.
    KNKK-KUNNR  = KNA1-KUNNR.
    KNKK-KKBER  = RF02L-KKBER.
    YKNKK-KUNNR = KNKK-KUNNR.
    YKNKK-KKBER = KNKK-KKBER.
* auch für Neukunden können schon Auftragswerte da sein!
    PERFORM ERMITTELN_SAUFT USING KNA1-KUNNR RF02L-SAUFT RF02L-HORDA.
    RF02L-OBLIG = KNKK-SKFOR + KNKK-SSOBL + RF02L-SAUFT.
    PERFORM AUSSCHOEPFUNGSGRAD_BERECHNEN
      USING KNKK-KLIMK RF02L-OBLIG RF02L-KLPRZ.
  ENDIF.

* ------ Alten Stand in YKNKK merken -----------------------------------
  IF  T020-AKTYP = 'V'
  AND KLIM-XEXKK = 'X'.
    YKNKK = KNKK.
  ENDIF.
  ELSEIF P_CHAR = 'CASH'.
    SELECT SINGLE CASHD CASHA CASHC  FROM KNKK INTO
        (LD_CASHD, LD_CASHA, LD_CASHC)
                               WHERE KUNNR = KNKK-KUNNR
                               AND   KKBER = KNKK-KKBER.

    CHECK SY-SUBRC = 0.
    IF KNKK-CASHD NE LD_CASHD
    OR KNKK-CASHA NE LD_CASHA
    OR KNKK-CASHC NE LD_CASHC.
      KNKK-CASHD = LD_CASHD.
      KNKK-CASHA = LD_CASHA.
      KNKK-CASHC = LD_CASHC.
    ENDIF.
  ELSEIF P_CHAR = 'KLIM'.
    SELECT SINGLE KLIMK SKFOR SSOBL FROM KNKK INTO
        (LD_KLIMK, LD_SKFOR, LD_SSOBL)
                               WHERE KUNNR = KNKK-KUNNR
                               AND   KKBER = KNKK-KKBER.

    CHECK SY-SUBRC = 0.
    KNKK-KLIMK = LD_KLIMK.
    KNKK-SKFOR = LD_SKFOR.
    KNKK-SSOBL = LD_SSOBL.
  ENDIF.
ENDFORM.
*eject
*---------------------------------------------------------------------*
*        SUBROUTINE *KNKK_LESEN                                       *
*---------------------------------------------------------------------*
*        Nachlesen eines KNKK-Satzes in die Workarea *KNKK.           *
*---------------------------------------------------------------------*
*  -->   K01_KONTO: Kontonummer des Kunden                            *
*---------------------------------------------------------------------*
FORM *KNKK_LESEN USING
            K01_KONTO    LIKE KNKK-KNKLI.
*ORM *KNKK_LESEN USING K01_KONTO.
  SELECT SINGLE * FROM  KNKK
                  INTO *KNKK
                  WHERE KUNNR = K01_KONTO
                  AND   KKBER = RF02L-KKBER.
ENDFORM.                                                    "K01_KONTO

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE KONTODATEN_ZURUECKSETZEN                          *
*---------------------------------------------------------------------*
FORM KONTODATEN_ZURUECKSETZEN.

*------- Allgemeine Daten ---------------------------------------------
  CLEAR:   KNA1,
           KNKA, YKNKA,
*------- KKBER-abhängige Daten -----------------------------------------
           KNKK, YKNKK.
ENDFORM.                    "KONTODATEN_ZURUECKSETZEN

*eject
*---------------------------------------------------------------------*
*       FORM  KONTONUMMER_PRUEFEN                                     *
*---------------------------------------------------------------------*
*       Prüfung, ob die Kontonummer maximal 10stellig eingegeben      *
*       wurde.                                                        *
*---------------------------------------------------------------------*
*ORM KONTONUMMER_PRUEFEN.
* IF  RF02L-KUNNR CN ' 1234567890'.
*   IF RF02L-KUNNR+10(6) NE SPACE.
*     MESSAGE E708.
*   ENDIF.
* ELSE.
*   IF RF02L-KUNNR(6) CN '0'.
*     MESSAGE E708.
*   ENDIF.
* ENDIF.
*NDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE KNKK_KONSISTENZCHECK                              *
*---------------------------------------------------------------------*
*        Die Kreditlimit-Daten (KUNDE und BETRAG) werden              *
*        auf Vollständigkeit und Konsistenz geprüft.                  *
*---------------------------------------------------------------------*
FORM KNKK_KONSISTENZCHECK.
  CHECK T020-AKTYP NE 'A'.

*------- KUNDE fehlt -> Daten ergänzen ---------------------------------
  IF KNKK-KNKLI = SPACE.
    KNKK-KNKLI = KNA1-KUNNR.
  ENDIF.

*------- Hinweis, falls Kreditlimit 0 ----------------------------------
  IF KNKK-KNKLI = KNA1-KUNNR.
    IF KNKK-KLIMK = 0.
      IF  KLIM-XM762      EQ SPACE
      AND IMPPAR-OKCOD(3) NE 'TXT'.
        KLIM-XM762 = 'X'.
        MESSAGE W762 WITH RF02L-WAERB.
      ENDIF.
    ENDIF.
  ENDIF.

*------- Kreditlimit überschritten? ------------------------------------
  IF KNKK-KNKLI = KNA1-KUNNR.
    IF RF02L-OBLIG > KNKK-KLIMK.
      IF KLIM-XM774A = SPACE.
        KLIM-XM774A = 'X'.
        MESSAGE W774 WITH KNA1-KUNNR RF02L-KKBER.
      ENDIF.
    ENDIF.
    PERFORM AUSSCHOEPFUNGSGRAD_BERECHNEN
      USING KNKK-KLIMK RF02L-OBLIG RF02L-KLPRZ.
  ENDIF.

*------- ACHTUNG: Folgende Prüfungen nur bei REFERENZ ------------------
  CHECK KNKK-KNKLI NE KNA1-KUNNR.

*------- Bei Referenz: Konto muss vorhanden sein -----------------------
  PERFORM KNKK_REFERENZCHECK.

* ------ Bei Referenz: Betrag auf 0 setzen -----------------------------
  IF KNKK-KLIMK NE 0.
    KNKK-KLIMK = 0.
    IF SY-BINPT = SPACE.
      MESSAGE S717 WITH KNKK-KNKLI.
    ELSE.
      MESSAGE E717 WITH KNKK-KNKLI.
    ENDIF.
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDFORM.                    "KNKK_KONSISTENZCHECK

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE KNKK_REFERENZCHECK                                *
*---------------------------------------------------------------------*
*        Die KNKLI-Angabe wird auf Korrektheit geprüft.               *
*---------------------------------------------------------------------*
FORM KNKK_REFERENZCHECK.
  CHECK T020-AKTYP NE 'A'.

*------- Prüfungen nur bei echter Referenz -----------------------------
  CHECK KNKK-KNKLI NE KNA1-KUNNR.

*------- Referiertes Konto muss vorhanden sein -------------------------
   *KNA1-KUNNR = KNKK-KNKLI.
  PERFORM *KNA1_LESEN.
  IF SY-SUBRC NE 0.
    MESSAGE E707 WITH KNKK-KNKLI.
  ENDIF.

*------- Referenzdaten gepflegt? ---------------------------------------
  PERFORM *KNKK_LESEN USING KNKK-KNKLI.
  IF SY-SUBRC = 0.

*------- Doppelte Referenz? --------------------------------------------
    IF *KNKK-KNKLI NE *KNKK-KUNNR.
      MESSAGE E712 WITH *KNKK-KUNNR *KNKK-KNKLI.
    ENDIF.

*------- Kreditlimit des Referenzdebitoren überschritten? --------------
    PERFORM ERMITTELN_SAUFT USING *KNKK-KUNNR SAUFT RF02L-HORDA.
    CLEAR: S066, S067.   "n1718046
    OBLIG = *KNKK-SKFOR + *KNKK-SSOBL + SAUFT.
    IF OBLIG > *KNKK-KLIMK.
      IF KLIM-XM774R = SPACE.
        KLIM-XM774R = 'X'.
        MESSAGE W774 WITH *KNKK-KUNNR *KNKK-KKBER.
      ENDIF.
    ENDIF.
  ELSE.
    MESSAGE E711 WITH KNKK-KNKLI RF02L-KKBER.
  ENDIF.
ENDFORM.                    "KNKK_REFERENZCHECK
*&---------------------------------------------------------------------*
*&      Form  READ_KNKKF1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM READ_KNKKF1 USING P_KNKK LIKE KNKK
                       ES_KNKKF1 LIKE KNKKF1
                       EP_SUBRC  LIKE SY-SUBRC.

  EP_SUBRC = 4.
  CLEAR: ES_KNKKF1.

* ------- Kreditvektor im dezentralen SD-System lesen ------------------
  IF  T000CM-XCVRD NE SPACE            "Kreditvektor wird genutzt
  AND T000CM-XCVCR EQ SPACE            "aber nicht erstellt
  AND SY-BINPT = SPACE.
    CALL FUNCTION 'CREDITCONTROL_READ_KNKKF1'
         EXPORTING
              I_KUNNR            = P_KNKK-KUNNR
              I_KKBER            = P_KNKK-KKBER
         IMPORTING
              E_KNKKF1           = ES_KNKKF1
         EXCEPTIONS
              DATA_NOT_AVAILABLE = 1
              OTHERS             = 2.

    EP_SUBRC = SY-SUBRC.

    IF EP_SUBRC = 1
    AND P_KNKK-KUNNR = P_KNKK-KNKLI.
*----- knkkf1/Knkkf2 entries with regul = ' ' are not created for childs
      CALL FUNCTION 'CREDITCONTROL_READ_KNKKF1'
           EXPORTING
                I_KUNNR            = P_KNKK-KUNNR
                I_KKBER            = P_KNKK-KKBER
                I_REGUL            = ' '
           IMPORTING
                E_KNKKF1           = ES_KNKKF1
           EXCEPTIONS
                DATA_NOT_AVAILABLE = 1
                OTHERS             = 2.

      EP_SUBRC = SY-SUBRC.
    ENDIF.
  ENDIF.
ENDFORM.                               " READ_KNKKF1
