  METHOD SET_RUN_MODE.
    IF iv_modein EQ space.
      rv_modout = abap_true.
    ELSE.
      rv_modout = space.
    ENDIF.
  ENDMETHOD.
