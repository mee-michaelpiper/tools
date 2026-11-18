  METHOD get_data.

    MOVE-CORRESPONDING is_import TO ms_import.

    get_default_values(
      EXPORTING
        iv_strname  = 'YSDWS_SALESDOC_DFLTCLASSATTR'
        iv_caller   = mv_caller
      CHANGING
        cs_zielstr  = ms_import ).



    TRY.

        CASE is_import-i_handle.
          WHEN 'GET_ORDERITEMS' or
            'GET_CONFIGURATIONS'.
            es_export = get_item_data( 'C' ).
          WHEN 'GET_OFFERITEMS'.
            es_export = get_item_data( 'B' ).
          WHEN 'GET_PARTNERS'.
            get_partners_data( ).
            es_export-et_item = export_bapi_partner( '000000' ).
          WHEN 'GET_OFFERFLOW'.
            es_export = get_flow_data( 'B' ).
          WHEN 'GET_ORDERFLOW'.
            es_export = get_flow_data( 'C' ).

        ENDCASE.


      CATCH ycx_sdws_interface .


    ENDTRY.

  ENDMETHOD.
