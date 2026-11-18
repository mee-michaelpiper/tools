  METHOD availability.

    DATA lo_error TYPE REF TO ycx_sdws_interface.
    DATA ls_import TYPE ysdws_availability_i_s.
    DATA ls_return TYPE ysdws_return_e_s.

    ls_import = is_import.

    TRY.

        availability_plausi_check( CHANGING cs_import = ls_import ).

        availability_check( EXPORTING is_import = ls_import
                            IMPORTING es_export = es_export ).

      CATCH ycx_sdws_interface INTO lo_error.

        IF sy-langu = ycl_sdws_interface_all=>get_instance( )->mv_message_spras.

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
