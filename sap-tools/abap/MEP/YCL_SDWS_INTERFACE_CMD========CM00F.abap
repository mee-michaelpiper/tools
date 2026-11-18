  METHOD map_sales_data.
*      IMPORTING
*        is_ref type CMDS_EI_CMD_SALES
*        is_sales TYPE tys_import
*      returning
*       value(rs_sales_data) type CMDS_EI_CMD_SALES
*      RAISING
*        ycx_sdws_interface .

    DATA lt_in TYPE ysdws_comhdr_tt.

*       Vertriebsdaten
    TRY.
        rs_sales_data = is_ref.
        rs_sales_data-sales[ 1 ]-task = 'I'.
        set_data( EXPORTING it_source = is_sales-hdr
                   CHANGING cs_target = rs_sales_data-sales[ 1 ]-data ).

        LOOP AT rs_sales_data-sales[ 1 ]-functions-functions
          ASSIGNING FIELD-SYMBOL(<function>).
          <function>-task = 'I'.
          CLEAR <function>-data.
        ENDLOOP.

*
        DATA ls_funct_key TYPE cmds_ei_functions_key.
        DATA(lt_comm) = is_sales-itm.
        DELETE lt_comm WHERE vakey NS 'FUNCT'.
        ASSIGN rs_sales_data-sales[ 1 ]-functions-functions TO FIELD-SYMBOL(<funct>).

        LOOP AT lt_comm  ASSIGNING FIELD-SYMBOL(<com>).
          DATA(lt_flt_comm) = lt_comm[]. DELETE lt_flt_comm WHERE vakey NE <com>-vakey.
          MOVE-CORRESPONDING lt_flt_comm TO lt_in.

          ls_funct_key = <com>-vakey+5.
          READ TABLE <funct> WITH KEY data_key = ls_funct_key ASSIGNING FIELD-SYMBOL(<funct_key>).
          IF sy-subrc NE 0.
            APPEND INITIAL LINE TO <funct> ASSIGNING <funct_key>.
            <funct_key>-data_key = ls_funct_key.
            <funct_key>-task = 'I'.
          ENDIF.
          set_data( EXPORTING it_source = lt_in
            CHANGING cs_target = <funct_key>-data ).
        ENDLOOP.

      CATCH cx_sy_itab_line_not_found.
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid   = ycx_sdws_interface=>no_data_found
            mv_kunnr = mv_ref_customer
            mv_msgv1 = convert_syst_msgv( text-003 ).
    ENDTRY.

  ENDMETHOD.
