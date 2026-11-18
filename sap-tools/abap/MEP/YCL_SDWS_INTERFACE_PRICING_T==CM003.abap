  METHOD pricing.
    DATA lt_result TYPE prct_result_multi_item.
    data lt_vfkomv type VFSC0_VFKOMV_TAB .
    DATA lt_xkomv  TYPE va_komv_t.

*     CALL FUNCTION 'PRICING_REFRESH'
*        TABLES tkomk = lt_komk
*               tkomv = lt_xkomv.

    DATA(lt_komk) = fill_tkomk( ms_import ).

    DATA(lt_komp) = fill_tkomp( ms_import )."#EC CI_SORTED

    CALL FUNCTION 'PRICING_MULTI_ITEM'  "#EC CI_SORTED
      EXPORTING iv_calculation_type     = determine_pricing_type(  )
                iv_group_logic_required = ' ' " mV_GROUP_LOGIC_REQUIRED
                iv_no_ix_komk           = abap_true
                iv_get_tkomv            = abap_true
      IMPORTING et_pricing_result       = lt_result
      CHANGING  ct_komk                 = lt_komk
                ct_komp                 = lt_komp
                ct_komv                 = lt_xkomv.

*    IF mV_GROUP_LOGIC_REQUIRED = abap_true.
*
*      DATA(lt_vbap) = VALUE vbapu_tty( FOR <wa> IN lt_komp
*                                       ( posnr = <wa>-kposn uepos = <wa>-uepos ) ).
*
*      CALL FUNCTION 'PRICING_COMPLETE'
*        EXPORTING calculation_type = 'A'    " Preisfindungsart
*                  preliminary      = ' '
*        TABLES    tkomk            = lt_komk
*                  tkomp            = lt_komp
*                  tkomv            = lt_xkomv
*                  svbap            = lt_vbap
*        CHANGING  c_vfkomv         = lt_vfkomv.
*    ENDIF.

    es_export-e_sessionid = ms_import-i_sessionid.
    es_export-et_mat      = prepare_response( it_result = lt_result
                                              it_komk   = lt_komk
                                              it_komp   = lt_komp
                                              it_xkomv  = lt_xkomv ).
  ENDMETHOD.
