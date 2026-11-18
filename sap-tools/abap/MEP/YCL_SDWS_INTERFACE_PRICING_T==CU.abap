CLASS ycl_sdws_interface_pricing_t DEFINITION
  PUBLIC
  INHERITING FROM ycl_sdws_interface FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-DATA mo_instance TYPE REF TO ycl_sdws_interface_pricing_t.

    CLASS-METHODS get_instance
      IMPORTING is_import TYPE ysdws_tpricing_i_s
      RETURNING VALUE(ro_instance) TYPE REF TO ycl_sdws_interface_pricing_t.

    METHODS start_pricing
*      IMPORTING is_import TYPE ysdws_tpricing_i_s
      EXPORTING es_export TYPE ysdws_tpricing_e_s.

