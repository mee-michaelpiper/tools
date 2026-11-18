  PRIVATE SECTION.

    CONSTANTS mc_chare TYPE char1 VALUE 'E' ##NO_TEXT.
    CONSTANTS mc_check_rule_a TYPE bapit441v-prreg VALUE 'A' ##NO_TEXT.
    CLASS-DATA mo_instance TYPE REF TO ycl_sdws_interface_avail .

    METHODS availability_plausi_check
      CHANGING
        !cs_import TYPE ysdws_availability_i_s
      RAISING
        ycx_sdws_interface .
    METHODS availability_check
      IMPORTING
        !is_import TYPE ysdws_availability_i_s
      EXPORTING
        !es_export TYPE ysdws_availability_e_s
      RAISING
        ycx_sdws_interface .
    METHODS material_availability
      IMPORTING
        !is_import TYPE ysdws_availability_mat_i_s
      EXPORTING
        !et_export TYPE YSDWS_ATP_MAT_E_TT
      RAISING
        ycx_sdws_interface .
