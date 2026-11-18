  METHOD get_customersalesdata.

    set_import_data_range( ).


*    SELECT SINGLE *
*      INTO ms_knvv FROM knvv
*  WHERE vkorg  = ms_import-i_vkorg
*  AND    vtweg  = ms_import-i_vtweg
*  AND    kunnr  = ms_import-i_kunnr.

    SELECT * INTO ms_knvv FROM knvv  UP TO 1 ROWS       "FISJL20200429  OSS36178 HANADB
     WHERE vkorg    = ms_import-i_vkorg
      AND    vtweg  = ms_import-i_vtweg
      AND    kunnr  = ms_import-i_kunnr ORDER BY PRIMARY KEY.
   ENDSELECT.

    CHECK sy-subrc NE 0.

    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = text-006.

  ENDMETHOD.
