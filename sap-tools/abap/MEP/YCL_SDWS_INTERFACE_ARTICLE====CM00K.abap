  METHOD GET_PRODH_TEXT.
    DATA: lv_node   TYPE t179-prodh,
          lv_index  type n,
          lt_t179   TYPE TABLE OF prodh_disp,
          ls_values TYPE  YSDWS_COMITM_S.

    FIELD-SYMBOLS: <ls_t179> TYPE prodh_disp.

    lv_node = iv_value.
    CALL FUNCTION 'RV_PRODUKTHIERARCHIE_PRED_GET'
      EXPORTING
        spras               = sy-langu  "mv_spras
        node                = lv_node
      TABLES
        disp_t179           = lt_t179
      EXCEPTIONS
        node_does_not_exist = 1
        OTHERS              = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

  do 5 times.
    clear ls_values.
    UNASSIGN <ls_t179>.
    READ TABLE lt_t179 INDEX sy-index ASSIGNING <ls_t179>.
    if <ls_t179> is ASSIGNED.
      ls_values-fvalue     = <ls_t179>-vtext.
    endif.
*    LOOP AT lt_t179 ASSIGNING <ls_t179>.
    move sy-index to lv_index.
      CONCATENATE iv_fieldname lv_index INTO ls_values-QUALIF.
      CONDENSE ls_values-qualif.
      ls_values-vakey    = iv_vakey.
      APPEND ls_values TO ct_values.
*    ENDLOOP.
   enddo.
  ENDMETHOD.
