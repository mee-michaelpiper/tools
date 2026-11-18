  METHOD determine_pricing_type.
*  RETURNING VALUE(rv_knprs) type  t683-knprs_v.
    CALL FUNCTION 'PRICING_TYPE_DETERMINE'
      EXPORTING popup_i = ' '
                kvewe_i = ycl_sdws_interface_all=>mc_kvewe_a
                kappl_i = ycl_sdws_interface_all=>mc_kappl_v
                kalsm_i = ms_import-i_kalsm
      IMPORTING knprs_e = rv_knprs.
  ENDMETHOD.
