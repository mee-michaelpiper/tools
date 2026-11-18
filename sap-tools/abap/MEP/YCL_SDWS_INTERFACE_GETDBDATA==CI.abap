private section.

  types TTY_OUTPUTFIELDS type CHAR10 .
  types:
    BEGIN OF ty_s_clause.
  TYPES:   line(72)  TYPE c.
  TYPES: END OF ty_s_clause .
  types:
    tty_clause TYPE TABLE OF ty_s_clause
WITH NON-UNIQUE KEY TABLE_LINE .
  types:
    tty_SE16N_SELTAB  type table of SE16N_SELTAB
WITH NON-UNIQUE KEY TABLE_LINE .
  types:
    tty_columns TYPE TABLE OF string
WITH NON-UNIQUE KEY TABLE_LINE .

  data MV_NUMBER_OF_DOCUMENTS type INT4 .
  data MT_OUTPUTFIELDS type TTY_OUTPUTFIELDS .
  data MT_RETURNS type BAPIRET2_T .
  data MV_CALLER type YSDWS_CALLER .
  data MV_OPTION type OPTION .

  methods CHECK_IFIELDS
    importing
      value(IF_TDESCR) type ref to CL_ABAP_STRUCTDESCR
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_OFIELDS
    importing
      value(IF_TDESCR) type ref to CL_ABAP_STRUCTDESCR
    changing
      !CT_FIELDS type SE16N_OUTPUT_T
    raising
      YCX_SDWS_INTERFACE .
  methods GET_REF_COMPONENTS_OF
    returning
      value(RF_TDESCR) type ref to CL_ABAP_TYPEDESCR
    raising
      YCX_SDWS_INTERFACE .
  methods SET_DYNAMIC_WHERE
    importing
      !IS_IMPORT type YSDWS_GETDBDATA_I_S
    returning
      value(RT_WHERE) type TTY_SE16N_SELTAB .
  methods APPEND_HEADER_DATA
    importing
      !I_QUALIFIER type ANY
      !I_FVALUE type ANY
    returning
      value(RT_EXPORT) type YSDWS_COMHDR_TT .
  methods SET_IMPORT_DATA_WHERE
    importing
      !IV_STRNAM type ANY
    returning
      value(RV_COND_SYNTAX) type STRING .
  methods SET_RUN_MODE
    importing
      !IV_MODEIN type BOOKFLG
    returning
      value(RV_MODOUT) type CHAR1 .
  methods GET_DEFAULT_VALUES
    importing
      !IV_STRNAME type TABNAME
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
  methods CONSTRUCTOR .
  class-methods CHECK_FIELDS_IN_VIEW
    importing
      !IT_FIELDS type IHREP_STRING_TABLE
      !I_VIEWNAME type VIEWNAME
    returning
      value(RT_FIELDS) type IHREP_STRING_TABLE .
