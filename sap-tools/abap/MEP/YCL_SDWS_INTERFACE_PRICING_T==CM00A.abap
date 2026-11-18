  METHOD prepare_response.
*    IMPORTING it_result type prct_result_multi_item it_komp type VA_KOMp_T it_xkomv type va_komv_t
*             RETURNING VALUE(es_mat) TYPE YSDWS_TPRICING_E_T.

    DATA lr_relevant_stunr TYPE RANGE OF komv-stunr.
    DATA ls_komp           TYPE komp.
    DATA lt_komv           TYPE va_komv_t.

    IF ms_import-i_all_detail IS INITIAL.

      TRY.
          ycl_stvarvc=>get_selop( EXPORTING i_pname  = 'YSDWS_INTERFACE_PRICING'
                                            i_quali  = 'STUNR'
                                  IMPORTING et_selop = lr_relevant_stunr ).
        CATCH ycx_bc_err ##NO_HANDLER.
      ENDTRY.

    ENDIF.

    LOOP AT it_result ASSIGNING FIELD-SYMBOL(<rslt>).

      ls_komp = it_komp[ kposn = <rslt>-kposn ].
      IF ls_komp-uepos IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      ASSIGN rt_mat[ matnr = ls_komp-matnr ] TO FIELD-SYMBOL(<exp>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO rt_mat ASSIGNING <exp>.
        <exp>-matnr = ls_komp-matnr.
      ENDIF.

      APPEND INITIAL LINE TO <exp>-tiereds ASSIGNING FIELD-SYMBOL(<trds>).
      <trds>-yy_scale_prio = ls_komp-yy_scale_prio.
      <trds>-meinh         = ls_komp-vrkme.
      <trds>-umren         = ls_komp-umvkn.
      <trds>-umrez         = ls_komp-umvkz.

      REFRESH lt_komv.
      LOOP AT it_xkomv ASSIGNING FIELD-SYMBOL(<xkv>)
           FROM <rslt>-ix_komv_f TO <rslt>-ix_komv_t.
        APPEND <xkv> TO lt_komv.
      ENDLOOP.

      CALL FUNCTION 'PRICING_DIALOG_PAI'
        EXPORTING comm_head_i = it_komk[ 1 ]
                  comm_item_i = ls_komp
        TABLES    tkomv       = lt_komv.

      LOOP AT lt_komv ASSIGNING FIELD-SYMBOL(<komv>) WHERE stunr IN lr_relevant_stunr.

        APPEND INITIAL LINE TO <trds>-levels ASSIGNING FIELD-SYMBOL(<lvl>).
        MOVE-CORRESPONDING <komv> TO <lvl>.

      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.
