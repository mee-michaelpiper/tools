METHOD export_db_materialssold_data.

  LOOP AT mt_soldmat ASSIGNING FIELD-SYMBOL(<smat>).

    AT NEW matnr.
      DATA(ls_smat) = <smat>.
    ENDAT.

    IF <smat>-vrkme NE <smat>-meins.
      CALL FUNCTION 'UNIT_CONVERSION_SIMPLE'
        EXPORTING
          input                = <smat>-fkimg
          unit_in              = <smat>-vrkme
          unit_out             = <smat>-meins
        IMPORTING
          output               = <smat>-fkimg
        EXCEPTIONS
          conversion_not_found = 1
          division_by_zero     = 2
          input_invalid        = 3
          output_invalid       = 4
          overflow             = 5
          type_invalid         = 6
          units_missing        = 7
          unit_in_not_found    = 8
          unit_out_not_found   = 9
          OTHERS               = 10.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.

    ENDIF.
    ADD <smat>-fkimg TO ls_smat-sum_fkimg.
    ADD 1 TO ls_smat-cnt_mat.

    AT END OF matnr.
      export_to_item(
        EXPORTING
          iv_vakey = CONV #( ls_smat-matnr )
          is_quellstr  = ls_smat
          iv_strnam    = 'YSDWS_S_MATSOLD' " WebShop: verkaufte Artikel
        RECEIVING
          et_item      = DATA(lt_item) ).

      APPEND LINES OF lt_item TO et_item.

      ADD 1 TO mv_number_of_documents.
    ENDAT.
  ENDLOOP.


ENDMETHOD.
