  METHOD get_customerlist.

    set_import_data_range( ).


    SELECT *                         "#EC CI_NOFIELD
      INTO TABLE mt_kna1 FROM kna1
      WHERE KUNNR in mt_sel_kunnr
        and name1 IN mt_sel_name
        AND ort01 IN mt_sel_ort
        AND telf1 IN mt_sel_telfn.



    CHECK sy-subrc NE 0.



    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = Text-005.

  ENDMETHOD.
