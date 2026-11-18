  METHOD map_ref_customer2new.
*    raising YCX_SDWS_INTERFACE.
*    DATA lt_in TYPE ysdws_comhdr_tt.
*    DATA last_vakey TYPE vakeyf.

    TRY.
        DATA(header) = ms_ref_cmd-customers[ 1 ]-header.
        header-object_instance-kunnr = space.
        header-object_task = 'I'.

        DATA(central_data) = map_central_data( is_ref = ms_ref_cmd-customers[ 1 ]-central_data
                                               is_master = VALUE #( hdr = is_source-it_master itm = is_source-it_master_itm ) ).

**       Allgemeine Daten
*        DATA(central_data)  = ms_ref_cmd-customers[ 1 ]-central_data.
*        central_data-address-task = 'I'.
*        set_data( EXPORTING it_source = is_source-it_master
*          CHANGING cs_target = central_data-central-data ).
*
*        set_data( EXPORTING it_source = is_source-it_master
*          CHANGING cs_target = central_data-address-postal-data ).
*
*
*        DATA(lt_comm) = is_source-it_master_itm.
*        DELETE lt_comm WHERE vakey CS 'CONTACT'.
*
*        LOOP AT lt_comm ASSIGNING FIELD-SYMBOL(<com>).
*          DATA(lt_flt_comm) = lt_comm[]. DELETE lt_flt_comm WHERE vakey NE <com>-vakey.
*          MOVE-CORRESPONDING lt_flt_comm TO lt_in.
*
*          IF lt_flt_comm[ 1 ]-vakey CS 'PHONE'.
*            APPEND INITIAL LINE TO central_data-address-communication-phone-phone ASSIGNING FIELD-SYMBOL(<phone>).
*            <phone>-contact-task = 'I'.
*            <phone>-contact-data-consnumber = lines( central_data-address-communication-phone-phone ).
*            set_data( EXPORTING it_source = lt_in
*              CHANGING cs_target = <phone>-contact-data ).
*          ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'FAX'.
*            APPEND INITIAL LINE TO central_data-address-communication-fax-fax ASSIGNING FIELD-SYMBOL(<fax>).
*            <fax>-contact-task = 'I'.
*            <fax>-contact-data-consnumber = lines( central_data-address-communication-fax-fax ).
*            set_data( EXPORTING it_source = lt_in
*              CHANGING cs_target = <fax>-contact-data ).
*          ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'SMTP'.
*            APPEND INITIAL LINE TO central_data-address-communication-smtp-smtp ASSIGNING FIELD-SYMBOL(<smtp>).
*            <smtp>-contact-task = 'I'.
*            <smtp>-contact-data-consnumber = lines( central_data-address-communication-smtp-smtp ).
*            set_data( EXPORTING it_source = lt_in
*              CHANGING cs_target = <smtp>-contact-data ).
*          ENDIF.
*          DELETE lt_comm WHERE vakey EQ <com>-vakey.
*        ENDLOOP.
*
*        lt_comm = is_source-it_master_itm.
*        DELETE lt_comm WHERE vakey NS 'CONTACT'.
*
**       Kontaktdaten übernehmen
*        LOOP AT lt_comm ASSIGNING <com>
*        WHERE vakey CS 'CONTACT'.
*          lt_flt_comm = lt_comm[]. DELETE lt_flt_comm WHERE vakey NE <com>-vakey.
*          MOVE-CORRESPONDING lt_flt_comm TO lt_in.
*
*          IF lt_flt_comm[ 1 ]-vakey CS 'CONTACT' AND lt_flt_comm[ 1 ]-vakey+8 = space.
*            IF <com>-vakey(8) NE last_vakey.
*              last_vakey = <com>-vakey.
*              APPEND INITIAL LINE TO central_data-contact-contacts ASSIGNING FIELD-SYMBOL(<contact>).
*              <contact>-task = 'I'.
*            ENDIF.
*
*            set_data( EXPORTING it_source = lt_in
*              CHANGING cs_target = <contact>-data ).
*          ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'ADR3' AND lt_flt_comm[ 1 ]-vakey+12 = space..
*            <contact>-address_type_3-task = 'I'.
*            set_data( EXPORTING it_source = lt_in
*              CHANGING cs_target = <contact>-address_type_3-postal-data ).
*          ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'PHONE'.
*            APPEND INITIAL LINE TO <contact>-address_type_3-communication-phone-phone ASSIGNING <phone>.
*            <phone>-contact-task = 'I'.
*            <phone>-contact-data-consnumber = lines( <contact>-address_type_3-communication-fax-fax ).
*            set_data( EXPORTING it_source = lt_in
*              CHANGING cs_target = <phone>-contact-data ).
*          ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'FAX'.
*            APPEND INITIAL LINE TO <contact>-address_type_3-communication-fax-fax ASSIGNING <fax>.
*            <fax>-contact-task = 'I'.
*            <fax>-contact-data-consnumber = lines( <contact>-address_type_3-communication-fax-fax ).
*            set_data( EXPORTING it_source = lt_in
*              CHANGING cs_target = <fax>-contact-data ).
*          ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'SMTP'.
*            APPEND INITIAL LINE TO <contact>-address_type_3-communication-smtp-smtp ASSIGNING <smtp>.
*            <smtp>-contact-task = 'I'.
*            <smtp>-contact-data-consnumber = lines( <contact>-address_type_3-communication-smtp-smtp ).
*            set_data( EXPORTING it_source = lt_in
*              CHANGING cs_target = <smtp>-contact-data ).
*          ENDIF.
*          DELETE lt_comm WHERE vakey EQ <com>-vakey.
*        ENDLOOP.
*
*        LOOP AT central_data-contact-contacts ASSIGNING <contact>.
*          <contact>-task = 'I'.
*          CLEAR <contact>-data_key.
*        ENDLOOP.
*
**       TAX Data
*        DATA ls_tax_key TYPE cmds_ei_tax_ind_key.
*        lt_comm = is_source-it_master_itm.
*        DELETE lt_comm WHERE vakey NS 'TAX'.
*        ASSIGN ms_ref_cmd-customers[ 1 ]-central_data-tax_ind TO FIELD-SYMBOL(<tax>).
*
*        LOOP AT lt_comm  ASSIGNING <com>.
*          lt_flt_comm = lt_comm[]. DELETE lt_flt_comm WHERE vakey NE <com>-vakey.
*          MOVE-CORRESPONDING lt_flt_comm TO lt_in.
*
*          ls_tax_key = <com>-vakey+3.
*          READ TABLE <tax>-tax_ind WITH KEY data_key = ls_tax_key ASSIGNING FIELD-SYMBOL(<tax_ind>).
*          IF sy-subrc NE 0.
*            APPEND INITIAL LINE TO <tax>-tax_ind ASSIGNING <tax_ind>.
*          ENDIF.
*          <tax_ind>-task = 'I'.
*          set_data( EXPORTING it_source = lt_in
*            CHANGING cs_target = <tax_ind>-data ).
*        ENDLOOP.
*
*
*        LOOP AT <tax>-tax_ind ASSIGNING <tax_ind>.
*          <tax_ind>-task = 'I'.
*        ENDLOOP.

*       Buchungskreis Daten
        DATA(company_data) = map_company_data( is_ref = ms_ref_cmd-customers[ 1 ]-company_data
                                           is_company = VALUE #( hdr = is_source-it_company itm = is_source-it_company_itm ) ).
*        TRY.
*            DATA(company_data)  = ms_ref_cmd-customers[ 1 ]-company_data.
*            company_data-company[ 1 ]-task = 'I'.
*            company_data-company[ 1 ]-dunning-dunning[ 1 ]-task = 'I'.
*            set_data( EXPORTING it_source = is_source-it_company
*                CHANGING cs_target = company_data-company[ 1 ]-data ).
*
*          CATCH cx_sy_itab_line_not_found.
*            RAISE EXCEPTION TYPE ycx_sdws_interface
*              EXPORTING
*                textid   = ycx_sdws_interface=>no_data_found
*                mv_kunnr = mv_ref_customer
*                mv_msgv1 = text-004.
*        ENDTRY.

*       Vertriebsdaten
        DATA(sales_data) = map_sales_data( is_ref = ms_ref_cmd-customers[ 1 ]-sales_data
                                           is_sales = VALUE #( hdr = is_source-it_sales itm = is_source-it_sales_itm ) ).

**       Vertriebsdaten
*        TRY.
*            DATA(sales_data)  = ms_ref_cmd-customers[ 1 ]-sales_data.
*            sales_data-sales[ 1 ]-task = 'I'.
*            set_data( EXPORTING it_source = is_source-it_sales
*                       CHANGING cs_target = sales_data-sales[ 1 ]-data ).
*
*            LOOP AT sales_data-sales[ 1 ]-functions-functions
*              ASSIGNING FIELD-SYMBOL(<function>).
*              <function>-task = 'I'.
*              CLEAR <function>-data.
*
*            ENDLOOP.
*
*          CATCH cx_sy_itab_line_not_found.
*            RAISE EXCEPTION TYPE ycx_sdws_interface
*              EXPORTING
*                textid   = ycx_sdws_interface=>no_data_found
*                mv_kunnr = mv_ref_customer
*                mv_msgv1 = convert_syst_msgv( text-003 ).
*        ENDTRY.

*      Kreditdaten

*      Klassifizierung
        map_class_data( is_source-it_class ).
*        DATA(lt_class) = is_source-it_class.
*
*        LOOP AT lt_class ASSIGNING FIELD-SYMBOL(<cls>).
*          DATA(lt_flt_class) = lt_class[]. DELETE lt_flt_class WHERE vakey NE <cls>-vakey.
*          MOVE-CORRESPONDING lt_flt_class TO lt_in.
*          READ TABLE mt_allocvalueschar WITH KEY charact = <cls>-vakey ASSIGNING FIELD-SYMBOL(<vchar>).
*          IF sy-subrc EQ 0.
*            set_data( EXPORTING it_source = lt_in  CHANGING cs_target = <vchar> ).
*          ENDIF.
*
*          READ TABLE mt_allocvaluescurr WITH KEY charact = <cls>-vakey ASSIGNING FIELD-SYMBOL(<vcurr>).
*          IF sy-subrc EQ 0.
*            set_data( EXPORTING it_source = lt_in  CHANGING cs_target = <vcurr> ).
*          ENDIF.
*
*          READ TABLE mt_allocvaluesnum WITH KEY charact = <cls>-vakey ASSIGNING FIELD-SYMBOL(<vnum>).
*          IF sy-subrc EQ 0.
*            set_data( EXPORTING it_source = lt_in  CHANGING cs_target = <vnum> ).
*          ENDIF.
*
*          DELETE lt_class WHERE vakey =  <cls>-vakey.
*        ENDLOOP.

        ms_new_cmd-customers = VALUE #( ( header = header central_data = central_data company_data = company_data sales_data = sales_data ) ).

      CATCH cx_sy_itab_line_not_found.
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid   = ycx_sdws_interface=>no_data_found
            mv_kunnr = mv_ref_customer
            mv_msgv1 = convert_syst_msgv( text-002 ).
    ENDTRY.




  ENDMETHOD.
