  METHOD check_session_id.

    IF iv_sessionid IS INITIAL.

      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ycx_sdws_interface=>empty_sessionid.

    ENDIF.

*   prüfen ob Aufrufer bekannt und aktivert ist                 FISTL
    check_caller( iv_sessionid ).                              "FISTL

    enqueue_session_id( iv_session_id = iv_sessionid ).

    check_for_existing_sessionid( iv_sessionid ).

  ENDMETHOD.
