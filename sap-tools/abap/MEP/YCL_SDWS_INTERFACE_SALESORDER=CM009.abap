  METHOD fill_bapi_header.

    DATA: lo_error      TYPE REF TO cx_root,
          ls_bape_vbak  TYPE bape_vbak,
          ls_bape_vbakx TYPE bape_vbakx,
          ls_itmvakey   TYPE ty_itmvakey.



    FIELD-SYMBOLS <ref_str> TYPE any.

    LOOP AT it_header ASSIGNING FIELD-SYMBOL(<hdr>).


      ASSIGN COMPONENT <hdr>-qualif OF STRUCTURE ms_order_header_in TO FIELD-SYMBOL(<fieldhdr>).
      IF sy-subrc EQ 0 AND <fieldhdr> IS ASSIGNED.

        TRY.
            MOVE <hdr>-fvalue TO <fieldhdr>.
            ASSIGN COMPONENT <hdr>-qualif OF STRUCTURE ms_order_header_inx TO FIELD-SYMBOL(<fieldhdrx>).
            <fieldhdrx> = abap_true.
          CATCH cx_sy_conversion_no_number INTO lo_error.

        ENDTRY.
      ELSE.
        ASSIGN COMPONENT <hdr>-qualif OF STRUCTURE ls_bape_vbak TO <fieldhdr>.
        IF sy-subrc EQ 0 AND <fieldhdr> IS ASSIGNED.

          TRY.
              MOVE <hdr>-fvalue TO <fieldhdr>.
              ASSIGN COMPONENT <hdr>-qualif OF STRUCTURE ls_bape_vbakx TO <fieldhdrx>.
              <fieldhdrx> = abap_true.
            CATCH cx_sy_conversion_no_number INTO lo_error.

          ENDTRY.
        ELSE.
*       Feldname unbekann
        ENDIF.
      ENDIF.

      UNASSIGN: <fieldhdr>, <fieldhdrx>.
    ENDLOOP.

    CALL METHOD fill_bapi_header_customer
      EXPORTING
        is_bape_vbak  = ls_bape_vbak
        is_bape_vbakx = ls_bape_vbakx.



    CALL METHOD get_default_values
      EXPORTING
        iv_strname  = 'BAPISDHD1'
        iv_caller   = mv_caller
      CHANGING
        cs_zielstr  = ms_order_header_in
        cs_zielstrx = ms_order_header_inx.

    check_ag( ).
    check_we( ).

    IF ms_order_header_in-sales_off IS INITIAL.
      ms_order_header_in-sales_off  = ms_kunag-vkbur.
    ENDIF.

    IF ms_order_header_in-sales_grp IS INITIAL.
** Sonderlocke Verkaufsbüro /Verkäufergruppe
      SELECT SINGLE vkgrp INTO ms_order_header_in-sales_grp
        FROM  ysdsls_idocvkgrp
             WHERE  auart  = ms_order_header_in-doc_type
             AND    vkbur  = ms_order_header_in-sales_off.
    ENDIF.



  ENDMETHOD.
