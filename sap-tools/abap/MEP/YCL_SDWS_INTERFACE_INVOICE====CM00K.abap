  METHOD read_invoices.

*    DATA s_dlvcntrl TYPE  bapidlvbuffercontrol.
*    DATA et_delivery_header TYPE TABLE OF  bapidlvhdr.
*    DATA et_delivery_item TYPE TABLE OF  bapidlvitem.
*    DATA et_delivery_header_sts TYPE TABLE OF  bapidlvhdrsts.
*    DATA et_delivery_item_sts TYPE TABLE OF  bapidlvitemsts.
*    DATA et_delivery_partner TYPE TABLE OF  bapidlvpartners.
*    DATA et_document_flow TYPE TABLE OF  bapidocflow.
*    DATA et_foreign_trade_header TYPE TABLE OF  bapiforeigntradehdr.
*    DATA et_foreign_trade_item TYPE TABLE OF  bapiforeigntradeitem.
*    DATA et_hu_header TYPE TABLE OF  bapidlvhandlingunithdr.
*    DATA et_item_serial_no TYPE TABLE OF  bapidlvitmserno.
*    DATA extensionin TYPE TABLE OF bapiparex.
*    DATA extensionout TYPE TABLE OF  bapiparex.
*    DATA return TYPE TABLE OF  bapiret2.

    IF mt_sel_matnr IS NOT INITIAL.



      SELECT DISTINCT vbeln INTO TABLE mt_vbl_glt
        FROM  vbrp_vrpma
             WHERE  matnr  IN mt_sel_matnr
             AND    vkorg  = ms_import-i_vkorg
             AND    fkdat  IN mt_sel_fkdat
             AND    vtweg  = ms_import-i_vtweg
             AND    kunag  = ms_import-i_kunnr
             AND    ernam  IN mt_sel_ernam
             AND    erdat  IN mt_sel_erdat
             AND    vbeln  IN mt_sel_vbeln
             AND    posnr  IN mt_sel_posnr
             AND    aubel  IN mt_sel_aubel.

      IF sy-subrc EQ 0 AND mt_vbl_glt[] IS NOT INITIAL.
        SELECT        * INTO TABLE mt_header FROM  vbrk
           FOR ALL ENTRIES IN mt_vbl_glt
               WHERE  vbeln  = mt_vbl_glt-vbeln
               AND    vkorg  = ms_import-i_vkorg
               AND    vtweg  = ms_import-i_vtweg
               AND    ernam  IN mt_sel_ernam
               AND    erdat  IN mt_sel_erdat
               AND    kunag  = ms_import-i_kunnr
               AND    fkdat IN mt_sel_fkdat
               AND    erdat IN mt_sel_erdat.
      ENDIF.

    ELSE.
      SELECT        * INTO TABLE mt_header FROM  vbrk
             WHERE  vbeln  IN mt_sel_vbeln
             AND    vkorg  = ms_import-i_vkorg
             AND    vtweg  = ms_import-i_vtweg
             AND    ernam  IN mt_sel_ernam
             AND    erdat  IN mt_sel_erdat
             AND    kunag  = ms_import-i_kunnr
             AND    fkdat IN mt_sel_fkdat
             AND    erdat IN mt_sel_erdat.

    ENDIF.

    IF mt_header[] IS NOT INITIAL AND (
       mt_sel_aubel[] IS NOT INITIAL OR
       mt_sel_bstnk[] IS NOT INITIAL OR
       mt_sel_bstkd[] IS NOT INITIAL OR
       mt_sel_kommi[] IS NOT INITIAL ).

      SELECT DISTINCT f~vbeln INTO TABLE mt_vbl_glt
        FROM  vbrp AS f
       INNER JOIN vbak AS a
       ON f~aubel = a~vbeln
        FOR ALL ENTRIES IN mt_header
             WHERE  f~vbeln  = mt_header-vbeln
             AND    f~aubel IN mt_sel_aubel
             AND    f~matnr IN mt_sel_matnr
             AND    a~bstnk IN mt_sel_bstnk
             AND    a~bstdk IN mt_sel_bstkd
             AND    ( a~/fis/kommi_text1 IN mt_sel_kommi OR a~/fis/kommi_text2 IN mt_sel_kommi ).

      SORT mt_vbl_glt.
      LOOP AT mt_header ASSIGNING FIELD-SYMBOL(<vbrk>).
        DATA(ind) = sy-tabix.
        READ TABLE mt_vbl_glt WITH KEY vbeln = <vbrk>-vbeln
         BINARY SEARCH TRANSPORTING NO FIELDS.
        CHECK sy-subrc NE 0.
        DELETE mt_header INDEX ind.
      ENDLOOP.

    ENDIF.

    CHECK mt_header IS INITIAL.
    " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = 'Rechnung'(004).



  ENDMETHOD.
