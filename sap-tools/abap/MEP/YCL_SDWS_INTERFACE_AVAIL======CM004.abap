  METHOD availability_plausi_check.

*    " Sprache prüfen und ggf. setzen!
*    ycl_sdws_interface_all=>get_instance( )->check_iso_langu( cs_import-i_langu ).

    ycl_sdws_interface_all=>get_instance( )->check_session_id( cs_import-i_sessionid ).

    DATA(lv_kun_werks) = ycl_sdws_interface_all=>get_instance( )->check_kunnr(
                            EXPORTING iv_kunnr = cs_import-i_kunnr
                                      iv_vkorg = cs_import-i_vkorg
                                      iv_vtweg = cs_import-i_vtweg
                                      iv_spart = cs_import-i_spart ).

    IF cs_import-i_werks IS NOT INITIAL.
      ycl_sdws_interface_all=>get_instance( )->check_werks( cs_import-i_werks ).
    ENDIF.

    LOOP AT cs_import-it_mat ASSIGNING FIELD-SYMBOL(<ls_mat>).

      " Kein Werk je Mat. migegeben, Kunden-Lieferwerk übergeben.
      IF <ls_mat>-i_werks IS INITIAL.
        IF cs_import-i_werks IS NOT INITIAL.
          <ls_mat>-i_werks = cs_import-i_werks.
        ELSE.
          <ls_mat>-i_werks = lv_kun_werks.
        ENDIF.
      ENDIF.

      ycl_sdws_interface_all=>get_instance( )->check_werks( <ls_mat>-i_werks ).

      ycl_sdws_interface_all=>get_instance( )->check_matnr( <ls_mat>-i_matnr ).

      ycl_sdws_interface_all=>get_instance( )->check_matnr_werks( iv_matnr = <ls_mat>-i_matnr
                                                 iv_werks = <ls_mat>-i_werks ).

      ycl_sdws_interface_all=>get_instance( )->check_iso_code_unit( <ls_mat>-i_vrkme ).

    ENDLOOP.

  ENDMETHOD.
