***INCLUDE MF02CFA0 .

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE ABZUEGE_ERMITTELN                                  *
*---------------------------------------------------------------------*
*       KNC1 für alle zum Kontrollbereich gehörenden BUKRS lesen.     *
*---------------------------------------------------------------------*
FORM ABZUEGE_ERMITTELN.
  CLEAR: T001.

* ------ Aktuelles Geschäftsjahr eintragen -----------------------------
  LOOP AT BUKTAB.
    IF BUKTAB-PERIV = T001-PERIV.
      BUKTAB-GJAHR = GJAHR.
      MODIFY BUKTAB.
    ELSE.

* ------ Periode ermitteln ---------------------------------------------
      CLEAR: MONAT.
      CALL FUNCTION 'FI_PERIOD_DETERMINE'
           EXPORTING
               I_BUDAT = SY-DATLO
               I_MONAT = MONAT
               I_BUKRS = BUKTAB-BUKRS
           IMPORTING
               E_GJAHR = GJAHR
               E_MONAT = MONAT
           EXCEPTIONS
               ERROR_MESSAGE = 8
               OTHERS        = 4.

* ------ GJVariante ungültig? ------------------------------------------
      IF SY-SUBRC     NE 0
      OR BUKTAB-PERIV EQ SPACE.
        CLEAR: BUKTAB-GJAHR.
        MODIFY BUKTAB.
        T001-PERIV = BUKTAB-PERIV.
        CHECK 1 = 2.
      ELSE.
        T001-PERIV = BUKTAB-PERIV.
        BUKTAB-GJAHR = GJAHR.
        MODIFY BUKTAB.
      ENDIF.
    ENDIF.
  ENDLOOP.

* ------ KNC1 lesen und in KNC1TAB merken ------------------------------
  LOOP AT BUKTAB.
    CHECK NOT BUKTAB-GJAHR IS INITIAL.
    PERFORM KNC1_LESEN USING BUKTAB-BUKRS BUKTAB-GJAHR.
    CHECK SY-SUBRC = 0.
    CLEAR: KNC1TAB.
    MOVE-CORRESPONDING KNC1 TO KNC1TAB.
    APPEND KNC1TAB.
  ENDLOOP.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE ABZUEGE_KUMULIEREN                                 *
*---------------------------------------------------------------------*
*       KNC1-Daten aus KNC1TAB kumulieren.                            *
*---------------------------------------------------------------------*
FORM ABZUEGE_KUMULIEREN.
  CLEAR: KNC1.
  LOOP AT KNC1TAB.
    READ TABLE BUKTAB WITH KEY KNC1TAB-BUKRS.
    IF BUKTAB-WAERS NE RF02L-WAERB.
      PERFORM BETRAG_UMRECHNEN USING
        KNC1TAB-BABZG BUKTAB-WAERS RF02L-WAERB KNC1TAB-BABZG.
      PERFORM BETRAG_UMRECHNEN USING
        KNC1TAB-UABZG BUKTAB-WAERS RF02L-WAERB KNC1TAB-UABZG.
      PERFORM BETRAG_UMRECHNEN USING
        KNC1TAB-KUMAG BUKTAB-WAERS RF02L-WAERB KNC1TAB-KUMAG.
    ENDIF.
    KNC1-BABZG = KNC1-BABZG + KNC1TAB-BABZG.
    KNC1-UABZG = KNC1-UABZG + KNC1TAB-UABZG.
    KNC1-KUMAG = KNC1-KUMAG + KNC1TAB-KUMAG.
  ENDLOOP.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE AENDERUNGSBELEGE_ANZEIGEN                          *
*---------------------------------------------------------------------*
*       Die Änderungsbelege zu Konto/Kontrollbereich werden           *
*       angezeigt.                                                    *
*---------------------------------------------------------------------*
FORM AENDERUNGSBELEGE_ANZEIGEN.
  CASE OK-CODE.

*------- Änderungsbelege Feld (durch CURSOR Feld ausgewählt) -----------
    WHEN 'AEFD'.
      GET CURSOR FIELD CRS_FIELD.

* ------ Cursor positioniert? -------------------------------------
      IF  CRS_FIELD(4) NE 'KNKA'
      AND CRS_FIELD(4) NE 'KNKK'
      AND CRS_FIELD    NS '-'.
        CLEAR OK-CODE.
        MESSAGE E315.
      ENDIF.

* ------ Änderungsbelege zum Feld anzeigbar? ----------------------
      IF  CRS_FIELD(4) NE 'KNKA'
      AND CRS_FIELD(4) NE 'KNKK'
      AND CRS_FIELD(4) NE 'KNA1'.
        CLEAR OK-CODE.
        MESSAGE E779.
      ENDIF.

* ------ Änderungsbelege anzeigen ---------------------------------
      IF CRS_FIELD CS 'KNA1'.
        CALL DIALOG 'AENDERUNGSBELEGE_DEBITOR'
          EXPORTING RF01A-KUNNR FROM KNA1-KUNNR
                    DYNCL       FROM 'F'
                    FNAME       FROM CRS_FIELD.
      ELSE.
        IF KLIM-XBEKK = SPACE.
          CALL DIALOG 'AENDERUNGSBELEGE_KREDITLIMIT'
            EXPORTING RF01A-KUNNR FROM KNA1-KUNNR
                      FNAME       FROM CRS_FIELD.
        ELSE.
          CALL DIALOG 'AENDERUNGSBELEGE_KREDITLIMIT'
            EXPORTING RF01A-KUNNR FROM KNA1-KUNNR
                      RF01A-KKBER FROM RF02L-KKBER
                      FNAME       FROM CRS_FIELD.
        ENDIF.
      ENDIF.

*------- Änderungsbelege Konto -----------------------------------------
    WHEN 'AEKT'.
      IF KLIM-XBEKK = SPACE.
        CALL DIALOG 'AENDERUNGSBELEGE_KREDITLIMIT'
          EXPORTING RF01A-KUNNR FROM KNA1-KUNNR.
      ELSE.
        CALL DIALOG 'AENDERUNGSBELEGE_KREDITLIMIT'
          EXPORTING RF01A-KUNNR FROM KNA1-KUNNR
                    RF01A-KKBER FROM RF02L-KKBER.
      ENDIF.
  ENDCASE.
  CLEAR OK-CODE.
  PERFORM STEHENBLEIBEN.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE ALLES_INITIALISIEREN                               *
*---------------------------------------------------------------------*
*       Zurücksetzen aller Felder/Strukturen, bevor man auf das       *
*       Einstiegsbild kommt (weil nicht immer LEAVE TO TRANSACTION    *
*       gemacht wird).                                                *
*---------------------------------------------------------------------*
FORM ALLES_INITIALISIEREN.
  CLEAR:   KLIM, OLD.
  CLEAR:   KNKK, YKNKK, KNKA.
  CLEAR:   VKLTAB.
  REFRESH: VKLTAB, BUKTAB.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE AUFBAUEN_REFTAB                                    *
*---------------------------------------------------------------------*
*       Referenzierende Debitoren in REFTAB merken.                   *
*---------------------------------------------------------------------*
FORM AUFBAUEN_REFTAB.
  CHECK KLIM-XREFL = SPACE.
  SELECT * FROM  KNKK
           INTO *KNKK
           WHERE KNKLI = KNKK-KUNNR
           AND   KKBER = RF02L-KKBER.
    CHECK *KNKK-KUNNR NE KNA1-KUNNR.
    MOVE-CORRESPONDING *KNKK TO REFTAB.
*   PERFORM ERMITTELN_SAUFT USING KNKK-KUNNR SAUFT.
*   REFTAB-OBLIG = *KNKK-SKFOR + *KNKK-SSOBL + SAUFT.
    REFTAB-OBLIG = *KNKK-SKFOR + *KNKK-SSOBL.
    REFTAB-WAERS = T014-WAERS.
    APPEND REFTAB.
  ENDSELECT.

* ------ Ergebnis in KLIM-XREFL merken ---------------------------------
  DESCRIBE TABLE REFTAB LINES SY-TFILL.
  IF SY-TFILL = 0.
    KLIM-XREFL = 'N'.
  ELSE.
    KLIM-XREFL = 'X'.
  ENDIF.

* ------ Für Neuaufbau: Geschwister zu berücksichtigen in LCRDMF00!-----
  IF KNKK-KUNNR NE KNKK-KNKLI.
    KLIM-XREFL = 'X'.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE AUSSCHOEPFUNGSGRAD_BERECHNEN                       *
*---------------------------------------------------------------------*
*       Ausschöpfungsgrad ( Obligo in % des Kreditlimits)             *
*       berechnen.                                                    *
*---------------------------------------------------------------------*
*  ->   A01_KLIMK: Kreditlimit                                        *
*  ->   A01_OBLIG: Gesamtobligo                                       *
* <->   A01_KLPRZ: Ausschöpfungsgrad in %                             *
*---------------------------------------------------------------------*
FORM AUSSCHOEPFUNGSGRAD_BERECHNEN USING
            A01_KLIMK    LIKE KNKK-KLIMK
            A01_OBLIG    LIKE RF02L-OBLIG
            A01_KLPRZ    LIKE RF02L-KLPRZ.
*ORM AUSSCHOEPFUNGSGRAD_BERECHNEN
*   USING A01_KLIMK A01_OBLIG A01_KLPRZ.
DATA: LD_REFE1(16) TYPE P.
  CLEAR: LD_REFE1.
  IF A01_KLIMK  = 0
  OR A01_OBLIG < 0.
    CLEAR: A01_KLPRZ.
  ELSE.
    LD_REFE1 = ( A01_OBLIG * 10000 ) / A01_KLIMK.
  ENDIF.
  IF  A01_KLIMK = 0
  AND A01_OBLIG > 0.
    LD_REFE1 = 99999.
  ENDIF.
  IF LD_REFE1 > 99999.
    A01_KLPRZ = 99999.
  ELSE.
    A01_KLPRZ = LD_REFE1.
  ENDIF.
ENDFORM.
