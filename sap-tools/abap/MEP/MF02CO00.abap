*eject
*---------------------------------------------------------------------*
*       MODULE BEZ_KNA1-KUNNR                                         *
*---------------------------------------------------------------------*
*       Kontobezeichnung anzeigen                                     *
*---------------------------------------------------------------------*
MODULE BEZ_KNA1-KUNNR OUTPUT.

* ------ Aus Performancegründen nicht bei Batch-Input ------------------
  CHECK SY-BINPT NE 'X'.

* ------ GPA für KUNNR -------------------------------------------------
  IF SY-CALLD NE SPACE.
    GET PARAMETER ID 'KUN' FIELD RF02L-KUNNR.
  ENDIF.

* ------ Konto lesen ---------------------------------------------------
  IF RF02L-KUNNR EQ SPACE.
    CLEAR KNA1.
  ELSE.
    IF KNA1-KUNNR NE RF02L-KUNNR.
      CLEAR KNA1.
      SELECT SINGLE * FROM KNA1 WHERE KUNNR = RF02L-KUNNR.
      if sy-subrc eq 0.
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
      endif.
    ENDIF.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE BEZ_KNKK-CTLPC                                         *
*---------------------------------------------------------------------*
*       Bezeichnung der Risikoklasse anzeigen                         *
*---------------------------------------------------------------------*
MODULE BEZ_KNKK-CTLPC OUTPUT.

* ------ Aus Performancegründen nicht bei Batch-Input ------------------
  CHECK SY-BINPT NE 'X'.

* ------ Bezeichnung lesen ---------------------------------------------
  IF KNKK-CTLPC EQ SPACE.
    CLEAR T691T.
  ELSE.
    IF T691T-CTLPC NE KNKK-CTLPC.
      CLEAR T691T.
      SELECT SINGLE * FROM T691T WHERE SPRAS = SY-LANGU
                                 AND   CTLPC = KNKK-CTLPC
                                 AND   KKBER = RF02L-KKBER.
    ENDIF.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE BEZ_KNKK-GRUPP                                         *
*---------------------------------------------------------------------*
*       Bezeichnung der Gruppe anzeigen                               *
*---------------------------------------------------------------------*
MODULE BEZ_KNKK-GRUPP OUTPUT.

* ------ Aus Performancegründen nicht bei Batch-Input ------------------
  CHECK SY-BINPT NE 'X'.

* ------ Bezeichnung lesen ---------------------------------------------
  IF KNKK-GRUPP EQ SPACE.
    CLEAR T691C.
  ELSE.
    IF T691C-GRUPP NE KNKK-GRUPP.
      CLEAR T691C.
      SELECT SINGLE * FROM T691C WHERE SPRAS = SY-LANGU
                                 AND   GRUPP = KNKK-GRUPP
                                 AND   KKBER = RF02L-KKBER.
    ENDIF.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE BEZ_KNKK-KKBER                                         *
*---------------------------------------------------------------------*
*       Bezeichnung des Kontrollbereichs anzeigen.                    *
*---------------------------------------------------------------------*
MODULE BEZ_KNKK-KKBER OUTPUT.

* ------ Aus Performancegründen nicht bei Batch-Input ------------------
  CHECK SY-BINPT NE 'X'.

* ------ GPA für KKBER -------------------------------------------------
  GET PARAMETER ID 'KKB' FIELD RF02L-KKBER.

* ------ Kontrollbereich lesen -----------------------------------------
  IF RF02L-KKBER EQ SPACE.
    CLEAR T014T.
  ELSE.
    IF T014T-KKBER NE RF02L-KKBER.
      CLEAR T014T.
      SELECT SINGLE * FROM T014T WHERE SPRAS = SY-LANGU
                                 AND   KKBER = RF02L-KKBER.
    ENDIF.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE BEZ_KNKK-SBGRP                                         *
*---------------------------------------------------------------------*
*       Bezeichnung der Sachbearbeitergruppe anzeigen                 *
*---------------------------------------------------------------------*
MODULE BEZ_KNKK-SBGRP OUTPUT.

* ------ Aus Performancegründen nicht bei Batch-Input ------------------
  CHECK SY-BINPT NE 'X'.

* ------ Bezeichnung lesen ---------------------------------------------
  IF KNKK-SBGRP EQ SPACE.
    CLEAR T024B.
  ELSE.
    IF T024B-SBGRP NE KNKK-SBGRP.
      CLEAR T024B.
      SELECT SINGLE * FROM T024B WHERE SBGRP = KNKK-SBGRP
                                 AND   KKBER = RF02L-KKBER.
    ENDIF.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE D0220_ANZEIGEN                                        *
*---------------------------------------------------------------------*
*        Das Zahlungsverhalten einer Periode wird angezeigt.          *
*---------------------------------------------------------------------*
MODULE D0220_ANZEIGEN OUTPUT.
  IF SY-STEPL = 1.
    LNCUR = LNFIR.
    LNCNT = SY-LOOPC.
  ENDIF.
  READ TABLE KKNB4 INDEX LNCUR.
  IF SY-SUBRC = 0.
    MOVE-CORRESPONDING KKNB4 TO RF42B.
    RF42B-KJAHR = RF42B-JAHXX.
    RF42B-GJAHR = RF42B-JAHXX.
    RF42B-KMONA = RF42B-MONXX.
    LNCUR = LNCUR + 1.
  ELSE.
    EXIT FROM STEP-LOOP.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE D1004_ANZEIGEN                                         *
*---------------------------------------------------------------------*
*       Ein Eintrag aus der Tabelle VKLTAB wird im STEP-LOOP auf      *
*       Dynpro 1004 angezeigt.                                        *
*---------------------------------------------------------------------*
MODULE D1004_ANZEIGEN OUTPUT.

  IF SY-STEPL = 1.
    LNCNT = SY-LOOPC.
  ENDIF.
  IF sy-dynnr = 1004.
    LNCUR = kkber_control1-current_line.
  ELSEIF sy-dynnr = 1005.
    LNCUR = kkber_control-current_line.
  ENDIF.

* ------ Aus Tabelle VKLTAB anzeigen -----------------------------------
  READ TABLE VKLTAB INDEX LNCUR.
  IF SY-SUBRC = 0.
    *KNKK-KKBER = VKLTAB-KKBER.
    T014T-KKBTX = VKLTAB-KKBTX.
    *KNKK-KLIMK = VKLTAB-KLIMK.
    T014-WAERS  = VKLTAB-WAERB.
    *T014-WAERS = VKLTAB-WAERB.
    *KNKK-KNKLI = VKLTAB-KNKLI.

* ------ Referenzdebitor? ----------------------------------------------
    IF VKLTAB-KNKLI NE KNA1-KUNNR.
      PERFORM MODIFY_SCREEN USING '3' '002' 'VISIBLE'.
    ENDIF.

* ------ Keine Berechtigung? -------------------------------------------
    IF VKLTAB-XAUTH = SPACE.
      PERFORM MODIFY_SCREEN USING '2' '001' 'INVISIBLE'.
    ENDIF.

* ------ Aktueller Kontrollbereich hell --------------------------------
    IF VKLTAB-KKBER = RF02L-KKBER.
      PERFORM MODIFY_SCREEN USING '1' '001' 'INTENSIFIED'.
    ENDIF.
  ELSE.
    EXIT FROM STEP-LOOP.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE D1008_ANZEIGEN                                         *
*---------------------------------------------------------------------*
*       Ein Eintrag aus der Tabelle REFTAB wird im STEP-LOOP auf      *
*       Dynpro 1008 angezeigt.                                        *
*---------------------------------------------------------------------*
MODULE D1008_ANZEIGEN OUTPUT.

* ------ Anzahl Loopzeilen in LNCNT merken -----------------------------
  IF SY-STEPL = 1.
    LNCNT = SY-LOOPC.
    LNCUR = LNFIR.
  ENDIF.

* ------ Aus Tabelle REFTAB anzeigen -----------------------------------
  READ TABLE REFTAB INDEX LNCUR.
  IF SY-SUBRC = 0.
    LNCUR = LNCUR + 1.
    *KNKK-KUNNR  = REFTAB-KUNNR.
    *RF02L-OBLIG = REFTAB-OBLIG.
  ELSE.
    EXIT FROM STEP-LOOP.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE D1009_ANZEIGEN                                         *
*---------------------------------------------------------------------*
*       Ein Eintrag aus der Tabelle BUKTAB wird im STEP-LOOP auf      *
*       Dynpro 1009 angezeigt.                                        *
*---------------------------------------------------------------------*
MODULE D1009_ANZEIGEN OUTPUT.

* ------ Anzahl Loopzeilen in LNCNT merken -----------------------------
  IF SY-STEPL = 1.
    LNCNT = SY-LOOPC.
    LNCUR = LNFIR.
  ENDIF.

* ------ Aus Tabelle BUKTAB anzeigen -----------------------------------
  READ TABLE BUKTAB INDEX LNCUR.
  IF SY-SUBRC = 0.
    LNCUR = LNCUR + 1.
    MOVE-CORRESPONDING BUKTAB TO *T001.
  ELSE.
    EXIT FROM STEP-LOOP.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE DYNPRO_MODIFIZIEREN                                    *
*---------------------------------------------------------------------*
*       Modifikationen des Dynpros (Eingabebereitschaft ... )         *
*---------------------------------------------------------------------*
MODULE DYNPRO_MODIFIZIEREN OUTPUT.
  CASE SY-DYNNR.

* ------ Übersicht -----------------------------------------------------
    WHEN 105.
*     IF KNB5-MABER NE SPACE.
*       PERFORM MODIFY_SCREEN USING '1' '001' 'VISIBLE'.
*     ENDIF.
      IF KLIM-XEXKK = 'X'.
        IF KNKK-KNKLI = KNA1-KUNNR.
          IF RF02L-OBLIG > KNKK-KLIMK.
            PERFORM MODIFY_SCREEN USING '1' '002' 'INTENSIFIED'.
          ENDIF.
        ENDIF.
      ENDIF.

* ------ Zentraldaten --------------------------------------------------
    WHEN 120.
      IF T020-AKTYP = 'A'.
        PERFORM MODIFY_SCREEN_INPUT_OFF.
      ENDIF.
      IF KNKA-WAERS IS INITIAL.
        PERFORM MODIFY_SCREEN USING '1' '001' 'INVISIBLE'.
      ENDIF.

* ------ Status --------------------------------------------------------
    WHEN 210.

* ------ Limit überschritten ? -----------------------------------------
      IF KLIM-XEXKK = 'X'.
        IF KNKK-KNKLI = KNA1-KUNNR.
          IF RF02L-OBLIG > KNKK-KLIMK.
            PERFORM MODIFY_SCREEN USING '1' '001' 'INTENSIFIED'.
          ENDIF.
        ENDIF.
      ENDIF.

* ------ Ausschöpfungsgrad ausblenden bei Referenz ---------------------
      IF KLIM-XEXKK = 'X'.
        IF KNKK-KNKLI NE KNA1-KUNNR.
          PERFORM MODIFY_SCREEN USING '1' '001' 'INVISIBLE'.
        ENDIF.
      ENDIF.

* ------ Felder nicht eingabebereit beim Anzeigen ----------------------
      IF T020-AKTYP = 'A'.
        PERFORM MODIFY_SCREEN_INPUT_OFF.
      ENDIF.

* ------ 'Kreditlimit' nicht eingabebereit bei Referenz ----------------
      IF  T020-AKTYP NE 'A'
      AND KNKK-KNKLI NE SPACE
      AND KNKK-KNKLI NE KNA1-KUNNR
      AND SY-BINPT   EQ SPACE.
        PERFORM MODIFY_SCREEN USING '1' '002' 'INPUTOFF'.
      ENDIF.

* ------ 'Kreditvektor' unsichtbar -------------------------------------
      IF  T000CM-XCVRD IS INITIAL
      AND T000CM-XCVCR IS INITIAL.
        PERFORM MODIFY_SCREEN USING '1' 'CV' 'INVISIBLE'.
      ENDIF.

* ------ 'Referenz' nur eingabebereit im Batch-Input -------------------
      IF  SY-BINPT = SPACE.
        PERFORM MODIFY_SCREEN USING '1' '003' 'INPUTOFF'.
      ENDIF.

* ------ Hinweise -----------------------------------------------------
      IF KLIM-XEXKK = 'X'.
        IF KNKK-KNKLI NE KNA1-KUNNR.
          IF KLIM-XM712 = SPACE.
            MESSAGE S712 WITH KNA1-KUNNR KNKK-KNKLI.
            KLIM-XM712 = 'X'.
          ENDIF.
        ENDIF.
      ELSE.
        IF  KNKK-KNKLI NE KNA1-KUNNR
        AND KNKK-KNKLI NE SPACE.
          MESSAGE S763 WITH KNA1-KUNNR KNKK-KNKLI.
        ENDIF.
      ENDIF.

* ------ Neuaufbau für Kontrollbereich nötig? --------------------------
      IF T014N-KKBER NE SPACE.
        IF KLIM-XM778 = SPACE.
          MESSAGE S778 WITH T014N-KKBER.
          KLIM-XM778 = 'X'.
        ENDIF.
      ENDIF.

* ------ Externe Daten auf subscreen -----------------------------------
    WHEN 1090.

* ------ Felder nicht eingabebereit beim Anzeigen ----------------------
      IF T020-AKTYP = 'A'.
        PERFORM MODIFY_SCREEN_INPUT_OFF.
      ENDIF.
  ENDCASE.

* ------ Interne Bildmodifikation gemäß T055 ---------------------------
  IF SY-DYNNR = 120
  OR SY-DYNNR = 210
  OR SY-DYNNR = 1007
  OR SY-DYNNR = 1090.
    PERFORM X055_BERECHTIGUNG_PRUEFEN.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE DYNSEL_ANZEIGEN                                        *
*---------------------------------------------------------------------*
*       Auf Einstiegsdynpro:                                          *
*       Falls der SPA/GPA 'CDY' sitzt, wird ein Vorschlag             *
*       für die zu bearbeitenden Dynpros gemacht.                     *
*---------------------------------------------------------------------*
MODULE DYNSEL_ANZEIGEN OUTPUT.
  CHECK SY-BINPT NE 'X'.
  GET PARAMETER ID 'CDY' FIELD KLIM-AUSWL.
  GET PARAMETER ID 'CDY' FIELD SAVEDYNPRO.
  CHECK KLIM-AUSWL NE SPACE.

*------- Übersicht -----------------------------------------------------
  PERFORM DYNPRO_ANKREUZEN USING '105'.

*------- Allgemeine Daten ----------------------------------------------
  PERFORM DYNPRO_ANKREUZEN USING '110'.
  PERFORM DYNPRO_ANKREUZEN USING '120'.

*------- Kontrollbereichsdaten -----------------------------------------
  PERFORM DYNPRO_ANKREUZEN USING '210'.
  PERFORM DYNPRO_ANKREUZEN USING '220'.

*------- SUPPRESS DIALOG? ----------------------------------------------
  IF KLIM-AUSWL(1) = 'S'.
    SUPPRESS DIALOG.
    SHIFT KLIM-AUSWL.
    SET PARAMETER ID 'CDY' FIELD KLIM-AUSWL.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE EXCTAB_ERGAENZEN                                      *
*---------------------------------------------------------------------*
*        Bildspezifische Ergänzungen der EXCTAB                       *
*---------------------------------------------------------------------*
MODULE EXCTAB_ERGAENZEN OUTPUT.

* ------ Neuaufbauen nicht auf Zentralbildern -------------------------
* ------ und nicht auf Übersicht, wenn KNKK fehlt ----------------------
  IF SY-DYNNR = 110
  OR SY-DYNNR = 111   "mi/4.5B
  OR SY-DYNNR = 120
  OR ( SY-DYNNR = 105 AND KLIM-XEXKK = 'F' ). "CB 4.6A
    EXCTAB-OKCOD = 'NEUA'. COLLECT EXCTAB.
  ELSE.
    LOOP AT EXCTAB WHERE OKCOD = 'NEUA'.
      DELETE EXCTAB.
    ENDLOOP.
  ENDIF.

* ------ Ändern Referenz nur auf Status-Bild 210 ----------------------
  IF SY-DYNNR = 210.
    LOOP AT EXCTAB WHERE OKCOD = 'EREF'.
      DELETE EXCTAB.
    ENDLOOP.
  ELSE.
    EXCTAB-OKCOD = 'EREF'. COLLECT EXCTAB.
  ENDIF.

* ------ Referenzdebitor nur auf Status-Bild 210 + wenn gesetzt -------
  IF  SY-DYNNR   EQ 210
  AND KNKK-KNKLI NE KNA1-KUNNR.
    LOOP AT EXCTAB WHERE OKCOD = 'REFD'.
      DELETE EXCTAB.
    ENDLOOP.
  ELSE.
    EXCTAB-OKCOD = 'REFD'. COLLECT EXCTAB.
  ENDIF.

* ------ Feldänderungen nicht auf Zahlungsverhaltens-Bild 220 ---------
  IF SY-DYNNR = 220.
    EXCTAB-OKCOD = 'AEFD'. COLLECT EXCTAB.
  ELSE.
    LOOP AT EXCTAB WHERE OKCOD = 'AEFD'.
      DELETE EXCTAB.
    ENDLOOP.
  ENDIF.

* ------ Texte nur auf KKBER-Bildern 210 und 220 ----------------------
  IF SY-DYNNR = 210
  OR SY-DYNNR = 220.
    LOOP AT EXCTAB WHERE OKCOD = 'TEXT'.
      DELETE EXCTAB.
    ENDLOOP.
  ELSE.
    EXCTAB-OKCOD = 'TEXT'. COLLECT EXCTAB.
  ENDIF.

* ------ Keine EXIT-Kommandos im CALL-Modus ---------------------------
  IF SY-CALLD = 'X'.
    EXCTAB-OKCOD = 'EF17'. COLLECT EXCTAB.
    EXCTAB-OKCOD = 'ENXT'. COLLECT EXCTAB.
  ENDIF.

* ------ 'Offener Auftragswert' nur, wenn KNKK existiert --------------
  IF KLIM-XEXKK = SPACE.
    EXCTAB-OKCOD = 'SD  '. COLLECT EXCTAB.
  ENDIF.

* ------ 'Zusatzkomponenten' nur, wenn Open FI aktiv -------------------
  IF OFIWA-XTEXT IS INITIAL.
    EXCTAB-OKCOD = 'OPFI'. COLLECT EXCTAB.
  ENDIF.

* ------ 'Kreditvektor' nur wenn genutzt oder erstellt -----------------
* ------ gleiches gilt für Frühwarnliste -------------------------------
  IF  T000CM-XCVCR IS INITIAL
  AND T000CM-XCVRD IS INITIAL.
    EXCTAB-OKCOD = 'CV  '. COLLECT EXCTAB.
    EXCTAB-OKCOD = 'DK42'. COLLECT EXCTAB.
  ENDIF.

* ------ ARI-Funktionen nur, wenn Partner aktiviert -------------------
  PERFORM ECS_COLLECT_EXCTAB USING '01' 'EC01'.
  PERFORM ECS_COLLECT_EXCTAB USING '02' 'EC02'.
  PERFORM ECS_COLLECT_EXCTAB USING '03' 'EC03'.
  PERFORM ECS_COLLECT_EXCTAB USING '04' 'EC04'.
  PERFORM ECS_COLLECT_EXCTAB USING '05' 'EC05'.
  PERFORM ECS_COLLECT_EXCTAB USING '06' 'EC06'.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE PBO                                                    *
*---------------------------------------------------------------------*
*       Initialisierungen zum PBO-Zeitpunkt.                          *
*       (erstes Modul eines Dynpros)                                  *
*---------------------------------------------------------------------*
MODULE PBO OUTPUT.
  CASE SY-DYNNR.

* ------ Überblick: Anzeigewährungen richtig setzen --------------------
    WHEN 105.
      CLEAR: T001, RF02L-TXT01.
      T001-WAERS = RF02L-WAERB.
      T014-WAERS = RF02L-WAERB.
      RF02L-TXT01 = TEXT-010.
      RF02L-TXT01+30 = ZVPER.
*     RF02L-TXT01+42 = SY-ULINE.
      CONDENSE RF02L-TXT01.

* ------ Kontrollbereich mit max. Einzellimit in Anzeigefeld stellen ---
    WHEN 120.
      *KNKK-KKBER = KLIM-KKBER.

* ------ Status: Anzeigewährung richtig setzen -------------------------
    WHEN 210.
      CLEAR XHORDA.
      T014-WAERS = RF02L-WAERB.

* ------ Texte vorhanden? ----------------------------------------------
      IF TEXT_XUPD = 'X'.                   " Nach Textänderungen
        CLEAR: KLIM-XTEXT.                  " RF02L-XTEXT neu ermitteln
      ENDIF.
      IF KLIM-XTEXT = SPACE.
        CALL FUNCTION 'FI_TEXTS_CREDM'
             EXPORTING  I_OBJECT = 'KNKK'
                        I_AKTYP  = T020-AKTYP
                        I_KUNNR  = KNA1-KUNNR
                        I_KKBER  = RF02L-KKBER
                        I_CHECK  = 'X'
             EXCEPTIONS NO_TEXTS_FOUND = 1.
        IF SY-SUBRC = 1.
          RF02L-XTEXT = ' '.
        ELSE.
          RF02L-XTEXT = 'X'.
        ENDIF.
        KLIM-XTEXT = 'X'.
      ENDIF.

* ------ SUPPRESS DIALOG, wenn nur Textpflege gewünscht (RFDKLI40) -----
      IF IMPPAR-OKCOD(3) = 'TXT'.
        IF KLIM-XSUPR = SPACE.
          OK-CODE = 'TEXT'.
          KLIM-XSUPR = 'X'.
          SUPPRESS DIALOG.
        ELSE.
          CASE IMPPAR-OKCOD+3(1).
            WHEN 'A'. OK-CODE = 'BACK'.
            WHEN 'P'. OK-CODE = 'UPDA'.
          ENDCASE.
          SUPPRESS DIALOG.
        ENDIF.
      ENDIF.

* ------ Zahlungsverhalten: Anzeigewährung richtig setzen --------------
    WHEN 220.
      T001-WAERS = RF02L-WAERB.
  ENDCASE.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE POPUP_MODIFIZIEREN                                     *
*---------------------------------------------------------------------*
*       Modifikationen eines POPUPs.                                  *
*---------------------------------------------------------------------*
MODULE POPUP_MODIFIZIEREN OUTPUT.
  IF SY-DYNNR = 1004
  OR SY-DYNNR = 1005.

  IF gd_init IS INITIAL.
    IF sy-dynnr = 1004.
      kkber_control1-lines = LNMAX.
      kkber_control1-top_line = 1.
      kkber_control1-current_line = 1.
    ELSEIF sy-dynnr = 1005.
      kkber_control-lines = LNMAX.
      kkber_control-top_line = 1.
      kkber_control-current_line = 1.
    ENDIF.
    gd_init = 'X'.
  ENDIF.

* ------ Gibts einen Referenzdebitoren? --------------------------------
    RC = 0.
    LOOP AT VKLTAB WHERE KNKLI NE KNA1-KUNNR.
      RC = 4.
      EXIT.
    ENDLOOP.

* ------ ... Spaltenüberschrift einblenden -----------------------------
    IF RC = 4.
      PERFORM MODIFY_SCREEN USING '3' '001' 'VISIBLE'.
    ENDIF.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE STATUS                                                 *
*---------------------------------------------------------------------*
*       Der Status wird aus Dynpronummer und Dynprogruppe abgeleitet. *
*       Die Dynpronummer bildet die ersten 3 Stellen, der T020-AKTYP  *
*       bildet die 4. Stelle, ausser wenn das Dynpro vom Typ 'A=V'    *
*       (d.h. Anzeigen = Verändern ) ist.                             *
*       (Reine Anzeigedynpros brauchen nur einen Status.)             *
*---------------------------------------------------------------------*
MODULE STATUS OUTPUT.
  UNPACK SY-DYNNR TO STATUS.
* mi/4.5B begin
  IF NOT ZAV_FLAG IS INITIAL.
    REPLACE '0111' WITH '0110' INTO STATUS.
  ENDIF.
* mi/4.5B end
  SHIFT STATUS.
  STATUS+3(1) = T020-AKTYP.

* ------ Open FI -------------------------------------------------------
  DESCRIBE TABLE FKTTAB LINES SY-TFILL.
  IF SY-TFILL > 0.
    XPAAKT = 'X'.
    STATUS(3)   = STATUS+4(3).
    STATUS+4(4) = 'OPFI'.
  ELSE.
    STATUS(3) = STATUS+4(3).
    STATUS+4  = SPACE.
  ENDIF.

* ------ Status setzen -------------------------------------------------
  SET PF-STATUS STATUS EXCLUDING EXCTAB.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE STATUS_EINSTIEG                                        *
*---------------------------------------------------------------------*
*       Die Status unterscheiden sich nach Aktivitätstyp.             *
*---------------------------------------------------------------------*
MODULE STATUS_EINSTIEG OUTPUT.

*------- Callmodus, Batch-Input? --------------------------------------
  REFRESH EXCTAB.
  IF SY-CALLD = 'X'
  OR SY-BINPT = 'X'.
    EXCTAB-OKCOD = 'EANZ'. APPEND EXCTAB.
    EXCTAB-OKCOD = 'EAEN'. APPEND EXCTAB.
  ENDIF.
  PERFORM EXCTAB_FUELLEN_B-I.

*------- Status setzen ------------------------------------------------
  SET PF-STATUS 'STRT' EXCLUDING EXCTAB.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE STATUS_POPUP                                           *
*---------------------------------------------------------------------*
*       Der Status wird aus der Dynprogruppe abgeleitet.              *
*---------------------------------------------------------------------*
MODULE STATUS_POPUP OUTPUT.
  SET PF-STATUS SY-DYNGR.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*        MODULE SUPPRESS_DIALOG                                       *
*---------------------------------------------------------------------*
MODULE SUPPRESS_DIALOG OUTPUT.
  SUPPRESS DIALOG.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE TITEL                                                  *
*---------------------------------------------------------------------*
*       Standard-Bildtitel für Datenbilder                            *
*       ----------------------------------                            *
*       Debitor - Kreditmanagement <F1> : <F2>                        *
*       Titel1 : Ändern / Anzeigen                                    *
*       Titel2 : Bildbeschreibung                                     *
*---------------------------------------------------------------------*
MODULE TITEL OUTPUT.
  CLEAR: TITEL1, TITEL2.

*------- Aktivität (Titel1) --------------------------------------------
  PERFORM TITEL_SETZEN_AKTIVITAET.

*------- Bild-Beschreibung (Titel2) ------------------------------------
  CASE SY-DYNNR.
*    WHEN 110. titel2 = text-a10.          "mi/4.5B
    WHEN 110 OR 111. TITEL2 = TEXT-A10.    "mi/4.5B
    WHEN 120. TITEL2 = TEXT-A20.
    WHEN 105. TITEL2 = TEXT-K05.
    WHEN 210. TITEL2 = TEXT-K10.
    WHEN 220. TITEL2 = TEXT-K20.
  ENDCASE.
  SET TITLEBAR 'T01' WITH TITEL1 TITEL2.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE TITEL_EINSTIEG                                         *
*---------------------------------------------------------------------*
*       Bildtitel für Einstiegsbild                                   *
*---------------------------------------------------------------------*
*       Debitor-Kreditmanagement <F1>: Einstieg                       *
*       Titel1 : Ändern / Anzeigen                                    *
*---------------------------------------------------------------------*
MODULE TITEL_EINSTIEG OUTPUT.
  CLEAR: TITEL1.

*------- Aktivität -----------------------------------------------------
  PERFORM TITEL_SETZEN_AKTIVITAET.
  SET TITLEBAR 'T00' WITH TITEL1.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE TITEL_POPUP                                            *
*---------------------------------------------------------------------*
*       Bildtitel für POPUP.                                          *
*---------------------------------------------------------------------*
MODULE TITEL_POPUP OUTPUT.
  CASE SY-DYNNR.
    WHEN 1001. POPUP_TITEL1 = TEXT-U10.
    WHEN 1002. POPUP_TITEL1 = TEXT-U20.
    WHEN 1003. POPUP_TITEL1 = TEXT-U30.
    WHEN 1004. POPUP_TITEL1 = TEXT-U40.
    WHEN 1005. POPUP_TITEL1 = TEXT-U50.
    WHEN 1006. POPUP_TITEL1 = TEXT-U60.
    WHEN 1007. POPUP_TITEL1 = TEXT-U70.
    WHEN 1008. POPUP_TITEL1 = TEXT-U80.
    WHEN 1009. POPUP_TITEL1 = TEXT-U90.
    WHEN 1010. POPUP_TITEL1 = TEXT-U91.
    WHEN 1011. POPUP_TITEL1 = TEXT-U92.
    WHEN 1014. POPUP_TITEL1 = TEXT-U94.
  ENDCASE.
  IF SY-DYNNR = 1001
  OR SY-DYNNR = 1002.
    SET TITLEBAR 'T02' WITH KLIM-BUKRS POPUP_TITEL1.
  ELSE.
    SET TITLEBAR 'T03' WITH POPUP_TITEL1.
  ENDIF.
ENDMODULE.

*eject
*---------------------------------------------------------------------*
*       MODULE TRANSAKTIONS_INIT OUTPUT                               *
*---------------------------------------------------------------------*
*       Lesen der Tabellen T020 und TSTCT.                            *
*       GPA                                                           *
*---------------------------------------------------------------------*
MODULE TRANSAKTIONS_INIT OUTPUT.
  PERFORM ALLES_INITIALISIEREN.
  PERFORM DB_INIT.
*------- Tabelle T000CM lesen (Verteiltes Kreditmanagement) ------------
  SELECT SINGLE * FROM T000CM.

*------- Tabelle T020 lesen --------------------------------------------
  IF T020-TCODE NE SY-TCODE.
    SELECT SINGLE * FROM  T020
                    WHERE TCODE = SY-TCODE.
    IF SY-SUBRC   NE 0
    OR T020-AKTYP CN 'AV'
    OR T020-DYNCL NE 'C'
    OR T020-FUNCL CN ' M'.
      MESSAGE A307 WITH SY-TCODE.
    ENDIF.
  ENDIF.

*------- Massenänderung nur über Report RFDKLI50 -----------------------
  IF  T020-FUNCL NE SPACE
  AND SY-CALLD   EQ SPACE.
    MESSAGE A308 WITH 'TRANSAKTIONS_INIT' T020-FUNCL.
  ENDIF.

*------- IMPORT-Parameter (aus RFDKLI40)? ------------------------------
  CLEAR: IMPPAR.
  IMPORT IMPPAR FROM MEMORY ID 'SAPMF02C/IMPPAR'.

*------- Aktivitätstyp für Berechtigungsprüfung setzen -----------------
  CASE T020-AKTYP.
    WHEN 'A'.
      ACTVT = '03'.
    WHEN 'V'.
      ACTVT = '02'.
  ENDCASE.

*------- AKTYP für Open FI ins Memory stellen (Input off auf subscreens)
  EXPORT AKTYP FROM T020-AKTYP TO MEMORY ID 'SAPMF02C/AKTYP'.

*------- Open FI aktiv? Funktionstext ermitteln, wenn eindeutig --------
  CALL FUNCTION 'OPEN_FI_PERFORM_00001550_E'
       IMPORTING
            E_ABEZ   = OFIWA-XTEXT
       TABLES
            T_FTEXTS = FTEXTSTAB.
  DESCRIBE TABLE FTEXTSTAB LINES SY-TFILL.
  IF SY-TFILL = 1.
    READ TABLE FTEXTSTAB INDEX 1.
    OFIWA-FTEXT = FTEXTSTAB-FTEXT.
  ELSE.
    OFIWA-FTEXT = TEXT-F01.
  ENDIF.

*------- ACHTUNG: Nur weiter, wenn Initialisierung noch nicht vorbei ---
  CHECK KLIM-XINIT = SPACE.

*------- Kennzeichen 'Initialisierung durchgeführt' setzen -------------
  IF KLIM-XINIT = SPACE.
    KLIM-XINIT = 'X'.
  ENDIF.
  PERFORM ECS_INITIALISIEREN.

*------- GPA fuer Kredit-Kontrollbereich und Konto ---------------------
*------- Falls sy-binpt = 'X' wird RF02L-KUNNR später mit den ----------
*------- übergegebenen Daten wieder überschrieben ----------------------
  GET PARAMETER ID 'KUN' FIELD RF02L-KUNNR.                      "157555
  IF SY-BINPT = SPACE.
    GET PARAMETER ID 'KKB' FIELD RF02L-KKBER.
*   GET PARAMETER ID 'KUN' FIELD RF02L-KUNNR.                    "157555
  ENDIF.

*------- Massenänderung? -----------------------------------------------
  IMPORT AUSTAB NEU FROM MEMORY ID 'SAPMF02C/MASS'.
  CHECK SY-SUBRC = 0.

*------- Zu ändernde Stammsätze gemäß AUSTAB abarbeiten ----------------
  LOOP AT AUSTAB WHERE AKTIV NE SPACE.

* ------- Initialisierung ----------------------------------------------
    CLEAR: KLIM.
    RF02L-KUNNR = AUSTAB-KNKLI.
    RF02L-KKBER = AUSTAB-KKBER.

* ------- Einlesen / Sperren -------------------------------------------
    PERFORM DEBITORENSTAMM_LESEN.
    PERFORM SPERREN.                   " dort T020-FUNCL abfragen??

* ------- Sperren erfolgreich? -> Verarbeiten --------------------------
    CLEAR: PROTAB.
    IF RC = 4.
      PROTAB-SUBRC = 4.
      PROTAB-MSGTY = 'E'.
    ELSE.
      KNKK-NXTRV = NEU-NXTRV.

* ------ Nächste Prüfung vor letzter Prüfung? -------------------------
      IF  NOT KNKK-NXTRV IS INITIAL
      AND     KNKK-NXTRV LT KNKK-DTREV.
        MESSAGE S771.
        PROTAB-SUBRC = 4.
        PROTAB-MSGTY = 'E'.
      ENDIF.

* ------- Änderung durchführen -----------------------------------------
      IF PROTAB-SUBRC = 0.
        PERFORM CHECK_AENDERUNGEN.
        PERFORM SCHLUSS_BEARBEITUNG.
        PROTAB-SUBRC = SY-SUBRC.
        PROTAB-MSGTY = SY-MSGTY.
      ENDIF.
    ENDIF.

* ------- Returncode in AUSTAB merken ----------------------------------
    PROTAB-KNKLI = AUSTAB-KNKLI.
    PROTAB-KKBER = AUSTAB-KKBER.
    PROTAB-MSGID = SY-MSGID.
    PROTAB-MSGNO = SY-MSGNO.
    PROTAB-MSGV1 = SY-MSGV1.
    PROTAB-MSGV2 = SY-MSGV2.
    PROTAB-MSGV3 = SY-MSGV3.
    PROTAB-MSGV4 = SY-MSGV4.
    APPEND PROTAB.
  ENDLOOP.

* ------- Abschließender COMMIT WORK -----------------------------------
  COMMIT WORK.

* ------- Protokoll dem Rufer (RFDKLI50) zurückgeben -------------------
  EXPORT PROTAB TO   MEMORY ID 'SAPMF02C/MASSPROT'.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.


*mi/4.5B begin
*&---------------------------------------------------------------------*
*&      Module  ZAV_VORBEREITEN  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE ZAV_VORBEREITEN OUTPUT.
  DATA: FELDLEISTE(200) VALUE SPACE.

  TRANSLATE FELDLEISTE USING ' *'.
  PERFORM ZAV_VORBEREITEN USING FELDLEISTE.

  READ_ADDRESS-MASTER_TAB   = 'KNA1'.
  READ_ADDRESS-MASTER_FIELD = 'ADRNR'.
  READ_ADDRESS-KEY_CONTENT  = KNA1-KUNNR.
  READ_ADDRESS-NUMBER       = KNA1-ADRNR.
  CLEAR READ_PERSON.
*  IF t020-aktyp = 'H'.
*    conversion = c_no_conversion.
*  ELSE.
*    conversion = c_conversion.
*  ENDIF.

* Anlegen Betrieb
  IF NOT DEBI_CALL IS INITIAL AND KNA1-ADRNR IS INITIAL.
    CLEAR READ_ADDRESS.
    READ_ADDRESS-MASTER_TAB = S_HANDLE.
  ENDIF.

  PERFORM ZAV_LESEN USING  READ_ADDRESS     READ_PERSON
                           C_TYPE_1         C_INIT
                           C_NO_CONVERSION  C_MAINTAIN
                           C_EXPORT         C_NO_REFERENCE.

ENDMODULE.                 " ZAV_VORBEREITEN  OUTPUT
*mi/4.5B end
