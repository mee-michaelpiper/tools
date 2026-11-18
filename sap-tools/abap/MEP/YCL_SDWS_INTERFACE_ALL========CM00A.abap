  METHOD dequeue_session_id.

    IF iv_session_id IS NOT INITIAL.

      CALL FUNCTION 'DEQUEUE_EYSDWS_SESSIONID'
        EXPORTING
*         mode_ysdws_sessionids = 'E'    " Sperrmodus zur Tabelle YSDWS_SESSIONIDS
*         mandt      = SY-MANDT    " 01. Enqueue Argument
          session_id = iv_session_id    " 02. Enqueue Argument
*         x_session_id          = SPACE    " Argument 02 mit Initialwert belegen?
*         _scope     = '3'
*         _synchron  = SPACE    " Synchron entsperren
*         _collect   = ' '    " Sperre zunächst nur Sammeln
        .

    ENDIF.
  ENDMETHOD.
