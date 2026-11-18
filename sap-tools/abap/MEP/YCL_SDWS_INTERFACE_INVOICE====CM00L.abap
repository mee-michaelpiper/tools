  METHOD read_invoice.

    SELECT SINGLE * INTO ms_vbrk             "#EC CI_SORTED    "FISJL20200429 OSS3361718 HANADB   "#EC CI_NOFIELD
      FROM vbrk
      WHERE vbeln = is_import-i_objky
       AND vkorg IN mt_sel_vkorg
       AND vtweg IN mt_sel_vtweg
       AND ( kunrg IN mt_sel_kunnr OR kunag IN mt_sel_kunnr ).      "FISbew20200508 OSS336178  added parentheses

    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_found
          mv_kunnr = ms_import-i_kunnr
          mv_msgv1 = 'Rechnung'(004).
    ENDIF.

    SELECT * INTO TABLE mt_vbrp "#EC CI_NOFIELD
      FROM vbrp
    WHERE vbeln = ms_vbrk-vbeln
      AND posnr IN mt_sel_posnr
      AND matnr IN mt_sel_matnr.


  ENDMETHOD.
