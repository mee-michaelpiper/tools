ENHANCEMENT 1  .
*&---------------------------------------------------------------------*
* Changes                                                   |patch     *
* Name      |Date                                           |K-orrektur*
* Description:                                              |C-Chainreq*
*&---------------------------------------------------------------------*
*           |                                               |          *
*                                                           |          *
*&---------------------------------------------------------------------*

if TESTRUN ne space and
  ycl_sdws_interface_salesorder=>mo_instance is NOT INITIAL.
 data(ylo_salesorder) = ycl_sdws_interface_salesorder=>mo_instance.
 data ylt_komvd type TABLE OF KOMVD.
 data ylt_komv type TABLE OF KOMV.
 data ylt_konv type TABLE OF konv.
 data yls_komk type komk.



 MOVE-CORRESPONDING da_vbak to yls_komk.
 MOVE-CORRESPONDING e_VBKD TO yls_KOMK.

 MOVE-CORRESPONDING e_konv[] to ylt_komv.

CALL FUNCTION 'RV_PRICE_PRINT_HEAD'
  EXPORTING
    comm_head_i         = yls_komk
*    LANGUAGE            = sy-langu
* IMPORTING
*   COMM_HEAD_E         =
*   COMM_MWSKZ          =
*   ET_QTYCNVFACT       =
  tables
    tkomv               = ylt_komv[]
    tkomvd              =  ylt_komvd.

  move-CORRESPONDING ylt_komvd to ylt_konv.
  append LINES OF ylt_konv to e_konv.

  perform map_konv_to_bapicond tables e_konv
                                      conditions_ex
                               using  da_vbak.

CALL METHOD ylo_salesorder->set_salesorder_response
  EXPORTING
    is_sales_header_out    = sales_header_out
    is_sales_header_status = sales_header_status
    it_items_ex            = items_ex[]
    it_schedule_ex         = schedule_ex[]
    it_business_ex         = business_ex[]
    it_incomplete_log      = incomplete_log[]
    it_extensionex         = extensionex[]
    it_conditions_ex       = conditions_ex[]
    it_partners_ex         = e_vbpa[]
    it_textheaders_ex      = textheaders_ex[]
    it_textlines_ex        = textlines_ex[]
    .

endif.
ENDENHANCEMENT.
