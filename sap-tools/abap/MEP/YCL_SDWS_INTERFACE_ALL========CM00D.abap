  METHOD start_log.

    DATA lv_timestampl TYPE timestampl.

    mv_interface = ms_log_time-interface  = iv_interface.
    ms_log_time-datum      = sy-datlo.
    ms_log_time-session_id = iv_session_id.

    GET TIME STAMP FIELD lv_timestampl.

    WRITE lv_timestampl TIME ZONE 'UTC' TO ms_log_time-timestamp_request.

  ENDMETHOD.
