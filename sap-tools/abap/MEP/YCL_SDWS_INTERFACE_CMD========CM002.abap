  METHOD managed.

    DATA lo_error TYPE REF TO ycx_sdws_interface.
    DATA ls_bapiret TYPE bapiret2.
    DATA ls_return TYPE ysdws_return_e_s.

    DATA(ls_import) = is_import.

    es_export-e_sessionid = is_import-i_sessionid.

    TRY.
        mv_ref_customer = fetch_ref_customer( is_import-i_refknr ).
        fetch_detail_objcl( ).
        fetch_data_cmd( ).
        fetch_data_creditmanagement(  ).
        map_ref_customer2new( ls_import ).
        es_export-e_kunnr = create_new_customer(  ).

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait   = 'X'   " Verwendung des Kommandos 'COMMIT AND WAIT'
          IMPORTING
            return = ls_bapiret.    " Rückmeldungen

        IF ls_bapiret IS NOT INITIAL.
          set_msg_text( ls_bapiret ).
        ENDIF.



      CATCH ycx_sdws_interface INTO lo_error.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND LINES OF mt_returns TO es_export-et_returns.
        ls_return-type = 'E'.
        IF sy-langu = ycl_sdws_interface_all=>get_instance( )->mv_message_spras OR
          ycl_sdws_interface_all=>get_instance( )->mv_message_spras EQ space.
          ls_return-message = lo_error->get_text( ).
        ELSE.
          ls_return-message = lo_error->get_exception_text_with_langu( ycl_sdws_interface_all=>get_instance( )->mv_message_spras ).
        ENDIF.
        APPEND ls_return TO es_export-et_returns.
        es_export-e_sessionid = is_import-i_sessionid.

    ENDTRY.


  ENDMETHOD.
