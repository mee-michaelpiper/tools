*&---------------------------------------------------------------------*
*& Report  YSDWS_DELETE_DBTAGLOG
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT ysdws_delete_dbtaglog_loop.

DATA gl_date type d.
DATA gl_time TYPE sytime.
DATA lv_logtime TYPE sytime.

PARAMETERS pa_von TYPE d OBLIGATORY.
PARAMETERS pa_bis TYPE d DEFAULT sy-datum OBLIGATORY.
PARAMETERS pa_dbcnt TYPE syst-dbcnt DEFAULT 1000 OBLIGATORY.
PARAMETERS pa_sec TYPE syst-dbcnt DEFAULT 2 OBLIGATORY.
AT SELECTION-SCREEN.
  IF pa_von GT pa_bis.
    MESSAGE s027(ysdws_interface) WITH 'Ungültige eingabe!'.
  ENDIF.

START-OF-SELECTION.
  gl_date = pa_von - 1 .


  WHILE gl_date LE pa_bis.    "täglich

    ADD 1 TO gl_date.
    SELECT logtime INTO lv_logtime
      UP TO pa_dbcnt ROWS
       FROM dbtablog WHERE logdate = gl_date
       AND ( tabname = 'YSDWS_LOG_TIME' " Webshop: Log /
          OR tabname = 'YSDWS_LOG_VALUE'
          or tabname = 'YCA_IO_DT_OPL' )
      ORDER BY logtime.
    ENDSELECT.


    IF sy-subrc NE 0.
      MESSAGE s027(ysdws_interface)
      WITH gl_date 'keine Datensätze selektiert ' 'DBTABLOG!'.
      CONTINUE.
    ENDIF.
    CLEAR: sy-subrc, gl_time.

    WHILE sy-subrc EQ 0.

      SELECT logtime INTO lv_logtime
        UP TO pa_dbcnt ROWS
         FROM dbtablog WHERE logdate = gl_date
         AND ( tabname = 'YSDWS_LOG_TIME' " Webshop: Log /
            OR tabname = 'YSDWS_LOG_VALUE'
            or tabname = 'YCA_IO_DT_OPL'
            or tabname = 'YCA_IO_DT_OPLV'  )
        ORDER BY logtime.
      ENDSELECT.

      CHECK sy-subrc EQ 0.

      SUBMIT ysdws_delete_dbtaglog
       WITH pa_date = gl_date
       WITH pa_time = lv_logtime
        AND RETURN.
      WAIT UP TO pa_sec SECONDS.
    ENDWHILE.

  ENDWHILE.
