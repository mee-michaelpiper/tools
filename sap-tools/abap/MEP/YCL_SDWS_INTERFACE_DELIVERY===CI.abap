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

  constants MC_COND type CHAR4 value 'COND' ##NO_TEXT.
  constants MC_PART type CHAR4 value 'PART' ##NO_TEXT.
  constants MC_SIGN type SIGN value 'I' ##NO_TEXT.
  data MC_HEADER_POS type POSNR value '000000' ##NO_TEXT.
  data MS_LIKP type LIKP .
  data MS_ORDER_HEADER_EX type BAPISDHD .
  data MT_EXTENSIONEX type TTY_BAPIPAREX .
  data MT_LIPS type TAB_LIPS .
  data MT_ITEMS type BAPIDLVITEM_T .
  data MT_HEADER type BAPIDLVHDR_T .
  data MT_ORDER_ADDR_EX type SHP_SADRVB_T .
  data MT_ORDER_CONDITIONS_EX type TTY_BAPICOND .
  data MT_OUTPUTFIELDS type TTY_OUTPUTFIELDS .
  data MT_RETURNS type BAPIRET2_T .
  data MT_SEL_KUNNR type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_KUNNR .
  data MT_SEL_BESTK type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_BESTK .
  data MT_SEL_BSTKD type TDT_RG_BSTKD .
  data MT_SEL_VTWEG type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_VTWEG .
  data MT_SEL_VKORG type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_VKORG .
  data MT_SEL_ERNAM type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_ERNAM .
  data MT_SEL_ERDAT type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_ERDAT .
  data MT_SEL_KOMMI type YSDWS_R_KOMMITEXT .
  data MT_SEL_MATNR type RANGE_T_MATNR .
  data MT_SEL_AUFNR type RANGE_VBELN_VA_TAB .
  data MT_SEL_VBELN type RANGE_VBELN_VA_TAB .
  data MT_SEL_BSTNK type SACO_BSTNK_RANGES_TAB .
  data MT_SEL_LFDAT type MSR_T_INSP_LFDAT_RANGE .
  data MT_VBL_GLT type TTY_VAKGU .
  data MT_VBPAVB type VBPAVB_TAB .
  data MV_CALLER type YSDWS_CALLER .
  data MV_ERFAB type ERDAT .
  data MV_ERFBI type ERSBI .
  data MV_LFDAB type DATAB .
  data MV_LFDBI type DATBI .
  data MV_NACHFOLGER type CHAR1 .
  data MV_NO_ACC_DOC type CHAR01 .
  data MV_NSTUFEN type STUFE_VBFA .
  data MV_OPTION type OPTION .
  data MV_TRVOG type TRVOG .
  data MV_VORGAENGER type CHAR1 .
  data MV_VSTUFEN type STUFE_VBFA .
  data MV_NUMBER_OF_DOCUMENTS type INT4 .
  data MT_SEL_POSNR type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_POSNR .
  data MT_VTRKH type /FIS/VTRKH_TAB .

  methods APPEND_HEADER_DATA
    importing
      !I_QUALIFIER type ANY
      !I_FVALUE type ANY
    returning
      value(RT_EXPORT) type YSDWS_COMHDR_TT .
  methods READ_DELIVERIES
    importing
      !IS_IMPORT type YSDWS_SALESDOC_DFLTCLASSATTR
    raising
      YCX_SDWS_INTERFACE .
  methods READ_DELIVERY
    importing
      !IS_IMPORT type YSDWS_SALESDOC_DFLTCLASSATTR
    raising
      YCX_SDWS_INTERFACE .
  methods SET_IMPORT_DATA_WHERE
    importing
      !IV_STRNAM type ANY
    returning
      value(RV_COND_SYNTAX) type STRING .
  methods CHECK_AG
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_WE
    raising
      YCX_SDWS_INTERFACE .
  methods PLAUSI_CHECKS
    raising
      YCX_SDWS_INTERFACE .
  methods SET_IMPORT_DATA_RANGE .
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
      !IV_VAKEY type STRING
      !IS_QUELLSTR type ANY
      !IV_STRNAM type ANY
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
