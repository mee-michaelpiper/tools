FUNCTION CREDITLIMIT_CHANGE.
*"----------------------------------------------------------------------
*"Verbuchungsfunktionsbaustein:
*"
*"Globale Schnittstelle:
*"       IMPORTING
*"             I_KNKA LIKE KNKA STRUCTURE KNKA
*"             I_KNKK LIKE KNKK STRUCTURE KNKK
*"             UPD_KNKA LIKE CDPOS-CHNGIND
*"             UPD_KNKK LIKE CDPOS-CHNGIND
*"             XNEUA LIKE RF02L-XNEUA DEFAULT SPACE
*"             XREFL LIKE RF02L-XNEUA DEFAULT SPACE
*"             YKNKA LIKE KNKA STRUCTURE KNKA
*"             YKNKK LIKE KNKK STRUCTURE KNKK
*"----------------------------------------------------------------------

*------- Daten aus Schnittstelle in Workareas stellen ------------------
  KNKA = I_KNKA.
  KNKK = I_KNKK.

*------- KNKA (Übergreifende Daten) aktualisieren ----------------------
  CASE UPD_KNKA.
    WHEN 'I'.
      PERFORM KNKA_INSERT.
    WHEN 'U'.
      PERFORM KNKA_UPDATE.
    WHEN 'D'.
      PERFORM KNKA_DELETE.
  ENDCASE.

*------- KNKK (Kreditlimit) aktualisieren ------------------------------
  CASE UPD_KNKK.
    WHEN 'D'.
      PERFORM KNKK_DELETE.
    WHEN 'I'.
      PERFORM KNKK_INSERT.
    WHEN 'U'.
      PERFORM KNKK_BEARBEITEN.
  ENDCASE.

*------- Kreditlimit neuaufbauen ---------------------------------------
  IF XNEUA NE SPACE.
    CHECK UPD_KNKK NE 'I'.
    KNKK = I_KNKK.
    CALL FUNCTION 'CREDITCONTROL_REBUILD'
        EXPORTING KUNNR = KNKK-KUNNR
                  KKBER = KNKK-KKBER
                  XREFL = XREFL.
  ENDIF.
ENDFUNCTION.
