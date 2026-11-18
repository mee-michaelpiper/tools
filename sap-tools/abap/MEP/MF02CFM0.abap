***INCLUDE MF02CFM0 .

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE MAHNDATEN_ERMITTELN                               *
*---------------------------------------------------------------------*
*        Lesen von KNB5 in allen beteiligten Buchungskreisen.         *
*---------------------------------------------------------------------*
FORM MAHNDATEN_ERMITTELN.
  REFRESH: KNB5TAB.

* ------ Mahndaten aller Mahnbereiche aller Buchungskreise lesen -------
  CLEAR: REFE1.
  LOOP AT BUKTAB.
    SELECT * FROM  KNB5
             WHERE KUNNR = KNA1-KUNNR
             AND   BUKRS = BUKTAB-BUKRS.
      IF NOT KNB5-GMVDT IS INITIAL.
        REFE1 = REFE1 + 1.
      ENDIF.
      MOVE-CORRESPONDING KNB5 TO KNB5TAB.
      APPEND KNB5TAB.
    ENDSELECT.
  ENDLOOP.

* ------ Mahndaten aller Mahnbereiche aller Buchungskreise lesen -------
  SORT KNB5TAB BY GMVDT DESCENDING MADAT DESCENDING MAHNS DESCENDING.
  READ TABLE KNB5TAB INDEX 1.
  IF SY-SUBRC = 0.
    MOVE-CORRESPONDING KNB5TAB TO KNB5.
    IF REFE1 > 1.
      MESSAGE S777 WITH KNA1-KUNNR REFE1.
    ENDIF.
  ELSE.
    CLEAR: KNB5.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM MELDUNG_ZUM_ZAHLVERHALTEN                                *
*---------------------------------------------------------------------*
*       Soll das Zahlverhalten in manchen Buchungskreisen             *
*       gar nicht aufgezeichnet werden?                               *
*       Ist bisher überhaupt irgendein Zahlverhalten aufgezeichnet    *
*       worden?                                                       *
*---------------------------------------------------------------------*
FORM MELDUNG_ZUM_ZAHLVERHALTEN.
  DESCRIBE TABLE KKNB4 LINES SY-TFILL.

* ------ Kein Zahlungsverhalten aufgezeichnet? -------------------------
  IF SY-TFILL = 0.
    MESSAGE S009.
  ELSE.

* ------ REFE1 = Anzahl KNB1, REFE2 = KNB1 mit XZVER = 'X' -------------
    CLEAR: REFE1, REFE2.
    LOOP AT BUKTAB.
      IF BUKTAB-XZVER NE SPACE.
        REFE2 = REFE2 + 1.
      ENDIF.
    ENDLOOP.

* ------ Zahlungsverhalten nicht in jedem BUKRS aufzuzeichnen? ---------
    DESCRIBE TABLE BUKTAB LINES SY-TFILL.
    IF SY-TFILL > REFE2.
      MESSAGE S767 WITH REFE2 SY-TFILL.
    ENDIF.

* ------ Debitor in keinem BUKRS angelegt? -----------------------------
    IF SY-TFILL = 0.
      MESSAGE S768 WITH KNA1-KUNNR.
    ENDIF.
  ENDIF.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       FORM  MODIFY_SCREEN                                           *
*---------------------------------------------------------------------*
*       Die Felder der SCREEN-GROUP M01-GROUP mit Wert M01-VALUE      *
*       werden gemäß M01-MODIF modifiziert.                           *
*---------------------------------------------------------------------*
*  -->  M01_GROUP SCREEN-GROUP                                        *
*  -->  M01_VALUE Wert in SCREEN-GROUP.                               *
*  -->  M01_MODIF Modifikation.                                       *
*---------------------------------------------------------------------*
FORM MODIFY_SCREEN USING
            M01_GROUP    TYPE C
            M01_VALUE    TYPE C
            M01_MODIF    TYPE C.
*ORM MODIFY_SCREEN USING M01_GROUP M01_VALUE M01_MODIF.
  CASE M01_GROUP.
    WHEN '1'. ASSIGN SCREEN-GROUP1 TO <F2>.
    WHEN '2'. ASSIGN SCREEN-GROUP2 TO <F2>.
    WHEN '3'. ASSIGN SCREEN-GROUP3 TO <F2>.
    WHEN '4'. ASSIGN SCREEN-GROUP4 TO <F2>.
  ENDCASE.
  LOOP AT SCREEN.
    CHECK <F2> = M01_VALUE.
    CASE M01_MODIF.
      WHEN 'INPUTOFF'.
        SCREEN-INPUT = 0.
      WHEN 'INTENSIFIED'.
        SCREEN-INTENSIFIED = 1.
      WHEN 'INVISIBLE'.
        SCREEN-OUTPUT      = 0.
        SCREEN-INPUT       = 0.
        SCREEN-INVISIBLE   = 1.
      WHEN 'VISIBLE'.
        SCREEN-ACTIVE      = 1.
        SCREEN-OUTPUT      = 1.
        SCREEN-INTENSIFIED = 1.
        SCREEN-INVISIBLE   = 0.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*       SUBROUTINE MODIFY_SCREEN_INPUT_OFF                            *
*---------------------------------------------------------------------*
*       Die Eingabebereitschaft für alle INPUT-Felder wird            *
*       zurückgenommen.                                               *
*---------------------------------------------------------------------*
FORM MODIFY_SCREEN_INPUT_OFF.
  LOOP AT SCREEN.
    CHECK SCREEN-INPUT = 1.
    CHECK SCREEN-NAME(4)  NE 'PUSH'.
    CHECK SCREEN-NAME(11) NE 'RF02L-HORDA'.
    SCREEN-INPUT = 0.
    MODIFY SCREEN.
  ENDLOOP.
ENDFORM.
