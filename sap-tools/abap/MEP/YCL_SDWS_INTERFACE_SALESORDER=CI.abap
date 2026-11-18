  PRIVATE SECTION.

    TYPES:
      tty_bapisditm TYPE STANDARD TABLE OF bapisditm .
    TYPES:
      tty_bapisditmx TYPE STANDARD TABLE OF bapisditmx .
    TYPES:
      tty_bapiparnr TYPE STANDARD TABLE OF bapiparnr .
    TYPES:
      tty_bapischdl TYPE STANDARD TABLE OF bapischdl .
    TYPES:
      tty_bapischdlx TYPE STANDARD TABLE OF bapischdlx .
    TYPES:
      tty_bapicondx TYPE STANDARD TABLE OF bapicondx .
    TYPES:
      tty_bapisdtext TYPE STANDARD TABLE OF bapisdtext .
    TYPES:
      tty_outputfields TYPE STANDARD TABLE OF ysdws_ex .

    DATA mt_order_addr_ex TYPE shp_sadrvb_t .
    DATA mc_header_pos TYPE posnr VALUE '000000' ##NO_TEXT.
    DATA mt_outputfields TYPE tty_outputfields .
    DATA mt_returns TYPE bapiret2_t .
    DATA mv_caller TYPE ysdws_caller .
    CONSTANTS mc_cond TYPE char4 VALUE 'COND' ##NO_TEXT.
    CONSTANTS mc_item TYPE char4 VALUE 'ITEM' ##NO_TEXT.
    CONSTANTS mc_text TYPE char4 VALUE 'TEXT' ##NO_TEXT.
    DATA ms_order_header_in TYPE bapisdhd1 .
    DATA ms_order_header_inx TYPE bapisdhd1x .
    DATA ms_logic_switch TYPE bapisdls .
    DATA mv_testrun TYPE bapiflag .
    DATA mt_order_items_in TYPE tty_bapisditm .
    DATA mt_order_items_inx TYPE tty_bapisditmx .
    DATA mt_order_partners TYPE tty_bapiparnr .
    DATA mt_order_schedules_in TYPE tty_bapischdl .
    DATA mt_order_schedules_inx TYPE tty_bapischdlx .
    DATA mt_order_conditions_in TYPE tty_bapicond .
    DATA mt_order_conditions_inx TYPE tty_bapicondx .
    DATA mt_order_text TYPE tty_bapisdtext .
    DATA mt_extensionin TYPE tty_bapiparex .
    DATA mt_extensionex TYPE tty_bapiparex .
    CONSTANTS mc_part TYPE char4 VALUE 'PART' ##NO_TEXT.
    DATA ms_order_header_ex TYPE bapisdhd .
    DATA mt_order_conditions_ex TYPE tty_bapicond .
    DATA mt_order_schedules_ex TYPE tty_bapisdhedu .
    DATA mt_order_items_ex TYPE tty_bapisdit .
    DATA mt_order_partners_ex TYPE tty_bapisdpart .
    CONSTANTS mc_sche TYPE char4 VALUE 'SCED' ##NO_TEXT.
    DATA mt_order_sdbusi_ex TYPE tty_bapisdbusi .
*  DATA mt_order_cfgs_ref  TYPE TABLE OF bapicucfg. "  Konfiguration: Referenzdaten
*  DATA mt_order_cfgs_inst TYPE TABLE OF   bapicuins. "  Konfiguration: Instanzen
*  DATA mt_order_cfgs_part_of  TYPE TABLE OF   bapicuprt. "  Konfiguration: Part-of Angaben
*  DATA mt_order_cfgs_value  TYPE TABLE OF   bapicuval. "  Konfiguration: Merkmalswerte
    DATA ms_cfgs TYPE ysdws_comcfg_ts .

    METHODS set_sysmsg_text .
    METHODS change_import_data .
    METHODS check_ag
      RAISING
        ycx_sdws_interface .
    METHODS check_we
      RAISING
        ycx_sdws_interface .
    METHODS constructor .
    METHODS export_bapi_cond
      IMPORTING
        !iv_itmnumber  TYPE posnr
      RETURNING
        VALUE(et_item) TYPE ysdws_comitm_tt .
    METHODS export_bapi_extensions
      IMPORTING
        !iv_strname          TYPE te_struc
        !iv_itmnumber        TYPE posnr
      RETURNING
        VALUE(es_salesorder) TYPE ysdws_salesorder_e_s .
    METHODS export_bapi_header
      RETURNING
        VALUE(et_header) TYPE ysdws_comhdr_tt .
    METHODS export_bapi_item
      IMPORTING
        !iv_itmnumber  TYPE posnr
      RETURNING
        VALUE(et_item) TYPE ysdws_comitm_tt .
    METHODS export_bapi_partner
      IMPORTING
        !iv_itmnumber  TYPE posnr
      RETURNING
        VALUE(et_item) TYPE ysdws_comitm_tt .
    METHODS export_bapi_schedules
      IMPORTING
        !iv_itmnumber  TYPE posnr
      RETURNING
        VALUE(et_item) TYPE ysdws_comitm_tt .
    METHODS fill_bapi_cond
      IMPORTING
        !it_import TYPE ysdws_comitm_tt .
    METHODS fill_bapi_header
      IMPORTING
        !it_header TYPE ysdws_comhdr_tt
      RAISING
        ycx_sdws_interface .
    METHODS fill_bapi_header_customer
      IMPORTING
        !is_bape_vbak  TYPE bape_vbak
        !is_bape_vbakx TYPE bape_vbakx .
    METHODS fill_bapi_item
      IMPORTING
        !it_import TYPE ysdws_comitm_tt .
    METHODS fill_bapi_item_customer
      IMPORTING
        !is_bape_vbap  TYPE bape_vbap
        !is_bape_vbapx TYPE bape_vbapx
        !iv_posnr      TYPE posnr .
    METHODS fill_bapi_partner
      IMPORTING
        !it_import TYPE ysdws_comitm_tt .
    METHODS fill_bapi_schedule
      IMPORTING
        !it_import TYPE ysdws_comitm_tt .
    METHODS fill_bapi_text
      IMPORTING
        !it_import TYPE ysdws_comitm_tt .
    METHODS get_default_values
      IMPORTING
        !iv_strname  TYPE tabname
        !iv_caller   TYPE ysdws_caller
      CHANGING
        !cs_zielstr  TYPE any
        !cs_zielstrx TYPE any .
    METHODS get_kuagv
      IMPORTING
        !iv_kunnr TYPE kunnr
        !iv_parvw TYPE parvw
        !iv_vkorg TYPE vkorg
        !iv_vtweg TYPE vtweg
        !iv_spart TYPE spart
      EXPORTING
        !es_kunwa TYPE kuagv
      RAISING
        ycx_sdws_interface .
    METHODS get_kuwe2
      IMPORTING
        !iv_kunnr TYPE kunnr
        !iv_parvw TYPE parvw
        !iv_vkorg TYPE vkorg
        !iv_vtweg TYPE vtweg
        !iv_spart TYPE spart
      EXPORTING
        !es_kunwa TYPE kuwev
      RAISING
        ycx_sdws_interface .
    METHODS map_export
      RETURNING
        VALUE(rs_export) TYPE ysdws_salesorder_e_s .
    METHODS map_import
      IMPORTING
        !is_import TYPE ysdws_salesorder_i_s
      RAISING
        ycx_sdws_interface .
    METHODS plausi_checks
      RAISING
        ycx_sdws_interface .
    METHODS set_run_mode
      IMPORTING
        !iv_modein       TYPE bookflg
      RETURNING
        VALUE(rv_modout) TYPE char1 .
    METHODS fill_bapi_cfgs
      IMPORTING
        !is_cfgs TYPE ysdws_comcfg_ts
      RAISING
        ycx_sdws_interface .
