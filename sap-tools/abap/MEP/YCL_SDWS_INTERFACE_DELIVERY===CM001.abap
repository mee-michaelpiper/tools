  METHOD check_ag.
*
*    READ TABLE mt_order_partners WITH KEY itm_number = mc_header_pos
*                                  partn_role = 'AG'
*     ASSIGNING FIELD-SYMBOL(<itm>).
*
*   if sy-subrc ne 0.
*      " Die Kundennummer muss befüllt sein!
*      RAISE EXCEPTION TYPE ycx_sdws_interface
*        EXPORTING
*          textid = ycx_sdws_interface=>empty_kunnr.
*   endif.
*
*    get_kuagv(
* EXPORTING
*   iv_kunnr = <itm>-partn_numb
*   iv_parvw = 'AG'
*   iv_vkorg = ms_order_header_in-sales_org
*   iv_vtweg = ms_order_header_in-distr_chan
*   iv_spart = ms_order_header_in-division
* IMPORTING
*   es_kunwa = ms_kunag ).


  ENDMETHOD.
