class YCL_SDWS_INTERFACE_PRICING definition
  public
  inheriting from YCL_SDWS_INTERFACE
  final
  create private .

public section.

  class-data MO_INSTANCE type ref to YCL_SDWS_INTERFACE_PRICING .

  class-methods GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to YCL_SDWS_INTERFACE_PRICING .
  methods START_PRICING
    importing
      !IS_IMPORT type YSDWS_PRICING_I_S
    exporting
      !ES_EXPORT type YSDWS_PRICING_E_S .
