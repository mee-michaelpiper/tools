  METHOD read_delivery.

    SELECT SINGLE * INTO ms_likp
      FROM likp
      WHERE vbeln = is_import-i_objky
       AND kunag IN mt_sel_kunnr.

    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_found
          mv_kunnr = ms_import-i_kunnr.
    ENDIF.

    SELECT * INTO TABLE mt_lips
      FROM lips
    WHERE vbeln = ms_likp-vbeln
     AND  posnr IN mt_sel_posnr
     and  matnr in mt_sel_matnr.

    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_found
          mv_kunnr = ms_import-i_kunnr.
    ENDIF.


    SELECT        * into table mt_VTRKH FROM  vtrkh
           WHERE  uevbeln  = ms_likp-vbeln.



  ENDMETHOD.
