  METHOD read_dangerous_detail.

    SELECT        * INTO TABLE mt_gg
      FROM  ymmms_gg
           WHERE  matnr  = is_import-i_objky
           AND ersda  IN mt_sel_ersda
           AND aedat IN mt_sel_laeda
           AND    loekz  = space
      ORDER BY comcn.

   if sy-subrc ne 0.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>matnr_not_exist
          mv_matnr = ms_import-material.

   endif.


  ENDMETHOD.
