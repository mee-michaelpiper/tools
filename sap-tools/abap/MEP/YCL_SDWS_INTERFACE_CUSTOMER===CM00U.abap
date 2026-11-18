METHOD export_db_customermaterial_dat.

  LOOP AT mt_knmt ASSIGNING FIELD-SYMBOL(<knmt>).

    export_to_item(
      EXPORTING
        iv_vakey = CONV #( <knmt>-matnr )
        is_quellstr  = <knmt>
        iv_strnam    = 'KNMT'
      RECEIVING
        et_item      = DATA(lt_item) ).

    APPEND LINES OF lt_item TO et_item.

    ADD 1 TO mv_number_of_documents.

  ENDLOOP.


ENDMETHOD.
