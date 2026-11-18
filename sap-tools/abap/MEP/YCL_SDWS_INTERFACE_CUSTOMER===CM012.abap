  METHOD get_materialssoldlist.

    set_import_data_range( ).

    SELECT        * INTO CORRESPONDING FIELDS OF TABLE mt_soldmat
      FROM  vbrk as k
      INNER JOIN vbrp as p
      ON k~vbeln = p~vbeln
           WHERE  k~vbeln  in mt_sel_vbeln
           AND    fkart  in mt_sel_fkart
*           AND    fktyp  in
           AND    fkdat  IN mt_sel_fkdat
           AND    k~erdat  IN mt_sel_erdat
           AND    kunrg  in mt_sel_kunrg
           AND    kunag  = ms_import-i_kunnr
      order by matnr k~erdat DESCENDING.

    check sy-subrc ne 0.



    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = 'Kunden-Artikel-Info'(003).

  ENDMETHOD.
