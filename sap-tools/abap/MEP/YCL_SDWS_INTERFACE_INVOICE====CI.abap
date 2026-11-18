private section.

  types:
    tty_bapisditm TYPE STANDARD TABLE OF bapisditm .
  types:
    tty_bapisditmx TYPE STANDARD TABLE OF bapisditmx .
  types:
    tty_bapiparnr TYPE STANDARD TABLE OF bapiparnr .
  types:
    tty_bapischdl TYPE STANDARD TABLE OF bapischdl .
  types:
    tty_bapischdlx TYPE STANDARD TABLE OF bapischdlx .
  types:
    tty_bapicondx TYPE STANDARD TABLE OF bapicondx .
  types:
    tty_bapisdtext TYPE STANDARD TABLE OF bapisdtext .
  types:
    tty_outputfields TYPE STANDARD TABLE OF ysdws_ex .
  types:
    tty_bapicond TYPE STANDARD TABLE OF bapicond .
  types:
    tty_bapiparex TYPE STANDARD TABLE OF bapiparex .

  data MV_NUMBER_OF_DOCUMENTS type INT4 .
  data MV_NACHFOLGER type CHAR1 .
  data MV_NO_ACC_DOC type CHAR01 .
  data MV_NSTUFEN type STUFE_VBFA .
  data MV_VORGAENGER type CHAR1 .
  data MV_VSTUFEN type STUFE_VBFA .
  data MT_VBL_GLT type TTY_VAKGU .
  data MV_ERFAB type ERDAT .
  data MV_ERFBI type ERSBI .
  data MV_FKDAB type DATAB .
  data MV_FKDBI type DATBI .
  data MV_TRVOG type TRVOG .
  data MT_SEL_BSTKD type TDT_RG_BSTKD .
  data MT_SEL_BSTNK type SACO_BSTNK_RANGES_TAB .
  data MT_SEL_ERDAT type SHP_ERDAT_RANGE_T .
  data MT_SEL_FKDAT type SHP_ERDAT_RANGE_T .
  data MT_SEL_KOMMI type YSDWS_R_KOMMITEXT .
  data MT_SEL_MATNR type RANGE_T_MATNR .
  data MT_SEL_VBELN type RANGE_VBELN_VA_TAB .
  data MT_SEL_AUBEL type RANGE_VBELN_VA_TAB .
  data MT_SEL_KUNNR type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_KUNNR .
  data MT_SEL_BESTK type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_BESTK .
  data MT_SEL_VKORG type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_VKORG .
  data MT_SEL_ERNAM type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_ERNAM .
  data MT_SEL_POSNR type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_POSNR .
  data MT_SEL_VTWEG type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_VTWEG .
  data MT_VBPAVB type VBPAVB_TAB .
  data MT_ORDER_ADDR_EX type SHP_SADRVB_T .
  data MT_OUTPUTFIELDS type TTY_OUTPUTFIELDS .
  data MT_RETURNS type BAPIRET2_T .
  data MV_CALLER type YSDWS_CALLER .
  data MV_OPTION type OPTION .
  data MS_ORDER_HEADER_EX type BAPISDHD .
  data MT_ORDER_CONDITIONS_EX type TTY_BAPICOND .
  data MT_EXTENSIONEX type TTY_BAPIPAREX .
  data MC_HEADER_POS type POSNR value '000000' ##NO_TEXT.
  constants MC_COND type CHAR4 value 'COND' ##NO_TEXT.
  constants MC_PART type CHAR4 value 'PART' ##NO_TEXT.
  constants MC_SIGN type SIGN value 'I' ##NO_TEXT.
  data MT_VBRP type VBRP_TAB .
  data MS_VBRK type VBRK .
  data MT_HEADER type VBRK_T .

  methods APPEND_HEADER_DATA
    importing
      !I_QUALIFIER type ANY
      !I_FVALUE type ANY
    returning
      value(RT_EXPORT) type YSDWS_COMHDR_TT .
  methods READ_INVOICES
    importing
      !IS_IMPORT type YSDWS_SALESDOC_DFLTCLASSATTR
    raising
      YCX_SDWS_INTERFACE .
  methods READ_INVOICE
    importing
      !IS_IMPORT type YSDWS_SALESDOC_DFLTCLASSATTR
    raising
      YCX_SDWS_INTERFACE .
  methods SET_IMPORT_DATA_WHERE
    importing
      !IV_STRNAM type ANY
    returning
      value(RV_COND_SYNTAX) type STRING .
  methods GET_FLOW_DATA
    importing
      !I_VBTYP type VBTYP
    returning
      value(ES_EXPORT) type YSDWS_CUSTOMER_DATA_E_S
    raising
      YCX_SDWS_INTERFACE .
  methods GET_ITEM_DATA
    importing
      !I_VBTYP type VBTYP
    returning
      value(ES_EXPORT) type YSDWS_CUSTOMER_DATA_E_S
    raising
      YCX_SDWS_INTERFACE .
  methods GET_PARTNERS_DATA
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_AG
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_WE
    raising
      YCX_SDWS_INTERFACE .
  methods GET_KUWE2
    importing
      !IV_KUNNR type KUNNR
      !IV_PARVW type PARVW
      !IV_VKORG type VKORG
      !IV_VTWEG type VTWEG
      !IV_SPART type SPART
    exporting
      !ES_KUNWA type KUWEV
    raising
      YCX_SDWS_INTERFACE .
  methods SET_IMPORT_DATA_RANGE .
  methods GET_KUAGV
    importing
      !IV_KUNNR type KUNNR
      !IV_PARVW type PARVW default 'AG'
      !IV_VKORG type VKORG
      !IV_VTWEG type VTWEG
      !IV_SPART type SPART
    exporting
      !ES_KUNWA type KUAGV
    changing
      !ET_VBPAVB type VBPAVB_TAB optional
    raising
      YCX_SDWS_INTERFACE .
  methods PLAUSI_CHECKS
    raising
      YCX_SDWS_INTERFACE .
  methods SET_RUN_MODE
    importing
      !IV_MODEIN type BOOKFLG
    returning
      value(RV_MODOUT) type CHAR1 .
  methods GET_DEFAULT_VALUES
    importing
      !IV_STRNAME type TABNAME
      !IV_CALLER type YSDWS_CALLER
    changing
      !CS_ZIELSTR type ANY
      !CS_ZIELSTRX type ANY optional .
  methods EXPORT_TO_ITEM
    importing
      !IV_ITMNUMBER type POSNR optional
      !IS_QUELLSTR type ANY
      !IV_STRNAM type ANY
      !IV_VAKEY type VAKEY optional
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods MAP_IMPORT
    importing
      !IS_IMPORT type YSDWS_CUSTOMER_DATA_I_S .
  methods EXPORT_BAPI_EXTENSIONS
    importing
      !IV_STRNAME type TE_STRUC
      !IV_VAKEY type ANY
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods CONSTRUCTOR .
  methods EXPORT_BAPI_PARTNER
    importing
      !IV_ITMNUMBER type POSNR
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods EXPORT_BAPI_HEADER
    returning
      value(ET_HEADER) type YSDWS_COMHDR_TT .
