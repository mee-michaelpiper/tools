*&---------------------------------------------------------------------*
*& Report  YSDWS_TEST_BAPI_SALESORDER_CRT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT ysdws_test_bapi_salesorder_crt.


DATA:
  salesdocumentin         LIKE  bapivbeln-vbeln,
  wa_order_header_in      LIKE  bapisdhd1,
  order_header_inx        LIKE  bapisdhd1x,
  sender                  LIKE  bapi_sender,
  binary_relationshiptype LIKE  bapireltype-reltype,
  int_number_assignment   LIKE  bapiflag-bapiflag,
  behave_when_error       LIKE  bapiflag-bapiflag,
  logic_switch            LIKE  bapisdls,
  testrun                 LIKE  bapiflag-bapiflag,
  convert                 LIKE  bapiflag-bapiflag,
  return                  TYPE TABLE OF bapiret2,
  lt_order_items_in       TYPE TABLE OF bapisditm,
  wa_order_items_in       TYPE bapisditm,
  order_items_inx	        TYPE TABLE OF	bapisditmx,
  lt_order_partners       TYPE TABLE OF bapiparnr,
  wa_order_partners       TYPE bapiparnr,
  lt_order_schedules_in   TYPE TABLE OF bapischdl,
  wa_order_schedules_in   TYPE bapischdl,
  order_schedules_inx	    TYPE TABLE OF	bapischdlx,
  order_conditions_in	    TYPE TABLE OF	bapicond,
  order_conditions_inx    TYPE TABLE OF bapicondx,
  lt_cfg_ref              TYPE TABLE OF bapicucfg,
  wa_cfg_ref              TYPE bapicucfg,
  lt_cfg_inst	            TYPE TABLE OF	bapicuins,
  wa_cfg_inst	            TYPE bapicuins,
  lt_cfg_part_of          TYPE TABLE OF bapicuprt,
  wa_cfg_part_of          TYPE bapicuprt,
  lt_cfg_val              TYPE TABLE OF bapicuval,
  wa_cfg_val              TYPE bapicuval,
  lt_cfg_blob	            TYPE TABLE OF	bapicublb,
  wa_cfg_blob	            TYPE bapicublb,
  lt_cfg_vk	              TYPE TABLE OF	bapicuvk,
  wa_cfg_vk	              TYPE bapicuvk,
  lt_cfg_refinst          TYPE TABLE OF bapicuref,
  wa_cfg_refinst          TYPE bapicuref,
  order_ccard	            TYPE TABLE OF	bapiccard,
  order_text              TYPE TABLE OF bapisdtext,
  order_keys              TYPE TABLE OF bapisdkey,
  extensionin	            TYPE TABLE OF	bapiparex,
  partneraddresses        TYPE TABLE OF bapiaddr1,
  extensionex	            TYPE TABLE OF	bapiparex.
DATA: l_posnr TYPE vbap-posnr,
      l_posex TYPE vbap-posnr,
      l_sales TYPE vbak-vbeln.


DATA: BEGIN OF sel,
        vbeln type vbak-vbeln,
        auart TYPE vbak-auart,
        bstkd TYPE vbkd-bstkd,
        vkorg TYPE vbak-vkorg,
        vtweg TYPE vbak-vtweg,
        spart TYPE vbak-spart,
        vdatu TYPE vbak-vdatu,
        kunnr TYPE vbak-kunnr,
        matnr TYPE vbap-matnr,
      END OF sel.

CONSTANTS:  gc_cross               TYPE c VALUE 'X'
           .

DATA:  lt_sales_doc               TYPE TABLE OF sales_key
      ,lt_order_headers_out       TYPE TABLE OF bapisdhd
      ,lt_order_items_out         TYPE TABLE OF bapisdit
    "  ,lt_order_items_in          TYPE TABLE OF bapisditm
      ,lt_order_schedules_out     TYPE TABLE OF bapisdhedu
      ,lt_orders_cfgs_cucref_out  TYPE TABLE OF bapicucfgm
      ,lt_orders_cfgs_curfinst    TYPE TABLE OF bapicurefm
      ,lt_orders_cfgs_ins_out     TYPE TABLE OF bapicuinsm
      ,lt_orders_cfgs_prts_out    TYPE TABLE OF bapicuprtm
      ,lt_orders_cfgs_vals_out    TYPE TABLE OF bapicuvalm
      ,lt_orders_cfgs_curef_in    TYPE TABLE OF bapicucfg
      ,lt_orders_cfgs_curefins_in TYPE TABLE OF bapicuref
      ,lt_orders_cfgs_ins_in      TYPE TABLE OF bapicuins
      ,lt_orders_cfgs_prts_in     TYPE TABLE OF bapicuprt
      ,lt_orders_cfgs_vals_in     TYPE TABLE OF bapicuval
      ,lt_order_partners_out      TYPE TABLE OF bapisdpart
      ,lt_order_partners_in       TYPE TABLE OF bapiparnr
   "   ,lt_order_schedules_in      TYPE TABLE OF bapischdl
      ,lt_order_item_inx          type table of BAPISDITMX
      ,lt_return                  type table of BAPIRET2
      ,lt_orders_cfgs_blob_out    type table of BAPICUBLBM
      ,lt_orders_cfgs_variant_out type table of BAPICUVKM


      ,lwa_order_header_in        TYPE bapisdhd1
      ,lwa_order_header_out       TYPE bapisdhd
      ,lwa_bapi_view              TYPE order_view
      ,lwa_sales_doc              TYPE sales_key
      ,lwa_order_items            TYPE bapisdit
      ,lwa_order_schedules        TYPE bapisdhedu
      ,lwa_orders_cfgs_ref_in     TYPE bapicucfg
      ,lwa_orders_cfgs_curef_out    TYPE bapicucfgm
      ,lwa_orders_cfgs_curfinst_out TYPE bapicurefm
      ,lwa_orders_cfgs_curef_in     TYPE bapicuref
      ,lwa_orders_cfgs_ins_out      TYPE bapicuinsm
      ,lwa_orders_cfgs_ins_in       TYPE bapicuins
      ,lwa_orders_cfgs_prts_in      TYPE bapicuprt
      ,lwa_orders_cfgs_prts_out     TYPE bapicuprtm
      ,lwa_orders_cfgs_vals_out     TYPE bapicuvalm
      ,lwa_orders_cfgs_vals_in      TYPE bapicuval
      ,lwa_order_items_in           TYPE bapisditm
      ,lwa_order_partner_in         TYPE bapiparnr
      ,lwa_order_partner_out        TYPE bapisdpart
      ,lwa_order_schedules_in       TYPE bapischdl
      ,lwa_order_schedules_out      TYPE bapisdhedu
      ,lwa_order_item_inx           type BAPISDITMX


      ,lv_sales_doc               TYPE vbeln
      ,lv_index                   TYPE i
      .

DEFINE set_cfg_val.
  wa_cfg_val-charc = &1.
  "Characteristic Name
  wa_cfg_val-value = &2.
  "Characteristic Value
  wa_cfg_val-valcode = ' '.
  "Value Type: Interval Limits - Single Values
  APPEND wa_cfg_val TO lt_cfg_val.
END-OF-DEFINITION.


PARAMETERS:
  pa_vbeln like sel-vbeln,
  pa_auart LIKE sel-auart,
  pa_bstkd LIKE sel-bstkd,
  pa_vkorg LIKE sel-vkorg,
  pa_vtweg LIKE sel-vtweg,
  pa_spart LIKE sel-spart,
  pa_kunnr LIKE sel-kunnr,
  pa_vdatu LIKE sel-vdatu.

SELECT-OPTIONS: so_matnr FOR sel-matnr NO INTERVALS NO-EXTENSION.

START-OF-SELECTION.

 if pa_vbeln ne space.

* define order views
lwa_bapi_view-header = gc_cross.
lwa_bapi_view-item = gc_cross.
lwa_bapi_view-sdschedule = gc_cross.
lwa_bapi_view-configure = gc_cross.
lwa_bapi_view-partner =  gc_cross.

* fill order structure
lwa_sales_doc-vbeln = pa_vbeln.
APPEND lwa_sales_doc TO lt_sales_doc.


CALL FUNCTION 'BAPISDORDER_GETDETAILEDLIST'
  EXPORTING
    i_bapi_view                   = lwa_bapi_view
*   I_MEMORY_READ                 =
  TABLES
    sales_documents               = lt_sales_doc
    order_headers_out             = lt_order_headers_out
    order_items_out               = lt_order_items_out
    order_schedules_out           = lt_order_schedules_out
*    ORDER_BUSINESS_OUT            =
    order_partners_out            = lt_order_partners_out
*   ORDER_ADDRESS_OUT             =
*   ORDER_STATUSHEADERS_OUT       =
*   ORDER_STATUSITEMS_OUT         =
*   ORDER_CONDITIONS_OUT          =
*   ORDER_COND_HEAD               =
*   ORDER_COND_ITEM               =
*   ORDER_COND_QTY_SCALE          =
*   ORDER_COND_VAL_SCALE          =
*   ORDER_CONTRACTS_OUT           =
*   ORDER_TEXTHEADERS_OUT         =
*   ORDER_TEXTLINES_OUT           =
*   ORDER_FLOWS_OUT               =
    order_cfgs_curefs_out         = lt_orders_cfgs_curfinst
    order_cfgs_cucfgs_out         = lt_orders_cfgs_cucref_out
    order_cfgs_cuins_out          = lt_orders_cfgs_ins_out
    order_cfgs_cuprts_out         = lt_orders_cfgs_prts_out
    order_cfgs_cuvals_out         = lt_orders_cfgs_vals_out
    ORDER_CFGS_CUBLBS_OUT         = lt_orders_cfgs_blob_out
    ORDER_CFGS_CUVKS_OUT          = lt_orders_cfgs_variant_out
*   ORDER_BILLINGPLANS_OUT        =
*   ORDER_BILLINGDATES_OUT        =
*   ORDER_CREDITCARDS_OUT         =
*   EXTENSIONOUT                  =
          .


READ TABLE lt_order_headers_out INTO lwa_order_header_out INDEX 1.
lv_index = lwa_order_header_out-purch_no+14(6).
ADD 1 TO lv_index.
lwa_order_header_out-purch_no+14(6) = lv_index.
lwa_order_header_in-DOC_TYPE = lwa_order_header_out-DOC_TYPE.
lwa_order_header_in-SALES_ORG = lwa_order_header_out-SALES_ORG.
lwa_order_header_in-DISTR_CHAN = lwa_order_header_out-DISTR_CHAN.
lwa_order_header_in-DIVISION = lwa_order_header_out-DIVISION.
lwa_order_header_in-purch_no_c = lwa_order_header_out-purch_no.
lwa_order_header_in-PURCH_DATE = sy-datum.

LOOP AT lt_order_partners_out INTO lwa_order_partner_out
   WHERE partn_role = 'AG'.
  lwa_order_partner_in-partn_role = lwa_order_partner_out-partn_role.
  lwa_order_partner_in-partn_numb = lwa_order_partner_out-customer.
  APPEND lwa_order_partner_in TO lt_order_partners_in.
  CLEAR lwa_order_partner_in.
ENDLOOP.


LOOP AT lt_order_items_out INTO lwa_order_items
  WHERE hg_lv_item IS INITIAL.

  READ TABLE lt_order_schedules_out INTO lwa_order_schedules_out WITH
KEY itm_number = lwa_order_items-itm_number.

  lwa_order_schedules_in-itm_number =
                                   lwa_order_schedules_out-itm_number.
  lwa_order_schedules_in-req_qty    = lwa_order_schedules_out-req_qty.
  APPEND lwa_order_schedules_in TO lt_order_schedules_in.

  lwa_order_items_in-itm_number = lwa_order_items-itm_number.
  lwa_order_items_in-material   = lwa_order_items-material.
  lwa_order_items_in-po_itm_no  =  lwa_order_items-itm_number.
  lwa_order_items_in-target_qty = lwa_order_schedules_out-req_qty.
  APPEND lwa_order_items_in TO lt_order_items_in.

  lwa_order_item_inx-itm_number = lwa_order_items-itm_number.
  lwa_order_item_inx-po_itm_no = gc_cross.
  lwa_order_item_inx-CONFIG_ID = gc_cross.
  lwa_order_item_inx-INST_ID   = gc_cross.
  append lwa_order_item_inx to lt_order_item_inx.


  CLEAR lwa_order_items_in.
ENDLOOP.

LOOP AT lt_orders_cfgs_cucref_out INTO lwa_orders_cfgs_curef_out.
  lwa_orders_cfgs_ref_in-posex      = lwa_orders_cfgs_curef_out-posex.
  lwa_orders_cfgs_ref_in-config_id  =
                                    lwa_orders_cfgs_curef_out-config_id.
  lwa_orders_cfgs_ref_in-root_id    = lwa_orders_cfgs_curef_out-root_id.
  lwa_orders_cfgs_ref_in-COMPLETE   =
                                     lwa_orders_cfgs_curef_out-COMPLETE.
  lwa_orders_cfgs_ref_in-CONSISTENT =
                                   lwa_orders_cfgs_curef_out-CONSISTENT.
  APPEND lwa_orders_cfgs_ref_in TO lt_orders_cfgs_curef_in.
  CLEAR lwa_orders_cfgs_ref_in.
ENDLOOP.

LOOP AT lt_orders_cfgs_curfinst  INTO lwa_orders_cfgs_curfinst_out.
  lwa_orders_cfgs_curef_in-posex     =
                                     lwa_orders_cfgs_curfinst_out-posex.
  lwa_orders_cfgs_curef_in-config_id =
                                 lwa_orders_cfgs_curfinst_out-config_id.
  lwa_orders_cfgs_curef_in-inst_id   =
                                   lwa_orders_cfgs_curfinst_out-inst_id.
  APPEND lwa_orders_cfgs_curef_in TO lt_orders_cfgs_curefins_in.
  CLEAR lwa_orders_cfgs_curef_in.
ENDLOOP.

LOOP AT lt_orders_cfgs_ins_out INTO lwa_orders_cfgs_ins_out.
  lwa_orders_cfgs_ins_in-config_id = lwa_orders_cfgs_ins_out-config_id.
  lwa_orders_cfgs_ins_in-inst_id = lwa_orders_cfgs_ins_out-inst_id.
  lwa_orders_cfgs_ins_in-obj_type = lwa_orders_cfgs_ins_out-obj_type.
 lwa_orders_cfgs_ins_in-class_type = lwa_orders_cfgs_ins_out-class_type.
  lwa_orders_cfgs_ins_in-obj_key       =
                                         lwa_orders_cfgs_ins_out-obj_key
.
  lwa_orders_cfgs_ins_in-quantity      =
                                      lwa_orders_cfgs_ins_out-quantity.
  lwa_orders_cfgs_ins_in-QUANTITY_UNIT =
                                lwa_orders_cfgs_ins_out-QUANTITY_UNIT.
  lwa_orders_cfgs_ins_in-COMPLETE      =
                                      lwa_orders_cfgs_ins_out-COMPLETE.
  lwa_orders_cfgs_ins_in-CONSISTENT    =
                                    lwa_orders_cfgs_ins_out-CONSISTENT.
  APPEND lwa_orders_cfgs_ins_in TO lt_orders_cfgs_ins_in.
  CLEAR lwa_orders_cfgs_ins_in.
ENDLOOP.

LOOP AT lt_orders_cfgs_prts_out INTO lwa_orders_cfgs_prts_out.
 lwa_orders_cfgs_prts_in-config_id = lwa_orders_cfgs_prts_out-config_id.
 lwa_orders_cfgs_prts_in-parent_id = lwa_orders_cfgs_prts_out-parent_id.
  lwa_orders_cfgs_prts_in-inst_id = lwa_orders_cfgs_prts_out-inst_id.
  lwa_orders_cfgs_prts_in-part_of_no =
                                    lwa_orders_cfgs_prts_out-part_of_no.
  lwa_orders_cfgs_prts_in-obj_type = lwa_orders_cfgs_prts_out-obj_type.
  lwa_orders_cfgs_prts_in-class_type =
                                    lwa_orders_cfgs_prts_out-class_type.
  lwa_orders_cfgs_prts_in-obj_key = lwa_orders_cfgs_prts_out-obj_key.
  lwa_orders_cfgs_prts_in-SALES_RELEVANT =
                                lwa_orders_cfgs_prts_out-SALES_RELEVANT.
  APPEND lwa_orders_cfgs_prts_in TO lt_orders_cfgs_prts_in.
  CLEAR lwa_orders_cfgs_prts_in.
ENDLOOP.

LOOP AT lt_orders_cfgs_vals_out INTO lwa_orders_cfgs_vals_out.
  MOVE-CORRESPONDING lwa_orders_cfgs_vals_out to lwa_orders_cfgs_vals_in
  .
*lwa_orders_cfgs_vals_in-config_id = lwa_orders_cfgs_vals_out-config_id.
*  lwa_orders_cfgs_vals_in-inst_id   = lwa_orders_cfgs_vals_out-inst_id.
*  lwa_orders_cfgs_vals_in-charc     = lwa_orders_cfgs_vals_out-charc.
*  lwa_orders_cfgs_vals_in-value     = lwa_orders_cfgs_vals_out-value.
  APPEND lwa_orders_cfgs_vals_in TO lt_orders_cfgs_vals_in.
  CLEAR lwa_orders_cfgs_vals_in.
ENDLOOP.

* ABAP (iTab) -> XML
DATA(o_writer_itab_xml) = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_xml10 ).

    CALL TRANSFORMATION id
     SOURCE values = lt_orders_cfgs_vals_in
    RESULT XML o_writer_itab_xml.
DATA(itab_xml) = cl_abap_codepage=>convert_from( o_writer_itab_xml->get_output( ) ).


CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
  EXPORTING
*   SALESDOCUMENTIN               =
    order_header_in               = lwa_order_header_in
*   ORDER_HEADER_INX              =
*   SENDER                        =
*   BINARY_RELATIONSHIPTYPE       =
*   INT_NUMBER_ASSIGNMENT         =
*   BEHAVE_WHEN_ERROR             =
*   LOGIC_SWITCH                  =
*   TESTRUN                       =
*   CONVERT                       = ' '
 IMPORTING
   salesdocument                 = lv_sales_doc
  TABLES
    RETURN                        = lt_return
    order_items_in                = lt_order_items_in
    ORDER_ITEMS_INX               = lt_order_item_inx
    order_partners                = lt_order_partners_in
    order_schedules_in            = lt_order_schedules_in
*   ORDER_SCHEDULES_INX           =
*   ORDER_CONDITIONS_IN           =
*   ORDER_CONDITIONS_INX          =
   order_cfgs_ref                = lt_orders_cfgs_curef_in
   order_cfgs_inst               = lt_orders_cfgs_ins_in
   order_cfgs_part_of            = lt_orders_cfgs_prts_in
   order_cfgs_value              = lt_orders_cfgs_vals_in
*   ORDER_CFGS_BLOB               =
*   ORDER_CFGS_VK                 =
   order_cfgs_refinst            = lt_orders_cfgs_curefins_in
*   ORDER_CCARD                   =
*   ORDER_TEXT                    =
*   ORDER_KEYS                    =
*   EXTENSIONIN                   =
*   PARTNERADDRESSES              =
          .

CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
* EXPORTING
*   WAIT          =
* IMPORTING
*   RETURN        =
          .

 else.
  wa_order_header_in-doc_type    = pa_auart.    "Document Type
  wa_order_header_in-purch_no_c  = pa_bstkd.  "PO Numer
  wa_order_header_in-sales_org   = pa_vkorg.    "Sales Organization
  wa_order_header_in-distr_chan  = pa_vtweg.   "Dristibution Channel
  wa_order_header_in-division    = pa_spart.      "Division
  wa_order_header_in-req_date_h  = pa_vdatu.   "Required Date


******************** Populate Order item details and
*flags*****************
  LOOP AT so_matnr INTO DATA(rs_matnr).

    l_posnr = l_posnr + 10.
    l_posex  = l_posnr + 11.


    wa_order_items_in-itm_number = l_posnr. "Item Number
    wa_order_items_in-po_itm_no  = l_posnr.
    "POSEX required entry during configuration
    wa_order_items_in-material   = rs_matnr-low.
    "Populate material number
    APPEND wa_order_items_in TO lt_order_items_in.
    CLEAR wa_order_items_in.

    wa_order_schedules_in-itm_number = l_posnr.
    wa_order_schedules_in-req_qty    = 1.
    "Populate quantity
    wa_order_schedules_in-sched_line =  '1'.
    APPEND wa_order_schedules_in TO lt_order_schedules_in.
    CLEAR wa_order_schedules_in.


    wa_order_items_in-itm_number = l_posex .
    "Item Number
    wa_order_items_in-po_itm_no  = l_posex .
    "POSEX required entry during configuration
    wa_order_items_in-material   = '000000003000110000'.
    "Populate material number
    APPEND wa_order_items_in TO lt_order_items_in.
    CLEAR wa_order_items_in.

    wa_order_schedules_in-itm_number = l_posex .
    wa_order_schedules_in-req_qty    = 1.
    "Populate quantity
    wa_order_schedules_in-sched_line =  '1'.
    APPEND wa_order_schedules_in TO lt_order_schedules_in.
    CLEAR wa_order_schedules_in.

********* Filling ORDER_CFGS_REFINST of type BAPICUREF with work area
*WA_CFG_REFINST
    wa_cfg_refinst-posex = l_posnr.
    wa_cfg_refinst-config_id = '000001'.
    wa_cfg_refinst-inst_id = '00000001'.
    APPEND  wa_cfg_refinst TO  lt_cfg_refinst.
    CLEAR  wa_cfg_refinst.

    wa_cfg_refinst-posex = l_posex .
    wa_cfg_refinst-config_id = '000001'.
    wa_cfg_refinst-inst_id = '00000002'.
    APPEND  wa_cfg_refinst TO  lt_cfg_refinst.
    CLEAR  wa_cfg_refinst.

*********Filling ORDER_CFGS_REF  of type BAPICUCFG with work area
*wa_cfg_cfg
    wa_cfg_ref-posex = l_posnr.
    wa_cfg_ref-config_id = '000001'.
    wa_cfg_ref-root_id = '00000001'.
    wa_cfg_ref-complete = 'T'.
    wa_cfg_ref-consistent = 'T'.
    APPEND wa_cfg_ref TO lt_cfg_ref.
    CLEAR wa_cfg_ref.

***ORDER_CFGS_INST  of type BAPICUINS with work area wa_cfg_inst
    wa_cfg_inst-config_id     =  '000001'.
    "External configuration ID (temporary)
    wa_cfg_inst-inst_id       =  '00000001'.
    "Instance number in the configuration
    wa_cfg_inst-obj_type      =  'MARA'.
    "Object type
    wa_cfg_inst-class_type    =  '300'.
    "Class type
    wa_cfg_inst-obj_key       =  '000000003000100000'.
    " Object key
    wa_cfg_inst-quantity      = 1.     "Instance Quantity
    wa_cfg_inst-quantity_unit = 'ST'.
    wa_cfg_inst-complete = 'T'.
    wa_cfg_inst-consistent = 'T'.
    APPEND wa_cfg_inst TO lt_cfg_inst.
    CLEAR wa_cfg_inst.

    wa_cfg_inst-config_id     =  '000001'.
    "External configuration ID (temporary)
    wa_cfg_inst-inst_id       =  '00000002'.
    "Instance number in the configuration
    wa_cfg_inst-obj_type      =  'MARA'.
    "Object type
    wa_cfg_inst-class_type    =  '300'.
    "Class type
    wa_cfg_inst-obj_key       =  '000000003000110000'.
    " Object key
    wa_cfg_inst-quantity      = 1.     "Instance Quantity
    wa_cfg_inst-quantity_unit = 'ST'.
    wa_cfg_inst-complete = 'T'.
    wa_cfg_inst-consistent = 'T'.
    APPEND wa_cfg_inst TO lt_cfg_inst.
    CLEAR wa_cfg_inst.

*********ORDER_CFGS_VALUE  of type BAPICUVAL with work area wa_cfg_val
*** for CHARCTERISTIC1
    CLEAR wa_cfg_val.
    wa_cfg_val-config_id = '000001'.
    "External configuration ID (temporary)
    wa_cfg_val-inst_id = '00000001'.
    "Instance number in the configuration
    wa_cfg_val-charc = 'ANTIDR0000'.
    "Characteristic Name
    wa_cfg_val-value = 'N'.
    "Characteristic Value
    wa_cfg_val-valcode = ' '.
    "Value Type: Interval Limits - Single Values
    APPEND wa_cfg_val TO lt_cfg_val.

    CLEAR wa_cfg_val.
    wa_cfg_val-config_id = '000001'.
    "External configuration ID (temporary)
    wa_cfg_val-inst_id = '00000001'.
    "Instance number in the configuration
    wa_cfg_val-charc = 'AULIEF0000'.
    "Characteristic Name
    wa_cfg_val-value = 'GU'.
    "Characteristic Value
    wa_cfg_val-valcode = ' '.
    "Value Type: Interval Limits - Single Values
    APPEND wa_cfg_val TO lt_cfg_val.

    CLEAR wa_cfg_val.
    wa_cfg_val-config_id = '000001'.
    "External configuration ID (temporary)
    wa_cfg_val-inst_id = '00000001'.
    "Instance number in the configuration
    wa_cfg_val-charc = 'AUFARBE000'.
    "Characteristic Name
    wa_cfg_val-value = '9016'.
    "Characteristic Value
    wa_cfg_val-valcode = ' '.
    "Value Type: Interval Limits - Single Values
    APPEND wa_cfg_val TO lt_cfg_val.

    CLEAR wa_cfg_val.
    wa_cfg_val-config_id = '000001'.
    "External configuration ID (temporary)
    wa_cfg_val-inst_id = '00000001'.
    "Instance number in the configuration
    wa_cfg_val-charc = 'ANZVAR0000'.
    "Characteristic Name
    wa_cfg_val-value = '1'.
    "Characteristic Value
    wa_cfg_val-valcode = ' '.
    "Value Type: Interval Limits - Single Values
    APPEND wa_cfg_val TO lt_cfg_val.

    CLEAR wa_cfg_val.
    wa_cfg_val-config_id = '000001'.
    "External configuration ID (temporary)
    wa_cfg_val-inst_id = '00000001'.
    set_cfg_val 'ABSCHL0000' space.
    " set_cfg_val 'ANTIDR0000' SPACE.
    " set_cfg_val 'ANZVAR0000' SPACE.
    set_cfg_val 'AUAUSL0000' space.
    "  set_cfg_val 'AUFARBE000' SPACE.
    set_cfg_val 'AULGL00000' space.
    set_cfg_val 'AULIEF0000' space.
    set_cfg_val 'BESCHICHT0' space.
    set_cfg_val 'FXMMANPR00' space.
    set_cfg_val 'FXMMEINS00' space.
    set_cfg_val 'FXMNETPR00' space.
    set_cfg_val 'GEHRANZ000' space.
    set_cfg_val 'GLAENGE000' space.
    set_cfg_val 'GMENGE0000' space.
    set_cfg_val 'PROFILFXM0' space.
    set_cfg_val 'PROFILFXMI' space.
    set_cfg_val 'PROFILLGL0' space.
    set_cfg_val 'PROFILLGLI' space.
    set_cfg_val 'SDVKORG000' space.
    set_cfg_val 'SDVTWEG000' space.
    set_cfg_val 'SETIKTXT00' space.
    set_cfg_val 'UMLAG00000' space.
    set_cfg_val 'UMLAGM0000' space.
    set_cfg_val 'VBAPWERK00' space.
    set_cfg_val 'VLAENGE001' space.
    set_cfg_val 'VMENGE0001' space.
    set_cfg_val 'WERKTYP000' space.


*-------
    CLEAR wa_cfg_val.
    wa_cfg_val-config_id = '000001'.
    "External configuration ID (temporary)
    wa_cfg_val-inst_id = '00000002'.
    "Instance number in the configuration
    wa_cfg_val-charc = 'AULIEF0000'.
    "Characteristic Name
    wa_cfg_val-value = 'GU'.
    "Characteristic Value
    wa_cfg_val-valcode = ' '.
    "Value Type: Interval Limits - Single Values
    APPEND wa_cfg_val TO lt_cfg_val.

    CLEAR wa_cfg_val.
    wa_cfg_val-config_id = '000001'.
    "External configuration ID (temporary)
    wa_cfg_val-inst_id = '00000002'.
    "Instance number in the configuration
    wa_cfg_val-charc = 'AUAUSL0000'.
    "Characteristic Name
    wa_cfg_val-value = '9.0000000000000000E+01'.
    "Characteristic Value
    wa_cfg_val-valcode = ' '.
    "Value Type: Interval Limits - Single Values
    APPEND wa_cfg_val TO lt_cfg_val.



    CLEAR wa_cfg_val.
    wa_cfg_val-config_id = '000001'.
    "External configuration ID (temporary)
    wa_cfg_val-inst_id = '00000002'.
    "Instance number in the configuration
    wa_cfg_val-charc = 'VMENGE0001'.
    "Characteristic Name
    wa_cfg_val-value = '1'.
    "Characteristic Value
    wa_cfg_val-valcode = ' '.
    "Value Type: Interval Limits - Single Values
    APPEND wa_cfg_val TO lt_cfg_val.

    CLEAR wa_cfg_val.
    wa_cfg_val-config_id = '000001'.
    "External configuration ID (temporary)
    wa_cfg_val-inst_id = '00000002'.
    set_cfg_val 'ABSCHL0000' space.
    set_cfg_val 'ANTIDR0000' space.
    "   set_cfg_val 'AUAUSL0000' SPACE.
    set_cfg_val 'AUFARBE000' space.
    set_cfg_val 'AUGEHR0000' space.
    set_cfg_val 'AULGL00000' space.
    set_cfg_val 'AULGLMAX00' space.
    set_cfg_val 'AULGLVS000' space.
    "  set_cfg_val 'AULIEF0000' SPACE.
    set_cfg_val 'BESCHICHT0' space.
    set_cfg_val 'FBANETPR00' space.
    set_cfg_val 'FXMBRGEW00' space.
    set_cfg_val 'FXMGEWEI00' space.
    set_cfg_val 'FXMMANPR00' space.
    set_cfg_val 'FXMMEINS00' space.
    set_cfg_val 'FXMNTGEW00' space.
    set_cfg_val 'MLGLANZ000' space.
    set_cfg_val 'PGESLAENGE' space.
    set_cfg_val 'PGESLGLANZ' space.
    set_cfg_val 'PGESLGLL00' space.
    set_cfg_val 'PGESREST00' space.
    set_cfg_val 'PROFILFXM0' space.
    set_cfg_val 'PROFILLGL0' space.
    set_cfg_val 'SDVKOND000' space.
    set_cfg_val 'SDVKORG000' space.
    set_cfg_val 'SDVTWEG000' space.
    set_cfg_val 'VARIANTE00' space.
    set_cfg_val 'VBAPWERK00' space.
    set_cfg_val 'VCSDBRGEW0' space.
    set_cfg_val 'VCSDGEWEI0' space.
    set_cfg_val 'VCSDNTGEW0' space.
    set_cfg_val 'VLAENGE000' space.
    " set_cfg_val 'VMENGE0000' SPACE.

    wa_cfg_part_of-config_id = '000001'.
    wa_cfg_part_of-parent_id = '00000001'.
    wa_cfg_part_of-inst_id = '00000002'.
    wa_cfg_part_of-part_of_no = '0010'.
    wa_cfg_part_of-obj_type = 'MARA'.
    wa_cfg_part_of-obj_key = '000000003000110000'.
    APPEND wa_cfg_part_of TO lt_cfg_part_of.
  ENDLOOP.

******************************** Populate partner
*details********************************

  wa_order_partners-partn_role = 'AG'.
  wa_order_partners-partn_numb = pa_kunnr.

  APPEND wa_order_partners TO lt_order_partners.
  CLEAR wa_order_partners.

endif.
********Create a sales order using
*BAPI_SALESORDER_CREATEFROMDAT2***********

  CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
    EXPORTING
      order_header_in    = wa_order_header_in
*     ORDER_HEADER_INX   = WA_ORDER_HEADER_INX
    IMPORTING
      salesdocument      = l_sales
    TABLES
      return             = return
      order_items_in     = lt_order_items_in
*     ORDER_ITEMS_INX    = I_ORDER_ITEMS_INX
      order_partners     = lt_order_partners
      order_schedules_in = lt_order_schedules_in
*     ORDER_SCHEDULES_INX           = I_ORDER_SCHEDULES_INX
      order_cfgs_part_of = lt_cfg_part_of
      "STRUCTURE  BAPICUPRT OPTIONAL
      order_cfgs_ref     = lt_cfg_ref
      order_cfgs_inst    = lt_cfg_inst
      order_cfgs_value   = lt_cfg_val
*     ORDER_CFGS_VK      = I_CFG_VK
      order_cfgs_refinst = lt_cfg_refinst.

*   Commit BAPI
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
