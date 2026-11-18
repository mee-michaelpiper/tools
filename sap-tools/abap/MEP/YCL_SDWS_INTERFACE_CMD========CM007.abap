  METHOD fetch_ref_customer.
*   returning value(rv_ref_customer) type kunnr raising YCX_SDWS_INTERFACE.

    get_default_values( CHANGING  cs_zielstr = ms_dflt_value ).
    IF iv_kunnr IS INITIAL.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_found
          mv_msgv1 = convert_syst_msgv( text-001 ).
    ENDIF.

    SELECT SINGLE kunnr FROM kna1
     WHERE kunnr = @iv_kunnr
     INTO @rv_ref_customer.
    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_found
          mv_kunnr = CONV #( iv_kunnr )
          mv_msgv1 = convert_syst_msgv( text-002 ).
    ENDIF.

  ENDMETHOD.
