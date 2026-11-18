  METHOD check_for_initial_meng.
    IF iv_menge IS INITIAL.
      " Die Menge ist unbefüllt!
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ycx_sdws_interface=>initial_meng.
    ENDIF.
  ENDMETHOD.
