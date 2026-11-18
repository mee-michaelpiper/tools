METHOD EXPORT_DB_CUSTOMER_SALESDATA.



    export_to_item(
      EXPORTING
        iv_vakey =  CONV #( ms_knvv-kunnr )
        is_quellstr  = ms_knvv
        iv_strnam    = 'KNVV'
      RECEIVING
        et_item      = DATA(lt_item) ).

    APPEND LINES OF lt_item TO et_item.




ENDMETHOD.
