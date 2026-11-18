METHOD EXPORT_DB_CUSTOMER_GENERALDATA.

  LOOP AT mt_kna1 ASSIGNING FIELD-SYMBOL(<kna1>).

    export_to_item(
      EXPORTING
        iv_vakey = CONV #( <kna1>-kunnr )
        is_quellstr  = <kna1>
        iv_strnam    = 'KNA1'
      RECEIVING
        et_item      = DATA(lt_item) ).

    APPEND LINES OF lt_item TO et_item.

    ADD 1 TO mv_number_of_documents.

  ENDLOOP.


ENDMETHOD.
