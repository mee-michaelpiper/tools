***INCLUDE MF02CFZ0 .

*eject
*---------------------------------------------------------------------*
*       FORM ZAHLUNGSVERHALTEN_ERMITTELN                              *
*---------------------------------------------------------------------*
*       Die Daten zum Zahlungsverhalten in den zum Kontrollbereich    *
*       gehörenden Buchungskreisen werden gelesen und kumuliert.      *
*---------------------------------------------------------------------*
FORM ZAHLUNGSVERHALTEN_ERMITTELN.
  IF KLIM-XZAVE = 'X'.
    PERFORM MELDUNG_ZUM_ZAHLVERHALTEN.
  ENDIF.

*------- Kennzeichen: Ist Zahlungsverhalten noch nicht ermittelt? ------
  CHECK KLIM-XZAVE = SPACE.
  CALL FUNCTION 'CUSTOMER_PAYMENT_HISTORY'
     EXPORTING  I_KKBER  = RF02L-KKBER
                I_KUNNR  = KNA1-KUNNR
     TABLES     T_KNB4   = KKNB4
     EXCEPTIONS NO_BUKRS = 1.

*------- Kennzeichen setzen: Zahlungsverhalten ist ermittelt -----------
  KLIM-XZAVE = 'X'.

*------- Begleitende Meldung -------------------------------------------
  PERFORM MELDUNG_ZUM_ZAHLVERHALTEN.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM ZAHLUNGSVERHALTEN_KUMULIEREN                             *
*---------------------------------------------------------------------*
*       Die aktuellsten 3 Perioden des aufgezeichneten                *
*       Zahlungsverhaltens im Kontrollbereich werden für die          *
*       Übersicht noch einmal kumuliert.                              *
*---------------------------------------------------------------------*
FORM ZAHLUNGSVERHALTEN_KUMULIEREN.
  CLEAR: AKNB4.
  ZVPER = '  /  -  /  '.

* ------ Zahlverhalten kumulieren --------------------------------------
  LOOP AT KKNB4.
    IF SY-TABIX = 1.
      ZVPER+6(2) = KKNB4-MONXX.
      ZVPER+9(2) = KKNB4-JAHXX+2.
    ENDIF.
    IF SY-TABIX > 3.
      EXIT.
    ENDIF.
    ZVPER(2)   = KKNB4-MONXX.
    ZVPER+3(2) = KKNB4-JAHXX+2.

*------- ... Verzugstage Skonto ----------------------------------------
    REFE1 = KKNB4-AGSXX + AKNB4-AGSXX.
    IF  KKNB4-AGSXX NE 0
    AND REFE1       NE 0.
      AKNB4-VZSXX =
      ( KKNB4-AGSXX * KKNB4-VZSXX + AKNB4-AGSXX * AKNB4-VZSXX ) /
          ( KKNB4-AGSXX + AKNB4-AGSXX ).
    ENDIF.
    AKNB4-AGSXX = KKNB4-AGSXX + AKNB4-AGSXX.

*------- ... Verzugstage Netto -----------------------------------------
    REFE1 = KKNB4-AGNXX + AKNB4-AGNXX.
    IF  KKNB4-AGNXX NE 0
    AND REFE1       NE 0.
      AKNB4-VZNXX =
      ( KKNB4-AGNXX * KKNB4-VZNXX + AKNB4-AGNXX * AKNB4-VZNXX ) /
        ( KKNB4-AGNXX + AKNB4-AGNXX ).
    ENDIF.
    AKNB4-AGNXX = KKNB4-AGNXX + AKNB4-AGNXX.

*------- ... Feldüberlauf verhindern -----------------------------------
    IF AKNB4-VZSXX > 999.
      AKNB4-VZSXX = 999.
    ENDIF.
    IF AKNB4-VZSXX < -999.
      AKNB4-VZSXX = -999.
    ENDIF.
    IF AKNB4-VZNXX > 999.
      AKNB4-VZNXX = 999.
    ENDIF.
    IF AKNB4-VZNXX < -999.
      AKNB4-VZNXX = -999.
    ENDIF.
  ENDLOOP.

* ------ Kein Zahlungsverhalten aufgezeichnet? -------------------------
  IF ZVPER CO ' -/'.
    CLEAR: ZVPER.
  ENDIF.

* ------ Daten in RF42B-Anzeigefelder stellen --------------------------
  RF42B-VZNXX = AKNB4-VZNXX.
  RF42B-VZSXX = AKNB4-VZSXX.
  RF42B-AGNXX = AKNB4-AGNXX.
  RF42B-AGSXX = AKNB4-AGSXX.

* ------ Daten in KUMUL stellen ----------------------------------------
  KUMUL-VZNXX = RF42B-VZNXX.
  KUMUL-VZSXX = RF42B-VZSXX.
  KUMUL-AGNXX = RF42B-AGNXX.
  KUMUL-AGSXX = RF42B-AGSXX.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE ZURUECK_ZUM_RUFER                                  *
*---------------------------------------------------------------------*
*       Rückkehr zum Aufrufprogramm                                   *
*---------------------------------------------------------------------*
FORM ZURUECK_ZUM_RUFER.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDFORM.
