  METHOD CHECK_WE.
*       READ TABLE mt_order_partners WITH KEY itm_number = mc_header_pos
*                                  partn_role = 'WE'
*     ASSIGNING FIELD-SYMBOL(<itm>).
*
*    check sy-subrc eq 0.
*
*    get_kuwe2(
* EXPORTING
*   iv_kunnr = <itm>-partn_numb
*   iv_parvw = 'WE'
*   iv_vkorg = ms_order_header_in-sales_org
*   iv_vtweg = ms_order_header_in-distr_chan
*   iv_spart = ms_order_header_in-division
* IMPORTING
*   es_kunwa = ms_kunwe ).
*
*

  ENDMETHOD.
