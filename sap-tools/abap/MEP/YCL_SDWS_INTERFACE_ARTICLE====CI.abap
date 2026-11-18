private section.

  types:
    tty_outputfields TYPE STANDARD TABLE OF ysdws_ex .
  types:
    tty_bapiparex TYPE STANDARD TABLE OF bapiparex .
  types:
    tty_bapi_makt_ga TYPE STANDARD TABLE OF sktext . "bapi_makt_ga .
  types:
    tty_bapi_marm_ga TYPE STANDARD TABLE OF smeinh . "bapi_marm_ga .
  types:
    tty_bapi_mean_ga TYPE STANDARD TABLE OF meani . "bapi_mean_ga .
  types:
    tty_bapi_mltx_ga TYPE STANDARD TABLE OF bapi_mltx_ga . " mltx . "bapi_mltx_ga .
  types:
    tty_bapi_mlan_ga TYPE STANDARD TABLE OF mlan . "bapi_mlan_ga .
  types:
    BEGIN OF ty_materials,
      matnr TYPE matnr,
    END OF ty_materials .
  types:
    tty_materials TYPE STANDARD TABLE OF ty_materials .
  types:
    tty_mmmsgg TYPE STANDARD TABLE OF ymmms_gg .

  data MT_GG type TTY_MMMSGG .
  constants PRUEFTEXT_TDID type TDID value 'PRUE' ##NO_TEXT.
  constants VERTRIEBSTEXT_TDID type TDID value '0001' ##NO_TEXT.
  constants BESTELLTEXT_TDID type TDID value 'BEST' ##NO_TEXT.
  constants GRUNDDTEXT_TDID type TDID value 'GRUN' ##NO_TEXT.
  constants IVERMTEXT_TDID type TDID value 'IVER' ##NO_TEXT.
  constants MATNOTIZ_TDID type TDID value 'LTXT' ##NO_TEXT.
  constants MC_SIGN type SIGN value 'I' ##NO_TEXT.
  data MT_EXTENSIONEX type TTY_BAPIPAREX .
  data MT_OUTPUTFIELDS type TTY_OUTPUTFIELDS .
  data MT_RETURNS type BAPIRET2_T .
  data MV_CALLER type YSDWS_CALLER .
  data MV_OPTION type OPTION .
  data MV_NUMBER_OF_DOCUMENTS type INT4 .
  data MT_SEL_POSNR type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_POSNR .
  data MARA type MARA .
  data MARC type MARC .
  data MPOP type MPOP .
  data MPGD type MPGD .
  data MARD type MARD .
  data MBEW type MBEW .
  data MLGN type MLGN .
  data MVKE type MVKE .
  data MLGT type MLGT .
  data MFHM type MFHM .
  data MYMS type MYMS .
  data MT_MATERIALDESCRIPTION type TTY_BAPI_MAKT_GA .
  data MT_UNITSOFMEASURE type TTY_BAPI_MARM_GA .
  data MT_INTERNATIONARTICLENUMBERS type TTY_BAPI_MEAN_GA .
  data MT_MATERIALTEXT type TTY_BAPI_MLTX_GA .
  data MT_TAXCLASSIFICATIONS type TTY_BAPI_MLAN_GA .
  data MT_EXTENSIONOUT type TTY_BAPIPAREX .
  data MT_SEL_MATNR type YCL_SDWS_INTERFACE_ALL=>TTY_SEL_MATNR .
  data MT_MATERIALS type TTY_MATERIALS .
  data MT_SEL_ERSDA type YSDWS_R_ERSDA .
  data MT_SEL_LAEDA type YSDWS_R_LAEDA .
  data EINA type EINA .
  data EINE type EINE .

  methods SET_CLASS_ATTRIBUTES .
  methods READ_MAT_CLASSIFICATION_DETAIL
    importing
      !IS_IMPORT type YSDWS_ARTICLE_DFLTCLASSATTR
    raising
      YCX_SDWS_INTERFACE .
  methods EXPORT_CLASS
    exporting
      value(ES_CLASS) type YSDWS_CLASS_DATA_E_S
      !ET_RETURNS type YSDWS_RETURN_E_TT .
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
  methods READ_INFORECORD
    importing
      !IV_MATNR type MATNR
    exporting
      !ES_FLIFN type EINA .
  methods SEARCH_SOURCE_OF_SUPPLY
    importing
      !IV_DATUM type SY-DATLO optional
      !IV_WERKS type WERKS_D
      !IV_MATNR type MATNR
    returning
      value(RE_FLIEF) type FLIEF .
  methods GET_LANGTEXT
    importing
      !P_ID type TDID
      !P_MATERIAL type MATNR
      !P_SALESORG type VKORG optional
      !P_DISTR_CHAN type VTWEG optional
      !P_PLANT type WERKS_D optional
    changing
      value(P_MLTX) type TTY_BAPI_MLTX_GA .
  methods INIT_ATTRIBUTS .
  methods EXPORT_MATERIAL
    returning
      value(RT_ITEM) type YSDWS_COMITM_TT .
  methods APPEND_DATA_CONTAINER
    importing
      !I_QUALIFIER type ANY
      !I_FVALUE type ANY
    returning
      value(RT_EXPORT) type YSDWS_COMITM_TT .
  methods READ_DANGEROUS_DETAIL
    importing
      !IS_IMPORT type YSDWS_ARTICLE_DFLTCLASSATTR
    raising
      YCX_SDWS_INTERFACE .
  methods READ_MATERIAL
    importing
      !IS_IMPORT type YSDWS_ARTICLE_DFLTCLASSATTR
    raising
      YCX_SDWS_INTERFACE .
  methods READ_MATERIALS
    importing
      !IS_IMPORT type YSDWS_ARTICLE_DFLTCLASSATTR
    raising
      YCX_SDWS_INTERFACE .
  methods SET_IMPORT_DATA_WHERE
    importing
      !IV_STRNAM type ANY
    returning
      value(RV_COND_SYNTAX) type STRING .
  methods PLAUSI_CHECKS
    raising
      YCX_SDWS_INTERFACE .
  methods SET_IMPORT_DATA_RANGE
    changing
      !IS_IMPORT type YSDWS_ARTICLE_DFLTCLASSATTR .
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
