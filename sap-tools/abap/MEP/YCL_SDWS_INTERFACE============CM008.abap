  METHOD get_prodh_text.
    DATA: lv_node   TYPE t179-prodh,
          lv_index  TYPE n,
          lt_t179   TYPE TABLE OF prodh_disp,
          ls_values TYPE  ysdws_comitm_s.

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

    DO 5 TIMES.
      CLEAR ls_values.
      UNASSIGN <ls_t179>.
      READ TABLE lt_t179 INDEX sy-index ASSIGNING <ls_t179>.
      IF <ls_t179> IS ASSIGNED.
        ls_values-fvalue     = <ls_t179>-vtext.
      ENDIF.
*    LOOP AT lt_t179 ASSIGNING <ls_t179>.
      MOVE sy-index TO lv_index.
      CONCATENATE iv_fieldname lv_index INTO ls_values-qualif.
      CONDENSE ls_values-qualif.
      ls_values-vakey    = iv_vakey.
      APPEND ls_values TO ct_values.
*    ENDLOOP.
    ENDDO.
  ENDMETHOD.
