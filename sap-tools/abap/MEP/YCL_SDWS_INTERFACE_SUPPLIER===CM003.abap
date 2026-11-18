  METHOD get_data.

    MOVE-CORRESPONDING is_import TO ms_import.

    set_import_data_range( ms_import ).

    get_default_values(
      EXPORTING
        iv_strname  = 'YSDWS_SUPPLIER_DFLTCLASSATTR'
        iv_caller   = mv_caller
      CHANGING
        cs_zielstr  = ms_import ).
*
*
*
**    TRY.
*
    CASE is_import-i_handle.
      WHEN 'GET_SUPPLIERDATA'.
        get_supplierdata( ms_import ).
        es_export-et_item = export_to_item(
                                         EXPORTING
                                           is_quellstr = lfa1
                                           iv_strnam   = 'LFA1'
                                           iv_vakey    = |{ lfa1-lifnr }| ).

        es_export-et_item = VALUE #( BASE es_export-et_item
                                   ( LINES OF  export_to_item(
                                         EXPORTING
                                           is_quellstr = lfm1
                                           iv_strnam   = 'LFM1'
                                           iv_vakey    = |{ lfa1-lifnr && space && ms_import-ekorg }| ) ) ) .

*            lt_hdr  = append_header_data( EXPORTING i_qualifier = 'NUMBER_OF_DOCUMENTS' i_fvalue = mv_number_of_documents ).
*
    ENDCASE.

    "     APPEND LINES OF lt_hdr to es_export-et_header.


  ENDMETHOD.
