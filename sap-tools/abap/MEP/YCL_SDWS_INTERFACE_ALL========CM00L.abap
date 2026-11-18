  METHOD check_for_existing_sessionid.

    " Prüfung auf eindeutige Session-ID in Logtabelle
    " (auch wenn regelmässig reorganisiert)
    SELECT SINGLE mandt INTO @DATA(lv_mandt)
    FROM ysdws_log_time
    WHERE interface =  @ms_log_time-interface
      and session_id = @iv_sessionid.

    IF sy-subrc = 0.

      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid        = ycx_sdws_interface=>sessionid_exist
          mv_session_id = iv_sessionid.

    ENDIF.

  ENDMETHOD.
