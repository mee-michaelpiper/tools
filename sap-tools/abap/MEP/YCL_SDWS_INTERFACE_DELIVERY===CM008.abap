  METHOD get_data.

    DATA lv_itmnumber  TYPE posnr.

    MOVE-CORRESPONDING is_import TO ms_import.

    get_default_values(
      EXPORTING
        iv_strname  = 'YSDWS_SALESDOC_DFLTCLASSATTR'
        iv_caller   = mv_caller
      CHANGING
        cs_zielstr  = ms_import ).

    set_import_data_range( ).

*    TRY.

        CASE is_import-i_handle.
          WHEN 'GET_DELIVERIES'.
            read_deliveries( ms_import ).
            LOOP AT mt_header ASSIGNING FIELD-SYMBOL(<vbl>).

              DATA(lt_container) = export_to_item(
                EXPORTING
                  iv_vakey =  |{ <vbl>-vbeln }|
                  is_quellstr  = <vbl>
                  iv_strnam    = 'BAPIDLVHDR' ).

              APPEND LINES OF lt_container TO es_export-et_item.
              ADD 1 TO mv_number_of_documents.
            ENDLOOP.
          WHEN 'GET_ITEMS'.
            read_delivery( ms_import ).

            clear lt_container.
            LOOP AT mt_lips ASSIGNING FIELD-SYMBOL(<item>).
              lt_container = export_to_item(
                EXPORTING
                   iv_vakey =  |{ <item>-posnr && 'ITEM' }|
                  is_quellstr  = <item>
                  iv_strnam    = 'BAPIDLVITEM' ).
              APPEND LINES OF lt_container TO es_export-et_item.
            ENDLOOP.

            clear lt_container.
            loop at mt_vtrkh ASSIGNING FIELD-SYMBOL(<trac>).
                lt_container = export_to_item(
                EXPORTING
                   iv_vakey =  |{ <trac>-VBELN && 'TRAC' }|
                  is_quellstr  = <trac>
                  iv_strnam    = 'VTRKH' ).
              APPEND LINES OF lt_container TO es_export-et_item.
            endloop.
        ENDCASE.


*      CATCH ycx_sdws_interface .
*    ENDTRY.
    es_export-e_sessionid = is_import-i_sessionid.
    es_export-et_header = append_header_data(
        EXPORTING i_qualifier = 'NUMBER_OF_DOCUMENTS' i_fvalue = mv_number_of_documents ).
  ENDMETHOD.
