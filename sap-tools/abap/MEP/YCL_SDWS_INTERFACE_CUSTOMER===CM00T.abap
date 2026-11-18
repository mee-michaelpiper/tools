  METHOD compare_seloption.


    rt_vbeln = mt_vbl_glt. " Gültige Vertriebsbelege

    CHECK mt_sel_kommi IS NOT INITIAL OR
          mt_sel_bstnk IS NOT INITIAL.
    CHECK mt_vbl_glt[] IS NOT INITIAL.

    REFRESH rt_vbeln.

    SELECT DISTINCT vbeln
   INTO TABLE rt_vbeln
   FROM vbak FOR ALL ENTRIES IN mt_vbl_glt
   WHERE ( vbeln =  mt_vbl_glt-vbeln )
     AND ( /fis/kommi_text1 IN mt_sel_kommi OR /fis/kommi_text2 IN mt_sel_kommi )
     AND ( bstnk IN mt_sel_bstnk ).

*    CHECK mt_sel_bstkd IS NOT INITIAL OR
*        mt_sel_bstkd_e IS NOT INITIAL AND
*        rt_vbeln IS NOT INITIAL.


*    SELECT DISTINCT vbeln
*   INTO TABLE rt_vbeln
*   FROM vbkd
*   WHERE  vbeln IN mt_sel_vbeln )
*   AND   ( trvog = mv_trvog )
*   AND   ( /fis/kommi_text1 IN mt_sel_kommi  OR /fis/kommi_text2 IN mt_sel_kommi )
*   AND   ( vbeln IN mt_sel_vbeln ) ORDER BY vbeln.
  ENDMETHOD.
