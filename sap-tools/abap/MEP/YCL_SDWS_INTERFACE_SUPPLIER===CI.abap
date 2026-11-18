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
    TTY_KNMT type STANDARD TABLE OF knmt .
  types:
    begin of ty_r_kdmat,
    sign type DDSIGN,
    option type DDOPTION,
    low type kdmat,
    high type kdmat,
    end of ty_r_kdmat .
  types:
    TTY_KDMAT type STANDARD TABLE OF ty_r_kdmat .

  data LFA1 type LFA1 .
  data LFM1 type LFM1 .
  data MS_ADDR1_COMPLETE type SZADR_ADDR1_COMPLETE .
  data MV_NUMBER_OF_DOCUMENTS type INT4 .
  data MV_ERFAB type ERDAT .
  data MV_ERFBI type ERSBI .
  data MV_GLTAB type DATAB .
  data MV_GLTBI type DATBI .
  data MT_SEL_ERDAT type SHP_ERDAT_RANGE_T .
  data MT_SEL_GLDTM type SHP_ERDAT_RANGE_T .
  data MT_SEL_MATNR type RANGE_T_MATNR .
  constants MC_SIGN type SIGN value 'I' ##NO_TEXT.
  data MT_OUTPUTFIELDS type TTY_OUTPUTFIELDS .
  data MT_RETURNS type BAPIRET2_T .
  data MV_CALLER type YSDWS_CALLER .
  data MV_OPTION type OPTION .

  methods GET_SUPPLIERDATA
    importing
      !IS_IMPORT type YSDWS_SUPPLIER_DFLTCLASSATTR
    raising
      YCX_SDWS_INTERFACE .
  methods SET_IMPORT_DATA_RANGE
    importing
      !IS_IMPORT type YSDWS_SUPPLIER_DFLTCLASSATTR .
  methods EXPORT_ADDR_TO_ITEM
    importing
      !IV_ITMNUMBER type POSNR optional
      !IS_QUELLSTR type ANY
      !IV_STRNAM type ANY
      !IV_VAKEY type STRING optional
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
  methods EXPORT_TO_ITEM
    importing
      !IV_ITMNUMBER type POSNR optional
      !IS_QUELLSTR type ANY
      !IV_STRNAM type ANY
      !IV_VAKEY type STRING optional
    returning
      value(ET_ITEM) type YSDWS_COMITM_TT .
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
  methods CONSTRUCTOR .
