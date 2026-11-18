  METHOD save_document_sd_sales.

    TYPES:
      tct_bapisditm TYPE STANDARD TABLE OF bapisditm .
    TYPES:
      tct_konv      TYPE STANDARD TABLE OF konv .
    TYPES:
      tct_konvkom   TYPE STANDARD TABLE OF konvkom .
    TYPES:
      tct_konvkomx  TYPE STANDARD TABLE OF konvkomx .
    TYPES:
      tct_vbap      TYPE STANDARD TABLE OF vbap .
    TYPES:
      tct_vbapkom   TYPE STANDARD TABLE OF vbapkom .
    TYPES:
      tct_vbapkomx  TYPE STANDARD TABLE OF vbapkomx .
    TYPES:
      tct_vbep      TYPE STANDARD TABLE OF vbep .
    TYPES:
      tct_vbepkom   TYPE STANDARD TABLE OF vbepkom .
    TYPES:
      tct_vbepkomx  TYPE STANDARD TABLE OF vbepkomx .
    TYPES:
      tct_vbkd      TYPE STANDARD TABLE OF vbkd .
    TYPES:
      tct_vbpa      TYPE STANDARD TABLE OF vbpavb .
    TYPES:
      tct_vbpakom   TYPE STANDARD TABLE OF vbpakom .

    DATA lt_vbap TYPE tct_vbap.
    DATA lt_vbep TYPE tct_vbep.
    DATA lt_vbpa TYPE tct_vbpa.
    DATA lt_vbkd TYPE tct_vbkd.
    DATA lt_konv TYPE TABLE OF konv.
    DATA ylt_komvd TYPE TABLE OF komvd.
    DATA ylt_komv TYPE TABLE OF komv.

    DATA yls_komk TYPE komk.

    CHECK ycl_sdws_interface_salesorder=>mo_instance IS NOT INITIAL.


    MOVE-CORRESPONDING fvbak TO yls_komk.
    MOVE-CORRESPONDING fxvbkd[ 1 ] TO yls_komk.
    MOVE-CORRESPONDING fxvbap[] TO lt_vbap.
    MOVE-CORRESPONDING fxvbep[] TO lt_vbep.
    MOVE-CORRESPONDING fxvbpa[] TO lt_vbpa.
    MOVE-CORRESPONDING fxvbkd[] TO lt_vbkd.
    MOVE-CORRESPONDING fxkomv[] TO lt_konv.

    PERFORM ms_badi_extensionex IN PROGRAM saplvbak USING  fvbak
                                         lt_vbap[]
                                         lt_vbep[]
                                         lt_vbpa[]
                                         lt_vbkd[]
                                         lt_konv[]
                                CHANGING mo_instance->mt_extensionex[].

    PERFORM map_vbak_to_bapisdhd IN PROGRAM saplvbak
                                  TABLES mo_instance->mt_returns
                                         mo_instance->mt_extensionex
                                   USING fvbak
                                 CHANGING mo_instance->ms_order_header_ex.

    PERFORM map_vbap_to_bapisdit IN PROGRAM saplvbak
                                TABLES mo_instance->mt_returns
                                       fxvbap
                                       mo_instance->mt_order_items_ex
                                       mo_instance->mt_extensionex
                                 USING fvbak.

    PERFORM map_vbep_to_bapisdhedu IN PROGRAM saplvbak TABLES fxvbep
                                          mo_instance->mt_order_schedules_ex
                                         mo_instance->mt_extensionex
                                    USING fvbak.

    PERFORM map_vbkd_to_bapisdbusi IN PROGRAM saplvbak TABLES fxvbkd
                                          fxvbap
                                           mo_instance->mt_order_sdbusi_ex
                                           mo_instance->mt_extensionex
                                  USING fvbak.

    PERFORM map_konv_to_bapicond IN PROGRAM saplvbak
                          TABLES lt_konv
                                 mo_instance->mt_order_conditions_ex
                           USING fvbak.

    PERFORM map_vbpa_to_bapisdpart IN PROGRAM saplvbak
             TABLES  fxvbpa
                                         mo_instance->mt_order_partners_ex.

    mo_instance->mt_order_addr_ex = fxvbadr.

*    ms_order_header_ex = is_sales_header_out.
*    mt_order_conditions_ex = it_conditions_ex.
*    mt_order_items_ex = it_items_ex.
*    mt_order_schedules_ex = it_schedule_ex.
*    mt_extensionex = it_extensionex.
    "  mt_order_partners_ex = it_partners_ex.

  ENDMETHOD.
