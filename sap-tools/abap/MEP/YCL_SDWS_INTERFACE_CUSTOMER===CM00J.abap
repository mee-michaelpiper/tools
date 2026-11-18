  METHOD get_offers_data.

    set_import_data_range( ).
    mv_trvog = '2'.

    mt_vbl_glt = get_vbeln_vakgu( ).
    mt_vbl_glt = get_vbeln_vmvaa( ).
    mt_vbl_glt = get_vbeln_vapma( ).
    mt_vbl_glt = get_vbeln_vakpa( ).
    mt_vbl_glt = compare_seloption( ).

    CHECK mt_vbl_glt[] IS INITIAL.

    " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = 'Angebote'(002).

  ENDMETHOD.
