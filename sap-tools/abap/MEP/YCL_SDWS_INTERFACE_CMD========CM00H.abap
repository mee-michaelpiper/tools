  METHOD map_central_data.
*      IMPORTING
*        is_ref type CMDS_EI_CMD_master
*        is_company TYPE tys_import
*      returning
*       value(rs_central) type CMDS_EI_CMD_master
*      RAISING
*        ycx_sdws_interface .

    DATA lt_in TYPE ysdws_comhdr_tt.
    DATA last_vakey TYPE vakeyf.

*       Allgemeine Daten
    rs_central  = is_ref.
    rs_central-address-task = 'I'.
    set_data( EXPORTING it_source = is_master-hdr
               CHANGING cs_target = rs_central-central-data ).

    set_data( EXPORTING it_source = is_master-hdr
               CHANGING cs_target = rs_central-address-postal-data ).

    DATA(lt_comm) = is_master-itm.
    DELETE lt_comm WHERE vakey CS 'CONTACT'.

    LOOP AT lt_comm ASSIGNING FIELD-SYMBOL(<com>).
      DATA(lt_flt_comm) = lt_comm[]. DELETE lt_flt_comm WHERE vakey NE <com>-vakey.
      MOVE-CORRESPONDING lt_flt_comm TO lt_in.

      IF lt_flt_comm[ 1 ]-vakey CS 'PHONE'.
        APPEND INITIAL LINE TO rs_central-address-communication-phone-phone ASSIGNING FIELD-SYMBOL(<phone>).
        <phone>-contact-task = 'I'.
        <phone>-contact-data-consnumber = lines( rs_central-address-communication-phone-phone ).
        set_data( EXPORTING it_source = lt_in
          CHANGING cs_target = <phone>-contact-data ).
      ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'FAX'.
        APPEND INITIAL LINE TO rs_central-address-communication-fax-fax ASSIGNING FIELD-SYMBOL(<fax>).
        <fax>-contact-task = 'I'.
        <fax>-contact-data-consnumber = lines( rs_central-address-communication-fax-fax ).
        set_data( EXPORTING it_source = lt_in
          CHANGING cs_target = <fax>-contact-data ).
      ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'SMTP'.
        APPEND INITIAL LINE TO rs_central-address-communication-smtp-smtp ASSIGNING FIELD-SYMBOL(<smtp>).
        <smtp>-contact-task = 'I'.
        <smtp>-contact-data-consnumber = lines( rs_central-address-communication-smtp-smtp ).
        set_data( EXPORTING it_source = lt_in
          CHANGING cs_target = <smtp>-contact-data ).
      ENDIF.
      DELETE lt_comm WHERE vakey EQ <com>-vakey.
    ENDLOOP.

    lt_comm = is_master-itm.
    DELETE lt_comm WHERE vakey NS 'CONTACT'.

*       Kontaktdaten übernehmen
    LOOP AT lt_comm ASSIGNING <com>
    WHERE vakey CS 'CONTACT'.
      lt_flt_comm = lt_comm[]. DELETE lt_flt_comm WHERE vakey NE <com>-vakey.
      MOVE-CORRESPONDING lt_flt_comm TO lt_in.

      IF lt_flt_comm[ 1 ]-vakey CS 'CONTACT' AND lt_flt_comm[ 1 ]-vakey+8 = space.
        IF <com>-vakey(8) NE last_vakey.
          last_vakey = <com>-vakey.
          APPEND INITIAL LINE TO rs_central-contact-contacts ASSIGNING FIELD-SYMBOL(<contact>).
          <contact>-task = 'I'.
        ENDIF.

        set_data( EXPORTING it_source = lt_in
          CHANGING cs_target = <contact>-data ).
      ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'ADR3' AND lt_flt_comm[ 1 ]-vakey+12 = space..
        <contact>-address_type_3-task = 'I'.
        set_data( EXPORTING it_source = lt_in
          CHANGING cs_target = <contact>-address_type_3-postal-data ).
      ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'PHONE'.
        APPEND INITIAL LINE TO <contact>-address_type_3-communication-phone-phone ASSIGNING <phone>.
        <phone>-contact-task = 'I'.
        <phone>-contact-data-consnumber = lines( <contact>-address_type_3-communication-fax-fax ).
        set_data( EXPORTING it_source = lt_in
          CHANGING cs_target = <phone>-contact-data ).
      ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'FAX'.
        APPEND INITIAL LINE TO <contact>-address_type_3-communication-fax-fax ASSIGNING <fax>.
        <fax>-contact-task = 'I'.
        <fax>-contact-data-consnumber = lines( <contact>-address_type_3-communication-fax-fax ).
        set_data( EXPORTING it_source = lt_in
          CHANGING cs_target = <fax>-contact-data ).
      ELSEIF  lt_flt_comm[ 1 ]-vakey CS 'SMTP'.
        APPEND INITIAL LINE TO <contact>-address_type_3-communication-smtp-smtp ASSIGNING <smtp>.
        <smtp>-contact-task = 'I'.
        <smtp>-contact-data-consnumber = lines( <contact>-address_type_3-communication-smtp-smtp ).
        set_data( EXPORTING it_source = lt_in
          CHANGING cs_target = <smtp>-contact-data ).
      ENDIF.
      DELETE lt_comm WHERE vakey EQ <com>-vakey.
    ENDLOOP.

    LOOP AT rs_central-contact-contacts ASSIGNING <contact>.
      <contact>-task = 'I'.
      CLEAR <contact>-data_key.
    ENDLOOP.

*       TAX Data
    DATA ls_tax_key TYPE cmds_ei_tax_ind_key.
    lt_comm = is_master-itm.
    DELETE lt_comm WHERE vakey NS 'TAX'.
    ASSIGN ms_ref_cmd-customers[ 1 ]-central_data-tax_ind TO FIELD-SYMBOL(<tax>).

    LOOP AT lt_comm  ASSIGNING <com>.
      lt_flt_comm = lt_comm[]. DELETE lt_flt_comm WHERE vakey NE <com>-vakey.
      MOVE-CORRESPONDING lt_flt_comm TO lt_in.

      ls_tax_key = <com>-vakey+3.
      READ TABLE <tax>-tax_ind WITH KEY data_key = ls_tax_key ASSIGNING FIELD-SYMBOL(<tax_ind>).
      IF sy-subrc NE 0.
        APPEND INITIAL LINE TO <tax>-tax_ind ASSIGNING <tax_ind>.
      ENDIF.
      <tax_ind>-task = 'I'.
      set_data( EXPORTING it_source = lt_in
        CHANGING cs_target = <tax_ind>-data ).
    ENDLOOP.


    LOOP AT <tax>-tax_ind ASSIGNING <tax_ind>.
      <tax_ind>-task = 'I'.
    ENDLOOP.

  ENDMETHOD.
