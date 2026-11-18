class YCL_SDWS_INTERFACE_DELIVERY definition
  public
  final
  create private .

public section.

  types:
    BEGIN OF ty_vbeln,
        vbeln TYPE vbeln,
      END OF ty_vbeln .
  types:
    tty_bapisdit TYPE STANDARD TABLE OF bapisdit .
  types:
    tty_bapisdhedu TYPE STANDARD TABLE OF bapisdhedu .
  types:
    tty_bapisdbusi TYPE STANDARD TABLE OF bapisdbusi .
  types:
    tty_bapiincomp TYPE STANDARD TABLE OF bapiincomp .
  types:
    tty_bapisdtehd TYPE STANDARD TABLE OF bapisdtehd .
  types:
    tty_bapitextli TYPE STANDARD TABLE OF bapitextli .
  types:
    tty_bapisdpart TYPE STANDARD TABLE OF vbpavb .
  types:
    tty_vakgu  TYPE STANDARD TABLE OF sales_key WITH DEFAULT KEY .
  types:
    tty_vbeln  TYPE STANDARD TABLE OF ty_vbeln WITH DEFAULT KEY .

  data MT_DELIVERIES_BADI type LESHP_DELIVERY_T .
  class-data MO_INSTANCE type ref to YCL_SDWS_INTERFACE_DELIVERY .
  data MS_IMPORT type YSDWS_SALESDOC_DFLTCLASSATTR .
  data MS_KUNAG type KUAGV .
  data MS_KUNWE type KUNWE .

  methods GET_DATA
    importing
      !IS_IMPORT type YSDWS_SALESDOC_DATA_I_S
    exporting
      !ES_EXPORT type YSDWS_SALESORDER_E_S
    raising
      YCX_SDWS_INTERFACE .
  methods MODIFY_DELIVERIES
    importing
      !EXTENSIONIN type BAPIPAREX optional
      !IX_DELIVERIES type LESHP_DELIVERY_T
    exporting
      !ET_EXTENSIONOUT type BAPIPAREX_T
    changing
      !ET_DELIVERY_HEADER type BAPIDLVHDR_T
      !ET_DELIVERY_ITEM type BAPIDLVITEM_T
      !ET_DELIVERY_HEADER_STS type BAPIDLVHDRSTS_T optional
      !ET_DELIVERY_ITEM_STS type BAPIDLVITEMSTS_T optional
      !ET_DELIVERY_PARTNER type BAPIDLVPARTNERS_T optional
      !ET_DOCUMENT_FLOW type BAPIDOCFLOW_T optional
      !ET_FOREIGN_TRADE_HEADER type BAPIFOREIGNTRADEHDR optional
      !ET_FOREIGN_TRADE_ITEM type BAPIFOREIGNTRADEITEM optional
      !ET_HU_HEADER type BAPIDLVHANDLINGUNITHDR optional
      !ET_ITEM_SERIAL_NO type BAPIDLVITMSERNO optional
      !RETURN type BAPIRET2_T optional .
  class-methods GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to YCL_SDWS_INTERFACE_DELIVERY .
