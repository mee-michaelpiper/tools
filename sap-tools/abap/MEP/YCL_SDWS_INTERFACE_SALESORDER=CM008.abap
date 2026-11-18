  METHOD fill_bapi_text.

    TYPES: BEGIN OF ty_txtky,
             txtid TYPE tdid,
             laiso TYPE laiso,
           END OF ty_txtky.

    DATA: ls_item     TYPE bapisdtext,
          ls_key      TYPE ty_txtky,
          lo_error    TYPE REF TO cx_root,
          ls_itmvakey TYPE ty_itmvakey.

    LOOP AT it_import ASSIGNING FIELD-SYMBOL(<itm>)
      WHERE vakey CS  mc_text.

      IF  ( ( ls_itmvakey-itm_number NE <itm>-vakey(6) OR
           ls_itmvakey-itm_key NE <itm>-vakey+10 )
                  AND ls_itmvakey IS NOT INITIAL ) OR
            <itm>-qualif = 'TEXT_LINE'.

        IF <itm>-qualif = 'TEXT_LINE'.
          ls_item-text_line = <itm>-fvalue.
        ENDIF.
        IF ls_itmvakey IS INITIAL.
          ls_itmvakey = <itm>-vakey.
        ENDIF.

        ls_item-itm_number  = ls_itmvakey-itm_number.
        ls_key              = ls_itmvakey-itm_key.
        ls_item-text_id     = ls_key-txtid.
        ls_item-langu_iso   = ls_key-laiso.

        APPEND ls_item  TO mt_order_text.
        CLEAR: ls_itmvakey, ls_item .

        IF <itm>-qualif = 'TEXT_LINE'.
          CONTINUE.
        ENDIF.
      ENDIF.
      ls_itmvakey = <itm>-vakey.

      ASSIGN COMPONENT <itm>-qualif OF STRUCTURE ls_item   TO
  FIELD-SYMBOL(<fielditm>).
      IF sy-subrc EQ 0 AND <fielditm> IS ASSIGNED.

        TRY.
            MOVE <itm>-fvalue TO <fielditm>.

          CATCH cx_sy_conversion_no_number INTO lo_error.

        ENDTRY.
      ELSE.

*       Feldname unbekann

      ENDIF.
    ENDLOOP.

    CHECK sy-subrc EQ 0 AND ls_item IS NOT INITIAL.
    ls_item-itm_number  = ls_itmvakey-itm_number.
    ls_key     = ls_itmvakey-itm_key.
    ls_item-text_id =  ls_key-txtid.
    ls_item-langu_iso = ls_key-laiso.

    APPEND ls_item  TO mt_order_text.



  ENDMETHOD.
