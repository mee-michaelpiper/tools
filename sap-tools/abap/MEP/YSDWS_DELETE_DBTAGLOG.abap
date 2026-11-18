*&---------------------------------------------------------------------*
*& Report  YSDWS_DELETE_DBTAGLOG
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT ysdws_delete_dbtaglog.
TABLES dbtablog.
"SELECT-OPTIONS so_date FOR dbtablog-logdate.
PARAMETERS pa_date LIKE dbtablog-logdate.
PARAMETERS pa_time like dbtablog-LOGTIME.

START-OF-SELECTION.

  DELETE FROM dbtablog WHERE logdate = pa_date
  and LOGTIME le pa_time
  AND ( tabname = 'YSDWS_LOG_TIME' " Webshop: Log / Protokoll-Tabelle mit Zeitangaben
  OR tabname = 'YSDWS_LOG_VALUE'
  or tabname = 'YCA_IO_DT_OPLV'
  or tabname = 'YCA_IO_DT_OPL' ). " Webshop: Log / Protokoll-Tabelle mit Werten

  IF sy-subrc EQ 0.
    COMMIT WORK AND WAIT.
    MESSAGE s027(ysdws_interface)
      WITH pa_date pa_time sy-dbcnt 'Datensätze aus DBTABLOG gelöscht!'.
  ELSE.
    MESSAGE s027(ysdws_interface)
      WITH pa_date pa_time 'keine Datensätze selektiert ' 'DBTABLOG!'.
  ENDIF.
