  PRIVATE SECTION.

    TYPES: BEGIN OF tys_import,
             hdr TYPE ysdws_comhdr_tt,
             itm TYPE ysdws_comitm_tt,
           END OF tys_import.

    CONSTANTS mc_chare TYPE char1 VALUE 'E' ##NO_TEXT.

    DATA ms_knka TYPE knka .
    DATA mt_knkk TYPE TABLE OF knkk .
    DATA mv_ref_customer TYPE kunnr .
    DATA ms_new_cmd TYPE cmds_ei_main .
    DATA ms_ref_cmd TYPE cmds_ei_main .
    DATA mv_objecttable TYPE tabelle .
    DATA mv_classnum TYPE klasse_d .
    DATA mv_classtype TYPE klassenart .
    DATA mt_allocvaluesnum  TYPE TABLE OF bapi1003_alloc_values_num .
    DATA mt_allocvalueschar TYPE TABLE OF bapi1003_alloc_values_char .
    DATA mt_allocvaluescurr TYPE TABLE OF bapi1003_alloc_values_curr .
    DATA ms_dflt_value TYPE ysdws_cmd_ref_customer .
    DATA mt_returns TYPE ysdws_return_e_tt .
    DATA mv_caller TYPE ysdws_caller .

    METHODS constructor .
    METHODS creditlimit_change
      IMPORTING
        !iv_newkunnr TYPE kunnr
      RAISING
        ycx_sdws_interface .
    METHODS objcl_create
      IMPORTING
        !iv_newkunnr TYPE kunnr
      RAISING
        ycx_sdws_interface .
    METHODS fetch_ref_customer
      IMPORTING
        !iv_kunnr              TYPE ref_kunnr
      RETURNING
        VALUE(rv_ref_customer) TYPE kunnr
      RAISING
        ycx_sdws_interface .
    METHODS fetch_detail_objcl .
    METHODS fetch_data_cmd
      RAISING
        ycx_sdws_interface .
    METHODS fetch_data_creditmanagement .
    METHODS map_ref_customer2new
      IMPORTING
        !is_source TYPE ysdws_cmd_i_s
      RAISING
        ycx_sdws_interface .

    METHODS  map_class_data
      IMPORTING it_class TYPE ysdws_comitm_tt
      RAISING
                ycx_sdws_interface .

    METHODS map_central_data
      IMPORTING
        is_ref            TYPE cmds_ei_central_data
        is_master         TYPE tys_import
      RETURNING
        VALUE(rs_central) TYPE cmds_ei_central_data
      RAISING
        ycx_sdws_interface .

    METHODS map_company_data
      IMPORTING
        is_ref                 TYPE cmds_ei_cmd_company
        is_company             TYPE tys_import
      RETURNING
        VALUE(rs_company_data) TYPE cmds_ei_cmd_company
      RAISING
        ycx_sdws_interface .

    METHODS map_sales_data
      IMPORTING
        is_ref               TYPE cmds_ei_cmd_sales
        is_sales             TYPE tys_import
      RETURNING
        VALUE(rs_sales_data) TYPE cmds_ei_cmd_sales
      RAISING
        ycx_sdws_interface .
    METHODS create_new_customer
      RETURNING
        VALUE(rv_new_customer) TYPE kunnr
      RAISING
        ycx_sdws_interface .
    METHODS set_msg_text
      IMPORTING
        !is_bapiret TYPE bapiret2 OPTIONAL .
    METHODS set_data
      IMPORTING
        !it_source TYPE ysdws_comhdr_tt
      CHANGING
        !cs_target TYPE any .
    METHODS convert_syst_msgv
      IMPORTING
        !iv_text      TYPE any
      RETURNING
        VALUE(rv_msg) TYPE syst_msgv .
