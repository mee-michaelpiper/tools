  METHOD read_deliveries.

    DATA s_dlvcntrl TYPE  bapidlvbuffercontrol.
    DATA et_delivery_header TYPE TABLE OF  bapidlvhdr.
    DATA et_delivery_item TYPE TABLE OF  bapidlvitem.
    DATA et_delivery_header_sts TYPE TABLE OF  bapidlvhdrsts.
    DATA et_delivery_item_sts TYPE TABLE OF  bapidlvitemsts.
    DATA et_delivery_partner TYPE TABLE OF  bapidlvpartners.
    DATA et_document_flow TYPE TABLE OF  bapidocflow.
    DATA et_foreign_trade_header TYPE TABLE OF  bapiforeigntradehdr.
    DATA et_foreign_trade_item TYPE TABLE OF  bapiforeigntradeitem.
    DATA et_hu_header TYPE TABLE OF  bapidlvhandlingunithdr.
    DATA et_item_serial_no TYPE TABLE OF  bapidlvitmserno.
    DATA extensionin TYPE TABLE OF bapiparex.
    DATA extensionout TYPE TABLE OF  bapiparex.
    DATA return TYPE TABLE OF  bapiret2.

    CALL FUNCTION 'BAPI_DELIVERY_GETLIST'
      EXPORTING
        is_dlv_data_control = s_dlvcntrl
      TABLES
*       IT_ABLAD            =
*       IT_ABTNR            =
*       it_aufnr            = mt_sel_aufnr
*       IT_AULWE            =
        it_bestk            = mt_sel_bestk
*       IT_BLDAT            =
*       IT_CHARG            =
*       IT_CMFRE            =
*       IT_CMGST            =
*       IT_CMNGV            =
*       IT_CTLPC            =
*       IT_EAN11            =
        it_erdat            = mt_sel_erdat
        it_ernam            = mt_sel_ernam
*       IT_FKSTK            =
*       IT_GBSTK            =
*       IT_GRUPP            =
*       IT_KDMAT            =
*       IT_KKBER            =
*       IT_KNKLI            =
*       IT_KODAT            =
*       IT_KOQUK            =
*       IT_KOSTK            =
*       IT_KUNN2            =
        it_kunnr            = mt_sel_kunnr
*       IT_KUNWE            =
*       IT_LDDAT            =
*       IT_LFART            =
        it_lfdat            = mt_sel_lfdat
*       IT_LGNUM            =
*       IT_LGORT            =
*       IT_LGTOR            =
*       IT_LIFEX            =
*       IT_LIFSK            =
*       IT_LPRIO            =
*       IT_LSTEL            =
*       IT_LVSTK            =
*       IT_MATKL            =
        it_matnr            = mt_sel_matnr
*       IT_PARNR            =
*       IT_PARVW            =
*       IT_PERNR            =
*       IT_PKSTK            =
*       IT_PRVBE            =
*       IT_ROUTE            =
*       IT_SAMMG            =
*       IT_SBGRP            =
*       IT_SPART            =
*       IT_SPDNR            =
*       IT_TDDAT            =
*       IT_TKNUM            =
*       IT_TRAID            =
*       IT_TRSTA            =
        it_vbeln            = mt_sel_vbeln
*       IT_VBTYP            =
        it_vgbel            = mt_sel_aufnr
*       IT_VGSYS            =
*       IT_VKBUR            =
*       IT_VKGRP            =
        it_vkorg            = mt_sel_vkorg
*       IT_VSBED            =
*       IT_VSTEL            =
        it_vtweg            = mt_sel_vtweg
*       IT_WADAT            =
*       IT_WADAT_IST        =
*       IT_WAKTI            =
*       IT_WAUHR            =
*       IT_WBSTK            =
*       IT_WERKS            =
*       IT_XBLNR            =
        et_delivery_header  = mt_header
        et_delivery_item    = mt_items
*       ET_DELIVERY_HEADER_STS        =
*       ET_DELIVERY_ITEM_STS          =
*       ET_DELIVERY_PARTNER =
*       ET_DOCUMENT_FLOW    =
*       ET_FOREIGN_TRADE_HEADER       =
*       ET_FOREIGN_TRADE_ITEM         =
*       ET_HU_HEADER        =
*       ET_ITEM_SERIAL_NO   =
*       EXTENSIONIN         =
        extensionout        = mt_extensionex
*       RETURN              =
      .

    modify_deliveries(
      EXPORTING
*        extensionin            =
        ix_deliveries          = mt_deliveries_badi
      IMPORTING
       et_extensionout           = mt_extensionex
      CHANGING
        et_delivery_header     = mt_header
        et_delivery_item       = mt_items ).
*        et_delivery_header_sts =
*        et_delivery_item_sts   =
*        et_delivery_partner    =
*        et_document_flow       =
*       et_foreign_trade_header =
*       et_foreign_trade_item  =
*       et_hu_header           =
*       et_item_serial_no      =
*        return                 =.

    CHECK mt_header IS INITIAL.
    " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = ms_import-i_kunnr
        mv_msgv1 = 'Lieferungen'(003).



  ENDMETHOD.
