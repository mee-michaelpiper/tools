class YCL_SDWS_INTERFACE_ARTICLE definition
  public
  final
  create private .

public section.

  data MO_CLASS type ref to YCL_SDWS_INTERFACE_CLASS .
  class-data MO_INSTANCE type ref to YCL_SDWS_INTERFACE_ARTICLE .
  data MS_IMPORT type YSDWS_ARTICLE_DFLTCLASSATTR .

  methods GET_DATA
    importing
      !IS_IMPORT type YSDWS_ARTICLE_DATA_I_S
    exporting
      !ES_EXPORT type YSDWS_ARTICLE_DATA_E_S
      !ES_CLASS type YSDWS_CLASS_DATA_E_S
    raising
      YCX_SDWS_INTERFACE .
  class-methods GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to YCL_SDWS_INTERFACE_ARTICLE .
