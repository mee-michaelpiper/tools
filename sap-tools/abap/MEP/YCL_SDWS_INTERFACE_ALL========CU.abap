class YCL_SDWS_INTERFACE_ALL definition
  public
  final
  create private .

public section.

  types:
    tty_sel_posnr TYPE RANGE OF posnr .
  types:
    tty_sel_vtweg TYPE RANGE OF vtweg .
  types:
    tty_sel_vkorg TYPE RANGE OF vkorg .
  types:
    tty_sel_vbeln TYPE RANGE OF vbeln .
  types:
    tty_sel_bestk TYPE RANGE OF bestk .
  types:
    tty_sel_aufnr TYPE RANGE OF aufnr .
  types:
    tty_sel_matnr TYPE RANGE OF matnr .
  types:
    tty_sel_kunnr TYPE RANGE OF kunnr .
  types:
    tty_sel_erdat TYPE RANGE OF erdat .
  types:
    tty_sel_ernam TYPE RANGE OF ernam .

  constants MC_INTERFACE_CMD type YSDWS_INTERFACE value '13' ##NO_TEXT.
  constants MC_INTERFACE_PLANT_AVAIL type YSDWS_INTERFACE value '12' ##NO_TEXT.
  constants MC_INTERFACE_AVAIL type YSDWS_INTERFACE value '01' ##NO_TEXT.
  constants MC_INTERFACE_PRICING type YSDWS_INTERFACE value '02' ##NO_TEXT.
  constants MC_KAPPL_V type KAPPL value 'V' ##NO_TEXT.
  constants MC_KVEWE_A type KVEWE value 'A' ##NO_TEXT.
  constants MC_DEFAULT_VKORG type VBAK-VKORG value '100' ##NO_TEXT.
  constants MC_DEFAULT_VTWEG type VBAK-VTWEG value '00' ##NO_TEXT.
  constants MC_DEFAULT_SPART type VBAK-SPART value '00' ##NO_TEXT.
  class-data MV_MESSAGE_SPRAS type T002-SPRAS .
  constants MC_INTERFACE_SALESORDER type YSDWS_INTERFACE value '03' ##NO_TEXT.
  class-data MV_CALLER type YSDWS_CALLER .
  class-data MO_INSTANCE type ref to YCL_SDWS_INTERFACE_ALL .
  class-data MV_SET_ALL_OUTPUT_DATA type CHAR1 .
  constants MC_INTERFACE_CUSTOMER_DATA type YSDWS_INTERFACE value '04' ##NO_TEXT.
  class-data MV_INTERFACE type YSDWS_INTERFACE .
  constants MC_INTERFACE_SUPPLIER_DATA type YSDWS_INTERFACE value '10' ##NO_TEXT.
  constants MC_INTERFACE_DOCUMENT type YSDWS_INTERFACE value '05' ##NO_TEXT.
  constants MC_INTERFACE_INVOICE type YSDWS_INTERFACE value '08' ##NO_TEXT.
  constants MC_INTERFACE_DELIVERY type YSDWS_INTERFACE value '07' ##NO_TEXT.
  constants MC_INTERFACE_SALESDOC type YSDWS_INTERFACE value '06' ##NO_TEXT.
  constants MC_INTERFACE_ARTICLE type YSDWS_INTERFACE value '09' ##NO_TEXT.
  constants MC_INTERFACE_GETDBDATA type YSDWS_INTERFACE value '11' ##NO_TEXT.

  methods CONVERT_2BASE64
    importing
      !IV_BINDATA type XSTRING optional
      value(IV_BINLENG) type I optional
      !IV_BAPIMSG type ANY optional
      !IT_RETURNS type YSDWS_RETURN_E_TT optional
    returning
      value(RV_B64DATA) type STRING
    raising
      YCX_SDWS_INTERFACE .
  methods SET_MSG_FIELDS
    exporting
      !ES_MSG_FIELDS type SCX_T100KEY .
  methods CHECK_SESSION_ID
    importing
      !IV_SESSIONID type YSDWS_SESSIONID
    raising
      YCX_SDWS_INTERFACE .
  methods ENQUEUE_SESSION_ID
    importing
      !IV_SESSION_ID type YSDWS_SESSIONID
    raising
      YCX_SDWS_INTERFACE .
  methods DEQUEUE_SESSION_ID
    importing
      !IV_SESSION_ID type YSDWS_SESSIONID .
  methods CHECK_KUNNR
    importing
      !IV_KUNNR type YSDWS_AVAILABILITY_I_S-I_KUNNR
      !IV_VKORG type YSDWS_AVAILABILITY_I_S-I_VKORG optional
      !IV_VTWEG type YSDWS_AVAILABILITY_I_S-I_VTWEG optional
      !IV_SPART type YSDWS_AVAILABILITY_I_S-I_SPART optional
    returning
      value(RV_KUN_WERKS) type KNVV-VWERK
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_ISO_LANGU
    importing
      !IV_LANGU type SPRAS_ISO
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_MATNR
    importing
      !IV_MATNR type ANY
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_WERKS
    importing
      !IV_WERKS type YSDWS_AVAILABILITY_MAT_I_S-I_WERKS
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_MATNR_WERKS
    importing
      !IV_MATNR type YSDWS_AVAILABILITY_MAT_I_S-I_MATNR
      !IV_WERKS type YSDWS_AVAILABILITY_MAT_I_S-I_WERKS
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_AUART
    importing
      !IV_AUART type VBAK-AUART
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_KALSM
    importing
      !IV_KALSM type VBAK-KALSM
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_ISO_CODE_UNIT
    importing
      !IV_ISO_CODE type ANY
    raising
      YCX_SDWS_INTERFACE .
  methods CONVERT_SAP_LANG_TO_ISO_LANG
    importing
      !IV_INPUT type T002-SPRAS
    exporting
      !EV_OUTPUT type T002-LAISO .
  methods GET_WEEK_FROM_COM_DATE
    importing
      !IS_WMDVEX type BAPIWMDVE
    changing
      !CS_KOND type YSDWS_AVAILABILITY_MAT_E_S .
  methods CONVERT_ISO_MEINS_SO_SAP_CODE
    importing
      !IV_ISOCODE_UNIT type ISOCD_UNIT
    returning
      value(RV_MSEHI) type T006-MSEHI
    raising
      YCX_SDWS_INTERFACE .
  methods START_LOG
    importing
      !IV_INTERFACE type YSDWS_INTERFACE
      !IV_SESSION_ID type YSDWS_SESSIONID .
  methods END_LOG
    importing
      !IS_IMPORT_AVAIL type YSDWS_AVAILABILITY_I_S optional
      !IS_EXPORT_AVAIL type YSDWS_AVAILABILITY_E_S optional
      !IS_IMPORT_PRICING type YSDWS_PRICING_I_S optional
      !IS_EXPORT_PRICING type YSDWS_PRICING_E_S optional
      !IS_IMPORT_SALESORDER type YSDWS_SALESORDER_I_S optional
      !IS_EXPORT_SALESORDER type YSDWS_SALESORDER_E_S optional
      !IS_IMPORT_CUSTOMER_DATA type YSDWS_CUSTOMER_DATA_I_S optional
      !IS_EXPORT_CUSTOMER_DATA type YSDWS_CUSTOMER_DATA_E_S optional
      !IV_SERVICE type YSDWS_INTERFACE optional
      !IS_IMPORT_DOCUMENT type YSDWS_DOCUMENT_DATA_I_S optional
      !IS_EXPORT_DOCUMENT type YSDWS_DOCUMENT_E_S optional
      !IS_IMPORT type ANY optional
      !IS_EXPORT type ANY optional .
  methods WRITE_LOG
    importing
      !IS_IMPORT_AVAIL type YSDWS_AVAILABILITY_I_S optional
      !IS_EXPORT_AVAIL type YSDWS_AVAILABILITY_E_S optional
      !IS_IMPORT_PRICING type YSDWS_PRICING_I_S optional
      !IS_EXPORT_PRICING type YSDWS_PRICING_E_S optional
      !IS_IMPORT_SALESORDER type YSDWS_SALESORDER_I_S optional
      !IS_EXPORT_SALESORDER type YSDWS_SALESORDER_E_S optional
    changing
      !CS_LOG_TIME type YSDWS_LOG_TIME
      !CT_LOG_VALUE type YSDWS_LOG_VALUE_TT .
  methods CHECK_FOR_INITIAL_MENG
    importing
      !IV_MENGE type YSDWS_PRICING_MAT_I_S-I_MENGE
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_VTBER
    importing
      !IV_VKORG type YSDWS_PRICING_I_S-I_VKORG
      !IV_VTWEG type YSDWS_PRICING_I_S-I_VTWEG
      !IV_SPART type YSDWS_PRICING_I_S-I_SPART
    raising
      YCX_SDWS_INTERFACE .
  methods GET_MATERIAL_VRKME
    importing
      !IV_MATNR type MATNR
      !IV_VKORG type VKORG optional
      !IV_VTWEG type VTWEG optional
    returning
      value(RV_MEINH) type MEINH .
  class-methods GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to YCL_SDWS_INTERFACE_ALL .
  methods SET_ATTRIBUT
    importing
      !IS_IMPORT type YSDWS_SALESORDER_I_S
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_MARM_ENTRY
    importing
      !IV_MATNR type MATNR
      !IV_VRKME_ISO type ISOCD_UNIT
    raising
      YCX_SDWS_INTERFACE .
  methods GET_DESCRIPTION
    importing
      !IV_TABNAME type TABNAME
      !IV_FIELDNAME type FIELDNAME
      !IV_VALUE type ANY
      !IV_VAKEY type ANY
    exporting
      !ES_VALUES type YSDWS_COMITM_S .
