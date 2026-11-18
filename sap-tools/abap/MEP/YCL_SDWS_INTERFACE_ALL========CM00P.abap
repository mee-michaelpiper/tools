  METHOD set_attribut.

*    " Sprache prüfen und ggf. setzen!
*    check_iso_langu( is_import-i_langu ).

    check_session_id( is_import-i_sessionid ).

    mv_set_all_output_data = is_import-i_all_detail.

  ENDMETHOD.
