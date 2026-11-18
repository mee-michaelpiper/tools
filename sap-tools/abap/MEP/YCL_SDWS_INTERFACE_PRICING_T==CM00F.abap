  METHOD set_default_pricing_kalsm.
    " FISHD20240506 OSS425607 -->
    IF ms_import-i_kalsm IS INITIAL.
      SELECT SINGLE kalks FROM knvv
        INTO @DATA(lv_kalks)
        WHERE kunnr = @ms_import-i_kunnr
          AND vkorg = @ms_import-i_vkorg
          AND vtweg = @ms_import-i_vtweg
          AND spart = @ms_import-i_spart.
      IF sy-subrc = 0.
        CASE lv_kalks.
          " Meesenburg Standard (alt)
          WHEN 'M'.
            ms_import-i_kalsm = 'YVAA00'.
            " Meesenburg neu
          WHEN 'A'.
            ms_import-i_kalsm = 'YVAANP'.
          WHEN OTHERS.
        ENDCASE.
      ENDIF.
    ENDIF.
    " FISHD20240506 OSS425607 <--

    IF ms_import-i_kalsm IS INITIAL.
      TRY.
          ycl_stvarvc=>get_param( EXPORTING i_pname = 'YSDWS_INTERFACE_PRICING'
                                            i_quali = 'KALSM'
                                  IMPORTING e_param = ms_import-i_kalsm  ).

        CATCH ycx_bc_err.

          RAISE EXCEPTION TYPE ycx_sdws_interface
            EXPORTING textid = ycx_sdws_interface=>empty_kalsm.

      ENDTRY.
    ENDIF.

    ycl_sdws_interface_all=>get_instance( )->check_kalsm( ms_import-i_kalsm ).

    SELECT SINGLE * INTO @ms_t683v
      FROM t683v
      WHERE vkorg = @ms_import-i_vkorg
        AND kalks = @lv_kalks
        AND kalsm = @ms_import-i_kalsm.
  ENDMETHOD.
