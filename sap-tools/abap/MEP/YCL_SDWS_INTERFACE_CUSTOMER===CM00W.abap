  METHOD get_customermaterial_data.

    set_import_data_range( ).


    SELECT        * INTO TABLE mt_knmt FROM  knmt
           WHERE  vkorg  = ms_import-i_vkorg
           AND    vtweg  = ms_import-i_vtweg
           AND    kunnr  = ms_import-i_kunnr
           AND    matnr  IN mt_sel_matnr
           and    kdmat  in mt_sel_kdmat.





    CHECK mt_knmt[] IS INITIAL.

    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = 'Kunden-Artikel-Info'(003).

  ENDMETHOD.
