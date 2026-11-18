***INCLUDE MF02CFV0 .

*eject
*---------------------------------------------------------------------*
*       FORM VKLTAB_APPEND                                            *
*---------------------------------------------------------------------*
*       Ein KNKK-Satz wird in die VKLTAB aufgenommen.                 *
*---------------------------------------------------------------------*
FORM VKLTAB_APPEND.
  CLEAR: VKLTAB.

* ------ Berechtigungsprüfung für Kontrollbereich ----------------------
  PERFORM BERECHTIGUNG_PRUEFEN_KNKK USING *KNKK-KKBER 'SKIP' ACTVT.
  VKLTAB-XAUTH = XAUTH.

* ------ Kontrollbereich mit Bezeichnung -------------------------------
  VKLTAB-KKBER = *KNKK-KKBER.
  PERFORM T014_LESEN  USING *KNKK-KKBER.
  PERFORM T014T_LESEN USING *KNKK-KKBER.
  IF SY-SUBRC = 0.
    VKLTAB-KKBTX = T014T-KKBTX.
  ENDIF.

* ------ Keine Berechtigung? -------------------------------------------
  IF VKLTAB-XAUTH = SPACE.
    VKLTAB-KKBTX = TEXT-006.
  ENDIF.

* ------ Kreditlimit in A- und B-Segment-Währung -----------------------
  VKLTAB-KNKLI = *KNKK-KNKLI.
  VKLTAB-KLIMK = *KNKK-KLIMK.
  VKLTAB-WAERB = T014-WAERS.

* ------ KLIMK in KNKA-WAERS umrechnen, wenn KNKA existiert ------------
  IF KLIM-XEXKA = 'X'
  AND KNKA-WAERS NE SPACE.
    IF KNKA-WAERS = T014-WAERS.
      VKLTAB-WAERA = KNKA-WAERS.
      VKLTAB-KLIMA = VKLTAB-KLIMK.
    ELSE.
      VKLTAB-WAERA = KNKA-WAERS.
      PERFORM BETRAG_UMRECHNEN
        USING VKLTAB-KLIMK T014-WAERS KNKA-WAERS VKLTAB-KLIMA.
    ENDIF.
  ELSE.
    CLEAR: VKLTAB-WAERA, VKLTAB-KLIMA.
  ENDIF.

* ------ Eintrag in VKLTAB ---------------------------------------------
  APPEND VKLTAB.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM VKLTAB_FUELLEN                                           *
*---------------------------------------------------------------------*
*       Die vergebenen Kreditlimits werden in die Tabelle VKLTAB      *
*       eingestellt.                                                  *
*---------------------------------------------------------------------*
FORM VKLTAB_FUELLEN.
DATA: LS_KNKKF1 LIKE KNKKF1.
DATA: LD_SUBRC LIKE SY-SUBRC.

* ------ Nur füllen, falls noch leer -----------------------------------
  DESCRIBE TABLE VKLTAB LINES SY-TFILL.
  CHECK SY-TFILL = 0.

* ------ Initialisierung -----------------------------------------------
  CLEAR: RF02L-KLIMG, RF02L-KLIME, XAUTF.

* ------ KNKK lesen und in VKLTAB stellen ------------------------------
  SELECT * INTO  *KNKK
           FROM  KNKK
           WHERE KUNNR = KNA1-KUNNR.
    PERFORM READ_KNKKF1 USING *KNKK LS_KNKKF1 LD_SUBRC.
    IF LD_SUBRC = 0.
      *KNKK-KLIMK = LS_KNKKF1-KLIMK.
    ENDIF.
    PERFORM VKLTAB_APPEND.
  ENDSELECT.

* ------ KLIM-WAERA setzen ---------------------------------------------
  CLEAR: KLIM-WAERA.
  IF KLIM-XEXKA = 'X'.
    KLIM-WAERA = KNKA-WAERS.
  ENDIF.

* ------ RF02L-KLIMG_KLIME erstmalig errechnen -------------------------
  PERFORM KLIMG_KLIME_AKTUALISIEREN.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM VORBEREITUNG_UEBERSICHT                                  *
*---------------------------------------------------------------------*
*       Vorbereitungen für die Übersicht                              *
*---------------------------------------------------------------------*
FORM VORBEREITUNG_UEBERSICHT.

*------- Bei bereits vorbereiteter Übersicht kumulierte Daten setzen ---
  IF KLIM-XUEBE = 'X'.
    RF42B-VZNXX = KUMUL-VZNXX.
    RF42B-VZSXX = KUMUL-VZSXX.
    RF42B-AGNXX = KUMUL-AGNXX.
    RF42B-AGSXX = KUMUL-AGSXX.
  ENDIF.

*------- Kennzeichen: Ist Übersicht noch nicht vorbereitet? ------------
  CHECK KLIM-XUEBE = SPACE.

* ------ Zum Kontrollbereich gehörende Buchungskreise in BUKTAB sammeln
  PERFORM BUKTAB_FUELLEN.

* ------ Zahlungsverhalten ermitteln -----------------------------------
  PERFORM ZAHLUNGSVERHALTEN_ERMITTELN.
  PERFORM ZAHLUNGSVERHALTEN_KUMULIEREN.

* ------ Abzüge / Ausgleichsbetrag aus KNC1-Daten ermitteln ------------
  PERFORM ABZUEGE_ERMITTELN.
* PERFORM ABZUEGE_KUMULIEREN.

* ------ Mahndaten lesen -----------------------------------------------
  PERFORM MAHNDATEN_ERMITTELN.

* ------ DSO ermitteln -------------------------------------------------
  PERFORM DSO_ERMITTELN.
  PERFORM ABZUEGE_KUMULIEREN.

*------- Kennzeichen setzen: Übersicht ist vorbereitet -----------------
  KLIM-XUEBE = 'X'.
ENDFORM.
