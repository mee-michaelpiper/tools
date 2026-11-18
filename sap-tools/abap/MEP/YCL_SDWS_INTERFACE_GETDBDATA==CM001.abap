  METHOD APPEND_HEADER_DATA.

    DATA: ls_header     TYPE ysdws_comhdr_s.

    ls_header-qualif = i_qualifier.
    WRITE i_fvalue TO ls_header-fvalue.

    APPEND ls_header TO rt_export.

  ENDMETHOD.
