***INCLUDE MF02CFX0 .

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE X055_AUFBAUEN                                     *
*---------------------------------------------------------------------*
*        Aktivität: Ändern                                            *
*        Die interne Tabelle X055 wird aus den Tabellen T055G und     *
*        T055 aufgebaut. Dabei werden nur diese Felder in die X055    *
*        aufgenommen, die zu Gruppen gehören, für welche der          *
*        Anwender keine Berechtigung hat.                             *
*---------------------------------------------------------------------*
FORM X055_AUFBAUEN.
  CHECK T020-AKTYP EQ 'V'.
  CHECK X055_CHECK NE 'X'.

  SELECT * FROM T055G WHERE KOART = 'C'
                        AND XNOBE = SPACE.
    AUTHORITY-CHECK OBJECT 'F_KNKA_AEN'
      ID 'VGRUP' FIELD T055G-GRUPP.
    IF SY-SUBRC NE 0.
      SELECT * FROM T055 WHERE KOART = T055G-KOART
                         AND   GRUPP = T055G-GRUPP.
        X055-FELDN = T055-FELDN.
        APPEND X055.
      ENDSELECT.
    ENDIF.
  ENDSELECT.

  X055_CHECK = 'X'.
  DESCRIBE TABLE X055 LINES X055_COUNT.
ENDFORM.

*eject
*---------------------------------------------------------------------*
*        SUBROUTINE X055_BERECHTIGUNG_PRUEFEN                         *
*---------------------------------------------------------------------*
*        Aktivität: Ändern (und Sperren, Löschvormerkung setzen).     *
*        Prüfung der Änderungsberechtigung                            *
*---------------------------------------------------------------------*
FORM X055_BERECHTIGUNG_PRUEFEN.
  IF  T020-AKTYP   EQ 'V'
  AND X055_COUNT   NE  0.
    CLEAR: I.
    LOOP AT SCREEN.
      CHECK SCREEN-INPUT = 1.
      LOOP AT X055 WHERE FELDN = SCREEN-NAME.
        I = I + 1.
        SCREEN-INPUT = 0.
        MODIFY SCREEN.
      ENDLOOP.
    ENDLOOP.
    IF I > 0.
      IF KLIM-XM743 = SPACE.
        MESSAGE S743 WITH I.
        KLIM-XM743 = 'X'.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
