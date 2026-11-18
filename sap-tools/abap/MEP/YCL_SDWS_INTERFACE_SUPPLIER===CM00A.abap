  METHOD EXPORT_ADDR_TO_ITEM.

*    DATA: ls_item     TYPE ysdws_comitm_s,
*          ls_itmvakey TYPE ty_itmvakey.
*
*
*         addrnumber LIKE addr1_sel-addrnumber,
*         addrhandle LIKE addr1_sel-addrhandle,
*         addr1_tab TYPE szadr_addr1_line OCCURS 0,
*         adtel_tab TYPE szadr_adtel_line OCCURS 0,
*         adfax_tab TYPE szadr_adfax_line OCCURS 0,
*         adttx_tab TYPE szadr_adttx_line OCCURS 0,
*         adtlx_tab TYPE szadr_adtlx_line OCCURS 0,
*         adsmtp_tab TYPE szadr_adsmtp_line OCCURS 0,
*         adrml_tab TYPE szadr_adrml_line OCCURS 0,
*         adx400_tab TYPE szadr_adx400_line OCCURS 0,
*         adrfc_tab TYPE szadr_adrfc_line OCCURS 0,
*         adprt_tab TYPE szadr_adprt_line OCCURS 0,          "*178i
*         adssf_tab TYPE szadr_adssf_line OCCURS 0,          "*178i
*         aduri_tab TYPE szadr_aduri_line OCCURS 0,          "*178i
*         adpag_tab TYPE szadr_adpag_line OCCURS 0,          "*178i
*         adrct_tab TYPE szadr_adrct_line OCCURS 0,
*         adrt_tab TYPE szadr_adrt_line OCCURS 0,
*         adru_tab TYPE szadr_adru_line OCCURS 0,            "*981i
*
*
*
*    IF iv_itmnumber IS SUPPLIED.
*      ls_itmvakey-itm_number = iv_itmnumber.
*      ls_itmvakey-itm_obj    = iv_strnam(4).
*      " ls_itmvakey-itm_key
*    ELSE.
*      ls_itmvakey = iv_vakey.
*    ENDIF.
*
*    LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
*      WHERE strname = iv_strnam.    "'VBFA'.
*      ls_item-vakey = ls_itmvakey.
*      ls_item-qualif = <opt>-fieldname.
*      ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE is_quellstr TO FIELD-SYMBOL(<value>).
*      IF <value> IS ASSIGNED.
*        WRITE <value> TO ls_item-fvalue.
*      ELSE.
*        ls_item-fvalue = 'NOT_ASSIGNED'.
*      ENDIF.
*      APPEND ls_item TO et_item.
*      UNASSIGN <value>.
*    ENDLOOP.
*

  ENDMETHOD.
