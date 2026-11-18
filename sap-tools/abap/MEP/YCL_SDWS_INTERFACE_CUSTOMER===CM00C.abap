  METHOD get_data.

    DATA lt_hdr TYPE ysdws_comhdr_tt.

    ms_import = is_import.
    get_default_values(
      EXPORTING
        iv_strname  = 'YSDWS_CUSTOMER_DATA_I_S'
        iv_caller   = mv_caller
      CHANGING
        cs_zielstr  = ms_import ).



*    TRY.

    CASE is_import-i_handle.
      when 'GET_MATERIALSSOLDLIST'.
        GET_MATERIALSSOLDLIST( ).
        es_export-et_item = export_db_materialssold_data( ).
      WHEN 'GET_CUSTOMERSALESDATA'.
        get_customersalesdata( ).
        es_export-et_item = export_db_customer_salesdata( ).
      WHEN 'GET_CUSTOMERLIST'.
        get_customerlist( ).
        es_export-et_item = export_db_customer_generaldata( ).
        lt_hdr = append_header_data( EXPORTING i_qualifier = 'NUMBER_OF_DOCUMENTS' i_fvalue = mv_number_of_documents ).
      WHEN 'GET_CUSTOMERMATERIALDATA'.
        get_customermaterial_data( ).
        es_export-et_item = export_db_customermaterial_dat( ).
        lt_hdr = append_header_data( EXPORTING i_qualifier = 'NUMBER_OF_DOCUMENTS' i_fvalue = mv_number_of_documents ).

      WHEN 'GET_PARTNERS'.

        get_partners_data( ).
        lt_hdr = export_bapi_header(
                      is_quellstr = ms_kunag
                      iv_strnam   = 'KUAGV' ).
        es_export-et_item = export_bapi_partner( '000000' ).
      WHEN 'GET_ORDERS'.
        get_orders_data( ).
        es_export-et_item = export_bapi_item( '000000' ).

        lt_hdr = append_header_data( EXPORTING i_qualifier = 'NUMBER_OF_DOCUMENTS' i_fvalue = mv_number_of_documents ).
      WHEN 'GET_OFFERS'.
        get_offers_data( ).
        es_export-et_item = export_bapi_item( '000000' ).
        lt_hdr  = append_header_data( EXPORTING i_qualifier = 'NUMBER_OF_DOCUMENTS' i_fvalue = mv_number_of_documents ).

    ENDCASE.

    APPEND LINES OF lt_hdr TO es_export-et_header.


  ENDMETHOD.
