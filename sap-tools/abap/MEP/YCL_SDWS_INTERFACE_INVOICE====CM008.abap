  METHOD get_data.

    MOVE-CORRESPONDING is_import TO ms_import.

    get_default_values(
      EXPORTING
        iv_strname  = 'YSDWS_SALESDOC_DFLTCLASSATTR'
        iv_caller   = mv_caller
      CHANGING
        cs_zielstr  = ms_import ).

    set_import_data_range( ).

    es_export-e_sessionid = is_import-i_sessionid.
*    TRY.

        CASE is_import-i_handle.
          WHEN 'GET_INVOICES'.
            read_invoices( ms_import ).
            LOOP AT mt_header ASSIGNING FIELD-SYMBOL(<vbl>).

              DATA(lt_container) = export_to_item(
                EXPORTING
                  iv_vakey =  |{ <vbl>-vbeln }|
                  is_quellstr  = <vbl>
                  iv_strnam    = 'VBRK' ).

              APPEND LINES OF lt_container TO es_export-et_item.
              ADD 1 TO mv_number_of_documents.
            ENDLOOP.


          WHEN 'GET_ITEMS'.
            read_invoice( ms_import ).

            LOOP AT mt_vbrp ASSIGNING FIELD-SYMBOL(<item>).
              es_export-et_item = export_to_item(
                EXPORTING
                   iv_vakey =  |{ <item>-posnr && 'ITEM' }|
                  is_quellstr  = <item>
                  iv_strnam    = 'VBRP' ).

              APPEND LINES OF lt_container TO es_export-et_item.
              ADD 1 TO mv_number_of_documents.
            ENDLOOP.
        ENDCASE.


*      CATCH ycx_sdws_interface .
*    ENDTRY.


    es_export-et_header = append_header_data(
       EXPORTING i_qualifier = 'NUMBER_OF_DOCUMENTS' i_fvalue = mv_number_of_documents ).

  ENDMETHOD.
