*----------------------------------------------------------------------*
* Programmname:   YSDWS_DELETE_LOG
* Entwickler:     Erwin Ulrich
* Datum:          01.04.2017
*
* Beschreibung:   Löschprogramm für die beiden Logtabellen zum Webshop
*
*                 YSDWS_LOG_TIME + YSDWS_LOG_VALUE
*
*                 FIS/OSS: 239253
*----------------------------------------------------------------------*
* Änderungshistorie: (alt nach neu)
*Entwickler Datum                                                  Patch
*Beschreibung                              (K)orrektur (C)hangereq OssNr
*----------------------------------------------------------------------*

REPORT ysdws_delete_log.

INCLUDE ysdws_delete_log_top.
INCLUDE ysdws_delete_log_sel.

START-OF-SELECTION.

  IF so_datum[] IS NOT INITIAL OR so_guid[] IS NOT INITIAL.
    CLEAR gt_time[].
    SELECT * INTO TABLE gt_time        "#EC CI_NOFIRST
      FROM ysdws_log_time
      WHERE guid  IN so_guid
      AND   datum IN so_datum.
    IF sy-subrc = 0.
      DATA(lv_lines) = lines( gt_time ).
      CALL FUNCTION 'Y_SDWS_LOG_VB_DELETE' IN UPDATE TASK
        EXPORTING
          it_delete_log_time = gt_time[].
      COMMIT WORK.
      " Es wurden &1 Sätze aus der Tabelle YSDWS_LOG_TIME + abhängige gelöscht!
      MESSAGE i020(ysdws_interface) WITH lv_lines.
    ELSE.
      " Es wurden keine Sätze in Tabelle YSDWS_LOG_TIME gefunden!
      MESSAGE i021(ysdws_interface).
    ENDIF.
  ELSE.
    " Bitte Datum oder GUID befüllen!
    MESSAGE i022(ysdws_interface) DISPLAY LIKE 'E'.
  ENDIF.
