FUNCTION z_sise_creditlimit_set.
*"----------------------------------------------------------------------
*" Kreditlimit (KNKK-KLIMK) eines Kunden je Kreditkontrollbereich setzen
*" – per RFC aus dem SiSe-Portal (SAP-API). Macht dasselbe wie FD32 beim
*" Sichern (SAPMF02C, FORM SCHLUSS_BEARBEITUNG):
*"   Sperre EXKNKA, Änderungsbeleg KLIM (KLIM_WRITE_DOCUMENT),
*"   CREDITLIMIT_CHANGE in der Verbuchung, COMMIT WORK AND WAIT.
*"
*" Funktionsgruppe: z. B. ZSISE_CREDIT   Abwicklungsart: REMOTEFÄHIG
*" Alle Parameter "Wertübergabe" (Pflicht bei RFC).
*"
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(IV_KUNNR) TYPE  KUNNR
*"     VALUE(IV_KKBER) TYPE  KKBER DEFAULT '298'
*"     VALUE(IV_KLIMK) TYPE  KLIMK
*"     VALUE(IV_USERNAME) TYPE  CDUSERNAME OPTIONAL
*"     VALUE(IV_TESTRUN) TYPE  XFELD DEFAULT SPACE
*"  EXPORTING
*"     VALUE(EV_KLIMK_OLD) TYPE  KLIMK
*"     VALUE(EV_KLIMK_NEW) TYPE  KLIMK
*"     VALUE(EV_WAERS) TYPE  WAERS
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
* IV_USERNAME: SAP-Benutzer der Person im Portal (optional). Steht dann als
*              Änderer im Änderungsbeleg statt des RFC-Benutzers.
* IV_TESTRUN:  'X' = nur prüfen, nichts ändern.
* Neu angelegt wird nichts: Der Kunde braucht bereits einen KNKK-Satz im
* Kreditkontrollbereich (entsteht bei der Neuanlage vom Musterkunden).

  DATA: lv_kunnr      TYPE kunnr,
        ls_t014       TYPE t014,
        ls_knka       TYPE knka,
        ls_knkk_old   TYPE knkk,
        ls_knkk_new   TYPE knkk,
        ls_xf02c      TYPE xf02c,
        lv_upd_knka   TYPE cdpos-chngind,
        lv_upd_knkk   TYPE cdpos-chngind,
        lv_username   TYPE cdusername,
        lv_objectid   TYPE cdhdr-objectid,
        lv_klimk_txt  TYPE char20,
        lv_old_txt    TYPE char20.

  CLEAR: ev_klimk_old, ev_klimk_new, ev_waers.
  REFRESH et_return.

  lv_kunnr = iv_kunnr.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_kunnr
    IMPORTING
      output = lv_kunnr.

*------- Eingaben prüfen -------------------------------------------------
  IF iv_klimk < 0.
    PERFORM add_return TABLES et_return USING 'E' 'Kreditlimit darf nicht negativ sein.' '' '' ''.
    RETURN.
  ENDIF.

  SELECT SINGLE * FROM t014 INTO ls_t014 WHERE kkber = iv_kkber.
  IF sy-subrc <> 0.
    PERFORM add_return TABLES et_return USING 'E' 'Kreditkontrollbereich' iv_kkber 'gibt es nicht.' ''.
    RETURN.
  ENDIF.
  ev_waers = ls_t014-waers.

  SELECT SINGLE kunnr FROM kna1 INTO lv_kunnr WHERE kunnr = lv_kunnr.
  IF sy-subrc <> 0.
    PERFORM add_return TABLES et_return USING 'E' 'Kunde' lv_kunnr 'gibt es nicht.' ''.
    RETURN.
  ENDIF.

*------- Berechtigung: Kreditkontrollbereich ändern (wie FD32) -----------
  AUTHORITY-CHECK OBJECT 'F_KNKA_KKB'
    ID 'KKBER' FIELD iv_kkber
    ID 'ACTVT' FIELD '02'.
  IF sy-subrc <> 0.
    PERFORM add_return TABLES et_return USING 'E' 'Keine Berechtigung, Kreditlimits im Kreditkontrollbereich' iv_kkber 'zu ändern.' ''.
    RETURN.
  ENDIF.

*------- Sperren (wie FD32, FORM SPERREN) --------------------------------
  CALL FUNCTION 'ENQUEUE_EXKNKA'
    EXPORTING
      kunnr          = lv_kunnr
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.
  IF sy-subrc = 1.
    PERFORM add_return TABLES et_return USING 'E' 'Kreditdaten des Kunden' lv_kunnr 'sind gesperrt von' sy-msgv1.
    RETURN.
  ELSEIF sy-subrc <> 0.
    PERFORM add_return TABLES et_return USING 'E' 'Sperre für Kunde' lv_kunnr 'nicht möglich.' ''.
    RETURN.
  ENDIF.

*------- Alte Daten lesen (erst nach der Sperre) -------------------------
  SELECT SINGLE * FROM knkk INTO ls_knkk_old
    WHERE kunnr = lv_kunnr AND kkber = iv_kkber.
  IF sy-subrc <> 0.
    PERFORM dequeue USING lv_kunnr.
    PERFORM add_return TABLES et_return USING 'E' 'Kunde' lv_kunnr 'hat keine Kreditdaten im Bereich' iv_kkber.
    RETURN.
  ENDIF.
  ev_klimk_old = ls_knkk_old-klimk.

  SELECT SINGLE * FROM knka INTO ls_knka WHERE kunnr = lv_kunnr.
  IF sy-subrc <> 0.
    " Übergreifende Kreditdaten fehlen (sollte es bei vorhandenem KNKK nicht geben) -> wie FD32 mit anlegen
    CLEAR ls_knka.
    ls_knka-kunnr = lv_kunnr.
    ls_knka-waers = ls_t014-waers.
    lv_upd_knka   = 'I'.
  ENDIF.

  " Maximales Einzellimit (KNKA-KLIME) beachten, wie FD32
  IF ls_knka-klime > 0 AND iv_klimk > ls_knka-klime.
    PERFORM dequeue USING lv_kunnr.
    WRITE ls_knka-klime TO lv_klimk_txt CURRENCY ls_knka-waers LEFT-JUSTIFIED.
    PERFORM add_return TABLES et_return USING 'E' 'Kreditlimit über dem maximalen Einzellimit' lv_klimk_txt ls_knka-waers ''.
    RETURN.
  ENDIF.

  IF ls_knkk_old-klimk = iv_klimk.
    PERFORM dequeue USING lv_kunnr.
    ev_klimk_new = iv_klimk.
    PERFORM add_return TABLES et_return USING 'S' 'Kreditlimit ist bereits gesetzt, keine Änderung.' '' '' ''.
    RETURN.
  ENDIF.

*------- Neue Daten (Rest des Satzes bleibt, auch CASH-Felder) -----------
  ls_knkk_new       = ls_knkk_old.
  ls_knkk_new-klimk = iv_klimk.
  ls_knkk_new-aedat = sy-datum.
  ls_knkk_new-aenam = sy-uname.
  IF ls_knkk_new-knkli IS INITIAL.
    ls_knkk_new-knkli = ls_knkk_new-kunnr.  " wie FD32: KNKLI sicherheitshalber setzen
  ENDIF.
  lv_upd_knkk = 'U'.
  ev_klimk_new = iv_klimk.

  WRITE ls_knkk_old-klimk TO lv_old_txt   CURRENCY ls_t014-waers LEFT-JUSTIFIED.
  WRITE iv_klimk          TO lv_klimk_txt CURRENCY ls_t014-waers LEFT-JUSTIFIED.

  IF iv_testrun = 'X'.
    PERFORM dequeue USING lv_kunnr.
    PERFORM add_return TABLES et_return USING 'S' 'Testlauf: Kreditlimit würde geändert von' lv_old_txt 'auf' lv_klimk_txt.
    RETURN.
  ENDIF.

*------- Änderungsbeleg KLIM (wie FD32, FORM CD_CALL_KLIM) ---------------
  lv_username = sy-uname.
  IF iv_username IS NOT INITIAL.
    SELECT SINGLE bname FROM usr02 INTO lv_username WHERE bname = iv_username.
    IF sy-subrc <> 0.
      lv_username = sy-uname.
      PERFORM add_return TABLES et_return USING 'W' 'SAP-Benutzer' iv_username 'unbekannt, Änderer ist' sy-uname.
    ENDIF.
  ENDIF.

  lv_objectid       = lv_kunnr.
  ls_xf02c-t014waers = ls_t014-waers.

  CALL FUNCTION 'KLIM_WRITE_DOCUMENT' IN UPDATE TASK
    EXPORTING
      objectid                = lv_objectid
      tcode                   = 'FD32'
      utime                   = sy-uzeit
      udate                   = sy-datum
      username                = lv_username
      object_change_indicator = 'U'
      o_yknka                 = ls_knka
      n_knka                  = ls_knka
      upd_knka                = lv_upd_knka
      o_yknkk                 = ls_knkk_old
      n_knkk                  = ls_knkk_new
      o_xf02c                 = ls_xf02c
      n_xf02c                 = ls_xf02c
      upd_knkk                = lv_upd_knkk.

*------- Ändern (Verbuchungsbaustein, wie FD32) --------------------------
  CALL FUNCTION 'CREDITLIMIT_CHANGE' IN UPDATE TASK
    EXPORTING
      i_knka   = ls_knka
      i_knkk   = ls_knkk_new
      upd_knka = lv_upd_knka
      upd_knkk = lv_upd_knkk
      yknka    = ls_knka
      yknkk    = ls_knkk_old
      xneua    = space
      xrefl    = space.

  COMMIT WORK AND WAIT.
  IF sy-subrc <> 0.
    PERFORM dequeue USING lv_kunnr.
    PERFORM add_return TABLES et_return USING 'E' 'Verbuchung fehlgeschlagen (SM13 prüfen).' '' '' ''.
    RETURN.
  ENDIF.

  PERFORM dequeue USING lv_kunnr.
  PERFORM add_return TABLES et_return USING 'S' 'Kreditlimit geändert von' lv_old_txt 'auf' lv_klimk_txt.

ENDFUNCTION.

*----------------------------------------------------------------------*
* In ein Include der Funktionsgruppe (z. B. LZSISE_CREDITF01)
*----------------------------------------------------------------------*
FORM add_return TABLES ct_return STRUCTURE bapiret2
                USING  iv_type TYPE bapi_mtype
                       iv_v1 iv_v2 iv_v3 iv_v4.
  DATA ls_return TYPE bapiret2.
  ls_return-type       = iv_type.
  ls_return-id         = '00'.
  ls_return-number     = '001'.          " &1&2&3&4&5&6&7&8
  ls_return-message_v1 = iv_v1.
  ls_return-message_v2 = iv_v2.
  ls_return-message_v3 = iv_v3.
  ls_return-message_v4 = iv_v4.
  CONCATENATE iv_v1 iv_v2 iv_v3 iv_v4 INTO ls_return-message SEPARATED BY space.
  CONDENSE ls_return-message.
  APPEND ls_return TO ct_return.
ENDFORM.

FORM dequeue USING iv_kunnr TYPE kunnr.
  CALL FUNCTION 'DEQUEUE_EXKNKA'
    EXPORTING
      kunnr = iv_kunnr.
ENDFORM.
