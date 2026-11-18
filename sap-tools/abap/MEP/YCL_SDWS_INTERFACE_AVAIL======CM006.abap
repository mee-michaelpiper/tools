  METHOD plant_atp_determine.

    DATA lo_error TYPE REF TO ycx_sdws_interface.
    DATA ls_kond TYPE  ysdws_plant_atp_mat_e_s.
    DATA ls_import TYPE ysdws_plant_atp_determine_i_s.
    DATA ls_return TYPE ysdws_return_e_s.
    DATA yls_plant TYPE yif_ex_badi_find_plant=>ty_s_selvar.


    ls_import = is_import.

    TRY.

        es_export-e_sessionid = ls_import-i_sessionid.

        me->convert_ext2int( CHANGING cs_values = ls_import-hdr ).

        get_default_values( CHANGING  cs_zielstr = ls_import-hdr ).

        fetch_kuwe2( is_vtcom = CORRESPONDING #( ls_import-hdr MAPPING kunnr = i_kunnr vkorg = i_vkorg vtweg = i_vtweg spart = i_spart ) ).
        MOVE-CORRESPONDING ms_knvv TO yls_plant.
        CLEAR yls_plant-dwerk.

        LOOP AT ls_import-it_mat ASSIGNING FIELD-SYMBOL(<fs_mat>).
          CLEAR ls_kond.

          convert_ext2int( CHANGING cs_values = <fs_mat> ).
          fetch_maapv( is_mtcom = VALUE #( matnr = <fs_mat>-i_matnr vkorg = ls_import-i_vkorg vtweg = ls_import-i_vtweg ) ).
          IF <fs_mat>-i_werks IS INITIAL.
            DATA(ls_attr) = CORRESPONDING ty_s_attr_werks_determin( ls_import-hdr ).
            ls_attr-matnr = <fs_mat>-i_matnr.
*            <fs_mat>-i_werks = determination_plant( is_attr = ls_attr ).                      "C415062
            MOVE-CORRESPONDING ms_maapv TO yls_plant-i.

            <fs_mat>-i_werks = NEW ycl_sdpf_finding_plant( )->get_with_all_routines( is_data = yls_plant ). "C415062
            "value #( kunnr = is_import-i_kunnr matnr = <fs_mat>-i_matnr vkorg = ls_import-i_vkorg vtweg = ls_import-i_vtweg  ) ).      "C415062
          ENDIF.

          fetch_maepv(  is_mtcom = VALUE #( matnr = <fs_mat>-i_matnr werks = <fs_mat>-i_werks ) ).

          ls_kond-matnr = <fs_mat>-i_matnr.

          material_availability( EXPORTING is_import =  CORRESPONDING #( <fs_mat> )
                                 IMPORTING et_export = ls_kond-t_atp ).

          ls_kond-t_mat = export_to_item(  EXPORTING iv_vakey = 'MVKE'
                                                  is_quellstr = ms_maapv
                                                   iv_strnam  = 'MAAPV' ).

          APPEND  ls_kond TO  es_export-et_kond.

        ENDLOOP.



      CATCH ycx_sdws_interface INTO lo_error.

        IF sy-langu = ycl_sdws_interface_all=>get_instance( )->mv_message_spras OR
          ycl_sdws_interface_all=>get_instance( )->mv_message_spras EQ space.

          ls_return-message = lo_error->get_text( ).

        ELSE.

          ls_return-message = lo_error->get_exception_text_with_langu( ycl_sdws_interface_all=>get_instance( )->mv_message_spras ).

        ENDIF.

        ls_return-type    = mc_chare.

        es_export-e_sessionid = is_import-i_sessionid.
        APPEND ls_return TO es_export-et_returns.

    ENDTRY.

    ycl_sdws_interface_all=>get_instance( )->dequeue_session_id( iv_session_id = is_import-i_sessionid ).

  ENDMETHOD.
