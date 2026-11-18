  METHOD get_default_pricing_kalsm.

    TRY.
        CALL METHOD ycl_stvarvc=>get_param
          EXPORTING
            i_pname = 'YSDWS_INTERFACE_PRICING'
            i_quali = 'KALSM'
          IMPORTING
            e_param = rv_kalsm.
      CATCH ycx_bc_err .

        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid = ycx_sdws_interface=>empty_kalsm.

    ENDTRY.

  ENDMETHOD.
