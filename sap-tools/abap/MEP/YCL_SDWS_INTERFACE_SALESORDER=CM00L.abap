  METHOD set_run_mode.
    IF iv_modein EQ space.
      rv_modout = abap_true.
    ELSE.
      rv_modout = space.
    ENDIF.
  ENDMETHOD.
