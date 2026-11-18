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

  data MV_NACHFOLGER type CHAR1 .
  data MV_NO_ACC_DOC type CHAR01 .
  data MV_NSTUFEN type STUFE_VBFA .
  data MV_VORGAENGER type CHAR1 .
  data MV_VSTUFEN type STUFE_VBFA .
  data MT_VBL_GLT type TTY_VAKGU .
  data MV_ERFAB type ERDAT .
  data MV_ERFBI type ERSBI .
  data MV_GLTAB type DATAB .
  data MV_GLTBI type DATBI .
  data MV_TRVOG type TRVOG .
  data MT_SEL_BSTKD type TDT_RG_BSTKD .
  data MT_SEL_ERDAT type SHP_ERDAT_RANGE_T .
  data MT_SEL_GLDTM type SHP_ERDAT_RANGE_T .
  data MT_SEL_KOMMI type YSDWS_R_KOMMITEXT .
  data MT_SEL_MATNR type RANGE_T_MATNR .
  data MT_SEL_VBELN type RANGE_VBELN_VA_TAB .
  constants MC_SIGN type SIGN value 'I' ##NO_TEXT.
  data MT_VBPAVB type VBPAVB_TAB .
  data MT_ORDER_ADDR_EX type SHP_SADRVB_T .
  data MT_OUTPUTFIELDS type TTY_OUTPUTFIELDS .
  data MT_RETURNS type BAPIRET2_T .
  data MV_CALLER type YSDWS_CALLER .
  constants MC_PART type CHAR4 value 'PART' ##NO_TEXT.
  data MV_OPTION type OPTION .
  data MS_ORDER_HEADER_EX type BAPISDHD .
  data MT_ORDER_CONDITIONS_EX type TTY_BAPICOND .
  data MT_EXTENSIONEX type TTY_BAPIPAREX .
  data MC_HEADER_POS type POSNR value '000000' ##NO_TEXT.
  constants MC_COND type CHAR4 value 'COND' ##NO_TEXT.

  methods SET_SCED_DATA
    importing
      !IT_VBEP type VBEP_T
      !IV_POSNR type POSNR
    changing
      !CT_ITEM type YSDWS_COMITM_TT .
  methods SET_CONF_DATA
    importing
      !IT_CONF type CONF_OUT_TT
      !IV_POSNR type POSNR
    changing
      !CT_ITEM type YSDWS_COMITM_TT .
  methods GET_CONFIGURATION
    importing
      !IV_CUOBJ type CUOBJ
    returning
      value(RT_CONF) type CONF_OUT_TT .
  methods CHECK_POSNR_IN_SEL
    importing
      !IV_POSNR type POSNR
    returning
      value(RV_RESULT) type CHAR1 .
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
  methods MAP_IMPORT
    importing
      !IS_IMPORT type YSDWS_SALESDOC_DATA_I_S
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
      !IV_VAKEY type ANY optional
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
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
