CLASS ycl_sdws_interface_getdbdata DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF tty_import_dflt,
        in TYPE ysdws_getdbdata_i_s, " Webshop: Tabellenselektion Importstruktur
      END OF tty_import_dflt .

    DATA ms_import TYPE tty_import_dflt .
    CLASS-DATA mo_instance TYPE REF TO ycl_sdws_interface_getdbdata .

    METHODS get_data
      IMPORTING
        !is_import TYPE ysdws_getdbdata_i_s
      EXPORTING
        !es_export TYPE ysdws_getdbdata_e_s
      RAISING
        ycx_sdws_interface .
    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_instance) TYPE REF TO ycl_sdws_interface_getdbdata .
