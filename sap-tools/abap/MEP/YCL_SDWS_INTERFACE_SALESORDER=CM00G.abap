  METHOD export_bapi_item.

    DATA: ls_item     TYPE ysdws_comitm_s,
          ls_itmvakey TYPE ty_itmvakey.

    READ TABLE mt_order_items_ex WITH KEY itm_number = iv_itmnumber
        ASSIGNING FIELD-SYMBOL(<item>).

    CHECK sy-subrc EQ 0.

    ls_itmvakey-itm_number = iv_itmnumber.
    ls_itmvakey-itm_obj = mc_item.

    LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
      WHERE strname = 'BAPISDIT'.
      ls_item-vakey  = ls_itmvakey.
      ls_item-qualif = <opt>-fieldname.
      ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE <item> TO FIELD-SYMBOL(<value>).
      IF <value> IS ASSIGNED.
        WRITE <value> TO ls_item-fvalue.
      ELSE.
        ls_item-fvalue = 'NOT_ASSIGNED'.
      ENDIF.
      APPEND ls_item TO et_item.
      UNASSIGN <value>.
    ENDLOOP.




  ENDMETHOD.
