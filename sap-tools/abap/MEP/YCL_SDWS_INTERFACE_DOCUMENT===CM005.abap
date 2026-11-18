  METHOD convert_otf.

    DATA lt_pdftab TYPE TABLE OF tline.
    DATA ls_import TYPE ysdws_document_data_i_s.
    DATA lv_pdf_file TYPE fpcontent.

    IF mt_otf[] IS INITIAL.

*     prüfen ob über WebDynpro die Daten bereitgestellt werden
      IMPORT lv_pdf_file TO rs_export-e_pdfbin FROM MEMORY ID 'PDF_FILE'.

      IF sy-subrc NE 0.
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid = VALUE scx_t100key(
                      msgid = sy-msgid
                      msgno = sy-msgno
                      attr1 = sy-msgv1 ).

      ELSE.
*        CALL METHOD cl_gui_frontend_services=>file_get_size
*          EXPORTING
*            file_name = rs_export-e_pdfbin
*          IMPORTING
*            file_size = rs_export-e_pdf_filesize.
      ENDIF.

    ELSE.
      CALL FUNCTION 'CONVERT_OTF'
        EXPORTING
          format                = 'PDF'
        IMPORTING
          bin_filesize          = rs_export-e_pdf_filesize
          bin_file              = rs_export-e_pdfbin
        TABLES
          otf                   = mt_otf
          lines                 = lt_pdftab
        EXCEPTIONS
          err_max_linewidth     = 1
          err_format            = 2
          err_conv_not_possible = 3
          err_bad_otf           = 4
          OTHERS                = 5.

      IF sy-subrc NE 0.
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid = VALUE scx_t100key(
                      msgid = sy-msgid
                      msgno = sy-msgno
                      attr1 = sy-msgv1 ).
      ENDIF.
    ENDIF.
  ENDMETHOD.
