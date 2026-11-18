CLASS ycl_sdws_interface_cmd DEFINITION
  PUBLIC
  INHERITING FROM ycl_sdws_interface
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    CLASS-DATA mo_instance TYPE REF TO ycl_sdws_interface_cmd .

    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_instance) TYPE REF TO ycl_sdws_interface_cmd .
    METHODS managed
      IMPORTING
        !is_import TYPE ysdws_cmd_i_s
      EXPORTING
        !es_export TYPE ysdws_cmd_e_s .
