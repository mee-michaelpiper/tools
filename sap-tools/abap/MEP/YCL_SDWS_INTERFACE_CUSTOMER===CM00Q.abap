  METHOD get_vbeln_vmvaa.

    IF mt_sel_bstkd[] IS INITIAL OR mv_nodata_found EQ abap_true.
      rt_vbeln = mt_vbl_glt. " Gültige Vertriebsbelege
      EXIT.
    ENDIF.

    IF mt_vbl_glt[] IS INITIAL.

      SELECT DISTINCT vbeln
      INTO TABLE rt_vbeln
      FROM m_vmvaa
        WHERE  bstkd IN mt_sel_bstkd
        AND   ( vkorg = ms_import-i_vkorg )
        AND   ( trvog = mv_trvog )
*        AND   ( AUDAT IN IAUDAT )
        AND   ( vtweg = ms_import-i_vtweg )
        AND   ( spart = ms_import-i_spart )
*        AND   ( auart IN iauart )
        AND   ( kunnr = ms_import-i_kunnr )
*        AND   ( VKBUR IN IVKBUR )
*        AND   ( VKGRP IN IVKGRP )
*        AND   ( BSTNK IN IBSTNK )
*        AND   ( ERNAM IN IERNAM )
        AND   ( vbeln IN mt_sel_vbeln ).


    ELSE.
      SELECT DISTINCT vbeln
        INTO TABLE rt_vbeln
          FROM m_vmvaa FOR ALL ENTRIES IN mt_vbl_glt
        WHERE  bstkd IN mt_sel_bstkd
        AND   ( vkorg = ms_import-i_vkorg )
        AND   ( trvog = mv_trvog )
*        AND   ( AUDAT IN IAUDAT )
        AND   ( vtweg = ms_import-i_vtweg )
        AND   ( spart = ms_import-i_spart )
*        AND   ( auart IN iauart )
        AND   ( kunnr = ms_import-i_kunnr )
*        AND   ( VKBUR IN IVKBUR )
*        AND   ( VKGRP IN IVKGRP )
*        AND   ( BSTNK IN IBSTNK )
*        AND   ( ERNAM IN IERNAM )
        AND   ( vbeln IN mt_sel_vbeln )
        AND   ( vbeln = mt_vbl_glt-vbeln ).
    ENDIF.

    IF rt_vbeln[] IS INITIAL.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_found
          mv_kunnr = ms_import-i_kunnr
          mv_msgv1 = 'Aufträge'(001).
    ENDIF.
  ENDMETHOD.
