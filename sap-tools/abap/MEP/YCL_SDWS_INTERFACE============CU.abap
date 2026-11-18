class YCL_SDWS_INTERFACE definition
  public
  create public .

public section.

  types:
    BEGIN OF  ty_s_service,
        caller  TYPE ysdws_caller,
        service TYPE ysdws_interface,
      END OF ty_s_service .
  types:
    BEGIN OF ty_s_attr_werks_determin .
          INCLUDE TYPE ysdws_plant_atp_header_i_s.  " Webshop: Verfügbarkeitsprüfung - Importstruktur " Webshop: Verfügbarkeitsprüfung - Importstruktur " Webshop: Verfügbarkeitsprüfung - Importstruktur " Webshop: Verfügbarkeitsprüfung - Importstruktur " W
    TYPES:  matnr TYPE matnr,
            END OF ty_s_attr_werks_determin .
  types:
    tty_outputfields TYPE STANDARD TABLE OF ysdws_ex .

  data MS_KNVV type KNVV .
  data MS_MAAPV type MAAPV .
  data MS_MAEPV type MAEPV .

  methods FETCH_MAAPV
    importing
      !IS_MTCOM type MTCOM
    returning
      value(RS_MAAPV) type MAAPV
    raising
      YCX_SDWS_INTERFACE .
  methods FETCH_MAEPV
    importing
      !IS_MTCOM type MTCOM
    returning
      value(RS_MAEPV) type MAEPV
    raising
      YCX_SDWS_INTERFACE .
  methods GET_DEFAULT_VALUES
    changing
      !CS_ZIELSTR type ANY
      !CS_ZIELSTRX type ANY optional .
  methods CONVERT_EXT2INT
    changing
      !CS_VALUES type ANY .
  methods FETCH_KUWE2
    importing
      !IS_VTCOM type VTCOM
    returning
      value(RS_KNVV) type KNVV
    raising
      YCX_SDWS_INTERFACE .
  methods CONSTRUCTOR .
  methods GET_DESCRIPTION
    importing
      !IV_TABNAME type TABNAME
      !IV_FIELDNAME type FIELDNAME
      !IV_VALUE type ANY
      !IV_VAKEY type ANY
    exporting
      !ES_VALUES type YSDWS_COMITM_S .
  methods GET_PRODH_TEXT
    importing
      !IV_FIELDNAME type FIELDNAME
      !IV_VALUE type ANY
      !IV_VAKEY type ANY
    changing
      !CT_VALUES type YSDWS_COMITM_TT .
  methods EXPORT_TO_ITEM
    importing
      !IV_VAKEY type STRING
      !IS_QUELLSTR type ANY
      !IV_STRNAM type ANY
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods GET_WEEK_FROM_COM_DATE
    importing
      !IS_WMDVEX type BAPIWMDVE
    returning
      value(RV_WEEK) type SCAL-WEEK .
