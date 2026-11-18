  method SET_SCREEN.

    if ms_tnapr-formtype = '2'.
      re_screen = 'W'.
    else.
      re_screen = abap_true.
    endif.

  endmethod.
