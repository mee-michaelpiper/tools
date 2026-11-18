  METHOD map_company_data.
*      IMPORTING
*        is_ref type CMDS_EI_CMD_company
*        is_company TYPE tys_import
*      returning
*       value(rs_sales_data) type CMDS_EI_CMD_company
*      RAISING
*        ycx_sdws_interface .

    DATA lt_in TYPE ysdws_comhdr_tt.
    DATA last_vakey TYPE vakeyf.

    TRY.
        rs_company_data  = ms_ref_cmd-customers[ 1 ]-company_data.
        rs_company_data-company[ 1 ]-task = 'I'.
        rs_company_data-company[ 1 ]-dunning-dunning[ 1 ]-task = 'I'.
        set_data( EXPORTING it_source = is_company-hdr
            CHANGING cs_target = rs_company_data-company[ 1 ]-data ).

      CATCH cx_sy_itab_line_not_found.
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid   = ycx_sdws_interface=>no_data_found
            mv_kunnr = mv_ref_customer
            mv_msgv1 = text-004.
    ENDTRY.


  ENDMETHOD.
