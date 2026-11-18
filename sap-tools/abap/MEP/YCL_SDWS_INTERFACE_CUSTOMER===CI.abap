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
  types:
    tty_knmt TYPE STANDARD TABLE OF knmt .
  types:
    BEGIN OF ty_r_ort,
      sign   TYPE ddsign,
      option TYPE ddoption,
      low    TYPE ort01,
      high   TYPE ort01,
    END OF ty_r_ort .
  types:
    tty_ort TYPE STANDARD TABLE OF ty_r_ort .
  types:
    BEGIN OF ty_r_telf1,
      sign   TYPE ddsign,
      option TYPE ddoption,
      low    TYPE telf1,
      high   TYPE telf1,
    END OF ty_r_telf1 .
  types:
    tty_telf1 TYPE STANDARD TABLE OF ty_r_telf1 .
  types:
    BEGIN OF ty_r_name,
      sign   TYPE ddsign,
      option TYPE ddoption,
      low    TYPE name1_gp,
      high   TYPE name1_gp,
    END OF ty_r_name .
  types:
    tty_name TYPE STANDARD TABLE OF ty_r_name .
  types:
    BEGIN OF ty_r_kdmat,
      sign   TYPE ddsign,
      option TYPE ddoption,
      low    TYPE kdmat,
      high   TYPE kdmat,
    END OF ty_r_kdmat .
  types:
    tty_kdmat TYPE STANDARD TABLE OF ty_r_kdmat .
  types:
    rty_fkdat TYPE TABLE OF range_fkart .

  data MV_NODATA_FOUND type NO_DATA .
  data MT_SOLDMAT type YSDWS_T_MATSOLD .
  data MT_KNMT type TTY_KNMT .
  data MV_NUMBER_OF_DOCUMENTS type INT4 .
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
  data MT_SEL_BSTNK type SACO_BSTNK_RANGES_TAB .
  data MT_SEL_KDMAT type TTY_KDMAT .
  data MT_SEL_NAME type TTY_NAME .
  data MT_SEL_ORT type TTY_ORT .
  data MT_SEL_TELFN type TTY_TELF1 .
  data:
    mt_kna1 TYPE TABLE OF kna1 .
  data MS_KNVV type KNVV .
  data MT_SEL_KUNNR type YSDWS_KUNNR_R .
  data MT_SEL_FKDAT type SHP_ERDAT_RANGE_T .
  data MT_SEL_FKART type RTY_FKDAT .
  data MT_SEL_KUNRG type YSDWS_KUNNR_R .

  methods APPEND_HEADER_DATA
    importing
      !I_QUALIFIER type ANY
      !I_FVALUE type ANY
    returning
      value(RT_EXPORT) type YSDWS_COMHDR_TT .
  methods CHECK_KOMMITXT_IN_SEL
    importing
      !IS_WA type ANY
    returning
      value(RV_RESULT) type CHAR1 .
  methods GET_SALESDOCUMENT_DB .
  methods GET_VBELN_VMVAA
    returning
      value(RT_VBELN) type TTY_VBELN
    raising
      YCX_SDWS_INTERFACE .
  methods COMPARE_SELOPTION
    returning
      value(RT_VBELN) type TTY_VBELN .
  methods GET_VBELN_VAKGU
    returning
      value(RT_VBELN) type TTY_VBELN
    raising
      YCX_SDWS_INTERFACE .
  methods GET_VBELN_VAKPA
    returning
      value(RT_VBELN) type TTY_VBELN
    raising
      YCX_SDWS_INTERFACE .
  methods GET_VBELN_VAPMA
    returning
      value(RT_VBELN) type TTY_VBELN
    raising
      YCX_SDWS_INTERFACE .
  methods SET_IMPORT_DATA_RANGE .
  methods GET_CUSTOMERMATERIAL_DATA
    raising
      YCX_SDWS_INTERFACE .
  methods GET_MATERIALSSOLDLIST
    raising
      YCX_SDWS_INTERFACE .
  methods GET_OFFERS_DATA
    raising
      YCX_SDWS_INTERFACE .
  methods GET_ORDERS_DATA
    raising
      YCX_SDWS_INTERFACE .
  methods GET_PARTNERS_DATA
    returning
      value(RT_ITEM) type YSDWS_COMITM_TT
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
  methods EXPORT_TO_ITEM
    importing
      !IV_ITMNUMBER type POSNR optional
      !IS_QUELLSTR type ANY
      !IV_STRNAM type ANY
      !IV_VAKEY type VAKEY optional
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods EXPORT_BAPI_COND
    importing
      !IV_ITMNUMBER type POSNR
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
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
  methods EXPORT_BAPI_ITEM
    importing
      !IV_ITMNUMBER type POSNR
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
  methods EXPORT_DB_CUSTOMERMATERIAL_DAT
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods EXPORT_DB_MATERIALSSOLD_DATA
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods EXPORT_DB_CUSTOMER_GENERALDATA
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods EXPORT_DB_CUSTOMER_SALESDATA
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods EXPORT_BAPI_HEADER
    importing
      !IS_QUELLSTR type ANY
      !IV_STRNAM type ANY
      !IV_VAKEY type ANY optional
    returning
      value(ET_HEADER) type YSDWS_COMHDR_TT .
  methods GET_CUSTOMERLIST
    raising
      YCX_SDWS_INTERFACE .
  methods GET_CUSTOMERSALESDATA
    raising
      YCX_SDWS_INTERFACE .
