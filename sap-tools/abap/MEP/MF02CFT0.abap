***INCLUDE MF02CFT0 .

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE T014_LESEN                                        *
*---------------------------------------------------------------------*
*        Die Tabelle T014 wird gelesen.                               *
*---------------------------------------------------------------------*
FORM T014_LESEN USING
            T02_KKBER    LIKE KNKK-KKBER.
*ORM T014_LESEN USING T02_KKBER.
  SELECT SINGLE * FROM  T014
                  WHERE KKBER = T02_KKBER.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE T014N_LESEN                                       *
*---------------------------------------------------------------------*
*        Die Tabelle T014N wird gelesen.                              *
*---------------------------------------------------------------------*
FORM T014N_LESEN.
  SELECT SINGLE * FROM  T014N
                  WHERE KKBER = RF02L-KKBER.
  IF SY-SUBRC NE 0.
    CLEAR: T014N.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE T014T_LESEN                                       *
*---------------------------------------------------------------------*
*        Die Tabelle T014T wird gelesen.                              *
*---------------------------------------------------------------------*
FORM T014T_LESEN USING
            L02_KKBER    LIKE RF02L-KKBER.
*ORM T014T_LESEN USING L02_KKBER.
  SELECT SINGLE * FROM  T014T
                  WHERE SPRAS = SY-LANGU
                    AND KKBER = L02_KKBER.
  IF SY-SUBRC NE 0.
    T014T-KKBTX = TEXT-004.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM TITEL_SETZEN_AKTIVITAET                                  *
*---------------------------------------------------------------------*
*       Titel1 : Ändern / Anzeigen                                    *
*---------------------------------------------------------------------*
FORM TITEL_SETZEN_AKTIVITAET.
  CASE T020-AKTYP.
    WHEN 'V'.
      TITEL1 = TEXT-T01.
    WHEN 'A'.
      TITEL1 = TEXT-T02.
  ENDCASE.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM TRANSAKTION_VERLASSEN                                    *
*---------------------------------------------------------------------*
*       Transaktion neu anwählen bzw. zum Aufrufer zurück             *
*---------------------------------------------------------------------*
FORM TRANSAKTION_VERLASSEN.
  IF SY-CALLD = SPACE.
    LEAVE TO CURRENT TRANSACTION.           "946620
  ELSE.
    PERFORM ZURUECK_ZUM_RUFER.
  ENDIF.
ENDFORM.
