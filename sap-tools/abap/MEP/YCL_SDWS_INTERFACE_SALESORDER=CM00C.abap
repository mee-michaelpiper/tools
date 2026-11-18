  METHOD map_export.

    DATA ls_return_o TYPE ysdws_return_e_s.

* Meldungen zurückgeben
    LOOP AT mt_returns ASSIGNING FIELD-SYMBOL(<return>).
      CLEAR ls_return_o.
      ls_return_o-type = <return>-type.
      ls_return_o-message = <return>-message.
      ls_return_o-posnr = <return>-row.
      APPEND ls_return_o TO rs_export-et_returns.
    ENDLOOP.

    DATA(lt_hdr) = export_bapi_header( ).
    DATA(lt_export) = export_bapi_extensions( iv_itmnumber = '000000'
          iv_strname = 'BAPE_VBAK' ).
    rs_export-et_header = VALUE #( BASE lt_hdr
                                   ( LINES OF lt_export-et_header ) ).

    DATA(lt_cnd) = export_bapi_cond( '000000' ).
    rs_export-et_item = export_bapi_partner( '000000' ).

    rs_export-et_item = VALUE #( BASE rs_export-et_item
                                   ( LINES OF lt_cnd ) ).
*
    LOOP AT mt_order_items_ex ASSIGNING FIELD-SYMBOL(<item>).
      DATA(lt_itm) = export_bapi_item( <item>-itm_number ).
      lt_export = export_bapi_extensions(
          iv_itmnumber = <item>-itm_number
          iv_strname = 'BAPE_VBAP'  ).
      DATA(lt_itmsce) = export_bapi_schedules( <item>-itm_number ).
      lt_cnd = export_bapi_cond( <item>-itm_number ).
      DATA(lt_prt) = export_bapi_partner( <item>-itm_number ).
      rs_export-et_item = VALUE #( BASE rs_export-et_item
                                     ( LINES OF lt_itm )
                                     ( LINES OF lt_export-et_item )
                                     ( LINES OF lt_itmsce )
                                     ( LINES OF lt_cnd )
                                     ( LINES OF lt_prt )
                                     ).
    ENDLOOP.
  ENDMETHOD.
