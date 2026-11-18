class YCL_SDWS_INTERFACE_INVOICE definition
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

  data MS_IMPORT type YSDWS_SALESDOC_DFLTCLASSATTR .
  data MS_KUNWE type KUWEV .
  data MS_KUNAG type KUAGV .
  class-data MO_INSTANCE type ref to YCL_SDWS_INTERFACE_INVOICE .

  methods GET_DATA
    importing
      !IS_IMPORT type YSDWS_SALESDOC_DATA_I_S
    exporting
      !ES_EXPORT type YSDWS_ALLG_DATA_E_S
    raising
      YCX_SDWS_INTERFACE .
  class-methods GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to YCL_SDWS_INTERFACE_INVOICE .
