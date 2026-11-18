class YCL_SDWS_INTERFACE_DOCUMENT definition
  public
  final
  create public .

public section.

  data MT_OTF type TSFOTF .
  data MS_TNAPR type TNAPR .
  data MS_NAST type NAST .
  class-data MO_INSTANCE type ref to YCL_SDWS_INTERFACE_DOCUMENT .

  methods SET_SCREEN
    returning
      value(RE_SCREEN) type CHAR1 .
  class-methods SET_DOCUMENT_REQUEST .
  class-methods SET_DOCUMENT_RESPONSE
    importing
      !IT_OTF type TSFOTF
    exceptions
      LEAVE_PROGRAMM .
  class-methods GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to YCL_SDWS_INTERFACE_DOCUMENT .
  methods CHECK_IMPORT_DATA
    importing
      !IV_KSCHL type KSCHL
      !IV_OBJKY type OBJKY
      !IV_KUNNR type KUNNR
      !IV_SPRAS type SPRAS
    raising
      YCX_SDWS_INTERFACE .
  methods CONVERT_OTF
    importing
      !IS_IMPORT type YSDWS_DOCUMENT_DATA_I_S optional
    returning
      value(RS_EXPORT) type YSDWS_DOCUMENT_E_S
    raising
      YCX_SDWS_INTERFACE .
