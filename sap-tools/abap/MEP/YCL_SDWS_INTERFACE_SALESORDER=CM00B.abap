  METHOD fill_bapi_partner.

    DATA: ls_bapiparnr  TYPE bapiparnr.

    DATA: ls_item       TYPE bapisditm,
          ls_itemx      TYPE bapisditmx,
          lo_error      TYPE REF TO cx_root,
          ls_bape_vbap  TYPE bape_vbap,
          ls_bape_vbapx TYPE bape_vbapx,
          ls_itmvakey   TYPE ty_itmvakey.

    LOOP AT it_import ASSIGNING FIELD-SYMBOL(<itm>)
      WHERE vakey CS  mc_part.

      IF ( ls_itmvakey-itm_number NE <itm>-vakey(6) OR
         ls_itmvakey-itm_key NE <itm>-vakey+10 ) AND ls_itmvakey IS NOT INITIAL.

        ls_bapiparnr-partn_role  = ls_itmvakey-itm_key.

        APPEND ls_bapiparnr TO mt_order_partners.
        CLEAR ls_bapiparnr.
      ENDIF.
      ls_itmvakey = <itm>-vakey.

      ASSIGN COMPONENT <itm>-qualif OF STRUCTURE ls_bapiparnr  TO FIELD-SYMBOL(<fielditm>).
      IF sy-subrc EQ 0 AND <fielditm> IS ASSIGNED.

        TRY.
            MOVE <itm>-fvalue TO <fielditm>.

          CATCH cx_sy_conversion_no_number INTO lo_error.

        ENDTRY.
      ELSE.

*       Feldname unbekann

      ENDIF.
    ENDLOOP.

    CHECK sy-subrc EQ 0.
    ls_bapiparnr-itm_number =  ls_itmvakey-itm_number.
    ls_bapiparnr-partn_role  = ls_itmvakey-itm_key.

    APPEND ls_bapiparnr TO mt_order_partners.




















*  CALL FUNCTION 'K_CMPERS_CONV_INT_TO_EX'
*    EXPORTING
*      i_value_internal = is_ea_pos-kbetr
*      i_curr           = is_ea_pos-waerk
*      i_tabname        = '/FIS/CASH_EA_DIVKAS_TC'
*      i_fieldname      = 'KBETR'
*    IMPORTING
*      e_value_external = lv_bconv.
*
*  CALL FUNCTION 'CLSE_SELECT_USR01'
*    EXPORTING
*      username     = sy-uname
*    IMPORTING
**     X_USR01      = X_USR01
**     DATE_FORMAT  = DATE_FORMAT
*      decimal_sign = lv_decsn.
**     SEPARATOR          = lv_ussep
*
*  IF lv_decsn = ','.
*    TRANSLATE lv_bconv USING '. ,.'.
*  ELSE.
*    TRANSLATE lv_bconv USING ', '.
*  ENDIF.
*
*  CONDENSE  lv_bconv NO-GAPS.
*
*  ls_condition-cond_value = lv_bconv.
*  ls_condition-currency   = is_ea_pos-waerk.
*
*  APPEND ls_condition TO ct_condition.
*
*
*  CLEAR: ls_conditionx.
*  ls_conditionx-itm_number = is_ea_pos-posnr.
*  ls_conditionx-cond_type  = abap_true.
*  ls_conditionx-cond_value = abap_true.
*  ls_conditionx-currency   = abap_true.
*
*  APPEND ls_conditionx TO ct_conditionx.
*




  ENDMETHOD.
