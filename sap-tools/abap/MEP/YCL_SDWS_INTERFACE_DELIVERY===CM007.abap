  METHOD export_to_item.

    DATA: ls_item     TYPE ysdws_comitm_s,
          ls_itmvakey TYPE ty_itmvakey.

*    ls_itmvakey-itm_number = iv_itmnumber.
*    ls_itmvakey-itm_obj    = iv_strnam(4).
*   " ls_itmvakey-itm_key
    ls_itmvakey = iv_vakey.

    LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
      WHERE strname = iv_strnam.    "'VBFA'.
      ls_item-vakey = ls_itmvakey.
      ls_item-qualif = <opt>-fieldname.
      ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE is_quellstr TO FIELD-SYMBOL(<value>).
      IF <value> IS ASSIGNED.
        WRITE <value> TO ls_item-fvalue.
      ELSE.
        ls_item-fvalue = 'NOT_ASSIGNED'.
      ENDIF.
      APPEND ls_item TO et_item.
      UNASSIGN <value>.
    ENDLOOP.


  ENDMETHOD.
