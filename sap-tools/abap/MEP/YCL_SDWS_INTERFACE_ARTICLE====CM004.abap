  METHOD get_data.

    DATA lv_itmnumber  TYPE posnr.
    DATA lt_container  TYPE ysdws_comitm_tt.
    DATA ls_return     TYPE ysdws_return_e_s.

    MOVE-CORRESPONDING is_import TO ms_import.

    get_default_values(
      EXPORTING
        iv_strname  = 'YSDWS_ARTICLE_DFLTCLASSATTR'
        iv_caller   = mv_caller
      CHANGING
        cs_zielstr  = ms_import ).

    set_import_data_range( CHANGING is_import = ms_import ).

*    TRY.
    es_export-e_sessionid = is_import-i_sessionid.

    CASE is_import-i_handle.
      WHEN 'GET_DETAIL'.
        read_material( ms_import ).
        es_export-et_container = export_material( ).

      WHEN 'GET_DANGEROUS_DETAIL'.
        ms_import-material = ms_import-i_objky.
        read_dangerous_detail( ms_import ).
        LOOP AT mt_gg ASSIGNING FIELD-SYMBOL(<gg>).
          lt_container = export_to_item(
               EXPORTING
                 iv_vakey =  |{ <gg>-comcn }|
                 is_quellstr  = <gg>
                 iv_strnam    = 'YMMMS_GG' ).
          APPEND LINES OF lt_container TO es_export-et_container.
        ENDLOOP.


      WHEN 'GET_CLASSIFICATION'.
        ms_import-material = ms_import-i_objky.
        read_material( ms_import ).
        export_class(
       IMPORTING
         es_class   = es_class
         et_returns = es_export-et_returns ).


      WHEN 'GET_ARTICLES'.

        read_materials( ms_import ).

        LOOP AT mt_materials ASSIGNING FIELD-SYMBOL(<item>).
          TRY.
              ms_import-i_objky = <item>.
              read_material( ms_import ).
              ADD 1 TO mv_number_of_documents .
              lt_container = export_material( ).
              APPEND LINES OF lt_container TO es_export-et_container.
              REFRESH lt_container.
              read_inforecord( <item>-matnr ).
              lt_container = export_to_item(
                   EXPORTING
                     iv_vakey =  |{ mv_number_of_documents  && 'INFRE' }|
                     is_quellstr  = eina
                     iv_strnam    = 'EINA' ).
              APPEND LINES OF lt_container TO es_export-et_container.
            CATCH ycx_sdws_interface INTO DATA(lx_sdws).
              ls_return-message = lx_sdws->get_text( ).
              ls_return-type    = 'E'.
              APPEND ls_return TO es_export-et_returns.
          ENDTRY.

          init_attributs( ).
        ENDLOOP.

        lt_container = append_data_container(
            EXPORTING i_qualifier = 'NUMBER_OF_ARTICLES' i_fvalue = mv_number_of_documents ).

        APPEND LINES OF lt_container TO es_export-et_container.
    ENDCASE.


    es_export-e_sessionid = is_import-i_sessionid.

  ENDMETHOD.
