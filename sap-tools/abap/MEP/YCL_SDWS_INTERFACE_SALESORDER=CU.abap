CLASS ycl_sdws_interface_salesorder DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    TYPES:
      tty_bapisdit TYPE STANDARD TABLE OF bapisdit .
    TYPES:
      tty_bapiparex TYPE STANDARD TABLE OF bapiparex .
    TYPES:
      tty_bapisdhedu TYPE STANDARD TABLE OF bapisdhedu .
    TYPES:
      tty_bapisdbusi TYPE STANDARD TABLE OF bapisdbusi .
    TYPES:
      tty_bapiincomp TYPE STANDARD TABLE OF bapiincomp .
    TYPES:
      tty_bapicond TYPE STANDARD TABLE OF bapicond .
    TYPES:
      tty_bapisdtehd TYPE STANDARD TABLE OF bapisdtehd .
    TYPES:
      tty_bapitextli TYPE STANDARD TABLE OF bapitextli .
    TYPES:
      tty_bapisdpart TYPE STANDARD TABLE OF vbpavb .

    DATA ms_kunwe TYPE kuwev .
    DATA ms_kunag TYPE kuagv .
    CLASS-DATA mo_instance TYPE REF TO ycl_sdws_interface_salesorder .

    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_instance) TYPE REF TO ycl_sdws_interface_salesorder .
    CLASS-METHODS save_document_sd_sales
      IMPORTING
        !f_updkz TYPE updkz_d OPTIONAL
        !ft180   TYPE t180
      CHANGING
        !fyvblb  TYPE va_vblbvb_t
        !fxvblb  TYPE va_vblbvb_t
        !fyvbadr TYPE shp_sadrvb_t
        !fxvbadr TYPE shp_sadrvb_t
        !fyvbfa  TYPE va_vbfavb_t
        !fyvbep  TYPE va_vbepvb_t
        !fyvbkd  TYPE va_vbkdvb_t
        !fyvbpa  TYPE va_vbpavb_t
        !fyvbuk  TYPE va_vbukvb_t
        !fyvbup  TYPE va_vbupvb_t
        !fyfpla  TYPE va_fplavb_t
        !fyfplt  TYPE va_fpltvb_t
        !fvbak   TYPE vbak
        !fxvbap  TYPE va_vbapvb_t
        !fxkomv  TYPE va_komv_t
        !fxvbapf TYPE va_vbapf_t
        !fxvbfa  TYPE va_vbfavb_t
        !fxvbep  TYPE va_vbepvb_t
        !fxvbkd  TYPE va_vbkdvb_t
        !fxvbpa  TYPE va_vbpavb_t
        !fxvbuk  TYPE va_vbukvb_t
        !fxvbup  TYPE va_vbupvb_t
        !fxfpla  TYPE va_fplavb_t
        !fxfplt  TYPE va_fpltvb_t
        !fyvbak  TYPE vbak
        !fyvbapf TYPE va_vbapf_t
        !fyvbap  TYPE va_vbapvb_t .
    METHODS create_salesorder
      IMPORTING
        !is_import TYPE ysdws_salesorder_i_s
      EXPORTING
        !es_export TYPE ysdws_salesorder_e_s
      RAISING
        ycx_sdws_interface .
    METHODS set_salesorder_response
      IMPORTING
        !is_sales_header_out    TYPE bapisdhd
        !is_sales_header_status TYPE bapisdhdst
        !it_items_ex            TYPE tty_bapisdit
        !it_schedule_ex         TYPE tty_bapisdhedu
        !it_business_ex         TYPE tty_bapisdbusi
        !it_incomplete_log      TYPE tty_bapiincomp
        !it_extensionex         TYPE tty_bapiparex
        !it_conditions_ex       TYPE tty_bapicond
        !it_partners_ex         TYPE tty_bapisdpart
        !it_textheaders_ex      TYPE tty_bapisdtehd
        !it_textlines_ex        TYPE tty_bapitextli
      RAISING
        ycx_sdws_interface .
