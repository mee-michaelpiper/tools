  METHOD map_import.

    DATA(lt_header) =  is_import-i_header[].
    DATA(lt_item) =  is_import-i_item[].





    " SORT lt_item.
    CALL METHOD fill_bapi_partner( lt_item ).
    CALL METHOD fill_bapi_header( lt_header ).

    CALL METHOD fill_bapi_item( lt_item ).
    CALL METHOD fill_bapi_cond( lt_item ).
    CALL METHOD fill_bapi_text( lt_item ).

    CALL METHOD fill_bapi_schedule( lt_item ).

    "ms_cfgs = is_import-i_cfgs.
    CALL METHOD fill_bapi_cfgs( is_import-i_cfgs ).

  ENDMETHOD.
