  METHOD enqueue_session_id.

    CALL FUNCTION 'ENQUEUE_EYSDWS_SESSIONID'
      EXPORTING
        mode_ysdws_sessionids = 'E'    " Sperrmodus zur Tabelle YSDWS_SESSIONIDS
*       mandt                 = SY-MANDT    " 01. Enqueue Argument
        session_id            = iv_session_id    " 02. Enqueue Argument
*       x_session_id          = SPACE    " Argument 02 mit Initialwert belegen?
*       _scope                = '2'
*       _wait                 = SPACE
*       _collect              = ' '    " Sperre zunächst nur Sammeln
      EXCEPTIONS
        foreign_lock          = 1
        system_failure        = 2
        OTHERS                = 3.
    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid        = ycx_sdws_interface=>sessionid_enqueued
          mv_session_id = iv_session_id
*         previous      =
        .

    ENDIF.
  ENDMETHOD.
