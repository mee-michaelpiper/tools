*eject
*---------------------------------------------------------------------*
*        MODULE D0120_PRUEFEN                                         *
*---------------------------------------------------------------------*
*        Prüfungen auf Detailbild (Zentral)                           *
*---------------------------------------------------------------------*
MODULE D0120_PRUEFEN.
  CHECK T020-AKTYP NE 'A'.

* ------ Bei 'Löschen Zentraldaten' keine weiteren Prüfungen -----------
  CHECK OK-CODE NE 'DELA'.

* ------ KNKA darf fehlen (Wenn es da ist, geht Löschen nur mit F-Taste)
* IF KLIM-XEXKA = 'F'.
*   CLEAR: RF02L-KLIMG, RF02L-KLIME, KLIM-KKBER.
*   IF  KNKA-KLIMG IS INITIAL
*   AND KNKA-KLIME IS INITIAL
*   AND KNKA-WAERS IS INITIAL.
*     EXIT.
*   ENDIF.
* ENDIF.

* ------ Währung nötig, wenn Betrag eingegeben -------------------------
  IF KNKA-KLIMG > 0
  OR KNKA-KLIME > 0.
    IF KNKA-WAERS = SPACE.
      MESSAGE E733.
    ENDIF.

* ------ Beide Beträge nötig, wenn überhaupt ---------------------------
    IF KNKA-KLIMG = 0
    OR KNKA-KLIME = 0.
      MESSAGE E729.
    ENDIF.
  ENDIF.

* ------ Währung prüfen (gegen Tabelle TCURC) --------------------------
  IF KNKA-WAERS = SPACE.
*   MESSAGE E733.
  ELSE.
    SELECT SINGLE * FROM  TCURC
                    WHERE WAERS = KNKA-WAERS.
    IF SY-SUBRC NE 0.
      MESSAGE E352 WITH KNKA-WAERS.
    ENDIF.
  ENDIF.

* ------ Beide Werte müssen eingegeben sein ----------------------------
* IF KNKA-KLIMG = 0
* OR KNKA-KLIME = 0.
*   MESSAGE E729.
* ENDIF.

* ------ Letzte Auskunft in der Zukunft? ------------------------------
  IF  KNKA-DLAUS      > SY-DATLO
  AND IMPPAR-OKCOD(3) NE 'TXT'.
    MESSAGE W772.
  ENDIF.

* ------ VKLTAB-KLIMK in KNKA-WAERS umrechnen und in VKLTAB ändern -----
  LOOP AT VKLTAB.
    CHECK VKLTAB-WAERA NE KNKA-WAERS.
    VKLTAB-WAERA = KNKA-WAERS.
    IF KNKA-WAERS NE SPACE.
      CALL FUNCTION 'CONVERT_TO_FOREIGN_CURRENCY'
        EXPORTING
          DATE             = SY-DATLO
          LOCAL_AMOUNT     = VKLTAB-KLIMK
          LOCAL_CURRENCY   = VKLTAB-WAERB
          FOREIGN_CURRENCY = KNKA-WAERS
        IMPORTING
          FOREIGN_AMOUNT   = VKLTAB-KLIMA
          EXCHANGE_RATE    = RATE.
    ELSE.
      CLEAR: VKLTAB-KLIMA.
    ENDIF.
    MODIFY VKLTAB.
  ENDLOOP.
  KLIM-WAERA = KNKA-WAERS.

* ------ RF02L-KLIMG_KLIME neu bestimmen -------------------------------
  PERFORM KLIMG_KLIME_AKTUALISIEREN.

* ------ Keine weiteren Prüfungen ohne Zentralwährung/-beträge ---------
  CHECK KNKA-WAERS NE SPACE.

* ------ Gesamtlimit bereits überschritten? ----------------------------
  IF KNKA-KLIMG < RF02L-KLIMG.
    WRITE RF02L-KLIMG TO CHAR1 CURRENCY KNKA-WAERS.
    CONDENSE CHAR1 NO-GAPS.
    IF KNKA-WAERS = KLIM-WAERA.
      MESSAGE E775 WITH CHAR1 KNKA-WAERS.
    ELSE.
      MESSAGE S775 WITH CHAR1 KNKA-WAERS.
      PERFORM STEHENBLEIBEN.
    ENDIF.
  ENDIF.

* ------ Einzellimit bereits überschritten? ----------------------------
  IF KNKA-KLIME < RF02L-KLIME.
    WRITE RF02L-KLIME TO CHAR1 CURRENCY KNKA-WAERS.
    CONDENSE CHAR1 NO-GAPS.
    IF KNKA-WAERS = KLIM-WAERA.
      MESSAGE E776 WITH CHAR1 KNKA-WAERS.
    ELSE.
      MESSAGE S776 WITH CHAR1 KNKA-WAERS.
      PERFORM STEHENBLEIBEN.
    ENDIF.
  ENDIF.

* ------ Einzellimit grösser als Gesamtlimit? --------------------------
  IF KNKA-KLIME > KNKA-KLIMG.
    WRITE KNKA-KLIME TO CHAR1 CURRENCY KNKA-WAERS.
    CONDENSE CHAR1 NO-GAPS.
    WRITE KNKA-KLIMG TO CHAR2 CURRENCY KNKA-WAERS.
    CONDENSE CHAR2 NO-GAPS.
    MESSAGE E723 WITH CHAR1 CHAR2.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE D1007_PRUEFEN                                         *
*---------------------------------------------------------------------*
*        Prüfungen auf Popup 'Ändern Referenz'.                       *
*---------------------------------------------------------------------*
MODULE D1007_PRUEFEN.

* ------ Rücknahme Referenz --------------------------------------------
  IF KNKK-KNKLI = SPACE.
    KNKK-KNKLI = KNA1-KUNNR.
  ENDIF.

* ------ Check if customer is blocked----------------------------------
  IF cl_vs_switch_check=>cmd_vmd_cvp_ilm_sfw_01( ) IS NOT INITIAL.
    IF  KNKK-KNKLI NE SPACE
      AND KNKK-KNKLI NE KNA1-KUNNR
      AND KNKK-KNKLI NE YKNKK-KNKLI.
      PERFORM CHECK_BLOCK USING KNKK-KNKLI.
    ENDIF.
  ENDIF.
* ------ Referenzdebitoren sperren -------------------------------------
  IF  KNKK-KNKLI NE SPACE
  AND KNKK-KNKLI NE KNA1-KUNNR
  AND KNKK-KNKLI NE YKNKK-KNKLI.
    PERFORM SPERREN_KNKLI USING KNKK-KNKLI.
  ENDIF.

* ------ Zyklische Referenz u.a. prüfen --------------------------------
  PERFORM KNKK_REFERENZCHECK.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE DYNSEL_AUFBAUEN                                        *
*---------------------------------------------------------------------*
*       Prüfung, ob mindestens ein Bild markiert wurde                *
*---------------------------------------------------------------------*
MODULE DYNSEL_AUFBAUEN.
  DATA: LD_KUNNR LIKE KNA1-KUNNR.

  CLEAR: KLIM-AUSWL.

*------- Allgemeine Daten ----------------------------------------------
  PERFORM DYNSEL_EINTRAGEN USING 'RF02L-D0110'.
  PERFORM DYNSEL_EINTRAGEN USING 'RF02L-D0120'.

*------- Kontrollbereichsdaten -----------------------------------------
  PERFORM DYNSEL_EINTRAGEN USING 'RF02L-D0105'.
  PERFORM DYNSEL_EINTRAGEN USING 'RF02L-D0210'.
  PERFORM DYNSEL_EINTRAGEN USING 'RF02L-D0220'.

*------- mindestens ein zu bearbeitendes Bild markiert ? ---------------
  SET PARAMETER ID 'CDY' FIELD KLIM-AUSWL.
  IF KLIM-AUSWL = SPACE.
    SET CURSOR FIELD RF02L-D0110.
    MESSAGE S755.
    PERFORM STEHENBLEIBEN.
  ENDIF.

*------- Kontrollbereichsbilder ohne Kontrollbereich gewünscht? --------
  IF RF02L-KKBER = SPACE.
    IF RF02L-D0105 = 'X'
    OR RF02L-D0210 = 'X'
    OR RF02L-D0220 = 'X'.
      MESSAGE S756.
      CLEAR OK-CODE.
      PERFORM STEHENBLEIBEN.
    ENDIF.
  ENDIF.

*------- Zentraldaten zur Anzeige vorhanden? ---------------------------
  IF  RF02L-D0120 = 'X'
  AND KLIM-XEXKA  = 'F'
  AND T020-AKTYP  = 'A'.
    MESSAGE S704 WITH KNA1-KUNNR.
    CLEAR OK-CODE.
    PERFORM STEHENBLEIBEN.
  ENDIF.

*------- Kontrollbereichsdaten zur Anzeige vorhanden? ------------------
  IF  KLIM-XEXKK  = 'F'
  AND T020-AKTYP  = 'A'
  AND (    RF02L-D0105 = 'X'
        OR RF02L-D0210 = 'X'
        OR RF02L-D0220 = 'X' ) .
    MESSAGE S711 WITH KNA1-KUNNR RF02L-KKBER.
    CLEAR OK-CODE.
    PERFORM STEHENBLEIBEN.
  ENDIF.

*------- Berechtigung für Zentraldaten ? -------------------------------
  IF RF02L-D0120 = 'X'.
    PERFORM BERECHTIGUNG_PRUEFEN_KNKA USING ACTVT.
    IF XAUTH_KNKA = SPACE.
      CASE ACTVT.
        WHEN '02'.
*----- Anzeigeberechtigung vorhanden? ----------------------------------
          IF SY-BINPT = SPACE AND SY-CALLD = 'X'.
            PERFORM BERECHTIGUNG_PRUEFEN_KNKA USING '03'.
          ENDIF.
          IF  XAUTH_KNKA = 'X' AND SY-BINPT = SPACE
                               AND SY-CALLD = 'X'.
*----- ... ja, FD33 aufrufen -------------------------------------------
            PERFORM ALPHAFORMAT(SAPFS000) USING RF02L-KUNNR LD_KUNNR.
            SET PARAMETER ID 'KUN' FIELD LD_KUNNR.
            SET PARAMETER ID 'KKB' FIELD RF02L-KKBER.
            SET PARAMETER ID 'CDY' FIELD SAVEDYNPRO.
            MESSAGE S738 WITH 'F_KNKA_MAN' ACTVT.
            CALL TRANSACTION 'FD33' AND SKIP FIRST SCREEN.
            LEAVE PROGRAM.
          ELSE.
            MESSAGE E738 WITH 'F_KNKA_MAN' ACTVT.
          ENDIF.
        WHEN '03'.
          MESSAGE E737 WITH 'F_KNKA_MAN' ACTVT.
      ENDCASE.
    ENDIF.
  ENDIF.

*------- Berechtigung für Übersicht? (Kontoanalyse) --------------------
  IF RF02L-D0105 = 'X'
  OR RF02L-D0220 = 'X'.
    PERFORM BERECHTIGUNG_PRUEFEN_ANA.
  ENDIF.

*------- OK-Codes zurücksetzen -----------------------------------------
  IF OK-CODE = 'MALL'
  OR OK-CODE = 'MARK'.
    CLEAR OK-CODE.
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE DYNSEL_OKCODE                                          *
*---------------------------------------------------------------------*
*       Markieren / Markierungen löschen                              *
*---------------------------------------------------------------------*
MODULE DYNSEL_OKCODE.
  CASE OK-CODE.

*------- Markieren ALLER Einträge ( nur passend zum eingegebenen Key ) -
    WHEN 'MALL'.
      CLEAR: OK-CODE.
      RF02L-D0110 = 'X'.
      RF02L-D0120 = 'X'.
      IF RF02L-KKBER NE SPACE.
        RF02L-D0105 = 'X'.
        RF02L-D0210 = 'X'.
        RF02L-D0220 = 'X'.
      ENDIF.

*------- Markieren / Entmarkieren  eines einzelnen Eintrags ----------
    WHEN 'MARK'.
      GET CURSOR FIELD CRS_FIELD.
      IF CRS_FIELD(8) NE 'RF02L-D0'.
        CLEAR: OK-CODE, CRS_FIELD.
        MESSAGE E315.
      ENDIF.
      ASSIGN (CRS_FIELD) TO <F1>.
      IF <F1> NE 'X'.
        <F1> = 'X'.
      ELSE.
        <F1> = SPACE.
      ENDIF.

*------- Alle Markierungen zurücknehmen --------------------------------
    WHEN 'RALL'.
      CLEAR: OK-CODE, KLIM-AUSWL.
      CLEAR: RF02L-D0110, RF02L-D0120,
             RF02L-D0105, RF02L-D0210, RF02L-D0220.
      SET PARAMETER ID 'CDY' FIELD KLIM-AUSWL.
      PERFORM STEHENBLEIBEN.
  ENDCASE.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE EXIT                                                  *
*---------------------------------------------------------------------*
*        Verarbeitung der OK-Codes, die auf EXIT-Command liegen       *
*---------------------------------------------------------------------*
MODULE EXIT.
  CASE OK-CODE.
    WHEN 'F15'.
      PERFORM OKCODE_F15.
    WHEN 'F17'.
      PERFORM OKCODE_F17.
    WHEN 'NXT'.
      PERFORM OKCODE_NXT.
    WHEN 'REF'.
      PERFORM OKCODE_REF.
  ENDCASE.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE EXIT_EINSTIEG                                          *
*---------------------------------------------------------------------*
*       OK-Codes at Exit-Command (auf Einstiegsbild).                 *
*                                                                     *
*         - F03: Zurück                                               *
*         - F15: Beenden                                              *
*         - AEN: Wechseln zur Transaktion 'Ändern'                    *
*         - ANZ: Wechseln zur Transaktion 'Anzeigen'                  *
*---------------------------------------------------------------------*
MODULE EXIT_EINSTIEG.
  IF OK-CODE = 'F03'
  OR OK-CODE = 'F15'.
    SET SCREEN 0.
    LEAVE SCREEN.
  ELSE.
    CASE OK-CODE.
      WHEN 'AEN'.
        LEAVE TO TRANSACTION 'FD32'.
      WHEN 'ANZ'.
        LEAVE TO TRANSACTION 'FD33'.
    ENDCASE.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE EXIT_POPUP                                            *
*---------------------------------------------------------------------*
*       OK-Codes AT EXIT-COMMAND (auf POPUP)                          *
*---------------------------------------------------------------------*
MODULE EXIT_POPUP.
  CLEAR: OK-CODE.

* ------ Initialisierungen ---------------------------------------------
  CASE SY-DYNNR.
    WHEN 1005.
      CLEAR: KLIM-NKKBE.
    WHEN 1007.
      CLEAR: KNKK-KNKLI.
    WHEN 1009.
      CLEAR: *T001-BUKRS.
  ENDCASE.

* ------ POPUP verlassen -----------------------------------------------
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE FOLGEDYNPO_SETZEN                                      *
*---------------------------------------------------------------------*
*       Ermitteln des Folgedynpros aus Tabelle DYNTAB.                *
*       Das letzte hell zu prozessierende Dynpro ist in der           *
*       DYNTAB mit XLAST = 'X' gekennzeichnet.                        *
*       Falls das letzte Dynpro schon bearbeitet wurde,               *
*       aber die Funktion 'Sichern' nicht gewählt wurde,              *
*       wird ein Sicherheits-Dialogfenster gesendet.                  *
*---------------------------------------------------------------------*
MODULE FOLGEDYNPRO_SETZEN.
  PERFORM NAECHSTES_DYNPRO.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE KNKK-KLIMK                                            *
*---------------------------------------------------------------------*
*        Prüfung von KLIMK (Kreditlimit) und KNKLI (Referenzdebitor). *
*---------------------------------------------------------------------*
MODULE KNKK-KLIMK.
  CHECK T020-AKTYP NE 'A'.
  CHECK OK-CODE NE 'DELK'.

  IF  T000CM-XCVRD NE SPACE
  AND T000CM-XCVCR EQ SPACE
  AND GD_CV_TO_KNKK = 'X'.
    IF 1 = 2.
      MESSAGE I726.
    ENDIF.
    CALL FUNCTION 'CUSTOMIZED_MESSAGE'
      EXPORTING
        I_ARBGB = 'F4'
        I_DTYPE = 'I'
        I_MSGNR = '726'
        I_VAR01 = space
        I_VAR02 = space
        I_VAR03 = space
        I_VAR04 = space.

  ENDIF.
*------- Konsistenzcheck -----------------------------------------------
  PERFORM KNKK_KONSISTENZCHECK.

*------- Prüfung gegen KNKA: Maximales Einzellimit überschritten? ------
  IF KNKA-WAERS NE SPACE.
    IF KNKA-WAERS = RF02L-WAERB.
      IF KNKK-KLIMK > KNKA-KLIME.
        WRITE KNKA-KLIME TO CHAR1(16) CURRENCY KNKA-WAERS.
        MESSAGE E724 WITH CHAR1(16) KNKA-WAERS.
      ENDIF.
      KLIM-KLIMA = KNKK-KLIMK.
    ELSE.
      CALL FUNCTION 'CONVERT_TO_FOREIGN_CURRENCY'
        EXPORTING
          DATE             = SY-DATLO
          LOCAL_AMOUNT     = KNKK-KLIMK
          LOCAL_CURRENCY   = RF02L-WAERB
          FOREIGN_CURRENCY = KNKA-WAERS
        IMPORTING
          FOREIGN_AMOUNT   = KLIM-KLIMA
          EXCHANGE_RATE    = RATE.
      IF KLIM-KLIMA > KNKA-KLIME.
         *KNKA-KLIME = KLIM-KLIMA.
        WRITE *KNKA-KLIME TO CHAR1(16) CURRENCY KNKA-WAERS.
        WRITE  KNKA-KLIME TO CHAR2(16) CURRENCY KNKA-WAERS.
        MESSAGE E731 WITH CHAR1(16) KNKA-WAERS CHAR2(16) KNKA-WAERS.
      ENDIF.
    ENDIF.
  ENDIF.

*------- Prüfung gegen KNKA: Gesamtlimit überschritten -----------------
  IF KNKA-WAERS NE SPACE.
    REFE1 = KLIM-KLIMA.
    LOOP AT VKLTAB.
      CHECK VKLTAB-KKBER NE RF02L-KKBER.
      IF VKLTAB-WAERB = KNKA-WAERS.
        REFE1 = REFE1 + VKLTAB-KLIMK.
      ELSE.
        CALL FUNCTION 'CONVERT_TO_FOREIGN_CURRENCY'
          EXPORTING
            DATE             = SY-DATLO
            LOCAL_AMOUNT     = VKLTAB-KLIMK
            LOCAL_CURRENCY   = VKLTAB-WAERB
            FOREIGN_CURRENCY = KNKA-WAERS
          IMPORTING
            FOREIGN_AMOUNT   = REFE2
            EXCHANGE_RATE    = RATE.
        REFE1 = REFE1 + REFE2.
      ENDIF.
    ENDLOOP.
    IF REFE1 > KNKA-KLIMG.
       *KNKA-KLIMG = REFE1.
      WRITE *KNKA-KLIMG TO CHAR1(16) CURRENCY KNKA-WAERS.
      WRITE  KNKA-KLIMG TO CHAR2(16) CURRENCY KNKA-WAERS.
      MESSAGE E730 WITH CHAR1(16) KNKA-WAERS CHAR2(16) KNKA-WAERS.
    ENDIF.
  ENDIF.

*------- Aufnehmen/Ändern in VKLTAB ------------------------------------
  LOOP AT VKLTAB WHERE KKBER = RF02L-KKBER.
    TABIX = SY-TABIX.
    EXIT.
  ENDLOOP.
  IF SY-SUBRC = 0.
    IF KNKA-WAERS = SPACE.
      CLEAR: VKLTAB-KLIMA, VKLTAB-WAERA.
    ELSE.
      VKLTAB-KLIMA = KLIM-KLIMA.
      VKLTAB-WAERA = KLIM-WAERA.
    ENDIF.
    VKLTAB-KLIMK = KNKK-KLIMK.
    MODIFY VKLTAB INDEX TABIX.
  ELSE.
    CLEAR: VKLTAB.
    VKLTAB-XAUTH = 'X'.
    VKLTAB-KKBER = RF02L-KKBER.
    VKLTAB-KKBTX = RF02L-KKBTX.
    VKLTAB-KNKLI = KNKK-KNKLI.
    IF KNKA-WAERS = SPACE.
      CLEAR: VKLTAB-KLIMA, VKLTAB-WAERA.
    ELSE.
      VKLTAB-KLIMA = KLIM-KLIMA.
      VKLTAB-WAERA = KLIM-WAERA.
    ENDIF.
    VKLTAB-KLIMK = KNKK-KLIMK.
    VKLTAB-WAERB = RF02L-WAERB.
    APPEND VKLTAB.
    SORT VKLTAB.
  ENDIF.

*------- RF02l-KLIMG_KLIME neu bestimmen -------------------------------
  PERFORM KLIMG_KLIME_AKTUALISIEREN.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE KNKK-CTLPC                                            *
*---------------------------------------------------------------------*
*        Prüfung von CTLPC (Risikoklasse).                            *
*---------------------------------------------------------------------*
MODULE KNKK-CTLPC.
  CHECK T020-AKTYP NE 'A'.

* ------ Risikoklasse + Kontrollbereich in T691A? ----------------------
  IF KNKK-CTLPC NE SPACE.
    SELECT SINGLE * FROM  T691A
                    WHERE CTLPC = KNKK-CTLPC
                    AND   KKBER = RF02L-KKBER.
    IF SY-SUBRC NE 0.
      MESSAGE E769 WITH KNKK-CTLPC RF02L-KKBER.
    ENDIF.
  ENDIF.
  IF KNKK-CTLPC NE YKNKK-CTLPC.
    KLIM-XNEUR = 'X'.
  ELSE.
    CLEAR: KLIM-XNEUR.
  ENDIF.
ENDMODULE.


*eject
*---------------------------------------------------------------------*
*        MODULE KNKK-DTREV_NXTRV.                                     *
*---------------------------------------------------------------------*
*        Prüfung von DTREV (Datum letzte Prüfung)                     *
*                und NXTRV (Datum nächste Prüfung).                   *
*---------------------------------------------------------------------*
MODULE KNKK-DTREV_NXTRV.
  CHECK T020-AKTYP NE 'A'.

* ------ Letzte Prüfung in der Zukunft? -------------------------------
  IF  KNKK-DTREV      > SY-DATLO
  AND IMPPAR-OKCOD(3) NE 'TXT'.
    MESSAGE W772.
  ENDIF.

* ------ Nächste Prüfung in der Vergangenheit? ------------------------
  IF  NOT KNKK-NXTRV      IS INITIAL
  AND     KNKK-NXTRV      LT SY-DATLO
  AND     IMPPAR-OKCOD(3) NE 'TXT'.
    MESSAGE W773.
  ENDIF.

* ------ Nächste Prüfung vor letzter Prüfung? -------------------------
  IF  NOT KNKK-NXTRV      IS INITIAL
  AND     KNKK-NXTRV      LT KNKK-DTREV
  AND     IMPPAR-OKCOD(3) NE 'TXT'.
    MESSAGE W771.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE KNKK-GRUPP                                            *
*---------------------------------------------------------------------*
*        Prüfung von GRUPP (Gruppe)                                   *
*---------------------------------------------------------------------*
MODULE KNKK-GRUPP.
  CHECK T020-AKTYP NE 'A'.

* ------ Gruppe in T691B? ----------------------------------------------
  IF KNKK-GRUPP NE SPACE.
    SELECT SINGLE * FROM  T691B
                    WHERE GRUPP = KNKK-GRUPP
                    AND   KKBER = RF02L-KKBER.
    IF SY-SUBRC NE 0.
      MESSAGE E785 WITH KNKK-GRUPP.
    ENDIF.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE KNKK-KRAUS.                                           *
*---------------------------------------------------------------------*
*        Prüfung von KRAUS (Kreditauskunftsnummer).                   *
*---------------------------------------------------------------------*
MODULE KNKK-KRAUS.
  CHECK T020-AKTYP NE 'A'.
  CHECK KNKK-KRAUS NE SPACE.

* ------ Prüfung der Auskunftsnummer über Open FI ----------------------
  CALL FUNCTION 'OUTBOUND_CALL_00001240_P'
    EXPORTING
      I_KRAUS = KNKK-KRAUS
      I_KNKK  = KNKK
    EXCEPTIONS
      OTHERS  = 1.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE KNKK-REVDB.                                           *
*---------------------------------------------------------------------*
*        Prüfung von REVDB (Datum letzte externe Prüfung).            *
*---------------------------------------------------------------------*
MODULE KNKK-REVDB.
  CHECK T020-AKTYP NE 'A'.

* ------ Letzte Prüfung in der Zukunft? -------------------------------
  IF  KNKK-REVDB      > SY-DATLO
  AND IMPPAR-OKCOD(3) NE 'TXT'.
    MESSAGE W772.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE KNKK-SBGRP                                            *
*---------------------------------------------------------------------*
*        Prüfung von SBGRP (Sachbearbeitergruppe).                    *
*---------------------------------------------------------------------*
MODULE KNKK-SBGRP.
  CHECK T020-AKTYP NE 'A'.

* ------ Sachbearbeitergruppe in T024B? --------------------------------
  IF KNKK-SBGRP NE SPACE.
    SELECT SINGLE * FROM  T024B
                    WHERE SBGRP = KNKK-SBGRP
                    AND   KKBER = RF02L-KKBER.
    IF SY-SUBRC NE 0.
      MESSAGE E770 WITH KNKK-SBGRP.
    ENDIF.
  ENDIF.
  IF KNKK-SBGRP NE YKNKK-SBGRP.
    KLIM-XNEUB = 'X'.
  ELSE.
    CLEAR: KLIM-XNEUB.
  ENDIF.

ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE KONTO_LESEN                                            *
*---------------------------------------------------------------------*
*       Debitorendaten zum Kreditmanagement einlesen.                 *
*---------------------------------------------------------------------*
MODULE KONTO_LESEN.
  CLEAR KLIM.
  PERFORM DYNP_VALUES_READ.
  PERFORM DEBITORENSTAMM_LESEN.
  READ_ADDRESS-MASTER_TAB   = 'KNA1'.
  READ_ADDRESS-MASTER_FIELD = 'ADRNR'.
  READ_ADDRESS-KEY_CONTENT  = KNA1-KUNNR.
  READ_ADDRESS-NUMBER       = KNA1-ADRNR.
  CLEAR READ_PERSON.
  CONVERSION = C_NO_CONVERSION.

  PERFORM ZAV_LESEN USING  READ_ADDRESS     READ_PERSON
                           C_TYPE_1         C_INIT
                           C_NO_CONVERSION  C_MAINTAIN
                           C_NO_EXPORT      C_NO_REFERENCE.

  IF cl_iav_mapping_util=>is_iav_active( ) EQ abap_true.  "IAV
    CALL METHOD cl_iav_mapping_util=>get_address_as_kna1
      EXPORTING
        iv_adrnr                 = kna1-adrnr
        iv_application_component = 'FI_AR'
      CHANGING
        cs_kna1                  = int_kna1.
  else.
    int_kna1 = kna1.
  endif.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE OKCODE_BEARBEITEN                                      *
*---------------------------------------------------------------------*
*       OK-Code Bearbeitung auf einem Datenbild.                      *
*---------------------------------------------------------------------*
MODULE OKCODE_BEARBEITEN.

* ------ EXIT-Code 'F15' zurücknehmen, wenn inzwischen nicht mehr 'UPDA'
  IF OK-CODE NE 'UPDA'.
    CLEAR: EX-CODE.
  ENDIF.

* ------ 'Nächstes Bild' ist wie ENTER ---------------------------------
  IF OK-CODE = 'S+'.
    CLEAR: OK-CODE.
  ENDIF.

* ------ OK-Code für FI-ARI: Third-Party-Integration 'ECnn' ------------
  IF  OK-CODE(2)   EQ 'EC'
  AND OK-CODE+2(2) CO '0123456789'.
    PERFORM ECNN_OKCODE.
  ENDIF.

* ------ ENTER = Nächstes Bild (in NAECHSTES_DYNPRO) -------------------
  CASE OK-CODE.

* ------ ENTER = Nächstes Bild (in NAECHSTES_DYNPRO) -------------------
    WHEN SPACE.

* ------ Änderungsbelege -----------------------------------------------
    WHEN 'AEFD'.
      PERFORM AENDERUNGSBELEGE_ANZEIGEN.
    WHEN 'AEKT'.
      PERFORM AENDERUNGSBELEGE_ANZEIGEN.

* ------ Zurück --------------------------------------------------------
    WHEN 'BACK'.
      PERFORM OKCODE_F03.

* ------ Daten zur letzten Zahlung -------------------------------------
    WHEN 'CASH'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_CASH.

* ------ Kreditvektor anzeigen -----------------------------------------
    WHEN 'CV'.
      OK-CODE = SPACE.
      PERFORM OKCODE_CV.

* ------ Kreditlimit löschen (KNKA) ------------------------------------
    WHEN 'DELA'.
      OK-CODE = SPACE.
      PERFORM DELETE_KNKA.

* ------ Kreditlimit löschen (KNKK) ------------------------------------
    WHEN 'DELK'.
      OK-CODE = SPACE.
      PERFORM DELETE_KNKK.

* ------ Report RFDKLI40 (Übersicht) -----------------------------------
    WHEN 'DK40'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_DK40.
      PERFORM STEHENBLEIBEN.

* ------ Report RFDKLI41 (Stammblatt) ----------------------------------
    WHEN 'DK41'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_DK41.
      PERFORM STEHENBLEIBEN.

* ------ Report RFDKLI42 (Frühwarnliste) -------------------------------
    WHEN 'DK42'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_DK42.
      PERFORM STEHENBLEIBEN.
* ------ Report RFDKLI42 (Frühwarnliste) -------------------------------
    WHEN 'DK43'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_DK43.
      PERFORM STEHENBLEIBEN.

* ------ Dokumente anzeigen --------------------------------------------
    WHEN 'DOKA'.
      CLEAR: OK-CODE.

* ------ Schlüssel: KUNNR ----------------------------------------------
      DRAD_OBJKY = KNA1-KUNNR.

* ------ REFRESH zu Beginn der Transaktion -----------------------------
      IF DRAD_XINIT = SPACE.
        DRAD_REFRESH = 'X'.
        DRAD_XINIT   = 'X'.
      ELSE.
        DRAD_REFRESH = ' '.
      ENDIF.

* ------ OPCOD: 2=Ändern, 3=Anzeigen -----------------------------------
      IF T020-AKTYP = 'A'.
        DRAD_OPCOD = '3'.
      ELSE.
        DRAD_OPCOD = '2'.
      ENDIF.

* ------ Dokumente dem Stammsatz zuordnen / anzeigen -------------------
      CALL FUNCTION 'DOCUMENT_ASSIGNMENT'
        EXPORTING
          CHECK_EXIST     = 'X'
          DOKOB           = 'KNA1'
          DOKOB_VORLAGE   = ' '
          OBJKY           = DRAD_OBJKY
          OBJKY_VORLAGE   = ' '
          OBJTXT          = ' '
          OPCODE          = DRAD_OPCOD
          REFRESH_FLAG    = DRAD_REFRESH
          VORSCHLAG_DOKAR = ' '
        IMPORTING
          VB_FLAG         = DRAD_VB
        TABLES
          TABDRAD         = XDRAD.

* ------ DSO-Berechnung anzeigen ---------------------------------------
    WHEN 'DSOI'.
      CLEAR: OK-CODE.
      PERFORM DSO_ERMITTELN.
      PERFORM DSO_ERKLAEREN.
      PERFORM STEHENBLEIBEN.

* ------ Einzelposten --------------------------------------------------
    WHEN 'FBL5'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_FBL5.

* ------ Einzelposten zum Kontrollbereich ------------------------------
    WHEN 'FBLK'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_FBL5_KKBER.

* ------ Umfeld: Debitorenstammsatz anzeigen ---------------------------
    WHEN 'FD03'.
      OK-CODE = SPACE.
      IF KLIM-BUKRS NE SPACE.
        SET PARAMETER ID 'BUK' FIELD KLIM-BUKRS.
      ENDIF.
      CALL TRANSACTION 'FD03'.

* ------ Umfeld: Kontoanalyse ------------------------------------------
    WHEN 'FD11'.
      OK-CODE = SPACE.
      IF KLIM-BUKRS NE SPACE.
        SET PARAMETER ID 'BUK' FIELD KLIM-BUKRS.
      ENDIF.
      CALL TRANSACTION 'FD11'.

* ------ Infosystem ----------------------------------------------------
    WHEN 'INFO'.
      PERFORM OKCODE_INFO.

* ------ Liste Buchungskreise, in denen Debitor angelegt ist -----------
    WHEN 'LBUD'.
      OK-CODE = SPACE.
      PERFORM OKCODE_LBUD USING 'LBUD'.

* ------ Liste alle Buchungskreise zum Kontrollbereich -----------------
    WHEN 'LBUK'.
      OK-CODE = SPACE.
      PERFORM OKCODE_LBUK.

* ------ MAIL senden ---------------------------------------------------
    WHEN 'MAIL'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_MAIL.

* ------ Kreditlimit neu aufbauen --------------------------------------
    WHEN 'NEUA'.
      OK-CODE = SPACE.
      PERFORM BERECHTIGUNG_PRUEFEN_BUK.

* ------ Hinweis auf längere Laufzeit ----------------------------------
      IF SY-BINPT = SPACE.
        MESSAGE I793.
      ENDIF.
* ------ Hinweis auf IMG-Einstellungen ---------------------------------
      MESSAGE I749.

* ------ Frage stellen -------------------------------------------------
      CHAR1    = TEXT-PT6.
      CHAR1+20 = KNKK-KUNNR.
      CHAR1+31 = KNKK-KKBER.
      CONDENSE CHAR1.
      CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE'
        EXPORTING
          TITEL         = CHAR1
          DIAGNOSETEXT1 = TEXT-P31
          DIAGNOSETEXT2 = TEXT-P32
          DIAGNOSETEXT3 = TEXT-P33
          TEXTLINE1     = TEXT-P34
          TEXTLINE2     = TEXT-P35
          DEFAULTOPTION = 'J'
        IMPORTING
          ANSWER        = ANSWER.
* ------ Antwort ausführen ---------------------------------------------
      IF ANSWER = 'J'.
        KLIM-XNEUA = 'X'.
        MESSAGE S758.
      ELSE.
        PERFORM STEHENBLEIBEN.
      ENDIF.

* ------ Oldest Due Date -----------------------------------------------
    WHEN 'OLDD'.
      OK-CODE = SPACE.
      PERFORM OKCODE_OLDD.

* ------ Open FI: Weitere Daten anzeigen? ------------------------------
    WHEN 'OPFI'.
      OK-CODE = SPACE.
      CALL FUNCTION 'OPEN_FI_PERFORM_00001510_E'
        EXPORTING
          I_KUNNR = KNA1-KUNNR
          I_KKBER = RF02L-KKBER
          I_AKTYP = T020-AKTYP
        IMPORTING
          E_XCHNG = OFIWA-XCHNG.
      PERFORM STEHENBLEIBEN.

* ------ Daten zum Referenzdebitor -------------------------------------
    WHEN 'REFD'.
      OK-CODE = SPACE.
      PERFORM OKCODE_REFD.

* ------ Liste referenzierende Debitoren -------------------------------
    WHEN 'REFL'.
      OK-CODE = SPACE.
      PERFORM OKCODE_REFL.

* ------ Offene Aufträge zum Kreditkonto -------------------------------
    WHEN 'REP1'.
      OK-CODE = SPACE.
      CALL FUNCTION 'CUSTOMER_OPEN_ORDERS'
        EXPORTING
          I_KKBER = RF02L-KKBER
          I_KNKLI = KNKK-KNKLI.

* ------ Offene Lieferungen/Fakturen zum Kreditkonto -------------------
    WHEN 'REP2'.
      OK-CODE = SPACE.
      CALL FUNCTION 'CUSTOMER_OPEN_DELIVERIES'
        EXPORTING
          I_KKBER = RF02L-KKBER
          I_KNKLI = KNKK-KNKLI.

* ------ Report RVKRED02 (Gesperrte Vertriebsbelege freigeben ----------
    WHEN 'RV02'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_RV02.

* ------ Report RVKRED03 (Genehmigte Vertriebsbelege erneut prüfen) ----
    WHEN 'RV03'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_RV03.

* ------ Voriges Bild --------------------------------------------------
    WHEN 'S-'.
      PERFORM BLAETTERN_ZURUECK.

* ------ SD-Ausschöpfung -----------------------------------------------
    WHEN 'SD  '.
      CLEAR: OK-CODE.
      PERFORM OKCODE_SD.

*------- nur intern gesetzt für Bildwiederholung nach
*        'POPUP_TO_CONFIRM_LOSS_OF_DATA' -------------------------------
    WHEN 'STOP'.
      CLEAR OK-CODE.
      PERFORM STEHENBLEIBEN.

* ------ Textverarbeitung ----------------------------------------------
    WHEN 'TEXT'.
      CLEAR OK-CODE.
      PERFORM OKCODE_TEXT.

* ------ Textverarbeitung zentral --------------------------------------
    WHEN 'TEXZ'.
      CLEAR OK-CODE.
      PERFORM OKCODE_TEXZ.

* ------ Übersicht KNKK ------------------------------------------------
    WHEN 'UKK'.
      CLEAR OK-CODE.
      PERFORM OKCODE_UKK.

* ------ Sichern -------------------------------------------------------
    WHEN 'UPDA'.
      PERFORM CHECK_AENDERUNGEN.
      IF KLIM-XCHNG = 'X'.
        PERFORM SCHLUSS_BEARBEITUNG.
        LEAVE TO CURRENT TRANSACTION.                       "946620
      ELSE.
        MESSAGE S311.
        IF SY-BINPT = SPACE.
          PERFORM TRANSAKTION_VERLASSEN.
        ELSE.
          PERFORM ZURUECK_ZUM_RUFER.
        ENDIF.
      ENDIF.

* ------ Mahndaten -----------------------------------------------------
    WHEN 'UMA '.
      CLEAR: OK-CODE.
      PERFORM OKCODE_UMA.

* ------ Zahldaten -----------------------------------------------------
    WHEN 'UZA '.
      CLEAR: OK-CODE.
      PERFORM OKCODE_UZA.

* ------ Verwaltungsdaten ----------------------------------------------
    WHEN 'VWDT'.
      CLEAR: OK-CODE.
      PERFORM OKCODE_VWDT.
  ENDCASE.

* ------ Sprung zu beliebigem Bild -------------------------------------
  IF OK-CODE(1) = '0'.
    IF OK-CODE = '0105'
    OR OK-CODE = '0220'.
      PERFORM BERECHTIGUNG_PRUEFEN_ANA.
    ENDIF.
    PERFORM OKCODE_BILD.
  ENDIF.

* ------ Blättern ------------------------------------------------------
  IF OK-CODE CA '+-'.
    PERFORM BLAETTERN USING LNFIR LNMAX LNCNT.
    PERFORM STEHENBLEIBEN.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE OKCODE_EINSTIEG                                        *
*---------------------------------------------------------------------*
*       OK-Code Verarbeitung auf dem Einstiegsbild.                   *
*---------------------------------------------------------------------*
MODULE OKCODE_EINSTIEG.
  PERFORM OKCODE_EINSTIEG.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE OKCODE_POPUP                                          *
*---------------------------------------------------------------------*
*        OK-Code-Bearbeitung auf POPUP.                               *
*---------------------------------------------------------------------*
MODULE OKCODE_POPUP.
  CASE OK-CODE.

* ------ Auswählen -----------------------------------------------------
    WHEN 'PICK'.
      CLEAR OK-CODE.
      GET CURSOR FIELD CRS_FIELD LINE CRS_LINE.
      IF CRS_LINE = 0.
        MESSAGE S009.
      ELSE.
        CASE SY-DYNNR.
          WHEN 1004.
            INDEX = kkber_control1-top_line + CRS_LINE - 1.
            READ TABLE VKLTAB INDEX INDEX.
          WHEN 1005.
            INDEX = kkber_control-top_line + CRS_LINE - 1.
            READ TABLE VKLTAB INDEX INDEX.
          WHEN 1009.
            INDEX = LNFIR + CRS_LINE - 1.
            READ TABLE BUKTAB INDEX INDEX.
        ENDCASE.
        IF SY-SUBRC = 0.
          CASE SY-DYNNR.
            WHEN 1004.
              PERFORM BERECHTIGUNG_PRUEFEN_KNKK
                USING VKLTAB-KKBER 'ERROR' ACTVT.
              KLIM-NKKBE = VKLTAB-KKBER.
            WHEN 1005.
              PERFORM BERECHTIGUNG_PRUEFEN_KNKK
                USING VKLTAB-KKBER 'ERROR' ACTVT.
              KLIM-NKKBE = VKLTAB-KKBER.
            WHEN 1009.
              KLIM-BUKRS = BUKTAB-BUKRS.
          ENDCASE.
          SET SCREEN 0.
          LEAVE SCREEN.
        ELSE.
          MESSAGE S009.
        ENDIF.
      ENDIF.
  ENDCASE.

* ------ Blättern ------------------------------------------------------
  IF OK-CODE CA '+-'.
    PERFORM BLAETTERN USING LNFIR LNMAX LNCNT.
    PERFORM STEHENBLEIBEN.
  ENDIF.

* ------ Scrollbar -----------------------------------------------------
  IF OK-CODE IS INITIAL.
    PERFORM STEHENBLEIBEN.
  ENDIF.

* ------ POPUP verlassen -----------------------------------------------
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  RF02L-HORDA  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE RF02L-HORDA INPUT.
  XHORDA = 'X'.
* ------- SD-Werte / Ausschöpfungsgrad ---------------------------------
  IF KNKK-KNKLI = KNA1-KUNNR.
    PERFORM ERMITTELN_SAUFT USING KNKK-KNKLI RF02L-SAUFT RF02L-HORDA.
    RF02L-OBLIG = KNKK-SKFOR + KNKK-SSOBL + RF02L-SAUFT.
    PERFORM AUSSCHOEPFUNGSGRAD_BERECHNEN
      USING KNKK-KLIMK RF02L-OBLIG RF02L-KLPRZ.
  ENDIF.
ENDMODULE.                 " RF02L-HORDA  INPUT


*mi/4.5B begin
*&---------------------------------------------------------------------*
*&      Module  ZAV_OKCODE_BEARBEITEN  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ZAV_OKCODE_BEARBEITEN INPUT.
  PERFORM ZAV_OKCODE_BEARBEITEN USING     C_TYPE_1
                                CHANGING  OK-CODE.
ENDMODULE.                 " ZAV_OKCODE_BEARBEITEN  INPUT
*mi/4.5B end
*&---------------------------------------------------------------------*
*&      Module  KNKK-KNKLI  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE knkk-knkli INPUT.

  IF cl_vs_switch_check=>cmd_vmd_cvp_ilm_sfw_01( ) IS NOT INITIAL.
    IF NOT knkk-knkli IS INITIAL.
      PERFORM check_block USING KNKK-KNKLI.
    ENDIF.
  ENDIF.
ENDMODULE.                 " KNKK-KNKLI  INPUT
