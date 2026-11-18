***INCLUDE MF02CFN0 .

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE NAECHSTER_KONTROLLBEREICH                         *
*---------------------------------------------------------------------*
*        Nächster Kontrollbereich.                                    *
*---------------------------------------------------------------------*
FORM NAECHSTER_KONTROLLBEREICH.
  OLD-LNFIR = LNFIR.
  OLD-LNMAX = LNMAX.
  CLEAR: KLIM-NKKBE.
  LNFIR = 1.
  DESCRIBE TABLE VKLTAB LINES LNMAX.
  IF SY-TFILL = 0.
    MESSAGE S715.
    LNFIR = OLD-LNFIR.
    LNMAX = OLD-LNMAX.
    PERFORM STEHENBLEIBEN.
  ELSE.

* ------ Fehlende Daten wegen mangelnder Berechtigung? -----------------
    IF XAUTF NE SPACE.
      MESSAGE S314.
    ENDIF.
    PERFORM CALL_SCREEN USING 'NXT'.
    IF KLIM-NKKBE = SPACE.
      LNFIR = OLD-LNFIR.
      LNMAX = OLD-LNMAX.
      PERFORM STEHENBLEIBEN.
    ELSE.

* ------ SUPRRESS DIALOG versuchen -------------------------------------
      SHIFT KLIM-AUSWL RIGHT.
      KLIM-AUSWL(1) = 'S'.

* ------ Allgemeine Dynpros rausnehmen ---------------------------------
      REPLACE '110' WITH '   ' INTO KLIM-AUSWL.
      REPLACE '111' WITH '   ' INTO KLIM-AUSWL.  "mi/4.5B
      REPLACE '120' WITH '   ' INTO KLIM-AUSWL.
      CONDENSE KLIM-AUSWL NO-GAPS.

* ------ Transaktion neu aufrufen --------------------------------------
      SET PARAMETER ID 'CDY' FIELD KLIM-AUSWL.
      SET PARAMETER ID 'KKB' FIELD KLIM-NKKBE.
      LEAVE TO CURRENT TRANSACTION.           "946620
    ENDIF.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM   NAECHSTES_DYNPRO                                       *
*---------------------------------------------------------------------*
*       Falls das letzte Dynpro schon bearbeitet wurde,               *
*       aber die Funktion 'Sichern' nicht gewählt wurde,              *
*       wird ein Sicherheits-Dialogfenster gesendet.                  *
*                                                                     *
*       Ermitteln des Folgedynpros aus Tabelle DYNTAB.                *
*---------------------------------------------------------------------*
FORM NAECHSTES_DYNPRO.
  UNPACK SY-DYNNR TO DYNTAB-DYNNR.
  READ TABLE DYNTAB WITH KEY DYNTAB-DYNNR.
  IF SY-SUBRC NE 0.
    MESSAGE A308 WITH 'NAECHSTES_DYNPRO' DYNTAB-DYNNR.
  ENDIF.

* ------ Bei Änderung des Horizont stehenbleiben -----------------------
  IF XHORDA = SPACE.
*------- Letztes Bild erreicht? ----------------------------------------
    IF DYNTAB-XLAST EQ 'X'.
      CASE T020-AKTYP.
        WHEN 'A'.
          PERFORM BEENDEN_JA_NEIN.
        WHEN 'V'.
          PERFORM CHECK_AENDERUNGEN.
          IF KLIM-XCHNG = 'X'.
            PERFORM SICHERN_JA_NEIN.
          ELSE.
            PERFORM BEENDEN_JA_NEIN.
          ENDIF.
      ENDCASE.

*------- nächste Dynpronummer ermitteln und setzen ---------------------
    ELSE.
      LOOP AT DYNTAB WHERE DYNNR GT DYNTAB-DYNNR
                     AND   XMARK NE SPACE.          "#EC PORTABLE
        EXIT.
      ENDLOOP.
      IF SY-SUBRC NE 0.
        MESSAGE A308 WITH 'NAECHSTES_DYNPRO' DYNTAB-DYNNR.
      ENDIF.

* ------ Bildspezifische Vorbereitung nötig? ---------------------------
      PERFORM BILDSPEZIFISCHE_VORBEREITUNG USING DYNTAB-DYNNR.

* ------ Zum nächsten Dynpro gehen -------------------------------------
      SET SCREEN DYNTAB-DYNNR.
      LEAVE SCREEN.
    ENDIF.
  ELSE.
    CLEAR XHORDA.
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDFORM.
