  METHOD fill_bapi_item.

    DATA: ls_item       TYPE bapisditm,
          ls_itemx      TYPE bapisditmx,
          lo_error      TYPE REF TO cx_root,
          ls_bape_vbap  TYPE bape_vbap,
          ls_bape_vbapx TYPE bape_vbapx,
          ls_itmvakey   TYPE ty_itmvakey.

    LOOP AT it_import ASSIGNING FIELD-SYMBOL(<itm>)
      WHERE vakey CS  mc_item.

      IF ls_itmvakey-itm_number NE <itm>-vakey(6)
        AND ls_itmvakey-itm_number NE '000000'.
        MOVE ls_itmvakey-itm_number TO: ls_itemx-itm_number, ls_item-itm_number.
        APPEND ls_itemx TO mt_order_items_inx.
        APPEND ls_item TO mt_order_items_in.

        CALL METHOD fill_bapi_item_customer(
          EXPORTING
            iv_posnr      = ls_itmvakey-itm_number
            is_bape_vbap  = ls_bape_vbap
            is_bape_vbapx = ls_bape_vbapx ).

        CLEAR: ls_item, ls_itemx, ls_bape_vbap, ls_bape_vbapx.
      ENDIF.
      ls_itmvakey = <itm>-vakey.

      ASSIGN COMPONENT <itm>-qualif OF STRUCTURE ls_item TO FIELD-SYMBOL(<fielditm>).
      IF sy-subrc EQ 0 AND <fielditm> IS ASSIGNED.

        TRY.
            MOVE <itm>-fvalue TO <fielditm>.
            ASSIGN COMPONENT <itm>-qualif OF STRUCTURE ls_itemx TO FIELD-SYMBOL(<fielditmx>).
            MOVE abap_true TO <fielditmx>.
          CATCH cx_sy_conversion_no_number INTO lo_error.

        ENDTRY.
      ELSE.
        ASSIGN COMPONENT <itm>-qualif OF STRUCTURE ls_bape_vbap TO <fielditm>.
        IF sy-subrc EQ 0 AND <fielditm> IS ASSIGNED.

          TRY.
              MOVE <itm>-fvalue TO <fielditm>.
              ASSIGN COMPONENT <itm>-qualif OF STRUCTURE ls_bape_vbapx TO <fielditmx>.
              MOVE abap_true TO <fielditmx>.
            CATCH cx_sy_conversion_no_number INTO lo_error.

          ENDTRY.
        ELSE.
*       Feldname unbekann
        ENDIF.
      ENDIF.
    ENDLOOP.

    CHECK sy-subrc EQ 0.
    MOVE ls_itmvakey-itm_number TO: ls_itemx-itm_number, ls_item-itm_number.
    APPEND ls_item TO mt_order_items_in.
    APPEND ls_itemx TO mt_order_items_inx.

    CALL METHOD fill_bapi_item_customer(
      EXPORTING
        iv_posnr      = ls_itmvakey-itm_number
        is_bape_vbap  = ls_bape_vbap
        is_bape_vbapx = ls_bape_vbapx ).





  ENDMETHOD.
