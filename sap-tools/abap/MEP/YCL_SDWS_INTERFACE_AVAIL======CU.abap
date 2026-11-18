class YCL_SDWS_INTERFACE_AVAIL definition
  public
  inheriting from YCL_SDWS_INTERFACE
  final
  create private .

public section.

  class-methods GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to YCL_SDWS_INTERFACE_AVAIL .
  methods AVAILABILITY
    importing
      !IS_IMPORT type YSDWS_AVAILABILITY_I_S
    exporting
      !ES_EXPORT type YSDWS_AVAILABILITY_E_S .
  methods PLANT_ATP_DETERMINE
    importing
      !IS_IMPORT type YSDWS_PLANT_ATP_DETERMINE_I_S
    exporting
      !ES_EXPORT type YSDWS_PLANT_ATP_E_S .
